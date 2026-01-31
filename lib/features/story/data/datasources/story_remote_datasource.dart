import 'dart:io';

abstract class StoryRemoteDataSource {
  Future<String> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  });

  Future<List<Map<String, dynamic>>> fetchFriendsStories(String userId);

  Future<void> deleteStory(String documentId, String fileId);
}
