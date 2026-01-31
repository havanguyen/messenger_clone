part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class DeleteAccountEvent extends AuthEvent {
  const DeleteAccountEvent();
}

class ReauthenticateEvent extends AuthEvent {
  final String password;

  const ReauthenticateEvent({required this.password});

  @override
  List<Object> get props => [password];
}

class UpdateUserAuthEvent extends AuthEvent {
  final String userId;
  final String? name;
  final String? email;
  final String? password;

  const UpdateUserAuthEvent({
    required this.userId,
    this.name,
    this.email,
    this.password,
  });

  @override
  List<Object?> get props => [userId, name, email, password];
}

class CheckCredentialsEvent extends AuthEvent {
  final String email;
  final String password;

  const CheckCredentialsEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
