import 'package:flutter/foundation.dart';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> sendMessage({
    required List<String> userIds,
    required String callId,
    required String callerName,
    required String callerId,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final payload = {
          'userIds': userIds,
          'callId': callId,
          'callerName': callerName,
          'callerId': callerId,
        };

        debugPrint(
          'Preparing to invoke Supabase Edge Function: sendPush with payload: $payload',
        );

        final response = await _supabase.functions.invoke(
          'sendPush',
          body: payload,
        );

        // Supabase functions.invoke returns FunctionResponse
        final data = response.data;

        debugPrint('Response from Edge Function: $data');

        if (data == null) {
          // Handle empty response logic if needed or just log
          debugPrint('Edge function returned null data');
        }
      } catch (e) {
        throw Exception('Error sending push notification via Supabase: $e');
      }
    });
  }
}
