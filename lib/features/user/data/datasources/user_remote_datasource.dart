import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class UserRemoteDataSource {
  Future<void> updateUserStatus(String userId, bool isActive);
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  });
  Future<String> updatePhotoUrl({
    required File imageFile,
    required String userId,
  });
  Future<Map<String, dynamic>> fetchUserDataById(String userId);
  Future<String?> getNameUser(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;
  final SupabaseClient supabase = Supabase.instance.client;

  UserRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    await firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'lastSeen': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (aboutMe != null) updates['aboutMe'] = aboutMe;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isEmpty) return;

    await firestore.collection('users').doc(userId).update(updates);
  }

  @override
  Future<String> updatePhotoUrl({
    required File imageFile,
    required String userId,
  }) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = '$userId/$fileName';

    await supabase.storage
        .from('avatars')
        .upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final newPhotoUrl = supabase.storage.from('avatars').getPublicUrl(path);

    await firestore.collection('users').doc(userId).update({
      'photoUrl': newPhotoUrl,
    });

    return newPhotoUrl;
  }

  @override
  Future<Map<String, dynamic>> fetchUserDataById(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found');

    final response = doc.data()!;
    return {
      'userName': response['name'] as String?,
      'photoUrl': response['photoUrl'] as String?,
      'userId': response['id'] ?? doc.id,
      'aboutMe': response['aboutMe'] as String?,
      'email': response['email'] as String?,
      'isActive': response['isActive'] as bool? ?? false,
    };
  }

  @override
  Future<String?> getNameUser(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['name'] as String?;
  }
}
