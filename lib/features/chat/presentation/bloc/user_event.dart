part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class GetAllUsersEvent extends UserEvent {}

class GetUserChatsEvent extends UserEvent {
  final String userId;
  const GetUserChatsEvent({required this.userId});
  @override
  List<Object> get props => [userId];
}
