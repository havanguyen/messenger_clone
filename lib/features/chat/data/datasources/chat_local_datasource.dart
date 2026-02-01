library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

abstract class ChatLocalDataSource {
  Future<String> getCurrentUserId();
  Future<User?> getCachedUser(String oduserId);
  Future<void> cacheUser(User user);
  Future<List<User>> getCachedUsers();
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _userBoxName = 'userBox';
  static const String _currentUserIdKey = 'currentUserId';

  @override
  Future<String> getCurrentUserId() async {
    final box = await Hive.openBox(_userBoxName);
    final userId = box.get(_currentUserIdKey);
    if (userId == null || userId is! String || userId.isEmpty) {
      throw Exception('No current user ID found');
    }
    return userId;
  }

  @override
  Future<User?> getCachedUser(String userId) async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.get(userId);
  }

  @override
  Future<void> cacheUser(User user) async {
    final box = await Hive.openBox<User>(_userBoxName);
    await box.put(user.id, user);
  }

  @override
  Future<List<User>> getCachedUsers() async {
    final box = await Hive.openBox<User>(_userBoxName);
    return box.values.toList();
  }
}
