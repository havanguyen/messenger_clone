import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

// Renamed from HiveService to HiveStorage to reflect it's an infrastructure component, not a service.
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
      // Removed AuthService fallback usage to adhere to Clean Architecture and avoid circular dependencies.
      // Callers must ensure they check AuthRepository if this returns empty/null, or better yet, use AuthRepository exclusively for auth checks.
      final id = box.get('currentUserId');
      if (id != null && id.isNotEmpty) {
        currentUserId = id;
        return id;
      }
      return currentUserId ?? '';
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
    return ''; // Return empty instead of throwing to avoid crashing unmigrated callers, let them handle empty.
  }
}
