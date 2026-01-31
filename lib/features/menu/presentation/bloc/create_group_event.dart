part of 'create_group_bloc.dart';

abstract class CreateGroupEvent extends Equatable {
  const CreateGroupEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriendsEvent extends CreateGroupEvent {
  const LoadFriendsEvent();
}

class SearchFriendsEvent extends CreateGroupEvent {
  final String query;
  const SearchFriendsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectFriendEvent extends CreateGroupEvent {
  final String friendId;
  const SelectFriendEvent(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class DeselectFriendEvent extends CreateGroupEvent {
  final String friendId;
  const DeselectFriendEvent(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class UpdateGroupNameEvent extends CreateGroupEvent {
  final String groupName;
  const UpdateGroupNameEvent(this.groupName);

  @override
  List<Object?> get props => [groupName];
}

class SubmitCreateGroupEvent extends CreateGroupEvent {
  const SubmitCreateGroupEvent();
}
