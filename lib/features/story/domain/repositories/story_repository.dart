import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';

abstract class StoryRepository {
  Future<Either<Failure, String>> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> fetchFriendsStories(
    String userId,
  );

  Future<Either<Failure, void>> deleteStory(String documentId, String fileId);
}
