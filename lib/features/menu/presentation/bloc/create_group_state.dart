part of 'create_group_bloc.dart';

// Assuming GroupMessage is in chat/model/group_message.dart
// But this file effectively imports 'group_message.dart' via part of?
// No, 'part of' files share imports of the parent file.
// Parent `create_group_bloc.dart` IMPORTS `group_message.dart`.
// So it SHOULD be visible.
// Lint says undefined. Maybe because I removed it in Step 469?
// Step 469 removed `import 'package:messenger_clone/features/chat/model/group_message.dart';`!
// I must Re-add it to `create_group_bloc.dart`.

enum CreateGroupStatus { idle, creating, success, error }

abstract class CreateGroupState extends Equatable {
  const CreateGroupState();

  @override
  List<Object?> get props => [];
}

class CreateGroupInitial extends CreateGroupState {}

class CreateGroupLoading extends CreateGroupState {}

class CreateGroupLoaded extends CreateGroupState {
  final List<User> friends;
  final List<String> selectedFriends;
  final String groupName;
  final CreateGroupStatus status;
  final List<User>? filteredFriends;
  final GroupMessage? createdGroup;

  const CreateGroupLoaded({
    required this.friends,
    required this.selectedFriends,
    required this.groupName,
    required this.status,
    this.filteredFriends,
    this.createdGroup,
  });

  CreateGroupLoaded copyWith({
    List<User>? friends,
    List<String>? selectedFriends,
    String? groupName,
    CreateGroupStatus? status,
    List<User>? filteredFriends,
    GroupMessage? createdGroup,
  }) {
    return CreateGroupLoaded(
      friends: friends ?? this.friends,
      selectedFriends: selectedFriends ?? this.selectedFriends,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      filteredFriends: filteredFriends ?? this.filteredFriends,
      createdGroup: createdGroup ?? this.createdGroup,
    );
  }

  @override
  List<Object?> get props => [
    friends,
    selectedFriends,
    groupName,
    status,
    filteredFriends,
    createdGroup,
  ];
}

class CreateGroupError extends CreateGroupState {
  final String message;
  const CreateGroupError(this.message);

  @override
  List<Object?> get props => [message];
}
