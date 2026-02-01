import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:messenger_clone/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserCredential>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await remoteDataSource.signIn(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await localDataSource.saveUserId(user.uid);

        final fcmToken = await remoteDataSource.getFcmToken();
        if (fcmToken != null) {
          await localDataSource.savePushToken(fcmToken);
          await remoteDataSource.updatePushToken(user.uid, fcmToken);
        }
      }

      return Right(credential);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> checkCredentials(
    String email,
    String password,
  ) async {
    try {
      final credential = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      final userId = credential.user?.uid;
      if (userId != null) {
        await remoteDataSource.signOut(userId, '');
      }
      return Right(userId);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final userId = await localDataSource.getUserId();
      final token = await localDataSource.getPushToken();

      await remoteDataSource.signOut(userId ?? '', token ?? '');
      await localDataSource.clearUserData();
      return const Right(null);
    } catch (e) {
      try {
        await localDataSource.clearUserData();
      } catch (_) {}
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await remoteDataSource.signUp(
        email: email,
        password: password,
        name: name,
      );
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    try {
      final result = await remoteDataSource.isEmailRegistered(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getUserIdFromEmail(String email) async {
    try {
      final result = await remoteDataSource.getUserIdFromEmail(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        userId: userId,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<String?> isLoggedIn() async {
    return await remoteDataSource.isLoggedIn();
  }

  @override
  Future<User?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      await localDataSource.clearUserData();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticate(String password) async {
    try {
      await remoteDataSource.reauthenticate(password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserAuth({
    required String userId,
    String? name,
    String? email,
    String? password,
  }) async {
    try {
      await remoteDataSource.updateUserAuth(
        userId: userId,
        name: name,
        email: email,
        password: password,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
