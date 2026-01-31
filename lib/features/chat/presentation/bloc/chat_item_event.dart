part of 'chat_item_bloc.dart';

sealed class ChatItemEvent extends Equatable {
  const ChatItemEvent();

  @override
  List<Object> get props => [];
}

final class GetChatItemEvent extends ChatItemEvent {
  const GetChatItemEvent();
  @override
  List<Object> get props => [];
}

final class UpdateChatItemEvent extends ChatItemEvent {
  final String groupChatId;
  const UpdateChatItemEvent({required this.groupChatId});
  @override
  List<Object> get props => [groupChatId];
}

final class UpdateUsersSeenEvent extends ChatItemEvent {
  final MessageModel message;
  const UpdateUsersSeenEvent({required this.message});
  @override
  List<Object> get props => [message];
}

final class SubscribeToChatStreamEvent extends ChatItemEvent {
  const SubscribeToChatStreamEvent();
  @override
  List<Object> get props => [];
}

final class UpdateChatItemFromMessagePageEvent extends ChatItemEvent {
  final GroupMessage groupMessage;
  const UpdateChatItemFromMessagePageEvent({required this.groupMessage});
  @override
  List<Object> get props => [groupMessage];
}
