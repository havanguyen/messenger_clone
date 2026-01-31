import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> updateUserStatus(
    String userId,
    bool isActive,
  ) async {
    try {
      await remoteDataSource.updateUserStatus(userId, isActive);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  }) async {
    try {
      await remoteDataSource.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        aboutMe: aboutMe,
        photoUrl: photoUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updatePhotoUrl({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.updatePhotoUrl(
        imageFile: imageFile,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchUserDataById(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.fetchUserDataById(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getNameUser(String userId) async {
    try {
      final result = await remoteDataSource.getNameUser(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
