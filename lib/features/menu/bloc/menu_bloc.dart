import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/friend_service.dart';
import 'package:messenger_clone/common/services/hive_service.dart';
import 'package:messenger_clone/common/services/user_service.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuInitial()) {
    on<FetchUserData>(_onFetchUserData);
    on<FetchNotificationCounts>(_onFetchNotificationCounts);
    on<SignOut>(_onSignOut);
    on<DeleteAccount>(_onDeleteAccount);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onFetchUserData(
    FetchUserData event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());
    try {
      String userId = await HiveService.instance.getCurrentUserId();
      final result = await UserService.fetchUserDataById(userId);
      if (result.containsKey('error')) {
        emit(MenuError(result['error'] as String));
      } else {
        emit(
          MenuLoaded(
            userName: result['userName'] as String?,
            userId: result['userId'] as String?,
            email: result['email'] as String?,
            aboutMe: result['aboutMe'] as String?,
            photoUrl: result['photoUrl'] as String?,
            pendingMessagesCount: state.pendingMessagesCount,
            friendRequestsCount: state.friendRequestsCount,
          ),
        );
      }
    } catch (e) {
      emit(MenuError('Failed to fetch user data: $e'));
    }
  }

  Future<void> _onFetchNotificationCounts(
    FetchNotificationCounts event,
    Emitter<MenuState> emit,
  ) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final friendRequestsCount =
            await FriendService.getPendingFriendRequestsCount(user.uid);
        emit(
          MenuLoaded(
            userName: state.userName,
            userId: state.userId,
            email: state.email,
            aboutMe: state.aboutMe,
            photoUrl: state.photoUrl,
            pendingMessagesCount: 2, // Placeholder, replace with actual logic
            friendRequestsCount: friendRequestsCount,
          ),
        );
      }
    } catch (e) {
      emit(MenuError('Failed to fetch notification counts: $e'));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      await AuthService.signOut();
      emit(AccountSignOutSuccess());
    } catch (e) {
      emit(MenuError('Failed to sign out: $e'));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception('User not logged in.');
      if (await _verifyPassword(event.password)) {
        await AuthService.deleteAccount();
        emit(AccountDeletionSuccess());
      } else {
        emit(MenuError('Incorrect password'));
      }
    } catch (e) {
      if (e.toString().contains('Rate limit exceeded')) {
        emit(MenuError('Rate limit exceeded. Please try again later.'));
      } else {
        emit(MenuError('Failed to delete account: $e'));
      }
    }
  }

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<MenuState> emit,
  ) async {
    emit(MenuLoading());
    try {
      String userId = await HiveService.instance.getCurrentUserId();
      final result = await UserService.fetchUserDataById(userId);
      if (result.containsKey('error')) {
        emit(MenuError(result['error'] as String));
        return;
      }
      final user = await AuthService.getCurrentUser();
      int? friendRequestsCount;
      if (user != null) {
        friendRequestsCount = await FriendService.getPendingFriendRequestsCount(
          user.uid,
        );
      }
      emit(
        MenuLoaded(
          userName: result['userName'] as String?,
          userId: result['userId'] as String?,
          email: result['email'] as String?,
          aboutMe: result['aboutMe'] as String?,
          photoUrl: result['photoUrl'] as String?,
          pendingMessagesCount: 2, // Placeholder, replace with actual logic
          friendRequestsCount: friendRequestsCount,
        ),
      );
    } catch (e) {
      emit(MenuError('Failed to refresh data: $e'));
    }
  }

  Future<bool> _verifyPassword(String password) async {
    try {
      await AuthService.reauthenticate(password);
      return true;
    } catch (e) {
      if (e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        return false; // Invalid password
      }
      throw Exception('Verification failed: $e');
    }
  }
}
