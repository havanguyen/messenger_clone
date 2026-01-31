import 'package:dartz/dartz.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

abstract class AbstractChatRepository {
  Future<List<MessageModel>> getMessages(
    String groupChatId,
    int limit,
    int offset,
    DateTime? newerThan,
  );
  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  );
  Future<Either<String, Stream<List<Map<String, dynamic>>>>> getChatStream(
    String groupChatId,
  );
  Future<Either<String, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
  });
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId);
  Future<void> updateMessage(MessageModel message);
  Future<Either<String, Stream<List<Map<String, dynamic>>>>> getMessagesStream(
    List<String> messageIds,
  );
  Future<Map<String, dynamic>> uploadFile(String filePath, String senderId);
  Future<String> downloadFile(String url, String filePath);
  Future<MessageModel> getMessageById(String messageId);
}
