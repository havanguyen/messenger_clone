library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:flutter/foundation.dart';
abstract class MessageRemoteDataSource {
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
  Future<Stream<List<Map<String, dynamic>>>> getChatStream(String groupChatId);
  Future<GroupMessage> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId);
  Future<void> updateMessage(MessageModel message);
  Future<Stream<List<Map<String, dynamic>>>> getMessagesStream(
    List<String> messageIds,
  );
  Future<Map<String, dynamic>> uploadFile(String filePath, String senderId);
  Future<String> downloadFile(String url, String filePath);
  Future<MessageModel> getMessageById(String messageId);
  String getPublicUrl(String filePath);
  Future<void> sendPushNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  });
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<MessageModel>> getMessages(
    String groupChatId,
    int limit,
    int offset,
    DateTime? newerThan,
  ) async {
    try {
      debugPrint('MessageRepo: getMessages for $groupChatId limit $limit');
      var query = _firestore
          .collection('messages')
          .where('groupMessagesId', isEqualTo: groupChatId);

      if (newerThan != null) {
        query = query.where(
          'createdAt',
          isGreaterThan: newerThan.toIso8601String(),
        );
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit > 0) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => MessageModel.fromMap({...doc.data(), '\$id': doc.id}))
          .toList();
    } catch (error) {
      throw Exception("Failed to fetch messages: $error");
    }
  }

  @override
  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      final data = message.toJson();
      if (!data.containsKey('createdAt')) {
        data['createdAt'] = message.createdAt.toIso8601String();
      }

      final docRef = await _firestore.collection('messages').add(data);
      final messageId = docRef.id;

      await _firestore
          .collection('group_messages')
          .doc(groupMessage.groupMessagesId)
          .update({'lastMessage': messageId});

      final doc = await docRef.get();
      return MessageModel.fromMap({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getChatStream(
    String groupChatId,
  ) async {
    return _firestore
        .collection('group_messages')
        .doc(groupChatId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists
                  ? [
                    {...doc.data()!, '\$id': doc.id},
                  ]
                  : [],
        );
  }

  @override
  Future<GroupMessage> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup = false,
    required String groupId,
    String? createrId,
  }) async {
    try {
      final data = {
        'groupName': groupName,
        'avatarGroupUrl': avatarGroupUrl,
        'isGroup': isGroup,
        'groupId': groupId,
        'createrId': createrId,
        'users': userIds,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('group_messages').add(data);
      final doc = await docRef.get();

      return GroupMessage.fromJson({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to create group messages: $error");
    }
  }

  @override
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('group_messages')
              .where('groupId', isEqualTo: groupId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return GroupMessage.fromJson({...doc.data(), '\$id': doc.id});
      }
      return null;
    } catch (error) {
      throw Exception("Failed to get group message: $error");
    }
  }

  @override
  Future<void> updateMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .update(message.toJson());
    } catch (error) {
      throw Exception("Failed to update message: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    String groupMessId = messageIds.isNotEmpty ? messageIds.first : '';
    return _firestore
        .collection('messages')
        .where('groupMessagesId', isEqualTo: groupMessId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => {...d.data(), '\$id': d.id}).toList();
        });
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String senderId,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('File not found');
      final fileName = filePath.split('/').last;
      final path = '$senderId/$fileName';

      await _supabase.storage
          .from('chat_media')
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return {'\$id': path, 'name': fileName};
    } catch (e) {
      throw Exception("Failed to upload file: $e");
    }
  }

  @override
  Future<String> downloadFile(String url, String filePath) async {
    try {
      final bytes = await _supabase.storage.from('chat_media').download(url);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw Exception("Failed to download file: $e");
    }
  }

  @override
  Future<MessageModel> getMessageById(String messageId) async {
    try {
      final doc = await _firestore.collection('messages').doc(messageId).get();
      if (!doc.exists) throw Exception("Message not found");
      return MessageModel.fromMap({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to fetch message: $error");
    }
  }

  @override
  String getPublicUrl(String filePath) {
    try {
      return _supabase.storage.from('chat_media').getPublicUrl(filePath);
    } catch (e) {
      return filePath;
    }
  }

  @override
  Future<void> sendPushNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  }) async {
    try {
      final payload = {
        'type': 'message',
        'userIds': userIds,
        'groupMessageId': groupMessageId,
        'messageContent': messageContent,
        'senderId': senderId,
        'senderName': senderName,
      };

      await _supabase.functions.invoke('sendPush', body: payload);
    } catch (e) {
      throw Exception('Error sending push notification via Supabase: $e');
    }
  }
}
