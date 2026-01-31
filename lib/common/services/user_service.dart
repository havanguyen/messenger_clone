import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<String>> getPushTargets(String userId) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('pushTargets')
              .eq('id', userId)
              .single();

      return List<String>.from(response['pushTargets'] ?? []);
    } catch (e) {
      throw Exception('Failed to get push targets: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return {
        'userName': response['name'] as String?,
        'photoUrl': response['photoUrl'] as String?,
        'userId': response['id'] ?? response['\$id'],
        'aboutMe': response['aboutMe'] as String?,
        'email': response['email'] as String?,
        'isActive': response['isActive'] as bool? ?? false,
      };
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (aboutMe != null) updates['aboutMe'] = aboutMe;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isEmpty) return;

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<void> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    required String password,
  }) async {
    try {
      final UserAttributes attributes = UserAttributes(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
      await _supabase.auth.updateUser(attributes);
    } catch (e) {
      throw Exception('Error updating authentication details: $e');
    }
  }

  static Future<String?> getNameUser(String userId) async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('name')
              .eq('id', userId)
              .single();
      return response['name'] as String?;
    } catch (e) {
      throw Exception('Failed to get user name: $e');
    }
  }

  static Future<String> updatePhotoUrl({
    required File imageFile,
    required String userId,
  }) async {
    return uploadAndUpdatePhoto(imageFile, userId);
  }

  static Future<String> uploadAndUpdatePhoto(
    File imageFile,
    String userId,
  ) async {
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '$userId/$fileName';

      await _supabase.storage
          .from('avatars')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final newPhotoUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      await _supabase
          .from('users')
          .update({'photoUrl': newPhotoUrl})
          .eq('id', userId);

      return newPhotoUrl;
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }
}
