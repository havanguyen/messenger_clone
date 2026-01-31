import 'dart:io';

import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as ChatModel;
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Group & User Methods ---

  Future<GroupMessage> updateGroupMessage(GroupMessage groupMessage) async {
    try {
      final response =
          await _supabase
              .from('group_messages')
              .update(groupMessage.toJson())
              .eq('id', groupMessage.groupMessagesId)
              .select()
              .single();
      return GroupMessage.fromJson(response);
    } catch (error) {
      throw Exception("Failed to update group message: $error");
    }
  }

  Future<void> updateChattingWithGroupMessId(
    String userId,
    String? groupMessId,
  ) async {
    try {
      await _supabase
          .from('users')
          .update({'chattingWithGroupMessId': groupMessId})
          .eq('id', userId);
    } catch (error) {
      throw Exception("Failed to update chattingWithGroupMessId: $error");
    }
  }

  Future<List<GroupMessage>> getGroupMessByIds(
    List<String> groupMessageIds,
  ) async {
    final List<GroupMessage> groupMessages = [];
    try {
      if (groupMessageIds.isEmpty) return [];

      final response = await _supabase
          .from('group_messages')
          .select()
          .filter('id', 'in', groupMessageIds); // Use filter for 'in' operation

      for (var doc in response) {
        final group = GroupMessage.fromJson(doc);
        groupMessages.add(group);
      }
    } catch (error) {
      throw Exception("Failed to fetch group chats: $error");
    }
    return groupMessages;
  }

  Future<List<ChatModel.User>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select();

      return (response as List).map((data) {
        final map = Map<String, dynamic>.from(data);
        if (!map.containsKey('\$id') && map.containsKey('id')) {
          map['\$id'] = map['id'];
        }
        return ChatModel.User.fromMap(map);
      }).toList();
    } catch (error) {
      throw Exception("Failed to fetch users: $error");
    }
  }

  Future<ChatModel.User?> getUserById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response);
      if (!map.containsKey('\$id') && map.containsKey('id')) {
        map['\$id'] = map['id'];
      }

      return ChatModel.User.fromMap(map);
    } catch (error) {
      throw Exception("Failed to fetch user: $error");
    }
  }

  Future<List<GroupMessage>> getGroupMessagesByUserId(String userId) async {
    try {
      final userResponse =
          await _supabase
              .from('users')
              .select('groupMessages')
              .eq('id', userId)
              .maybeSingle();

      if (userResponse == null) return [];

      final List<dynamic> groupMessages = userResponse['groupMessages'] ?? [];
      final List<String> groupMessIds =
          groupMessages
              .map((e) {
                if (e is String) return e;
                if (e is Map) return e['id'] ?? e['\$id'];
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

  Future<Stream<List<Map<String, dynamic>>>> getStreamToUpdateChatPage(
    String userId,
  ) async {
    try {
      return _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId);
    } catch (error) {
      throw Exception("Failed to getStreamToUpdateChatPage: $error");
    }
  }

  Future<Stream<List<Map<String, dynamic>>>> getUserStream(
    String userId,
  ) async {
    try {
      return _supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId);
    } catch (error) {
      throw Exception("Failed to fetch user stream: $error");
    }
  }

  Future<Stream<List<Map<String, dynamic>>>> getGroupMessageStream(
    String groupMessId,
  ) async {
    try {
      return _supabase
          .from('group_messages')
          .stream(primaryKey: ['id'])
          .eq('id', groupMessId);
    } catch (error) {
      throw Exception("Failed to fetch group message stream: $error");
    }
  }

  Future<GroupMessage> getGroupMessageById(String groupMessId) async {
    try {
      final groupMessage = await getGroupMessByIds([groupMessId]);
      return groupMessage.first;
    } catch (error) {
      throw Exception("Failed to fetch group message: $error");
    }
  }

  Future<List<ChatModel.User>> getFriendsList(String userId) async {
    try {
      final sentFriends = await _supabase
          .from('friends')
          .select()
          .eq('userId', userId)
          .eq('status', 'accepted');

      final receivedFriends = await _supabase
          .from('friends')
          .select()
          .eq('friendId', userId)
          .eq('status', 'accepted');

      final Set<String> friendIds = {};
      for (var doc in sentFriends) {
        friendIds.add(doc['friendId'] as String);
      }
      for (var doc in receivedFriends) {
        friendIds.add(doc['userId'] as String);
      }

      if (friendIds.isEmpty) return [];

      final friendsResponse = await _supabase
          .from('users')
          .select()
          .filter('id', 'in', friendIds.toList());

      return (friendsResponse as List).map((data) {
        final map = Map<String, dynamic>.from(data);
        if (!map.containsKey('\$id') && map.containsKey('id')) {
          map['\$id'] = map['id'];
        }
        return ChatModel.User.fromMap(map);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching friends list: $e');
    }
  }

  Future<GroupMessage> updateMemberOfGroup(
    String groupMessId,
    Set<String> memberIds,
  ) async {
    try {
      final response =
          await _supabase
              .from('group_messages')
              .update({'users': memberIds.toList()})
              .eq('id', groupMessId)
              .select()
              .single();

      return GroupMessage.fromJson(response);
    } catch (error) {
      throw Exception("Failed to update member of group: $error");
    }
  }

  // --- Message & Storage Methods ---

  Future<MessageModel> getMessageById(String messageId) async {
    try {
      final response =
          await _supabase
              .from('messages')
              .select()
              .eq('id', messageId)
              .single();
      return MessageModel.fromMap(response);
    } catch (error) {
      throw Exception("Failed to fetch message by ID: $error");
    }
  }

  Future<MessageModel> updateMessage(MessageModel message) async {
    try {
      final response =
          await _supabase
              .from('messages')
              .update(message.toJson())
              .eq('id', message.id)
              .select()
              .single();
      return MessageModel.fromMap(response);
    } catch (error) {
      throw Exception("Failed to update message: $error");
    }
  }

  Future<Stream<List<Map<String, dynamic>>>> getMessagesStream(
    List<String> messageIds,
  ) async {
    return _supabase.from('messages').stream(primaryKey: ['id']);
  }

  Future<List<MessageModel>> getMessages(
    String groupMessId,
    int limit,
    int offset,
    DateTime? newerThan,
  ) async {
    try {
      var query = _supabase
          .from('messages')
          .select()
          .eq('groupMessagesId', groupMessId);

      if (newerThan != null) {
        query = query.gt('createdAt', newerThan.toIso8601String());
      }

      // Order must be applied after filtering
      var orderedQuery = query.order('createdAt', ascending: false);

      if (newerThan == null) {
        final response = await orderedQuery.range(offset, offset + limit - 1);
        return (response as List)
            .map((doc) => MessageModel.fromMap(doc))
            .toList();
      } else {
        final response = await orderedQuery;
        return (response as List)
            .map((doc) => MessageModel.fromMap(doc))
            .toList();
      }
    } catch (error) {
      throw Exception("Failed to fetch messages: $error");
    }
  }

  Future<MessageModel> sendMessage(
    MessageModel message,
    GroupMessage groupMessage,
  ) async {
    try {
      final response =
          await _supabase
              .from('messages')
              .insert(message.toJson())
              .select()
              .single();

      final messageId = response['id'] ?? response['\$id'];

      // Update group with last message
      await _supabase
          .from('group_messages')
          .update({'lastMessage': messageId})
          .eq('id', groupMessage.groupMessagesId);

      return MessageModel.fromMap(response);
    } catch (error) {
      throw Exception("Failed to send message: $error");
    }
  }

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

      final response =
          await _supabase.from('group_messages').insert(data).select().single();

      return GroupMessage.fromJson({
        ...response,
        'groupMessagesId': response['id'] ?? response['\$id'],
      });
    } catch (error) {
      throw Exception("Failed to create group messages: $error");
    }
  }

  Future<GroupMessage?> getGroupMessagesByGroupId(String groupId) async {
    try {
      final response =
          await _supabase
              .from('group_messages')
              .select()
              .eq('groupId', groupId)
              .maybeSingle();

      if (response != null) {
        return GroupMessage.fromJson({
          ...response,
          'groupMessagesId': response['id'] ?? response['\$id'],
        });
      }
      return null;
    } catch (error) {
      throw Exception("Failed to get group message existence: $error");
    }
  }

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

  String getPublicUrl(String filePath) {
    try {
      return _supabase.storage.from('chat_media').getPublicUrl(filePath);
    } catch (e) {
      // If fail, return path or empty?
      return filePath;
    }
  }
}
