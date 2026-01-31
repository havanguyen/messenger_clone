/// Chat Repository Implementation
///
/// Implements the abstract ChatRepository interface from domain layer.
/// Coordinates between remote and local data sources.
library;

import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/network/network_info.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart'
    as domain;
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

class ChatRepositoryImpl implements domain.ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<GroupMessage>>> getGroupMessagesByUserId(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getGroupMessagesByUserId(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupMessage>> getGroupMessageById(
    String groupMessId,
  ) async {
    try {
      final result = await remoteDataSource.getGroupMessageById(groupMessId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getFriendsList(String userId) async {
    try {
      final result = await remoteDataSource.getFriendsList(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<User>>> getAllUsers() async {
    try {
      final result = await remoteDataSource.getAllUsers();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final result = await remoteDataSource.getUserById(userId);
      if (result == null) {
        return Left(ServerFailure(message: 'User not found'));
      }
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroupMessage(
    GroupMessage groupMessage,
  ) async {
    try {
      await remoteDataSource.updateGroupMessage(groupMessage);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  ) async {
    try {
      await remoteDataSource.updateChattingWithGroupMessId(userId, groupMessId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
    String? createrId,
  }) async {
    try {
      final result = await remoteDataSource.createGroupMessages(
        groupName: groupName,
        userIds: userIds,
        avatarGroupUrl: avatarGroupUrl,
        isGroup: isGroup,
        groupId: groupId,
        createrId: createrId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  ) async {
    try {
      await remoteDataSource.updateMemberOfGroup(groupMessId, memberIds);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  ) async {
    return await remoteDataSource.getStreamToUpdateChatPage(userId);
  }

  @override
  Future<Either<Failure, String>> uploadFile(
    String filePath,
    String senderId,
  ) async {
    try {
      final result = await remoteDataSource.uploadFile(filePath, senderId);
      return Right(result['\$id'] as String);
    } catch (e) {
      return Left(StorageFailure(message: e.toString()));
    }
  }

  @override
  String getPublicUrl(String filePath) {
    return remoteDataSource.getPublicUrl(filePath);
  }
}
