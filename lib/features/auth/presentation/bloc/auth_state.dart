part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthRegistered extends AuthState {
  final User user;

  const AuthRegistered({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

class AuthAccountDeleted extends AuthState {}

class AuthUserParamsUpdated extends AuthState {}

class AuthReauthenticated extends AuthState {}

class AuthCredentialsChecked extends AuthState {
  final String? userId;
  final bool isValid;

  const AuthCredentialsChecked({required this.isValid, this.userId});

  @override
  List<Object?> get props => [isValid, userId];
}
