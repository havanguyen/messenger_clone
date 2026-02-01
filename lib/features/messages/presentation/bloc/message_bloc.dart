import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as appUser;
import 'package:messenger_clone/features/messages/data/datasources/local/hive_chat_repository.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';
import 'package:messenger_clone/features/messages/domain/usecases/load_messages_usecase.dart';
import 'package:messenger_clone/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository chatRepository;
  final LoadMessagesUseCase loadMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;

  final int _limit = 20;
  late final Future<String> meId;
  StreamSubscription<List<Map<String, dynamic>>>? _chatStreamSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesStreamSubscription;
  Timer? _seenStatusDebouncer;

  MessageBloc({
    required this.chatRepository,
    required this.loadMessagesUseCase,
    required this.sendMessageUseCase,
  }) : super(MessageInitial()) {
    meId = HiveService.instance.getCurrentUserId();
    on<MessageLoadEvent>(_onLoad);
    on<MessageLoadMoreEvent>(_onLoadMore);
    on<MessageSendEvent>(_onSend);
    on<MessageUpdateGroupNameEvent>(_onUpdateName);
    on<MessageUpdateGroupAvatarEvent>(_onUpdateAvatar);
    on<MessageAddGroupMemberEvent>(_onAddMember);
    on<ClearMessageEvent>(_onClearMessageEvent);
    on<ReceiveMessageEvent>(_onReceiveMessageEvent);
    on<AddReactionEvent>(_onAddReactionEvent);
    on<SubscribeToChatStreamEvent>(_onSubscribeToChatStreamEvent);
    on<UnsubscribeFromChatStreamEvent>(_onUnsubscribeFromChatStreamEvent);
    on<SubscribeToMessagesEvent>(_onSubscribeToMessagesEvent);
    on<UnsubscribeFromMessagesEvent>(_onUnsubscribeFromMessagesEvent);
    on<UpdateMessageEvent>(_onUpdateMessageEvent);
    on<AddMeSeenMessageEvent>(_onAddMeSeenMessageEvent);
    on<MessageRemoveGroupMemberEvent>(_onRemoveMember);
  }
  List<appUser.User> _updateOthers(GroupMessage groupMessage, String meId) {
    return (groupMessage.users.length > 1)
        ? groupMessage.users.where((user) => user.id != meId).toList()
        : groupMessage.users.toList();
  }

  void _onLoad(MessageLoadEvent event, Emitter<MessageState> emit) async {
    emit(MessageLoading());
    try {
      final String me = await meId;
      final GroupMessage? groupMessage = event.groupMessage;
      final appUser.User? otherUser = event.otherUser;

      final Either<String, GroupMessage> groupResult =
          await _getOrCreateGroupMessage(groupMessage, otherUser, me);

      if (groupResult.isLeft()) {
        emit(MessageError(groupResult.fold((error) => error, (_) => "")));
        return;
      }

      GroupMessage finalGroupMessage =
          groupResult.fold((_) => null, (group) => group)!;
      MessageModel? lastMessage = finalGroupMessage.lastMessage;
      if (lastMessage != null &&
          lastMessage.idFrom != me &&
          !lastMessage.usersSeen.contains(appUser.User.createMeUser(me))) {
        lastMessage.addUserSeen(appUser.User.createMeUser(me));
        await chatRepository.updateMessage(lastMessage);
        finalGroupMessage = finalGroupMessage.copyWith(
          lastMessage: lastMessage,
        );
      }

      final List<appUser.User> others =
          (finalGroupMessage.users.length > 1)
              ? finalGroupMessage.users.where((user) => user.id != me).toList()
              : (finalGroupMessage.users).toList();

      List<MessageModel> cachedMessages =
          await HiveChatRepository.instance.getMessages(
            finalGroupMessage.groupMessagesId,
          ) ??
          [];

      if (cachedMessages.isNotEmpty) {
        emit(
          MessageLoaded(
            messages: cachedMessages,
            groupMessage: finalGroupMessage,
            others: others,
            meId: me,
            hasMoreMessages: true,
          ),
        );
      } else {
        emit(
          MessageLoaded(
            messages: [],
            groupMessage: finalGroupMessage,
            others: others,
            meId: me,
            hasMoreMessages: true,
          ),
        );
      }
      add(MessageLoadMoreEvent());
      add(SubscribeToChatStreamEvent());
      add(SubscribeToMessagesEvent());
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  void _onLoadMore(
    MessageLoadMoreEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        emit(currentState.copyWith(isLoadingMore: true));
        final offset = currentState.messages.length;
        final result = await loadMessagesUseCase(
          LoadMessagesParams(
            groupChatId: currentState.groupMessage.groupMessagesId,
            limit: _limit,
            offset: offset,
          ),
        );

        result.fold(
          (failure) {
            emit(currentState.copyWith(isLoadingMore: false));
          }, // Or show error
          (newMessages) async {
            Map<String, VideoPlayerController> newVideoPlayers = {};
            Map<String, Image> newImages = {};
            for (MessageModel message in newMessages) {
              if (message.type == "video") {
                try {
                  final controller = VideoPlayerController.networkUrl(
                    Uri.parse(message.content),
                  );
                  await controller.initialize();
                  newVideoPlayers[message.id] = controller;
                } catch (e) {
                  debugPrint("Error initializing video player: $e");
                }
              }
              if (message.type == "image") {
                try {
                  final image = Image.network(message.content);
                  newImages[message.id] = image;
                } catch (e) {
                  debugPrint("Error loading image: $e");
                }
              }
            }
            emit(
              currentState.copyWith(
                messages: [
                  ...currentState.messages,
                  ...newMessages,
                ], // Deduplication logic might be needed
                isLoadingMore: false,
                hasMoreMessages: newMessages.length >= _limit,
                videoPlayers: {
                  ...currentState.videoPlayers,
                  ...newVideoPlayers,
                },
                images: {...currentState.images, ...newImages},
              ),
            );
          },
        );
      }
    } catch (error) {
      if (state is MessageLoaded) {
        emit((state as MessageLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onSend(MessageSendEvent event, Emitter<MessageState> emit) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      final String me = await meId;
      final GroupMessage groupMessage = currentState.groupMessage;
      List<MessageModel> messages = List<MessageModel>.from(
        currentState.messages,
      );
      Map<String, VideoPlayerController> videoPlayers = Map.from(
        currentState.videoPlayers,
      );

      late final MessageModel newMessage;
      Map<String, Image> images = Map.from(currentState.images);
      String tempId = DateTime.now().millisecondsSinceEpoch.toString();

      switch (event.message.runtimeType) {
        case String:
          newMessage = MessageModel(
            id: tempId,
            sender: appUser.User.createMeUser(me),
            content: event.message,
            type: "text",
            groupMessagesId: groupMessage.groupMessagesId,
            status: MessageStatus.sending,
            createdAt: DateTime.now(),
            usersSeen: [],
            reactions: [],
          );
          break;
        case XFile:
          final file = event.message as XFile;
          newMessage = MessageModel(
            id: tempId,
            sender: appUser.User.createMeUser(me),
            content: file.path,
            type:
                (file.name.endsWith('.mp4') || file.name.endsWith('.mov'))
                    ? "video"
                    : "image",
            groupMessagesId: groupMessage.groupMessagesId,
            status: MessageStatus.sending,
            createdAt: DateTime.now(),
            usersSeen: [],
            reactions: [],
          );

          if (newMessage.type == "image") {
            images[tempId] = Image.file(File(file.path));
          }
          break;
        default:
          return;
      }

      messages.insert(0, newMessage);
      emit(
        currentState.copyWith(
          messages: messages,
          videoPlayers: videoPlayers,
          images: images,
        ),
      );

      try {
        MessageModel sentMessage;
        if (event.message is XFile) {
          final file = event.message as XFile;
          final uploadResult = await chatRepository.uploadFile(file.path, me);

          Map<String, dynamic> uploadRes = {};
          uploadResult.fold(
            (failure) => throw Exception(failure.toString()),
            (success) => uploadRes = success,
          );

          final String path = uploadRes['\$id'] ?? uploadRes['id'];
          final publicUrl = chatRepository.getPublicUrl(path);

          sentMessage = newMessage.copyWith(
            content: publicUrl,
            status: MessageStatus.sent,
          );

          final msgToSend = sentMessage.copyWith(id: '');
          final result = await sendMessageUseCase(
            SendMessageParams(message: msgToSend, groupMessage: groupMessage),
          );

          sentMessage = result.fold(
            (failure) => throw Exception(failure.toString()),
            (sent) => sent,
          );
        } else {
          var msgToSend = newMessage.copyWith(id: '');
          final result = await sendMessageUseCase(
            SendMessageParams(message: msgToSend, groupMessage: groupMessage),
          );
          sentMessage = result.fold(
            (failure) => throw Exception(failure.toString()),
            (sent) => sent,
          );
        }

        if (state is MessageLoaded) {
          final latestState = state as MessageLoaded;
          final List<MessageModel> latestMessages =
              (latestState.messages).toList();
          final int index = latestMessages.indexWhere(
            (message) => message.id == tempId,
          );
          if (index != -1) {
            latestMessages[index] = sentMessage;
            emit(
              latestState.copyWith(
                messages: latestMessages,
                lastSuccessMessage: sentMessage,
              ),
            );
            List<String> userIds =
                groupMessage.users.map((user) => user.id).toList();
            await chatRepository.sendPushNotification(
              userIds: userIds,
              groupMessageId: groupMessage.groupMessagesId,
              messageContent: sentMessage.content,
              senderId: me,
              senderName: sentMessage.sender.name,
            );
          }
        }
      } catch (error) {
        debugPrint("Error sending message: $error");
        if (state is MessageLoaded) {
          final latestState = state as MessageLoaded;
          final latestMessages = List<MessageModel>.from(latestState.messages);
          final int index = latestMessages.indexWhere(
            (message) => message.id == tempId,
          );
          if (index != -1) {
            latestMessages[index] = latestMessages[index].copyWith(
              status: MessageStatus.failed,
            );
            emit(latestState.copyWith(messages: latestMessages));
          }
        }
      }
    }
  }
  Future<Either<String, GroupMessage>> _getOrCreateGroupMessage(
    GroupMessage? groupMessage,
    appUser.User? otherUser,
    String me,
  ) async {
    if (groupMessage != null) return Right(groupMessage);
    if (otherUser != null) {
      try {
        final result = await chatRepository.createGroupMessages(
          userIds: [me, otherUser.id],
          groupId: 'PRIVATE_${[me, otherUser.id].join('_')}',
          groupName: '',
          isGroup: false,
          createrId: me,
        );
        return result.fold(
          (failure) => Left(failure.toString()),
          (group) => Right(group),
        );
      } catch (e) {
        return Left(e.toString());
      }
    }
    return const Left("Invalid arguments");
  }

  void _onRemoveMember(
    MessageRemoveGroupMemberEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is! MessageLoaded) return;
    final currentState = state as MessageLoaded;
    final removedUser = event.memberToRemove;
    final me = currentState.meId;

    try {
      final List<appUser.User> updatedUser =
          currentState.groupMessage.users
              .where((user) => user.id != removedUser.id)
              .toList();
      final Set<String> updatedUserIds = updatedUser.map((e) => e.id).toSet();

      GroupMessage updatedGroupFromBackend = currentState.groupMessage;

      final result = await (chatRepository as dynamic).updateMemberOfGroup(
        currentState.groupMessage.groupMessagesId,
        updatedUserIds,
      );

      if (result is Either) {
        result.fold(
          (failure) => throw Exception(failure.toString()),
          (success) => updatedGroupFromBackend = success,
        );
      } else {
        updatedGroupFromBackend = result;
      }

      emit(
        currentState.copyWith(
          groupMessage: updatedGroupFromBackend,
          others: _updateOthers(updatedGroupFromBackend, me),
          successMessage: '${removedUser.name} removed from group',
        ),
      );
      add(
        MessageSendEvent(
          "${currentState.groupMessage.users.firstWhere((u) => u.id == me).name} removed ${removedUser.name} from the group",
        ),
      );
      emit(currentState.copyWith(successMessage: null));
    } catch (e) {
      emit(MessageError('Failed to remove member: $e'));
    }
  }

  void _onUpdateName(
    MessageUpdateGroupNameEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        GroupMessage updatedGroup = currentState.groupMessage.copyWith(
          groupName: event.newName,
        );
        final result = await (chatRepository as dynamic).updateGroupMessage(
          updatedGroup,
        );

        if (result is Either) {
          result.fold(
            (failure) => throw Exception(failure.toString()),
            (success) => updatedGroup = success,
          );
        } else {
          updatedGroup = result;
        }
        add(MessageSendEvent("Group name updated to ${event.newName}"));

        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: 'Group name updated successfully',
          ),
        );
        emit(currentState.copyWith(successMessage: null));
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  void _onUpdateAvatar(
    MessageUpdateGroupAvatarEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        GroupMessage updatedGroup = currentState.groupMessage.copyWith(
          avatarGroupUrl: event.newAvatarUrl,
        );
        final result = await (chatRepository as dynamic).updateGroupMessage(
          updatedGroup,
        );
        if (result is Either) {
          result.fold(
            (failure) => throw Exception(failure.toString()),
            (success) => updatedGroup = success,
          );
        } else {
          updatedGroup = result;
        }
        emit(
          currentState.copyWith(
            groupMessage: updatedGroup,
            successMessage: 'Group avatar updated successfully',
          ),
        );
        emit(currentState.copyWith(successMessage: null));
      }
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }

  void _onAddMember(
    MessageAddGroupMemberEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(
        currentState.copyWith(
          groupMessage: event.newGroupMessage,
          others: _updateOthers(event.newGroupMessage, currentState.meId),
        ),
      );
      add(MessageSendEvent("New members added"));
    }
  }

  void _onAddMeSeenMessageEvent(
    AddMeSeenMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      final MessageModel message = event.message;
      if (message.idFrom != currentState.meId &&
          !message.isContains(currentState.meId)) {
        message.addUserSeen(appUser.User.createMeUser(currentState.meId));
        await chatRepository.updateMessage(message);
      }
    }
  }

  void _debouncedUpdateSeenStatus(MessageModel message) {
    if (_seenStatusDebouncer?.isActive ?? false) _seenStatusDebouncer?.cancel();
    _seenStatusDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        add(AddMeSeenMessageEvent(message));
      }
    });
  }

  void _onUpdateMessageEvent(
    UpdateMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        final String messageId = event.message.id;
        final List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );

        final int index = messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (index != -1) {
          messages[index] = event.message;
          emit(currentState.copyWith(messages: messages));
          _debouncedUpdateSeenStatus(event.message);
        }
      } catch (error) {
        debugPrint('Error updating message: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onUnsubscribeFromMessagesEvent(
    UnsubscribeFromMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _messagesStreamSubscription?.cancel();
    _messagesStreamSubscription = null;
  }

  void _onSubscribeToMessagesEvent(
    SubscribeToMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        await _messagesStreamSubscription?.cancel();

        debugPrint(
          'Subscribing to messages for groupMessageId: ${currentState.groupMessage.groupMessagesId}',
        );
        final messagesStreamResult = await chatRepository.getMessagesStream([
          currentState.groupMessage.groupMessagesId,
        ]);

        messagesStreamResult.fold(
          (failure) => emit(MessageError(failure.toString())),
          (stream) {
            _messagesStreamSubscription = stream.listen(
              (payload) {
                if (payload.isNotEmpty && !isClosed) {
                  add(ReceiveMessageEvent(payload));
                }
              },
              onError: (error) {
                debugPrint('Error in messages stream: $error');
                add(ReceiveMessageEvent([])); // Or handle error state
              },
            );
          },
        );
      } catch (error) {
        debugPrint('Error subscribing to messages stream: $error');
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onSubscribeToChatStreamEvent(
    SubscribeToChatStreamEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        if (_chatStreamSubscription != null) return;

        final chatStreamResult = await chatRepository.getChatStream(
          currentState.groupMessage.groupMessagesId,
        );

        chatStreamResult.fold((failure) => emit(MessageError(failure.toString())), (
          stream,
        ) {
          _chatStreamSubscription = stream.listen((payload) {
          });
        });
      } catch (error) {
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onUnsubscribeFromChatStreamEvent(
    UnsubscribeFromChatStreamEvent event,
    Emitter<MessageState> emit,
  ) async {
    await _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;
  }

  void _onAddReactionEvent(
    AddReactionEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final currentState = state as MessageLoaded;
        final String messageId = event.messageId;
        final String reaction = event.reaction;
        final List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );
        final int index = messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          List<String> reactions = List<String>.from(messages[index].reactions);
          reactions.add(reaction);
          messages[index] = messages[index].copyWith(reactions: reactions);
          emit(currentState.copyWith(messages: messages));
          await chatRepository.updateMessage(messages[index]);
        }
      } catch (error) {
        emit(MessageError(error.toString()));
      }
    }
  }

  void _onReceiveMessageEvent(
    ReceiveMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    if (state is MessageLoaded) {
      try {
        final payload = event.payload;
        if (payload.isEmpty) return;

        final currentState = state as MessageLoaded;
        List<MessageModel> messages = List<MessageModel>.from(
          currentState.messages,
        );
        final String me = await meId;

        bool stateChanged = false;

        for (final data in payload) {
          final MessageModel newMessage = MessageModel.fromMap(data);
          _debouncedUpdateSeenStatus(newMessage);

          final index = messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            if (messages[index] != newMessage) {
              messages[index] = newMessage;
              stateChanged = true;
            }
          } else {
            messages.insert(0, newMessage);
            stateChanged = true;
          }
        }
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (stateChanged) {

          emit(
            currentState.copyWith(
              messages: messages,
            ),
          );
        }
      } catch (error) {
        debugPrint('Error handling realtime message: $error');
      }
    }
  }

  void _onClearMessageEvent(
    ClearMessageEvent event,
    Emitter<MessageState> emit,
  ) {
    emit(MessageInitial());
  }

  @override
  Future<void> close() async {
    _seenStatusDebouncer?.cancel();
    _seenStatusDebouncer = null;
    List<Future<void>> futureList = [];
    if (_chatStreamSubscription != null) {
      futureList.add(_chatStreamSubscription!.cancel());
    }
    _chatStreamSubscription = null;
    if (_messagesStreamSubscription != null) {
      futureList.add(_messagesStreamSubscription!.cancel());
    }
    _messagesStreamSubscription = null;
    await Future.wait(futureList);
    return super.close();
  }
}
