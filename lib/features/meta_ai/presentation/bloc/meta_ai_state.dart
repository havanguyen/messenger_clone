import 'package:equatable/equatable.dart';

abstract class MetaAiState extends Equatable {
  const MetaAiState();

  @override
  List<Object?> get props => [];
}

class MetaAiInitial extends MetaAiState {
  const MetaAiInitial();

  @override
  List<Object?> get props => [];
}

class MetaAiLoading extends MetaAiState {
  final bool isConnected;

  const MetaAiLoading({this.isConnected = true});

  MetaAiLoading copyWith({bool? isConnected}) {
    return MetaAiLoading(isConnected: isConnected ?? this.isConnected);
  }

  @override
  List<Object?> get props => [isConnected];
}

class MetaAiLoaded extends MetaAiState {
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, String>> messages;
  final String? currentConversationId;
  final String aiMode;
  final bool isConnected;

  const MetaAiLoaded({
    this.conversations = const [],
    this.messages = const [],
    this.currentConversationId,
    this.aiMode = 'friend',
    this.isConnected = true,
  });

  MetaAiLoaded copyWith({
    List<Map<String, dynamic>>? conversations,
    List<Map<String, String>>? messages,
    String? currentConversationId,
    String? aiMode,
    bool? isConnected,
  }) {
    return MetaAiLoaded(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      aiMode: aiMode ?? this.aiMode,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    messages,
    currentConversationId,
    aiMode,
    isConnected,
  ];
}

class MetaAiError extends MetaAiState {
  final String error;
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, String>> messages;
  final String? currentConversationId;
  final String aiMode;
  final bool isConnected;

  const MetaAiError({
    required this.error,
    this.conversations = const [],
    this.messages = const [],
    this.currentConversationId,
    this.aiMode = 'friend',
    this.isConnected = true,
  });

  MetaAiError copyWith({
    String? error,
    List<Map<String, dynamic>>? conversations,
    List<Map<String, String>>? messages,
    String? currentConversationId,
    String? aiMode,
    bool? isConnected,
  }) {
    return MetaAiError(
      error: error ?? this.error,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      aiMode: aiMode ?? this.aiMode,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
    error,
    conversations,
    messages,
    currentConversationId,
    aiMode,
    isConnected,
  ];
}

class MetaAiSyncing extends MetaAiState {
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, String>> messages;
  final String? currentConversationId;
  final String aiMode;
  final bool isConnected;

  const MetaAiSyncing({
    this.conversations = const [],
    this.messages = const [],
    this.currentConversationId,
    this.aiMode = 'friend',
    this.isConnected = true,
  });

  MetaAiSyncing copyWith({
    List<Map<String, dynamic>>? conversations,
    List<Map<String, String>>? messages,
    String? currentConversationId,
    String? aiMode,
    bool? isConnected,
  }) {
    return MetaAiSyncing(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      aiMode: aiMode ?? this.aiMode,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    messages,
    currentConversationId,
    aiMode,
    isConnected,
  ];
}

class MetaAiConnectivityChanged extends MetaAiState {
  final bool isConnected;
  final List<Map<String, dynamic>> conversations;
  final List<Map<String, String>> messages;
  final String? currentConversationId;
  final String aiMode;

  const MetaAiConnectivityChanged({
    this.isConnected = true,
    this.conversations = const [],
    this.messages = const [],
    this.currentConversationId,
    this.aiMode = 'friend',
  });

  MetaAiConnectivityChanged copyWith({
    bool? isConnected,
    List<Map<String, dynamic>>? conversations,
    List<Map<String, String>>? messages,
    String? currentConversationId,
    String? aiMode,
  }) {
    return MetaAiConnectivityChanged(
      isConnected: isConnected ?? this.isConnected,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      aiMode: aiMode ?? this.aiMode,
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    conversations,
    messages,
    currentConversationId,
    aiMode,
  ];
}
