import 'package:equatable/equatable.dart';

abstract class AddMemberGroupEvent extends Equatable {
  const AddMemberGroupEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriendsEvent extends AddMemberGroupEvent {
  final List<String> userEnjoyedIds;

  const LoadFriendsEvent(this.userEnjoyedIds);

  @override
  List<Object?> get props => [userEnjoyedIds];
}

class SearchFriendsEvent extends AddMemberGroupEvent {
  final String query;

  const SearchFriendsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectFriendEvent extends AddMemberGroupEvent {
  final String friendId;

  const SelectFriendEvent(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class DeselectFriendEvent extends AddMemberGroupEvent {
  final String friendId;

  const DeselectFriendEvent(this.friendId);

  @override
  List<Object?> get props => [friendId];
}

class SubmitAddMembersEvent extends AddMemberGroupEvent {
  const SubmitAddMembersEvent();
}
