import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

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
      final id = box.get('currentUserId');
      if (id != null && id.isNotEmpty) {
        currentUserId = id;
        return id;
      }
      return currentUserId ?? '';
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
    return '';
  }
}
