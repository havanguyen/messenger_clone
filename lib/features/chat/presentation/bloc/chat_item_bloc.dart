import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:messenger_clone/features/chat/data/datasources/chat_remote_datasource.dart';

import 'package:messenger_clone/features/chat/domain/usecases/get_chat_items_usecase.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_friends_usecase.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

part 'chat_item_event.dart';
part 'chat_item_state.dart';

class ChatItemBloc extends Bloc<ChatItemEvent, ChatItemState> {
  final GetChatItemsUseCase getChatItemsUseCase;
  final GetFriendsUseCase getFriendsUseCase;

  final ChatRemoteDataSource? remoteDataSource;

  late final Future<String> meId;
  StreamSubscription<List<Map<String, dynamic>>>? _chatStreamSubscription;

  ChatItemBloc({
    required this.getChatItemsUseCase,
    required this.getFriendsUseCase,
    this.remoteDataSource,
  }) : super(ChatItemLoading()) {
    meId = HiveService.instance.getCurrentUserId();

    on<GetChatItemEvent>(_onGetChatItem);
    on<UpdateChatItemEvent>(_onUpdateChatItem);
    on<UpdateUsersSeenEvent>(_onUpdateUsersSeen);
    on<SubscribeToChatStreamEvent>(_onSubscribeToChatStream);
    on<UpdateChatItemFromMessagePageEvent>(_onUpdateChatItemFromMessagePage);
  }

  Future<void> _onGetChatItem(
    GetChatItemEvent event,
    Emitter<ChatItemState> emit,
  ) async {
    emit(ChatItemLoading());
    try {
      final String me = await meId;

      // Use UseCases instead of direct repository calls
      final chatItemsResult = await getChatItemsUseCase(
        GetChatItemsParams(userId: me),
      );
      final friendsResult = await getFriendsUseCase(
        GetFriendsParams(userId: me),
      );

      // Handle results with Either pattern
      chatItemsResult.fold(
        (failure) => emit(ChatItemError(message: failure.message)),
        (chatItems) {
          friendsResult.fold(
            (failure) => emit(ChatItemError(message: failure.message)),
            (friends) {
              emit(
                ChatItemLoaded(
                  meId: me,
                  chatItems: chatItems,
                  friends: friends,
                ),
              );
              add(SubscribeToChatStreamEvent());
            },
          );
        },
      );
    } catch (error) {
      emit(ChatItemError(message: error.toString()));
    }
  }

  Future<void> _onUpdateChatItem(
    UpdateChatItemEvent event,
    Emitter<ChatItemState> emit,
  ) async {
    try {
      if (state is ChatItemLoaded) {
        final currentState = state as ChatItemLoaded;

        // Use remote datasource directly for single item fetch
        if (remoteDataSource != null) {
          final groupMessage = await remoteDataSource!.getGroupMessageById(
            event.groupChatId,
          );

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
            chatItems.insert(
              0,
              ChatItem(groupMessage: groupMessage, meId: currentState.meId),
            );
          }

          emit(currentState.copyWith(chatItems: chatItems));
        }
      }
    } catch (error) {
      emit(ChatItemError(message: error.toString()));
    }
  }

  Future<void> _onUpdateUsersSeen(
    UpdateUsersSeenEvent event,
    Emitter<ChatItemState> emit,
  ) async {
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
  }

  Future<void> _onSubscribeToChatStream(
    SubscribeToChatStreamEvent event,
    Emitter<ChatItemState> emit,
  ) async {
    try {
      if (state is ChatItemLoaded && remoteDataSource != null) {
        final currentState = state as ChatItemLoaded;
        final userId = currentState.meId;
        await _chatStreamSubscription?.cancel();

        final stream = await remoteDataSource!.getStreamToUpdateChatPage(
          userId,
        );

        _chatStreamSubscription = stream.listen(
          (payload) {
            if (payload.isNotEmpty) {
              add(GetChatItemEvent());
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
  }

  Future<void> _onUpdateChatItemFromMessagePage(
    UpdateChatItemFromMessagePageEvent event,
    Emitter<ChatItemState> emit,
  ) async {
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
  }

  @override
  Future<void> close() async {
    await _chatStreamSubscription?.cancel();
    super.close();
  }
}
