import 'dart:convert';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AIService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> callMetaAIFunction(
    List<Map<String, String>> history,
    int maxTokens,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'metaAI',
        body: {'history': history, 'max_new_tokens': maxTokens},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        // Try parsing string if data is string
        // But usually invoke returns Map if JSON response
        if (data is String) {
          return jsonDecode(data);
        }
        throw Exception('Invalid response format');
      }
      return data;
    } catch (e) {
      throw Exception('Failed to call AI function: ${e.toString()}');
    }
  }

  static Future<String> createConversation({
    required String userId,
    required String aiType,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final conversationId = const Uuid().v4();
        // Assuming table 'ai_chat_history'
        final response =
            await _supabase
                .from('ai_chat_history')
                .insert({
                  'userId': userId,
                  'conversationId': conversationId,
                  'aiType': aiType,
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                })
                .select()
                .single();

        return response['id'] ?? response['conversationId'] ?? conversationId;
      } catch (e) {
        throw Exception('Failed to create conversation: $e');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getConversations(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await _supabase
            .from('ai_chat_history')
            .select()
            .eq('userId', userId);
        return (response as List).cast<Map<String, dynamic>>();
      } catch (e) {
        throw Exception('Failed to fetch conversations: $e');
      }
    });
  }

  static Future<List<Map<String, String>>> getConversationHistory(
    String conversationId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await _supabase
            .from('ai_messages')
            .select()
            .eq('conversationId', conversationId)
            .order(
              'timestamp',
              ascending: false,
            ); // Supabase uses ascending boolean

        return (response as List)
            .map(
              (doc) => {
                'role': (doc['role'] as String?) ?? '',
                'content': (doc['content'] as String?) ?? '',
                'timestamp': ((doc['timestamp'] as String?) ?? '').substring(
                  11,
                  16,
                ),
              },
            )
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch conversation history: $e');
      }
    });
  }

  static Future<void> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Validate user permissions implicitly via RLS

        await _supabase.from('ai_messages').insert({
          'conversationId': conversationId,
          'role': role,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        });

        await _supabase
            .from('ai_chat_history')
            .update({'updatedAt': DateTime.now().toIso8601String()})
            .eq('conversationId', conversationId);
      } catch (e) {
        throw Exception('Failed to add message: $e');
      }
    });
  }

  static Future<void> deleteConversation(String conversationId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Cascade delete if set up in DB, otherwise manual
        await _supabase
            .from('ai_messages')
            .delete()
            .eq('conversationId', conversationId);

        await _supabase
            .from('ai_chat_history')
            .delete()
            .eq('conversationId', conversationId);
      } catch (e) {
        throw Exception('Failed to delete conversation: $e');
      }
    });
  }

  static Future<void> deleteAllConversations(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Fetch all conversations then delete
        final conversations = await getConversations(userId);
        for (var conversation in conversations) {
          final id = conversation['conversationId'] ?? conversation['id'];
          if (id != null) {
            await deleteConversation(id);
          }
        }
      } catch (e) {
        throw Exception('Failed to delete all conversations: $e');
      }
    });
  }
}
