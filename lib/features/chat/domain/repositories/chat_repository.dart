/// Abstract Chat Repository Interface.
///
/// Defines the contract for chat data operations.
/// Implementation is in data/repositories/chat_repository_impl.dart
library;

import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

abstract class ChatRepository {
  /// Get all group messages for a user
  Future<Either<Failure, List<GroupMessage>>> getGroupMessagesByUserId(
    String userId,
  );

  /// Get a specific group message by ID
  Future<Either<Failure, GroupMessage>> getGroupMessageById(String groupMessId);

  /// Get friends list for a user
  Future<Either<Failure, List<User>>> getFriendsList(String userId);

  /// Get all users
  Future<Either<Failure, List<User>>> getAllUsers();

  /// Get user by ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Update group message
  Future<Either<Failure, void>> updateGroupMessage(GroupMessage groupMessage);

  /// Update chatting status
  Future<Either<Failure, void>> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  );

  /// Create new group message
  Future<Either<Failure, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });

  /// Update member of group
  Future<Either<Failure, void>> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  );

  /// Get stream for real-time updates
  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  );

  /// Upload file
  Future<Either<Failure, String>> uploadFile(String filePath, String senderId);

  /// Get public URL for file
  String getPublicUrl(String filePath);
}
