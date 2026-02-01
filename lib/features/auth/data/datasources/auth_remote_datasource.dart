/// Auth Remote Data Source
///
/// Handles Firebase Authentication and Firestore operations for auth.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_clone/core/network/network_utils.dart';

/// Abstract interface for auth remote data source
abstract class AuthRemoteDataSource {
  Future<String?> getUserIdFromEmail(String email);
  Future<String?> getUserIdFromEmailAndPassword(String email, String password);
  Future<bool> isEmailRegistered(String email);
  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  });
  Future<void> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  });
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut(String userId, String token);
  Future<User?> getCurrentUser();
  Future<String?> isLoggedIn();
  Future<void> deleteAccount();
  Future<void> reauthenticate(String password);
  Future<String?> getFcmToken();
  Future<void> updatePushToken(String userId, String token);
}

/// Implementation using Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String?> getUserIdFromEmail(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final snapshot =
            await _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) return null;
        return snapshot.docs.first.id;
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<String?> getUserIdFromEmailAndPassword(
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
        await _auth.signOut();
        return userId;
      } on FirebaseAuthException {
        return null;
      }
    });
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final snapshot =
            await _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();
        return snapshot.docs.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
  }

  @override
  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null && doc.data()!['email'] != null) {
        await _auth.sendPasswordResetEmail(email: doc.data()!['email']);
      }
    } catch (e) {
      throw Exception("Failed to initiate password reset: $e");
    }
  }

  @override
  Future<void> updateUserAuth({
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
          await _firestore.collection('users').doc(userId).update({
            'name': name,
          });
        }
        if (email != null) {
          await user.verifyBeforeUpdateEmail(email);
          await _firestore.collection('users').doc(userId).update({
            'email': email,
          });
        }
        if (password != null) {
          await user.updatePassword(password);
        }
      } catch (e) {
        throw Exception('Error updating authentication details: $e');
      }
    });
  }

  @override
  Future<User?> signUp({
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

  Future<void> _registerUser(User user, String name) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _firestore.collection('users').doc(user.uid).set({
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

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return credential;
      } on FirebaseAuthException catch (e) {
        throw Exception('Sign in failed: ${e.message}');
      }
    });
  }

  @override
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> updatePushToken(String userId, String token) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      await docRef.update({
        'pushTargets': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      print("Error updating push token: $e");
    }
  }

  @override
  Future<void> signOut(String userId, String token) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        if (token.isNotEmpty &&
            userId.isNotEmpty &&
            _auth.currentUser != null) {
          final docRef = _firestore.collection('users').doc(userId);
          await docRef.update({
            'pushTargets': FieldValue.arrayRemove([token]),
          });
        }
        await _auth.signOut();
      } catch (e) {
        return;
      }
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  @override
  Future<String?> isLoggedIn() async {
    final user = _auth.currentUser;
    return user?.uid;
  }

  @override
  Future<void> deleteAccount() async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final user = _auth.currentUser;
        if (user == null) return;

        final userId = user.uid;
        await _firestore.collection('users').doc(userId).delete();
        await user.delete();
      } catch (e) {
        throw Exception('An error occurred while deleting account: $e');
      }
    });
  }

  @override
  Future<void> reauthenticate(String password) async {
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
