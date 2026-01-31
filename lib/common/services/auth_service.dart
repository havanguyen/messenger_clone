import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/services/store.dart';
import 'package:messenger_clone/features/messages/data/data_sources/local/hive_chat_repository.dart';
// import 'package:messenger_clone/features/chat/model/user.dart' as chat_model; // Use if needed
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../features/meta_ai/data/meta_ai_message_hive.dart';
import 'network_utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<String?> getUserIdFromEmail(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response =
            await _supabase
                .from('users')
                .select('id')
                .eq('email', email)
                .maybeSingle();

        if (response == null) return null;
        // In Postgres/Supabase, id is usually matching Auth uid if set up that way,
        // or a uuid. We assume we are using the auth uid as the id in the users table.
        return response['id'] as String?;
      } catch (e) {
        return null; // Return null on error
      }
    });
  }

  static Future<String?> getUserIdFromEmailAndPassword(
    String email,
    String password,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final userId = credential.user?.uid;
        // We sign out immediately because this method just wants to resolve the ID
        await signOut();
        return userId;
      } on FirebaseAuthException {
        return null;
      }
    });
  }

  static Future<bool> isEmailRegistered(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response =
            await _supabase
                .from('users')
                .select('id')
                .eq('email', email)
                .maybeSingle();
        return response != null;
      } catch (e) {
        return false;
      }
    });
  }

  static Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    // Firebase handles password reset via email usually.
    // This signature is awkward for Firebase. We should preferably use email.
    // Ideally we fetch email from userId then send rest.
    try {
      final response =
          await _supabase
              .from('users')
              .select('email')
              .eq('id', userId)
              .maybeSingle();
      if (response != null && response['email'] != null) {
        await _auth.sendPasswordResetEmail(email: response['email']);
      }
    } catch (e) {
      throw Exception("Failed to initiate password reset: $e");
    }
  }

  static Future<void> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception("No user logged in");

        if (name != null) {
          await user.updateDisplayName(name);
          await _supabase.from('users').update({'name': name}).eq('id', userId);
        }
        if (email != null) {
          await user.verifyBeforeUpdateEmail(email);
          // Note: Updating email in DB should probably happen after verification in a real app,
          // but for now we sync it.
          await _supabase
              .from('users')
              .update({'email': email})
              .eq('id', userId);
        }
        if (password != null) {
          await user.updatePassword(password);
        }
      } catch (e) {
        throw Exception('Error updating authentication details: $e');
      }
    });
  }

  static Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(name);
          await _registerUser(user, name);
        }
        return user;
      } on FirebaseAuthException catch (e) {
        throw Exception('Sign up failed: ${e.message}');
      }
    });
  }

  static Future<void> _registerUser(User user, String name) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase.from('users').upsert({
          'id': user.uid,
          'email': user.email,
          'name': name,
          'pushTargets': [],
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        throw Exception('Failed to register user: $e');
      }
    });
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && credential.user != null) {
          await _updatePushToken(credential.user!.uid, fcmToken);
        }

        if (credential.user != null) {
          HiveService.instance.saveCurrentUserId(credential.user!.uid);
        }

        return credential;
      } on FirebaseAuthException catch (e) {
        throw Exception('Sign in failed: ${e.message}');
      }
    });
  }

  static Future<void> _updatePushToken(String userId, String token) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('pushTargets')
              .eq('id', userId)
              .maybeSingle();
      if (response != null) {
        List<dynamic> targets = response['pushTargets'] ?? [];
        // Cast to String list safely
        List<String> stringTargets = targets.map((e) => e.toString()).toList();

        if (!stringTargets.contains(token)) {
          stringTargets.add(token);
          await _supabase
              .from('users')
              .update({'pushTargets': stringTargets})
              .eq('id', userId);
          await Store.setTargetId(token);
        }
      }
    } catch (e) {
      // Ignore push token update errors
      print("Error updating push token: $e");
    }
  }

  static Future<void> signOut() async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        String token = await Store.getTargetId();
        String userId = await HiveService.instance.getCurrentUserId();

        if (token.isNotEmpty &&
            userId.isNotEmpty &&
            _auth.currentUser != null) {
          final response =
              await _supabase
                  .from('users')
                  .select('pushTargets')
                  .eq('id', userId)
                  .maybeSingle();
          if (response != null) {
            List<dynamic> targets = response['pushTargets'] ?? [];
            List<String> stringTargets =
                targets.map((e) => e.toString()).toList();
            stringTargets.remove(token);
            await _supabase
                .from('users')
                .update({'pushTargets': stringTargets})
                .eq('id', userId);
          }
        }

        await Store.setTargetId('');
        MetaAiServiceHive.clearAllBoxes();
        HiveService.instance.clearCurrentUserId();
        await HiveChatRepository.instance.clearAllMessages();
        await _auth.signOut();
      } catch (e) {
        return;
      }
    });
  }

  static Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  static Future<String?> isLoggedIn() async {
    final user = _auth.currentUser;
    return user?.uid;
  }

  static Future<void> deleteAccount() async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final userId = user.uid;
        HiveService.instance.clearCurrentUserId();
        await HiveChatRepository.instance.clearAllMessages();

        // Delete user from Supabase
        await _supabase.from('users').delete().eq('id', userId);

        // Delete auth account
        await user.delete();
      } catch (e) {
        throw Exception('An error occurred while deleting account: $e');
      }
    });
  }

  static Future<void> reauthenticate(String password) async {
    return NetworkUtils.withNetworkCheck(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");
      if (user.email == null) throw Exception("User email not found");

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    });
  }
}
