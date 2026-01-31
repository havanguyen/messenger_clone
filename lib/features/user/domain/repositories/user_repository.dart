import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateUserStatus(String userId, bool isActive);
  Future<Either<Failure, void>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? aboutMe,
    String? photoUrl,
  });
  Future<Either<Failure, String>> updatePhotoUrl({
    required File imageFile,
    required String userId,
  });
  Future<Either<Failure, Map<String, dynamic>>> fetchUserDataById(
    String userId,
  );
  Future<Either<Failure, String?>> getNameUser(String userId);
}
