library;

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/error/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserCredential>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, String?>> checkCredentials(
    String email,
    String password,
  );
  Future<Either<Failure, User?>> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, bool>> isEmailRegistered(String email);
  Future<Either<Failure, String?>> getUserIdFromEmail(String email);
  Future<Either<Failure, void>> resetPassword({
    required String userId,
    required String newPassword,
  });
  Future<String?> isLoggedIn();
  Future<User?> getCurrentUser();
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, void>> reauthenticate(String password);

  Future<Either<Failure, void>> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  });
}
