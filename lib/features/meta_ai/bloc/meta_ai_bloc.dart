import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/constants/ai_chat_constants.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/meta_ai_service.dart';
import '../data/meta_ai_message_hive.dart';
import 'meta_ai_event.dart';
import 'meta_ai_state.dart';

class MetaAiBloc extends Bloc<MetaAiEvent, MetaAiState> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final Set<String> _greetingSentConversations = {};
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  String? _userId;

  MetaAiBloc() : super(const MetaAiInitial()) {
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
        conversations:
            state is MetaAiLoaded
                ? (state as MetaAiLoaded).conversations
                : state is MetaAiError
                ? (state as MetaAiError).conversations
                : state is MetaAiSyncing
                ? (state as MetaAiSyncing).conversations
                : state is MetaAiConnectivityChanged
                ? (state as MetaAiConnectivityChanged).conversations
                : const [],
        messages:
            state is MetaAiLoaded
                ? (state as MetaAiLoaded).messages
                : state is MetaAiError
                ? (state as MetaAiError).messages
                : state is MetaAiSyncing
                ? (state as MetaAiSyncing).messages
                : state is MetaAiConnectivityChanged
                ? (state as MetaAiConnectivityChanged).messages
                : const [],
        currentConversationId:
            state is MetaAiLoaded
                ? (state as MetaAiLoaded).currentConversationId
                : state is MetaAiError
                ? (state as MetaAiError).currentConversationId
                : state is MetaAiSyncing
                ? (state as MetaAiSyncing).currentConversationId
                : state is MetaAiConnectivityChanged
                ? (state as MetaAiConnectivityChanged).currentConversationId
                : null,
        aiMode:
            state is MetaAiLoaded
                ? (state as MetaAiLoaded).aiMode
                : state is MetaAiError
                ? (state as MetaAiError).aiMode
                : state is MetaAiSyncing
                ? (state as MetaAiSyncing).aiMode
                : state is MetaAiConnectivityChanged
                ? (state as MetaAiConnectivityChanged).aiMode
                : 'friend',
      ),
    );

    if (!wasConnected && event.isConnected) {
      add(const SyncWithServer());
      add(const InitializeMetaAi(forceSync: true));
    }
  }

  Future<void> _onInitializeMetaAi(
    InitializeMetaAi event,
    Emitter<MetaAiState> emit,
  ) async {
    emit(
      MetaAiLoading(
        isConnected:
            state is MetaAiConnectivityChanged
                ? (state as MetaAiConnectivityChanged).isConnected
                : state is MetaAiLoaded
                ? (state as MetaAiLoaded).isConnected
                : state is MetaAiError
                ? (state as MetaAiError).isConnected
                : state is MetaAiSyncing
                ? (state as MetaAiSyncing).isConnected
                : true,
      ),
    );

    try {
      final localConversations = await MetaAiServiceHive.getConversations();
      emit(
        MetaAiLoaded(
          conversations: localConversations,
          isConnected:
              state is MetaAiLoading
                  ? (state as MetaAiLoading).isConnected
                  : true,
        ),
      );

      if (localConversations.isNotEmpty &&
          (state is MetaAiLoaded &&
              (state as MetaAiLoaded).currentConversationId == null)) {
        add(LoadConversation(localConversations.first['id']));
      }

      if ((state is MetaAiLoaded && (state as MetaAiLoaded).isConnected) &&
          (event.forceSync || await MetaAiServiceHive.isDataStale())) {
        add(const SyncWithServer());
      }
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Không tải được danh sách trò chuyện.',
          isConnected:
              state is MetaAiLoading
                  ? (state as MetaAiLoading).isConnected
                  : true,
        ),
      );
    }
  }

  Future<void> _onSyncWithServer(
    SyncWithServer event,
    Emitter<MetaAiState> emit,
  ) async {
    bool isConnected = true;
    List<Map<String, dynamic>> currentConversations = const [];
    List<Map<String, String>> currentMessages = const [];
    String? currentConversationId;
    String aiMode = 'friend';

    if (state is MetaAiLoaded) {
      isConnected = (state as MetaAiLoaded).isConnected;
      currentConversations = (state as MetaAiLoaded).conversations;
      currentMessages = (state as MetaAiLoaded).messages;
      currentConversationId = (state as MetaAiLoaded).currentConversationId;
      aiMode = (state as MetaAiLoaded).aiMode;
    } else if (state is MetaAiError) {
      isConnected = (state as MetaAiError).isConnected;
      currentConversations = (state as MetaAiError).conversations;
      currentMessages = (state as MetaAiError).messages;
      currentConversationId = (state as MetaAiError).currentConversationId;
      aiMode = (state as MetaAiError).aiMode;
    } else if (state is MetaAiSyncing) {
      isConnected = (state as MetaAiSyncing).isConnected;
      currentConversations = (state as MetaAiSyncing).conversations;
      currentMessages = (state as MetaAiSyncing).messages;
      currentConversationId = (state as MetaAiSyncing).currentConversationId;
      aiMode = (state as MetaAiSyncing).aiMode;
    } else if (state is MetaAiConnectivityChanged) {
      isConnected = (state as MetaAiConnectivityChanged).isConnected;
      currentConversations = (state as MetaAiConnectivityChanged).conversations;
      currentMessages = (state as MetaAiConnectivityChanged).messages;
      currentConversationId =
          (state as MetaAiConnectivityChanged).currentConversationId;
      aiMode = (state as MetaAiConnectivityChanged).aiMode;
    }

    if (state is MetaAiSyncing || !isConnected) return;

    emit(
      MetaAiSyncing(
        conversations: currentConversations,
        messages: currentMessages,
        currentConversationId: currentConversationId,
        aiMode: aiMode,
        isConnected: isConnected,
      ),
    );

    try {
      final user = await AuthService.getCurrentUser();
      _userId = user?.uid ?? '';
      final serverConversations = await AIService.getConversations(_userId!);
      final mappedConversations =
          serverConversations
              .map(
                (doc) => {
                  'id': doc['conversationId'] ?? doc['id'],
                  'aiMode': doc['aiType'] as String,
                  'createdAt': doc['createdAt'] as String,
                },
              )
              .toList();

      await MetaAiServiceHive.saveConversations(mappedConversations);
      await MetaAiServiceHive.saveLastSyncTimestamp();

      for (var conv in mappedConversations) {
        final messages = await AIService.getConversationHistory(conv['id']!);
        final sortedMessages = messages.reversed.toList();
        await MetaAiServiceHive.saveMessages(conv['id']!, sortedMessages);
      }

      emit(
        MetaAiLoaded(
          conversations: mappedConversations,
          messages: currentMessages,
          currentConversationId: currentConversationId,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );

      if (mappedConversations.isNotEmpty && currentConversationId == null) {
        add(LoadConversation(mappedConversations.first['id']!));
      } else if (mappedConversations.isEmpty) {
        add(const CreateConversation('friend'));
      }

      final actions = await MetaAiServiceHive.getOfflineActions();
      for (var action in actions) {
        try {
          if (action['type'] == 'add_message') {
            await AIService.addMessage(
              conversationId: action['conversationId'],
              role: action['role'],
              content: action['content'],
            );
          } else if (action['type'] == 'delete_conversation') {
            await AIService.deleteConversation(action['conversationId']);
          }
        } catch (e) {
          continue;
        }
      }
      await MetaAiServiceHive.clearOfflineActions();
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Không đồng bộ được với server.',
          conversations: currentConversations,
          messages: currentMessages,
          currentConversationId: currentConversationId,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );
    } finally {
      if (state is MetaAiSyncing) {
        emit(
          MetaAiLoaded(
            conversations: currentConversations,
            messages: currentMessages,
            currentConversationId: currentConversationId,
            aiMode: aiMode,
            isConnected: isConnected,
          ),
        );
      }
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MetaAiState> emit,
  ) async {
    bool isConnected = true;
    List<Map<String, dynamic>> currentConversations = const [];
    List<Map<String, String>> currentMessages = const [];
    String? currentConversationId;
    String aiMode = 'friend';

    if (state is MetaAiLoaded) {
      isConnected = (state as MetaAiLoaded).isConnected;
      currentConversations = (state as MetaAiLoaded).conversations;
      currentMessages = (state as MetaAiLoaded).messages;
      currentConversationId = (state as MetaAiLoaded).currentConversationId;
      aiMode = (state as MetaAiLoaded).aiMode;
    } else if (state is MetaAiError) {
      isConnected = (state as MetaAiError).isConnected;
      currentConversations = (state as MetaAiError).conversations;
      currentMessages = (state as MetaAiError).messages;
      currentConversationId = (state as MetaAiError).currentConversationId;
      aiMode = (state as MetaAiError).aiMode;
    } else if (state is MetaAiSyncing) {
      isConnected = (state as MetaAiSyncing).isConnected;
      currentConversations = (state as MetaAiSyncing).conversations;
      currentMessages = (state as MetaAiSyncing).messages;
      currentConversationId = (state as MetaAiSyncing).currentConversationId;
      aiMode = (state as MetaAiSyncing).aiMode;
    } else if (state is MetaAiConnectivityChanged) {
      isConnected = (state as MetaAiConnectivityChanged).isConnected;
      currentConversations = (state as MetaAiConnectivityChanged).conversations;
      currentMessages = (state as MetaAiConnectivityChanged).messages;
      currentConversationId =
          (state as MetaAiConnectivityChanged).currentConversationId;
      aiMode = (state as MetaAiConnectivityChanged).aiMode;
    }

    try {
      String conversationId;
      if (isConnected && _userId != null) {
        conversationId = await AIService.createConversation(
          userId: _userId!,
          aiType: event.aiMode,
        );
      } else {
        conversationId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        await MetaAiServiceHive.queueOfflineAction({
          'type': 'create_conversation',
          'userId': _userId ?? '',
          'aiMode': event.aiMode,
          'conversationId': conversationId,
        });
      }

      final newConversation = {
        'id': conversationId,
        'aiMode': event.aiMode,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final conversations = List<Map<String, dynamic>>.from(
        currentConversations,
      )..add(newConversation);
      await MetaAiServiceHive.saveConversations(conversations);

      emit(
        MetaAiLoaded(
          conversations: conversations,
          messages: [],
          currentConversationId: conversationId,
          aiMode: event.aiMode,
          isConnected: isConnected,
        ),
      );

      if (!_greetingSentConversations.contains(conversationId)) {
        final greeting =
            AIConfig.aiGreetings[event.aiMode] ??
            'Xin chào! Tôi có thể giúp gì cho bạn hôm nay?';
        final timestamp = _formatTimestamp(DateTime.now());
        final updatedMessages = List<Map<String, String>>.from([])
          ..add({'role': 'ai', 'content': greeting, 'timestamp': timestamp});
        await MetaAiServiceHive.saveMessages(conversationId, updatedMessages);

        if (isConnected && _userId != null) {
          await AIService.addMessage(
            conversationId: conversationId,
            role: 'ai',
            content: greeting,
          );
        } else {
          await MetaAiServiceHive.queueOfflineAction({
            'type': 'add_message',
            'conversationId': conversationId,
            'role': 'ai',
            'content': greeting,
          });
        }

        emit(
          MetaAiLoaded(
            conversations: conversations,
            messages: updatedMessages,
            currentConversationId: conversationId,
            aiMode: event.aiMode,
            isConnected: isConnected,
          ),
        );
        _greetingSentConversations.add(conversationId);
        _scrollToBottom();
      }
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Không tạo được cuộc trò chuyện.',
          conversations: currentConversations,
          messages: currentMessages,
          currentConversationId: currentConversationId,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );
    }
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<MetaAiState> emit,
  ) async {
    bool isConnected = true;
    List<Map<String, dynamic>> currentConversations = const [];
    String aiMode = 'friend';

    if (state is MetaAiLoaded) {
      isConnected = (state as MetaAiLoaded).isConnected;
      currentConversations = (state as MetaAiLoaded).conversations;
      aiMode = (state as MetaAiLoaded).aiMode;
    } else if (state is MetaAiError) {
      isConnected = (state as MetaAiError).isConnected;
      currentConversations = (state as MetaAiError).conversations;
      aiMode = (state as MetaAiError).aiMode;
    } else if (state is MetaAiSyncing) {
      isConnected = (state as MetaAiSyncing).isConnected;
      currentConversations = (state as MetaAiSyncing).conversations;
      aiMode = (state as MetaAiSyncing).aiMode;
    } else if (state is MetaAiConnectivityChanged) {
      isConnected = (state as MetaAiConnectivityChanged).isConnected;
      currentConversations = (state as MetaAiConnectivityChanged).conversations;
      aiMode = (state as MetaAiConnectivityChanged).aiMode;
    }

    try {
      final messages = await MetaAiServiceHive.getMessages(
        event.conversationId,
      );
      final conversation = currentConversations.firstWhere(
        (conv) => conv['id'] == event.conversationId,
      );
      emit(
        MetaAiLoaded(
          conversations: currentConversations,
          messages: messages,
          currentConversationId: event.conversationId,
          aiMode: conversation['aiMode'] as String,
          isConnected: isConnected,
        ),
      );
      _scrollToBottom();

      if (isConnected && await MetaAiServiceHive.isDataStale()) {
        final serverMessages = await AIService.getConversationHistory(
          event.conversationId,
        );
        final sortedMessages = serverMessages.reversed.toList();
        await MetaAiServiceHive.saveMessages(
          event.conversationId,
          sortedMessages,
        );
        emit(
          MetaAiLoaded(
            conversations: currentConversations,
            messages: sortedMessages,
            currentConversationId: event.conversationId,
            aiMode: conversation['aiMode'] as String,
            isConnected: isConnected,
          ),
        );
        _scrollToBottom();
      }
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Không tải được cuộc trò chuyện.',
          conversations: currentConversations,
          messages: const [],
          currentConversationId: null,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MetaAiState> emit,
  ) async {
    if (event.message.isEmpty) return;

    bool isConnected = true;
    List<Map<String, dynamic>> currentConversations = const [];
    List<Map<String, String>> currentMessages = const [];
    String? currentConversationId;
    String aiMode = 'friend';

    if (state is MetaAiLoaded) {
      isConnected = (state as MetaAiLoaded).isConnected;
      currentConversations = (state as MetaAiLoaded).conversations;
      currentMessages = (state as MetaAiLoaded).messages;
      currentConversationId = (state as MetaAiLoaded).currentConversationId;
      aiMode = (state as MetaAiLoaded).aiMode;
    } else if (state is MetaAiError) {
      isConnected = (state as MetaAiError).isConnected;
      currentConversations = (state as MetaAiError).conversations;
      currentMessages = (state as MetaAiError).messages;
      currentConversationId = (state as MetaAiError).currentConversationId;
      aiMode = (state as MetaAiError).aiMode;
    } else if (state is MetaAiSyncing) {
      isConnected = (state as MetaAiSyncing).isConnected;
      currentConversations = (state as MetaAiSyncing).conversations;
      currentMessages = (state as MetaAiSyncing).messages;
      currentConversationId = (state as MetaAiSyncing).currentConversationId;
      aiMode = (state as MetaAiSyncing).aiMode;
    } else if (state is MetaAiConnectivityChanged) {
      isConnected = (state as MetaAiConnectivityChanged).isConnected;
      currentConversations = (state as MetaAiConnectivityChanged).conversations;
      currentMessages = (state as MetaAiConnectivityChanged).messages;
      currentConversationId =
          (state as MetaAiConnectivityChanged).currentConversationId;
      aiMode = (state as MetaAiConnectivityChanged).aiMode;
    }

    if (currentConversationId == null) return;

    final timestamp = _formatTimestamp(DateTime.now());
    final updatedMessages = List<Map<String, String>>.from(currentMessages)
      ..add({'role': 'user', 'content': event.message, 'timestamp': timestamp});
    await MetaAiServiceHive.saveMessages(
      currentConversationId,
      updatedMessages,
    );

    emit(
      MetaAiLoaded(
        conversations: currentConversations,
        messages: updatedMessages,
        currentConversationId: currentConversationId,
        aiMode: aiMode,
        isConnected: isConnected,
      ),
    );
    messageController.clear();
    _scrollToBottom();

    try {
      if (isConnected && _userId != null) {
        await AIService.addMessage(
          conversationId: currentConversationId,
          role: 'user',
          content: event.message,
        );
      } else {
        await MetaAiServiceHive.queueOfflineAction({
          'type': 'add_message',
          'conversationId': currentConversationId,
          'role': 'user',
          'content': event.message,
        });
      }

      final history =
          updatedMessages
              .map((msg) => {'role': msg['role']!, 'content': msg['content']!})
              .toList();
      final modePrompts = AIConfig.aiPrompts;
      final enhancedPrompt = """
      ${event.message}
      ${modePrompts[aiMode] ?? 'Hãy trả lời một cách tự nhiên và hữu ích.'}
      """;
      history.add({'role': 'user', 'content': enhancedPrompt});

      Map<String, dynamic> responseData;
      if (isConnected) {
        responseData = await AIService.callMetaAIFunction(
          history,
          AIConfig.maxTokens,
        );
      } else {
        responseData = {
          'ok': false,
          'error': 'Bạn đang offline. Tin nhắn sẽ được đồng bộ khi có mạng.',
        };
      }

      if (responseData['ok'] == true) {
        final aiResponse =
            responseData['completion']?.toString() ??
            'Sorry, I cannot respond.';
        final aiTimestamp = _formatTimestamp(DateTime.now());
        final updatedMessagesWithAi = List<Map<String, String>>.from(
          updatedMessages,
        )..add({'role': 'ai', 'content': aiResponse, 'timestamp': aiTimestamp});
        await MetaAiServiceHive.saveMessages(
          currentConversationId,
          updatedMessagesWithAi,
        );

        if (isConnected && _userId != null) {
          await AIService.addMessage(
            conversationId: currentConversationId,
            role: 'ai',
            content: aiResponse,
          );
        } else {
          await MetaAiServiceHive.queueOfflineAction({
            'type': 'add_message',
            'conversationId': currentConversationId,
            'role': 'ai',
            'content': aiResponse,
          });
        }

        emit(
          MetaAiLoaded(
            conversations: currentConversations,
            messages: updatedMessagesWithAi,
            currentConversationId: currentConversationId,
            aiMode: aiMode,
            isConnected: isConnected,
          ),
        );
        _scrollToBottom();
      } else {
        throw Exception(responseData['error'] ?? 'Unknown AI error.');
      }
    } catch (e) {
      final errorMsg =
          e is SocketException
              ? 'Mất kết nối mạng'
              : e is TimeoutException
              ? 'Yêu cầu hết thời gian'
              : e.toString();
      final updatedMessagesWithError = List<Map<String, String>>.from(
        updatedMessages,
      )..add({
        'role': 'ai',
        'content': errorMsg,
        'timestamp': _formatTimestamp(DateTime.now()),
      });
      await MetaAiServiceHive.saveMessages(
        currentConversationId,
        updatedMessagesWithError,
      );
      emit(
        MetaAiError(
          error: errorMsg,
          conversations: currentConversations,
          messages: updatedMessagesWithError,
          currentConversationId: currentConversationId,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );
      _scrollToBottom();
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<MetaAiState> emit,
  ) async {
    bool isConnected = true;
    List<Map<String, dynamic>> currentConversations = const [];
    List<Map<String, String>> currentMessages = const [];
    String? currentConversationId;
    String aiMode = 'friend';

    if (state is MetaAiLoaded) {
      isConnected = (state as MetaAiLoaded).isConnected;
      currentConversations = (state as MetaAiLoaded).conversations;
      currentMessages = (state as MetaAiLoaded).messages;
      currentConversationId = (state as MetaAiLoaded).currentConversationId;
      aiMode = (state as MetaAiLoaded).aiMode;
    } else if (state is MetaAiError) {
      isConnected = (state as MetaAiError).isConnected;
      currentConversations = (state as MetaAiError).conversations;
      currentMessages = (state as MetaAiError).messages;
      currentConversationId = (state as MetaAiError).currentConversationId;
      aiMode = (state as MetaAiError).aiMode;
    } else if (state is MetaAiSyncing) {
      isConnected = (state as MetaAiSyncing).isConnected;
      currentConversations = (state as MetaAiSyncing).conversations;
      currentMessages = (state as MetaAiSyncing).messages;
      currentConversationId = (state as MetaAiSyncing).currentConversationId;
      aiMode = (state as MetaAiSyncing).aiMode;
    } else if (state is MetaAiConnectivityChanged) {
      isConnected = (state as MetaAiConnectivityChanged).isConnected;
      currentConversations = (state as MetaAiConnectivityChanged).conversations;
      currentMessages = (state as MetaAiConnectivityChanged).messages;
      currentConversationId =
          (state as MetaAiConnectivityChanged).currentConversationId;
      aiMode = (state as MetaAiConnectivityChanged).aiMode;
    }

    try {
      if (isConnected && _userId != null) {
        await AIService.deleteConversation(event.conversationId);
      } else {
        await MetaAiServiceHive.queueOfflineAction({
          'type': 'delete_conversation',
          'conversationId': event.conversationId,
        });
      }
      await MetaAiServiceHive.deleteConversation(event.conversationId);

      final updatedConversations = List<Map<String, dynamic>>.from(
        currentConversations,
      )..removeWhere((conv) => conv['id'] == event.conversationId);
      emit(
        MetaAiLoaded(
          conversations: updatedConversations,
          messages: [],
          currentConversationId: null,
          aiMode: 'friend',
          isConnected: isConnected,
        ),
      );

      _greetingSentConversations.remove(event.conversationId);

      if (updatedConversations.isNotEmpty) {
        add(LoadConversation(updatedConversations.first['id']));
      }
    } catch (e) {
      emit(
        MetaAiError(
          error: 'Không xóa được cuộc trò chuyện.',
          conversations: currentConversations,
          messages: currentMessages,
          currentConversationId: currentConversationId,
          aiMode: aiMode,
          isConnected: isConnected,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
