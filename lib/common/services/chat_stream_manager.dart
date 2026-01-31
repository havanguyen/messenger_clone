import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';

// Helper wrapper to match expected callback signature (RealtimeMessage)
// or we adapt callback to accept payload.
// Since we are refactoring, we can change the signature or adapt it.
// RealtimeMessage was Appwrite class. We define a custom one or use Map.

class ChatStreamManager {
  static final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _channel;
  final Set<GroupMessage> _subscribedGroupIds = {};

  // Callback expects generic payload now
  final Function(dynamic) _onMessageReceived;
  final Function(dynamic) _onError;

  ChatStreamManager({
    required Function(dynamic) onMessageReceived,
    required Function(dynamic) onError,
  }) : _onMessageReceived = onMessageReceived,
       _onError = onError;

  Future<void> initialize(
    String userId,
    List<GroupMessage> initialGroupIds,
  ) async {
    await dispose();
    _subscribedGroupIds.clear();
    _subscribedGroupIds.addAll(initialGroupIds);

    _createSubscription(userId);
  }

  void _createSubscription(String userId) {
    // Supabase Realtime Channels
    // We can listen to changes on 'messages' table for specific conditions?
    // Postgres Changes Listening:
    // channel.onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'messages', filter: 'receiverId=eq.$userId', callback: ...)
    // But we are listening to Group Messages.

    // For simplicity, we subscribe to 'group_messages' or 'messages'.
    // If we have many groups, one channel listening to 'messages' with specific filter might be hard if we want multiple groups.
    // Supabase supports listening to table level.
    // If rows have security policies, we only receive what we are allowed to see.
    // So listening to 'messages' table updates might be enough if RLS is set up.

    _channel = _supabase.channel('public:messages:$userId');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages', // Assuming table name
          callback: (payload) {
            debugPrint('Realtime message received: ${payload.newRecord}');
            // Convert payload to what app expects
            _onMessageReceived(payload);
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Subscribed to realtime messages');
          } else if (status == RealtimeSubscribeStatus.closed) {
            debugPrint('Channel closed');
          } else if (error != null) {
            debugPrint('Subscription error: $error');
            _onError(error);
          }
        });

    // Note: Appwrite logic was subscribing to specific documents.
    // Supabase logic is table-based usually.
    // If we want to filter by group, we rely on RLS or client side filter.
  }

  Future<void> addGroupMessage(String userId, GroupMessage group) async {
    if (_subscribedGroupIds.contains(group)) return;
    _subscribedGroupIds.add(group);
    // In Supabase table-wide subscription, we might not need to re-subscribe if we just rely on RLS.
    // But if we were filtering (not implemented above), we would need to update filter.
    // For now, no-op or re-init if meaningful.
  }

  Future<void> removeGroupMessage(String userId, GroupMessage group) async {
    if (!_subscribedGroupIds.contains(group)) return;
    _subscribedGroupIds.remove(group);
  }

  List<String> get subscribedGroupIds =>
      _subscribedGroupIds.map((e) => e.groupMessagesId).toList();

  bool isSubscribedToGroup(GroupMessage group) =>
      _subscribedGroupIds.contains(group);

  Future<void> dispose() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _subscribedGroupIds.clear();
  }
}
