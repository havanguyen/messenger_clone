import 'package:flutter/foundation.dart';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendMessageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> sendMessageNotification({
    required List<String> userIds,
    required String groupMessageId,
    required String messageContent,
    required String senderId,
    required String senderName,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Logic to filter userIds (e.g. check current view status) might need DB query
        // For now, sending to all listed userIds or keeping filter logic if possible
        // Ideally filter logic moves to Backend or we query DB first.

        final payload = {
          'type': 'message',
          'userIds':
              userIds, // Sending to all for now, assuming BE handles or client handles filtering
          'groupMessageId': groupMessageId,
          'messageContent': messageContent,
          'senderId': senderId,
          'senderName': senderName,
        };

        debugPrint(
          'Invoking Supabase Edge Function sendPush (message) with payload: $payload',
        );

        final response = await _supabase.functions.invoke(
          'sendPush',
          body: payload,
        );

        debugPrint('Response from Edge Function: ${response.data}');
      } catch (e) {
        throw Exception('Error sending push notification via Supabase: $e');
      }
    });
  }
}
