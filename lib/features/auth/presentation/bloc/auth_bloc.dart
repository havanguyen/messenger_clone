import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/login_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/register_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/logout_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/reauthenticate_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/update_user_auth_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_user_id_usecase.dart';

import 'package:messenger_clone/features/auth/domain/usecases/check_credentials_usecase.dart'; // We need this if using GetCurrentUser

part 'auth_event.dart';
part 'auth_state.dart';

/// AuthBloc - MVVM ViewModel using UseCases
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final ReauthenticateUseCase reauthenticateUseCase;
  final UpdateUserAuthUseCase updateUserAuthUseCase;
  final GetUserIdUseCase getUserIdUseCase;
  final CheckCredentialsUseCase checkCredentialsUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.resetPasswordUseCase,
    required this.deleteAccountUseCase,
    required this.reauthenticateUseCase,
    required this.updateUserAuthUseCase,
    required this.getUserIdUseCase,
    required this.checkCredentialsUseCase,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ResetPasswordEvent>(_onResetPassword);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<ReauthenticateEvent>(_onReauthenticate);
    on<UpdateUserAuthEvent>(_onUpdateUserAuth);
    on<CheckCredentialsEvent>(_onCheckCredentials);
  }

  Future<void> _onCheckCredentials(
    CheckCredentialsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await checkCredentialsUseCase(event.email, event.password);
    result.fold((failure) => emit(AuthError(message: failure.message)), (
      userId,
    ) {
      if (userId != null) {
        emit(AuthCredentialsChecked(isValid: true, userId: userId));
      } else {
        emit(const AuthCredentialsChecked(isValid: false));
      }
    });
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final userId = await checkAuthStatusUseCase();
    if (userId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (credential) => emit(AuthAuthenticated(user: credential.user!)),
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      RegisterParams(
        email: event.email,
        password: event.password,
        name: event.name,
      ),
    );
    result.fold((failure) => emit(AuthError(message: failure.message)), (user) {
      if (user != null) {
        emit(AuthRegistered(user: user));
      } else {
        emit(AuthError(message: 'Registration failed'));
      }
    });
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logoutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final idResult = await getUserIdUseCase(event.email);
    await idResult.fold(
      (failure) async => emit(AuthError(message: failure.message)),
      (userId) async {
        if (userId == null) {
          emit(const AuthError(message: "User not found"));
          return;
        }
        final result = await resetPasswordUseCase(
          ResetPasswordParams(userId: userId, newPassword: ''),
        );
        result.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (_) => emit(AuthPasswordResetSent()),
        );
      },
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await deleteAccountUseCase();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthAccountDeleted()),
    );
  }

  Future<void> _onReauthenticate(
    ReauthenticateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await reauthenticateUseCase(event.password);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthReauthenticated()),
    );
  }

  Future<void> _onUpdateUserAuth(
    UpdateUserAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await updateUserAuthUseCase(
      UpdateUserAuthParams(
        userId: event.userId,
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUserParamsUpdated()),
    );
  }
}
