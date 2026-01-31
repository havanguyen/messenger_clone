/// Auth Repository Interface
///
/// Abstract repository for authentication operations.
library;

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/error/failure.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserCredential>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, String?>> checkCredentials(
    String email,
    String password,
  );

  /// Sign up with email, password and name
  Future<Either<Failure, User?>> signUp({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Check if email is registered
  Future<Either<Failure, bool>> isEmailRegistered(String email);

  /// Get user ID from email
  Future<Either<Failure, String?>> getUserIdFromEmail(String email);

  /// Reset password
  Future<Either<Failure, void>> resetPassword({
    required String userId,
    required String newPassword,
  });

  /// Check if user is logged in
  Future<String?> isLoggedIn();

  /// Get current user
  Future<User?> getCurrentUser();

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();

  /// Reauthenticate user
  Future<Either<Failure, void>> reauthenticate(String password);

  Future<Either<Failure, void>> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  });
}
