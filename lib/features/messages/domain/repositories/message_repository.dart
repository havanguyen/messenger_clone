library;

import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

abstract class MessageRepository {
  Future<Either<Failure, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
    DateTime? newerThan,
  );
  Future<Either<Failure, MessageModel>> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  );
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getChatStream(
    String groupChatId,
  );
  Future<Either<Failure, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });
  Future<Either<Failure, GroupMessage?>> getGroupMessagesByGroupId(
    String groupId,
  );
  Future<Either<Failure, void>> updateMessage(MessageModel message);
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getMessagesStream(
    List<String> messageIds,
  );
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    String filePath,
    String senderId,
  );
  Future<Either<Failure, String>> downloadFile(String url, String filePath);
  Future<Either<Failure, MessageModel>> getMessageById(String messageId);
  String getPublicUrl(String filePath);
  Future<Either<Failure, void>> sendPushNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  });
}
