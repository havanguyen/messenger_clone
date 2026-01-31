/// Chat Remote Data Source
///
/// This is the old ChatRepository renamed to serve as DataSource.
/// It handles all remote operations with Firebase Firestore and Supabase Storage.
library;

import 'dart:io';

import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as ChatModel;
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract interface for remote data source
abstract class ChatRemoteDataSource {
  Future<GroupMessage> updateGroupMessage(GroupMessage groupMessage);
  Future<void> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  );
  Future<List<GroupMessage>> getGroupMessByIds(List<String> groupMessageIds);
  Future<List<ChatModel.User>> getAllUsers();
  Future<ChatModel.User?> getUserById(String userId);
  Future<List<GroupMessage>> getGroupMessagesByUserId(String userId);
  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  );
  Future<Stream<List<Map<String, dynamic>>>> getUserStream(String userId);
  Future<Stream<List<Map<String, dynamic>>>> getGroupMessageStream(
    String groupMessId,
  );
  Future<GroupMessage> getGroupMessageById(String groupMessId);
  Future<List<ChatModel.User>> getFriendsList(String userId);
  Future<GroupMessage> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  );
  Future<MessageModel> getMessageById(String messageId);
  Future<MessageModel> updateMessage(MessageModel message);
  Future<Stream<List<Map<String, dynamic>>>> getMessagesStream(
    List<String> messageIds,
  );
  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
    DateTime? newerThan,
  );
  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  );
  Future<GroupMessage> createGroupMessages({
    String? groupName,
    required List<String> userIds,
    String? avatarGroupUrl,
    bool isGroup,
    required String groupId,
    String? createrId,
  });
  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId);
  Future<dynamic> uploadFile(String filePath, String senderId);
  Future<String> downloadFile(String url, String filePath);
  String getPublicUrl(String filePath);
}

