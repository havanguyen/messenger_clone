import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'package:messenger_clone/features/chat/model/group_message.dart'; // Needed for GroupMessage usage
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/menu/domain/usecases/create_group_usecase.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_friends_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'create_group_event.dart';
part 'create_group_state.dart';

/// CreateGroupBloc - Manages group creation state
class CreateGroupBloc extends Bloc<CreateGroupEvent, CreateGroupState> {
  final GetFriendsUseCase getFriendsUseCase;
  final CreateGroupUseCase createGroupUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  firebase_auth.User? _currentUser;

  CreateGroupBloc({
    required this.getFriendsUseCase,
    required this.createGroupUseCase,
    required this.getCurrentUserUseCase,
  }) : super(CreateGroupInitial()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<SearchFriendsEvent>(_onSearchFriends);
    on<SelectFriendEvent>(_onSelectFriend);
    on<DeselectFriendEvent>(_onDeselectFriend);
    on<UpdateGroupNameEvent>(_onUpdateGroupName);
    on<SubmitCreateGroupEvent>(_onCreateGroup);
  }

  // Unused method removed: _generateGroupName

  Future<void> _onLoadFriends(
    LoadFriendsEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    emit(CreateGroupLoading());
    try {
      _currentUser = await getCurrentUserUseCase();
      if (_currentUser == null) throw Exception('User not logged in');

      final result = await getFriendsUseCase(
        GetFriendsParams(userId: _currentUser!.uid),
      );
      result.fold(
        (failure) => emit(CreateGroupError(failure.toString())),
        (friends) => emit(
          CreateGroupLoaded(
            friends: friends,
            selectedFriends: const [],
            groupName: '',
            status: CreateGroupStatus.idle,
            filteredFriends: null,
          ),
        ),
      );
    } catch (e) {
      emit(CreateGroupError(e.toString()));
    }
  }

  Future<void> _onSearchFriends(
    SearchFriendsEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final String query = event.query.trim().toLowerCase();
      final filteredFriends =
          query.isEmpty
              ? null
              : loaded.friends
                  .where(
                    (user) =>
                        user.name.toLowerCase().contains(query) ||
                        user.aboutMe.toLowerCase().contains(query),
                  )
                  .toList();
      emit(loaded.copyWith(filteredFriends: filteredFriends));
    }
  }

  void _onSelectFriend(
    SelectFriendEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final updated = List<String>.from(loaded.selectedFriends)
        ..add(event.friendId);
      emit(loaded.copyWith(selectedFriends: updated));
    }
  }

  void _onDeselectFriend(
    DeselectFriendEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      final updated = List<String>.from(loaded.selectedFriends)
        ..remove(event.friendId);
      emit(loaded.copyWith(selectedFriends: updated));
    }
  }

  void _onUpdateGroupName(
    UpdateGroupNameEvent event,
    Emitter<CreateGroupState> emit,
  ) {
    if (state is CreateGroupLoaded) {
      final loaded = state as CreateGroupLoaded;
      emit(loaded.copyWith(groupName: event.groupName));
    }
  }

  Future<void> _onCreateGroup(
    SubmitCreateGroupEvent event,
    Emitter<CreateGroupState> emit,
  ) async {
    if (state is CreateGroupLoaded) {
      emit(
        (state as CreateGroupLoaded).copyWith(
          status: CreateGroupStatus.creating,
        ),
      );
      try {
        _currentUser ??= await getCurrentUserUseCase();
        final Set<String> allUserInvolveMeId = {_currentUser!.uid};

        final currentState = state as CreateGroupLoaded;
        allUserInvolveMeId.addAll(currentState.selectedFriends);
        // Generate groupId logic removed as it's handled by UseCase/Repository or not needed here
        final groupMess = await createGroupUseCase(
          CreateGroupParams(
            groupName: currentState.groupName,
            userIds: allUserInvolveMeId.toList(),
            createrId: _currentUser!.uid,
            groupId: const Uuid().v1(),
          ),
        );

        groupMess.fold(
          (failure) => emit(CreateGroupError(failure.toString())),
          (group) => emit(
            (state as CreateGroupLoaded).copyWith(
              status: CreateGroupStatus.success,
              createdGroup: group,
            ),
          ),
        );

        // Removed redundant emit block that caused type mismatch
        // The success state is already emitted inside groupMess.fold
      } catch (e) {
        emit(CreateGroupError(e.toString()));
      }
    }
  }
}
