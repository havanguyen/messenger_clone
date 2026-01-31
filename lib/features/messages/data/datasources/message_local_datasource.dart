/// Message Local Data Source
///
/// Handles local caching of messages using Hive.
library;

import 'package:messenger_clone/features/messages/data/datasources/local/hive_chat_repository.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

/// Abstract interface for message local data source
abstract class MessageLocalDataSource {
  Future<List<MessageModel>> getCachedMessages(String groupChatId);
  Future<void> cacheMessages(String groupChatId, List<MessageModel> messages);
  Future<void> cacheMessage(MessageModel message);
  Future<void> clearMessages(String groupChatId);
  Future<void> clearAllMessages();
}

/// Implementation using Hive
class MessageLocalDataSourceImpl implements MessageLocalDataSource {
  @override
  Future<List<MessageModel>> getCachedMessages(String groupChatId) async {
    final messages = await HiveChatRepository.instance.getMessages(groupChatId);
    return messages ?? [];
  }

  @override
  Future<void> cacheMessages(
    String groupChatId,
    List<MessageModel> messages,
  ) async {
    await HiveChatRepository.instance.saveMessages(groupChatId, messages);
  }

  @override
  Future<void> cacheMessage(MessageModel message) async {
    await HiveChatRepository.instance.addMessage(message.groupMessagesId, [
      message,
    ]);
  }

  @override
  Future<void> clearMessages(String groupChatId) async {
    await HiveChatRepository.instance.clearMessages(groupChatId);
  }

  @override
  Future<void> clearAllMessages() async {
    await HiveChatRepository.instance.clearAllMessages();
  }
}