/// Implementation of ChatRemoteDataSource
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<GroupMessage> updateGroupMessage(GroupMessage groupMessage) async {
    try {
      await _firestore
          .collection('group_messages')
          .doc(groupMessage.groupMessagesId)
          .update(groupMessage.toJson());

      final doc =
          await _firestore
              .collection('group_messages')
              .doc(groupMessage.groupMessagesId)
              .get();

      return GroupMessage.fromJson({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to update group message: $error");
    }
  }

  @override
  Future<void> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'chattingWithGroupMessId': groupMessId,
      });
    } catch (error) {
      throw Exception("Failed to update chattingWithGroupMessId: $error");
    }
  }

  @override
  Future<List<GroupMessage>> getGroupMessByIds(
    List<String> groupMessageIds,
  ) async {
    final List<GroupMessage> groupMessages = [];
    try {
      if (groupMessageIds.isEmpty) return [];

      if (groupMessageIds.length > 10) {
        for (var id in groupMessageIds) {
          final doc =
              await _firestore.collection('group_messages').doc(id).get();
          if (doc.exists) {
            groupMessages.add(
              GroupMessage.fromJson({...doc.data()!, '\$id': doc.id}),
            );
          }
        }
      } else {
        final querySnapshot =
            await _firestore
                .collection('group_messages')
                .where(FieldPath.documentId, whereIn: groupMessageIds)
                .get();

        for (var doc in querySnapshot.docs) {
          final group = GroupMessage.fromJson({...doc.data(), '\$id': doc.id});
          groupMessages.add(group);
        }
      }
    } catch (error) {
      throw Exception("Failed to fetch group chats: $error");
    }
    return groupMessages;
  }

  @override
  Future<List<ChatModel.User>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        final map = doc.data();
        map['\$id'] = doc.id;
        return ChatModel.User.fromMap(map);
      }).toList();
    } catch (error) {
      throw Exception("Failed to fetch users: $error");
    }
  }

  @override
  Future<ChatModel.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final map = doc.data()!;
      map['\$id'] = doc.id;
      return ChatModel.User.fromMap(map);
    } catch (error) {
      throw Exception("Failed to fetch user: $error");
    }
  }

  @override
  Future<List<GroupMessage>> getGroupMessagesByUserId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data();
      if (data == null || !data.containsKey('groupMessages')) return [];

      final List<dynamic> groupMessages = data['groupMessages'] ?? [];
      final List<String> groupMessIds =
          groupMessages
              .map((e) {
                if (e is String) return e;
                if (e is Map) return e['\$id'] ?? e['id'];
                return null;
              })
              .whereType<String>()
              .toList();

      if (groupMessIds.isEmpty) {
        return [];
      }
      return getGroupMessByIds(groupMessIds);
    } catch (error) {
      throw Exception("Failed to fetch group messages: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  ) async {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map(
            (doc) =>
                doc.exists
                    ? [
                      {...doc.data()!, '\$id': doc.id},
                    ]
                    : [],
          );
    } catch (error) {
      throw Exception("Failed to getStreamToUpdateChatPage: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getUserStream(
    String userId,
  ) async {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map(
            (doc) =>
                doc.exists
                    ? [
                      {...doc.data()!, '\$id': doc.id},
                    ]
                    : [],
          );
    } catch (error) {
      throw Exception("Failed to fetch user stream: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getGroupMessageStream(
    String groupMessId,
  ) async {
    try {
      return _firestore
          .collection('group_messages')
          .doc(groupMessId)
          .snapshots()
          .map(
            (doc) =>
                doc.exists
                    ? [
                      {...doc.data()!, '\$id': doc.id},
                    ]
                    : [],
          );
    } catch (error) {
      throw Exception("Failed to fetch group message stream: $error");
    }
  }

  @override
  Future<GroupMessage> getGroupMessageById(String groupMessId) async {
    try {
      final groupMessage = await getGroupMessByIds([groupMessId]);
      return groupMessage.first;
    } catch (error) {
      throw Exception("Failed to fetch group message: $error");
    }
  }

  @override
  Future<List<ChatModel.User>> getFriendsList(String userId) async {
    try {
      final sentFriendsSnap =
          await _firestore
              .collection('friends')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();

      final receivedFriendsSnap =
          await _firestore
              .collection('friends')
              .where('friendId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();

      final Set<String> friendIds = {};
      for (var doc in sentFriendsSnap.docs) {
        friendIds.add(doc.data()['friendId'] as String);
      }
      for (var doc in receivedFriendsSnap.docs) {
        friendIds.add(doc.data()['userId'] as String);
      }

      if (friendIds.isEmpty) return [];

      final users = <ChatModel.User>[];
      if (friendIds.length > 10) {
        for (var fid in friendIds) {
          final u = await getUserById(fid);
          if (u != null) users.add(u);
        }
      } else {
        final usersSnap =
            await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: friendIds.toList())
                .get();
        for (var doc in usersSnap.docs) {
          final map = doc.data();
          map['\$id'] = doc.id;
          users.add(ChatModel.User.fromMap(map));
        }
      }
      return users;
    } catch (e) {
      throw Exception('Error fetching friends list: $e');
    }
  }

  @override
  Future<GroupMessage> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  ) async {
    try {
      await _firestore.collection('group_messages').doc(groupMessId).update({
        'users': memberIds.toList(),
      });

      final doc =
          await _firestore.collection('group_messages').doc(groupMessId).get();
      return GroupMessage.fromJson({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to update member of group: $error");
    }
  }

  @override
  Future<MessageModel> getMessageById(String messageId) async {
    try {
      final doc = await _firestore.collection('messages').doc(messageId).get();
      if (!doc.exists) throw Exception("Message not found");
      return MessageModel.fromMap({...doc.data()!, '\$id': doc.id});
    } catch (error) {
      throw Exception("Failed to fetch message by ID: $error");
    }
  }

  @override
  Future<MessageModel> updateMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .update(message.toJson());

      return await getMessageById(message.id);
    } catch (error) {
      throw Exception("Failed to update message: $error");
    }
  }

  @override
  Future<Stream<List<Map<String, dynamic>>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    return _firestore
        .collection('messages')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), '\$id': d.id}).toList(),
        );
  }

  @override
  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
    DateTime? newerThan,
  ) async {
    try {
      var query = _firestore
          .collection('messages')
          .where('groupMessagesId', isEqualTo: groupMessId);

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
      throw Exception("Failed to get group message existence: $error");
    }
  }

  @override
  Future<dynamic> uploadFile(String filePath, String senderId) async {
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
  String getPublicUrl(String filePath) {
    try {
      return _supabase.storage.from('chat_media').getPublicUrl(filePath);
    } catch (e) {
      return filePath;
    }
  }
}
