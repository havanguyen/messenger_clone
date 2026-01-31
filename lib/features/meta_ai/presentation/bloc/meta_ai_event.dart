import 'package:equatable/equatable.dart';

abstract class MetaAiEvent extends Equatable {
  const MetaAiEvent();
  @override
  List<Object?> get props => [];
}

class InitializeMetaAi extends MetaAiEvent {
  final bool forceSync;
  const InitializeMetaAi({this.forceSync = false});
  @override
  List<Object?> get props => [forceSync];
}

class SendMessage extends MetaAiEvent {
  final String message;
  const SendMessage(this.message);
  @override
  List<Object?> get props => [message];
}

class CreateConversation extends MetaAiEvent {
  final String aiMode;
  const CreateConversation(this.aiMode);
  @override
  List<Object?> get props => [aiMode];
}

class LoadConversation extends MetaAiEvent {
  final String conversationId;
  const LoadConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class DeleteConversation extends MetaAiEvent {
  final String conversationId;
  const DeleteConversation(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SyncWithServer extends MetaAiEvent {
  const SyncWithServer();
}

class UpdateConnectivity extends MetaAiEvent {
  final bool isConnected;
  const UpdateConnectivity(this.isConnected);
  @override
  List<Object?> get props => [isConnected];
}
