/// MetaAI Remote Data Source
library;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart'; // Uuid not used if I use document ID or existing ID logic?
// AIService used Uuid().v4().
import 'package:uuid/uuid.dart';
import 'package:messenger_clone/core/network/network_utils.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';

/// Abstract interface for Meta AI data source
abstract class MetaAiRemoteDataSource {
  Future<String> sendMessage(String message, String conversationId);
  Future<String> createConversation({String? title});
  Future<List<Map<String, dynamic>>> getConversations();
  Future<void> deleteConversation(String conversationId);
  Future<List<Map<String, String>>> loadConversationMessages(
    String conversationId,
  );
}

/// Implementation using Firestore and Supabase
class MetaAiRemoteDataSourceImpl implements MetaAiRemoteDataSource {
  final SupabaseClient _supabase;
  final FirebaseFirestore _firestore;

  MetaAiRemoteDataSourceImpl({
    SupabaseClient? supabase,
    FirebaseFirestore? firestore,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> sendMessage(String message, String conversationId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // 1. Invoke AI function
        final response = await _supabase.functions.invoke(
          'metaAI',
          body: {
            'history': [
              {'role': 'user', 'content': message},
            ],
            'max_new_tokens': 1000,
          },
        );

        String aiResponse = '';
        final data = response.data;
        if (data is Map<String, dynamic>) {
          aiResponse = data['response'] as String? ?? '';
        } else if (data is String) {
          final parsed = jsonDecode(data);
          aiResponse = parsed['response'] as String? ?? '';
        } else {
          throw Exception('Invalid response format');
        }

        // 2. Save User Message
        await _firestore.collection('ai_messages').add({
          'conversationId': conversationId,
          'role': 'user',
          'content': message,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // 3. Save AI Message
        await _firestore.collection('ai_messages').add({
          'conversationId': conversationId,
          'role': 'model', // Gemini/MetaAI usually uses 'model' or 'assistant'
          'content': aiResponse,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // 4. Update Conversation Header
        final convoQuery =
            await _firestore
                .collection('ai_chat_history')
                .where('conversationId', isEqualTo: conversationId)
                .limit(1)
                .get();

        if (convoQuery.docs.isNotEmpty) {
          await _firestore
              .collection('ai_chat_history')
              .doc(convoQuery.docs.first.id)
              .update({'updatedAt': DateTime.now().toIso8601String()});
        }

        return aiResponse;
      } catch (e) {
        throw Exception('Failed to send message: ${e.toString()}');
      }
    });
  }

  @override
  Future<String> createConversation({String? title}) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final userId = await HiveService.instance.getCurrentUserId();
        final conversationId = const Uuid().v4();

        final data = {
          'userId': userId,
          'conversationId': conversationId,
          'aiType': 'meta_ai',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        await _firestore.collection('ai_chat_history').add(data);
        return conversationId;
      } catch (e) {
        throw Exception('Failed to create conversation: $e');
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations() async {
    final userId = await HiveService.instance.getCurrentUserId();
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final querySnapshot =
            await _firestore
                .collection('ai_chat_history')
                .where('userId', isEqualTo: userId)
                .get();

        return querySnapshot.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        throw Exception('Failed to fetch conversations: $e');
      }
    });
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Delete messages
        final messages =
            await _firestore
                .collection('ai_messages')
                .where('conversationId', isEqualTo: conversationId)
                .get();

        // Batch delete is better but for now iterate
        for (var doc in messages.docs) {
          await doc.reference.delete();
        }

        // Delete history
        final history =
            await _firestore
                .collection('ai_chat_history')
                .where('conversationId', isEqualTo: conversationId)
                .get();

        for (var doc in history.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        throw Exception('Failed to delete conversation: $e');
      }
    });
  }

  @override
  Future<List<Map<String, String>>> loadConversationMessages(
    String conversationId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final querySnapshot =
            await _firestore
                .collection('ai_messages')
                .where('conversationId', isEqualTo: conversationId)
                .orderBy('timestamp', descending: true)
                .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          final timestamp = data['timestamp'] as String? ?? '';
          String formattedTime = '';
          if (timestamp.length >= 16) {
            formattedTime = timestamp.substring(11, 16);
          }

          return {
            'role': (data['role'] as String?) ?? '',
            'content': (data['content'] as String?) ?? '',
            'timestamp': formattedTime,
          };
        }).toList();
      } catch (e) {
        throw Exception('Failed to load messages: $e');
      }
    });
  }
}
