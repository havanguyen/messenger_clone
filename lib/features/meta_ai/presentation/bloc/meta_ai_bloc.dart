import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/features/meta_ai/domain/repositories/meta_ai_repository.dart';
import 'package:messenger_clone/features/meta_ai/domain/usecases/send_ai_message_usecase.dart';

import 'meta_ai_event.dart';
import 'meta_ai_state.dart';

class MetaAiBloc extends Bloc<MetaAiEvent, MetaAiState> {
  final MetaAiRepository repository;
  final SendAiMessageUseCase sendAiMessageUseCase;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  MetaAiBloc({required this.repository, required this.sendAiMessageUseCase})
    : super(const MetaAiInitial()) {
    on<InitializeMetaAi>(_onInitializeMetaAi);
    on<CreateConversation>(_onCreateConversation);
    on<LoadConversation>(_onLoadConversation);
    on<SendMessage>(_onSendMessage);
    on<DeleteConversation>(_onDeleteConversation);
    on<SyncWithServer>(_onSyncWithServer);
    on<UpdateConnectivity>(_onUpdateConnectivity);

    _initConnectivity();
    add(const InitializeMetaAi());
  }

  @override
  Future<void> close() {
    messageController.dispose();
    scrollController.dispose();
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    add(UpdateConnectivity(result != ConnectivityResult.none));
  }

  Future<void> _onUpdateConnectivity(
    UpdateConnectivity event,
    Emitter<MetaAiState> emit,
  ) async {
    bool wasConnected = true;
    if (state is MetaAiLoaded) {
      wasConnected = (state as MetaAiLoaded).isConnected;
    } else if (state is MetaAiError) {
      wasConnected = (state as MetaAiError).isConnected;
    } else if (state is MetaAiSyncing) {
      wasConnected = (state as MetaAiSyncing).isConnected;
    } else if (state is MetaAiConnectivityChanged) {
      wasConnected = (state as MetaAiConnectivityChanged).isConnected;
    } else if (state is MetaAiLoading) {
      wasConnected = (state as MetaAiLoading).isConnected;
    }

    emit(
      MetaAiConnectivityChanged(
        isConnected: event.isConnected,
        conversations: _getConversationsFromState(state),
        messages: _getMessagesFromState(state),
        currentConversationId: _getCurrentConversationIdFromState(state),
        aiMode: _getAiModeFromState(state),
      ),
    );

    if (!wasConnected && event.isConnected) {
      add(const SyncWithServer());
      add(const InitializeMetaAi(forceSync: true));
    }
  }

  List<Map<String, dynamic>> _getConversationsFromState(MetaAiState state) {
    if (state is MetaAiLoaded) return state.conversations;
    if (state is MetaAiError) return state.conversations;
    if (state is MetaAiSyncing) return state.conversations;
    if (state is MetaAiConnectivityChanged) return state.conversations;
    return const [];
  }

  List<Map<String, String>> _getMessagesFromState(MetaAiState state) {
    if (state is MetaAiLoaded) return state.messages;
    if (state is MetaAiError) return state.messages;
    if (state is MetaAiSyncing) return state.messages;
    if (state is MetaAiConnectivityChanged) return state.messages;
    return const [];
  }

  String? _getCurrentConversationIdFromState(MetaAiState state) {
    if (state is MetaAiLoaded) return state.currentConversationId;
    if (state is MetaAiError) return state.currentConversationId;
    if (state is MetaAiSyncing) return state.currentConversationId;
    if (state is MetaAiConnectivityChanged) return state.currentConversationId;
    return null;
  }

  String _getAiModeFromState(MetaAiState state) {
    if (state is MetaAiLoaded) return state.aiMode;
    if (state is MetaAiError) return state.aiMode;
    if (state is MetaAiSyncing) return state.aiMode;
    if (state is MetaAiConnectivityChanged) return state.aiMode;
    return 'friend';
  }

  Future<void> _onInitializeMetaAi(
    InitializeMetaAi event,
    Emitter<MetaAiState> emit,
  ) async {
    emit(MetaAiLoading(isConnected: true)); // simplified
    try {
      final result = await repository.getConversations();

      result.fold(
        (failure) =>
            emit(MetaAiError(error: failure.toString(), isConnected: true)),
        (conversations) {
          final validConversations =
              conversations.map((c) {
                return c;
              }).toList();

          if (validConversations.isNotEmpty) {
            final mostRecent = validConversations.last;
            emit(
              MetaAiLoaded(
                conversations: validConversations,
                currentConversationId: mostRecent['id'],
                messages: [], // We might need to load messages for it?
                isConnected: true,
              ),
            );
            add(LoadConversation(mostRecent['id']));
          } else {
            emit(
              MetaAiLoaded(
                conversations: [],
                currentConversationId: null,
                messages: [],
                isConnected: true,
              ),
            );
          }
        },
      );

      if (event.forceSync) {
        add(const SyncWithServer());
      }
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Failed to load conversation list.',
          isConnected: true,
        ),
      );
    }
  }

  Future<void> _onSyncWithServer(
    SyncWithServer event,
    Emitter<MetaAiState> emit,
  ) async {
    try {
      final result = await repository.getConversations();
      result.fold((failure) {}, (conversations) {
        emit(
          MetaAiLoaded(
            conversations: conversations,
            currentConversationId: _getCurrentConversationIdFromState(state),
            messages: _getMessagesFromState(state),
            aiMode: _getAiModeFromState(state),
            isConnected: true,
          ),
        );
      });
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MetaAiState> emit,
  ) async {
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<MetaAiState> emit,
  ) async {
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MetaAiState> emit,
  ) async {

    final result = await sendAiMessageUseCase(
      SendAiMessageParams(
        message: event.message,
        conversationId: _getCurrentConversationIdFromState(state)!,
      ),
    );

    result.fold(
      (failure) {
      },
      (response) {
      },
    );
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<MetaAiState> emit,
  ) async {
  }
}
