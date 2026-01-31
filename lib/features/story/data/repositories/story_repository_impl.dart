import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/story/data/datasources/story_remote_datasource.dart';
import 'package:messenger_clone/features/story/domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final StoryRemoteDataSource remoteDataSource;

  StoryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  }) async {
    try {
      final result = await remoteDataSource.postStory(
        userId: userId,
        mediaFile: mediaFile,
        mediaType: mediaType,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchFriendsStories(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.fetchFriendsStories(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(
    String documentId,
    String fileId,
  ) async {
    try {
      await remoteDataSource.deleteStory(documentId, fileId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
