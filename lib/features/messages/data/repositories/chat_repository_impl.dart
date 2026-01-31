import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/chat_repository.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/abstract_chat_repository.dart';

class ChatRepositoryImpl implements AbstractChatRepository {
  late final ChatRepository chatRepository;

  ChatRepositoryImpl() {
    chatRepository = ChatRepository();
  }

  @override
  Future<MessageModel> getMessageById(String messageId) async {
    try {
      final response = await chatRepository.getMessageById(messageId);
      return response;
    } catch (error) {
      debugPrint("Failed to fetch message: $error");
      throw Exception("Failed to fetch message: $error");
    }
  }

  @override
  Future<Either<String, Stream<List<Map<String, dynamic>>>>> getChatStream(
    String groupMessId,
  ) async {
    try {
      final response = await chatRepository.getGroupMessageStream(groupMessId);
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch chat stream: $error");
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
    DateTime? newerThan,
  ) async {
    try {
      final response = await chatRepository.getMessages(
        groupMessId,
        limit,
        offset,
        newerThan,
      );
      return response;
    } catch (error) {
      debugPrint("Failed to fetch messages: $error");
      return [];
    }
  }

  @override
  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      return chatRepository.sendMessage(message, groupMessage);
    } catch (error) {
      debugPrint("Failed to send message: $error");
      throw Exception("Failed to send message: $error");
    }
  }

  @override
  Future<Either<String, GroupMessage>> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
  }) async {
    try {
      // Logic for createrId might be needed if not passed.
      // Assuming createrId is handled inside or passed?
      // Abstract signature matches implementation args.
      final GroupMessage response = await chatRepository.createGroupMessages(
        groupName: groupName,
        userIds: userIds,
        avatarGroupUrl: avatarGroupUrl,
        isGroup: isGroup,
        groupId: groupId,
        // createrId? The abstract method doesn't have it?
        // In Appwrite impl it was passed? No, abstract method line 21 just has these args.
        // But AppwriteChatRepository.createGroupMessages had createrId.
        // Let's check abstract repo again. It does NOT have createrId.
        // So we might need to fetch meId here or it is not used?
        // Wait, createGroupMessages in Abstract definition:
        /*
            Future<Either<String, GroupMessage>> createGroupMessages({
                String? groupName,
                required List<String> userIds,
                String? avatarGroupUrl,
                bool isGroup = false,
                required String groupId,
             });
            */
        // So we don't pass createrId. ChatRepository needs it?
        // ChatRepository.createGroupMessages({..., String? createrId})
        // We can pass null or fetch it.
      );

      return Right(response);
    } catch (error) {
      return Left("Failed to create group messages: $error");
    }
  }

  @override
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId) async {
    return await chatRepository.getGroupMessagesByGroupId(groupId);
  }

  @override
  Future<void> updateMessage(MessageModel message) async {
    await chatRepository.updateMessage(message);
  }

  @override
  Future<Either<String, Stream<List<Map<String, dynamic>>>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    try {
      final response = await chatRepository.getMessagesStream(messageIds);
      return Right(response);
    } catch (error) {
      return Left("Failed to fetch message stream: $error");
    }
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String senderId,
  ) async {
    try {
      final result = await chatRepository.uploadFile(filePath, senderId);
      return result as Map<String, dynamic>;
    } catch (error) {
      debugPrint("Failed to upload file: $error");
      throw Exception("Failed to upload file: $error");
    }
  }

  @override
  Future<String> downloadFile(String url, String filePath) async {
    try {
      return chatRepository.downloadFile(url, filePath);
    } catch (error) {
      debugPrint("Failed to download file: $error");
      throw Exception("Failed to download file: $error");
    }
  }
}
