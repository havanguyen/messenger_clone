/// Message Repository Implementation
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/network/network_info.dart';
import 'package:messenger_clone/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:messenger_clone/features/messages/data/datasources/message_local_datasource.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final MessageLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<MessageModel>>> getMessages(
    String groupChatId,
    int limit,
    int offset,
    DateTime? newerThan,
  ) async {
    try {
      // Try cache first
      final cachedMessages = await localDataSource.getCachedMessages(
        groupChatId,
      );
      if (cachedMessages.isNotEmpty && !await networkInfo.isConnected) {
        return Right(cachedMessages);
      }

      // Fetch from remote
      final messages = await remoteDataSource.getMessages(
        groupChatId,
        limit,
        offset,
        newerThan,
      );

      // Cache the messages
      await localDataSource.cacheMessages(groupChatId, messages);

      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      final sentMessage = await remoteDataSource.sendMessage(
        message,
        groupMessage,
      );
      await localDataSource.cacheMessage(sentMessage);
      return Right(sentMessage);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getChatStream(
    String groupChatId,
  ) async {
    try {
      final stream = await remoteDataSource.getChatStream(groupChatId);
      return Right(stream);
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
  Future<Either<Failure, GroupMessage?>> getGroupMessagesByGroupId(
    String groupId,
  ) async {
    try {
      final result = await remoteDataSource.getGroupMessagesByGroupId(groupId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessage(MessageModel message) async {
    try {
      await remoteDataSource.updateMessage(message);
      await localDataSource.cacheMessage(message);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Map<String, dynamic>>>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    try {
      final stream = await remoteDataSource.getMessagesStream(messageIds);
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    String filePath,
    String senderId,
  ) async {
    try {
      final result = await remoteDataSource.uploadFile(filePath, senderId);
      return Right(result);
    } catch (e) {
      return Left(StorageFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile(
    String url,
    String filePath,
  ) async {
    try {
      final result = await remoteDataSource.downloadFile(url, filePath);
      return Right(result);
    } catch (e) {
      return Left(StorageFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MessageModel>> getMessageById(String messageId) async {
    try {
      final result = await remoteDataSource.getMessageById(messageId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  String getPublicUrl(String filePath) {
    return remoteDataSource.getPublicUrl(filePath);
  }

  @override
  Future<Either<Failure, void>> sendPushNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  }) async {
    try {
      await remoteDataSource.sendPushNotification(
        userIds: userIds,
        groupMessageId: groupMessageId,
        messageContent: messageContent,
        senderId: senderId,
        senderName: senderName,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
