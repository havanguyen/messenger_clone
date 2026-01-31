part of 'message_bloc.dart';

sealed class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object> get props => [];
}

final class MessageLoadEvent extends MessageEvent {
  final appUser.User? otherUser;
  final GroupMessage? groupMessage;
  final int offset;

  const MessageLoadEvent(this.otherUser, this.groupMessage, {this.offset = 0})
    : assert(
        (otherUser == null) != (groupMessage == null),
        'Either otherUser or groupMessage must be provided, but not both.',
      );
  @override
  List<Object> get props => [
    if (otherUser != null) otherUser!,
    if (groupMessage != null) groupMessage!,
    offset,
  ];
}

final class MessageLoadMoreEvent extends MessageEvent {
  const MessageLoadMoreEvent();
  @override
  List<Object> get props => [];
}

final class MessageSendEvent extends MessageEvent {
  final dynamic message;
  const MessageSendEvent(this.message);
  @override
  List<Object> get props => [message];
}

final class ClearMessageEvent extends MessageEvent {
  const ClearMessageEvent();
  @override
  List<Object> get props => [];
}

final class ReceiveMessageEvent extends MessageEvent {
  final List<Map<String, dynamic>> payload;
  const ReceiveMessageEvent(this.payload);
  @override
  List<Object> get props => [payload];
}

final class AddReactionEvent extends MessageEvent {
  final String messageId;
  final String reaction;
  const AddReactionEvent(this.messageId, this.reaction);
  @override
  List<Object> get props => [messageId, reaction];
}

final class UpdateMessageEvent extends MessageEvent {
  final MessageModel message;
  const UpdateMessageEvent(this.message);
  @override
  List<Object> get props => [message];
}

class SubscribeToChatStreamEvent extends MessageEvent {
  const SubscribeToChatStreamEvent();

  @override
  List<Object> get props => [];
}

class UnsubscribeFromChatStreamEvent extends MessageEvent {
  const UnsubscribeFromChatStreamEvent();

  @override
  List<Object> get props => [];
}

final class SubscribeToMessagesEvent extends MessageEvent {
  const SubscribeToMessagesEvent();

  @override
  List<Object> get props => [];
}

final class UnsubscribeFromMessagesEvent extends MessageEvent {
  const UnsubscribeFromMessagesEvent();

  @override
  List<Object> get props => [];
}

final class PickImage extends MessageEvent {
  final ImageSource source;

  const PickImage({required this.source});

  @override
  List<Object> get props => [source];
}

final class AddMeSeenMessageEvent extends MessageEvent {
  final MessageModel message;
  const AddMeSeenMessageEvent(this.message);
  @override
  List<Object> get props => [message];
}

class MessageUpdateGroupNameEvent extends MessageEvent {
  final String newName;

  const MessageUpdateGroupNameEvent(this.newName);

  @override
  List<Object> get props => [newName];
}

class MessageUpdateGroupAvatarEvent extends MessageEvent {
  final String newAvatarUrl;

  const MessageUpdateGroupAvatarEvent(this.newAvatarUrl);

  @override
  List<Object> get props => [newAvatarUrl];
}

class MessageAddGroupMemberEvent extends MessageEvent {
  final GroupMessage newGroupMessage;

  const MessageAddGroupMemberEvent(this.newGroupMessage);

  @override
  List<Object> get props => [newGroupMessage];
}

class MessageRemoveGroupMemberEvent extends MessageEvent {
  final appUser.User memberToRemove;

  const MessageRemoveGroupMemberEvent(this.memberToRemove);

  @override
  List<Object> get props => [memberToRemove];
}
