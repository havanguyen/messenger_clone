/// Message Repository Interface
///
/// Extended abstract repository for message operations with Either pattern.
library;

import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

abstract class MessageRepository {
  /// Get messages for a group chat
  Future<Either<Failure, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
    DateTime? newerThan,
  );

  /// Send a message
  Future<Either<Failure, MessageModel>> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  );

  /// Get chat stream for real-time updates
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getChatStream(
    String groupChatId,
  );

  /// Create group messages
  Future<Either<Failure, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });

  /// Get group message by group ID
  Future<Either<Failure, GroupMessage?>> getGroupMessagesByGroupId(
    String groupId,
  );

  /// Update message
  Future<Either<Failure, void>> updateMessage(MessageModel message);

  /// Get messages stream
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getMessagesStream(
    List<String> messageIds,
  );

  /// Upload file
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    String filePath,
    String senderId,
  );

  /// Download file
  Future<Either<Failure, String>> downloadFile(String url, String filePath);

  /// Get message by ID
  Future<Either<Failure, MessageModel>> getMessageById(String messageId);

  /// Get public URL for file
  String getPublicUrl(String filePath);

  /// Send push notification
  Future<Either<Failure, void>> sendPushNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  });
}
