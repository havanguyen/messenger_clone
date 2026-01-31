import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import 'auth_service.dart';

class HiveService {
  static final HiveService instance = HiveService._internal();
  late final Future<Box<String>> _box;
  String? currentUserId;

  factory HiveService() {
    return instance;
  }

  HiveService._internal() {
    _box = _initializeBox();
  }

  Future<Box<String>> _initializeBox() async {
    final box = await Hive.openBox<String>('currentUserBox');
    return box;
  }

  Future<void> saveCurrentUserId(String userId) async {
    final box = await _box;
    await box.put('currentUserId', userId);
    currentUserId = userId;
  }

  Future<void> clearCurrentUserId() async {
    final box = await _box;
    await box.delete('currentUserId');
    currentUserId = null;
  }

  Future<String> getCurrentUserId() async {
    try {
      final box = await _box;
      currentUserId = await AuthService.isLoggedIn();
      return box.get('currentUserId') ?? (currentUserId ?? '');
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
    throw Exception('Failed to get current user ID');
  }

  // Future<String> getCurrentUserId() async {
  //   try {
  //     if (currentUserId != null) {
  //       return currentUserId!;
  //     }
  //     final box = await _box;
  //     final currentUser = (await AuthService.getCurrentUser());
  //     currentUserId =
  //         box.get('currentUserId') ??
  //         ((currentUser == null ? '' : currentUser.$id));
  //     return currentUserId!;
  //   } catch (e) {
  //     debugPrint('Error getting current user ID: $e');
  //   }
  //   throw Exception('Failed to get current user ID');
  // }
}
