import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:messenger_clone/core/local/secure_storage.dart';
import 'package:messenger_clone/features/meta_ai/data/meta_ai_message_hive.dart';
import 'package:messenger_clone/features/messages/data/datasources/local/hive_chat_repository.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUserId(String userId);
  Future<String?> getUserId();
  Future<void> clearUserData();
  Future<void> savePushToken(String token);
  Future<String?> getPushToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<void> saveUserId(String userId) async {
    await HiveService.instance.saveCurrentUserId(userId);
  }

  @override
  Future<String?> getUserId() async {
    final id = await HiveService.instance.getCurrentUserId();
    return id.isEmpty ? null : id;
  }

  @override
  Future<void> clearUserData() async {
    await Store.setTargetId('');
    MetaAiServiceHive.clearAllBoxes();
    HiveService.instance.clearCurrentUserId();
    await HiveChatRepository.instance.clearAllMessages();
  }

  @override
  Future<void> savePushToken(String token) async {
    await Store.setTargetId(token);
  }

  @override
  Future<String?> getPushToken() async {
    return await Store.getTargetId();
  }
}
