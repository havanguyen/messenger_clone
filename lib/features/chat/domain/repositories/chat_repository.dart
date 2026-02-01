library;

import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<GroupMessage>>> getGroupMessagesByUserId(
    String userId,
  );
  Future<Either<Failure, GroupMessage>> getGroupMessageById(String groupMessId);
  Future<Either<Failure, List<User>>> getFriendsList(String userId);
  Future<Either<Failure, List<User>>> getAllUsers();
  Future<Either<Failure, User>> getUserById(String userId);
  Future<Either<Failure, void>> updateGroupMessage(GroupMessage groupMessage);
  Future<Either<Failure, void>> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  );
  Future<Either<Failure, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });
  Future<Either<Failure, void>> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  );
  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  );
  Future<Either<Failure, String>> uploadFile(String filePath, String senderId);
  String getPublicUrl(String filePath);
}
