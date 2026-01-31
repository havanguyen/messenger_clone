import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/chat_repository.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
// import 'package:messenger_clone/common/services/app_write_config.dart'; // Removed
// import 'package:messenger_clone/common/services/auth_service.dart'; // Removed direct usage

part 'chat_item_event.dart';
part 'chat_item_state.dart';

class ChatItemBloc extends Bloc<ChatItemEvent, ChatItemState> {
  final ChatRepository chatRepository;
  late final Future<String> meId;
  StreamSubscription<List<Map<String, dynamic>>>? _chatStreamSubscription;

  ChatItemBloc({required this.chatRepository}) : super(ChatItemLoading()) {
    meId = HiveService.instance.getCurrentUserId();
    on<GetChatItemEvent>((event, emit) async {
      emit(ChatItemLoading());
      try {
        final String me = await meId;
        List<GroupMessage> groupMessages = await chatRepository
            .getGroupMessagesByUserId(me);
        Future<List<User>> friendsFuture = chatRepository.getFriendsList(me);
        if (groupMessages.isEmpty) {
          List<User> friends = await friendsFuture;
          emit(ChatItemLoaded(meId: me, chatItems: [], friends: friends));
          return;
        }
        groupMessages.sort((a, b) {
          if (a.lastMessage == null && b.lastMessage == null) {
            return 0;
          } else if (a.lastMessage == null) {
            return 1;
          } else if (b.lastMessage == null) {
            return -1;
          } else {
            return b.lastMessage!.vietnamTime.compareTo(
              a.lastMessage!.vietnamTime,
            );
          }
        });
        List<ChatItem> chatItems = [];
        for (var groupMessage in groupMessages) {
          chatItems.add(ChatItem(groupMessage: groupMessage, meId: me));
        }
        List<User> friends = await friendsFuture;
        emit(ChatItemLoaded(meId: me, chatItems: chatItems, friends: friends));
        add(SubscribeToChatStreamEvent());
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateChatItemEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final GroupMessage groupMessage = await chatRepository
              .getGroupMessageById(event.groupChatId);
          List<ChatItem> chatItems = List.from(currentState.chatItems);
          final index = chatItems.indexWhere(
            (element) =>
                element.groupMessage.groupMessagesId ==
                groupMessage.groupMessagesId,
          );
          if (index != -1) {
            final chatItem = chatItems[index].copyWith(
              groupMessage: groupMessage,
            );
            chatItems.removeAt(index);
            chatItems.insert(0, chatItem);
          } else {
            // New chat item case?
            chatItems.insert(
              0,
              ChatItem(groupMessage: groupMessage, meId: currentState.meId),
            );
          }

          emit(currentState.copyWith(chatItems: chatItems));
          // Re-subscribe if needed, or just stay subscribed
          // add(SubscribeToChatStreamEvent());
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateUsersSeenEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final MessageModel message = event.message;
          final List<ChatItem> chatItems = (currentState.chatItems).toList();
          for (int i = 0; i < chatItems.length; i++) {
            if (chatItems[i].groupMessage.groupMessagesId ==
                message.groupMessagesId) {
              chatItems[i] = chatItems[i].copyWith(
                groupMessage: chatItems[i].groupMessage.copyWith(
                  lastMessage: message,
                ),
              );
              break;
            }
          }
          emit(currentState.copyWith(chatItems: chatItems));
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<SubscribeToChatStreamEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final userId = currentState.meId;
          await _chatStreamSubscription?.cancel();

          final stream = await chatRepository.getStreamToUpdateChatPage(userId);

          _chatStreamSubscription = stream.listen(
            (payload) {
              // Payload is List<Map<String, dynamic>> from Supabase stream
              // Represents the row(s) that changed (User row)
              if (payload.isNotEmpty) {
                final userData = payload.first;
                // Check if groupMessages changed?
                // Simplification: Just refresh the chat list if we get a user update for now
                // Ideally we diff or check specific fields.
                // Or if we implemented separate stream for group messages, we would handle that.

                // For now, let's just trigger a reload if we don't have enough info,
                // or better yet, since we don't know EXACTLY what changed without diffing,
                // maybe just re-fetch is safest but expensive.

                // Note: Supabase realtime usually gives you the new record.
                // If we are listening to user table, we get user row updates.
                // This includes new 'groupMessages' list.

                // Let's iterate over groupMessages in user doc and see if we have them.
                // This is complex to do fully correct in one go.
                // Let's assume ANY update to User triggers a refresh of chat items for now?
                // Or at least fetch the group list again.
                add(
                  GetChatItemEvent(),
                ); // Re-fetch everything (Cleanest for migration first pass)
              }
            },
            onError: (error) {
              debugPrint('Error via stream: $error');
            },
          );
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
    on<UpdateChatItemFromMessagePageEvent>((event, emit) async {
      try {
        if (state is ChatItemLoaded) {
          final currentState = state as ChatItemLoaded;
          final List<ChatItem> chatItems = (currentState.chatItems).toList();
          final GroupMessage newGroupMessage = event.groupMessage;
          final index = chatItems.indexWhere(
            (element) =>
                element.groupMessage.groupMessagesId ==
                newGroupMessage.groupMessagesId,
          );
          if (index != -1) {
            chatItems[index] = chatItems[index].copyWith(
              groupMessage: newGroupMessage,
            );
          }
          emit(currentState.copyWith(chatItems: chatItems));
        }
      } catch (error) {
        emit(ChatItemError(message: error.toString()));
      }
    });
  }
  @override
  Future<void> close() async {
    await _chatStreamSubscription?.cancel();
    super.close();
  }
}
