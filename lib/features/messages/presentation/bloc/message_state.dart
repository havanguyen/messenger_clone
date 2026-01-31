part of 'message_bloc.dart';

sealed class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object> get props => [];
}

final class MessageInitial extends MessageState {}

final class MessageLoading extends MessageState {}

final class MessageLoaded extends MessageState {
  final List<MessageModel> messages;
  final GroupMessage groupMessage;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final List<appUser.User> others;
  final String meId;
  final Map<String, VideoPlayerController> videoPlayers;
  final Map<String, Image> images;
  final MessageModel? lastSuccessMessage;
  final String? successMessage;
  const MessageLoaded({
    required this.messages,
    required this.groupMessage,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    required this.others,
    required this.meId,
    this.videoPlayers = const {},
    this.images = const {},
    this.lastSuccessMessage,
    this.successMessage,
  });
  @override
  List<Object> get props => [
    messages,
    groupMessage,
    isLoadingMore,
    hasMoreMessages,
    others,
    meId,
    videoPlayers,
    images,
    if (lastSuccessMessage != null) lastSuccessMessage!,
    if (successMessage != null) successMessage!,
  ];
  MessageLoaded copyWith({
    List<MessageModel>? messages,
    GroupMessage? groupMessage,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    List<appUser.User>? others,
    String? meId,
    Map<String, VideoPlayerController>? videoPlayers,
    Map<String, Image>? images,
    MessageModel? lastSuccessMessage,
    String? successMessage,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      groupMessage: groupMessage ?? this.groupMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      others: others ?? this.others,
      meId: meId ?? this.meId,
      videoPlayers: videoPlayers ?? this.videoPlayers,
      images: images ?? this.images,
      lastSuccessMessage: lastSuccessMessage ?? this.lastSuccessMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

final class MessageError extends MessageState {
  final String error;
  const MessageError(this.error);
  @override
  List<Object> get props => [error];
}
