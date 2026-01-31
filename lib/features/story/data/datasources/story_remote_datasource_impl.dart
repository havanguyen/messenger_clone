import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:messenger_clone/core/network/network_utils.dart';
import 'package:messenger_clone/features/story/data/datasources/story_remote_datasource.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';

class StoryRemoteDataSourceImpl implements StoryRemoteDataSource {
  final SupabaseClient supabase;
  final FirebaseFirestore firestore;
  final FriendRepository friendRepository;
  static const String _storageBucket = 'stories';

  StoryRemoteDataSourceImpl({
    required this.supabase,
    required this.firestore,
    required this.friendRepository,
  });

  @override
  Future<String> postStory({
    required String userId,
    required File mediaFile,
    required String mediaType,
  }) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final fileId = const Uuid().v4();
        final fileExt = mediaFile.path.split('.').last;
        final fileName = '$userId/$fileId.$fileExt';

        // Upload to Storage
        await supabase.storage.from(_storageBucket).upload(fileName, mediaFile);

        final mediaUrl = supabase.storage
            .from(_storageBucket)
            .getPublicUrl(fileName);

        final now = DateTime.now();
        final twentyFourHoursAgo =
            now.subtract(const Duration(hours: 24)).toIso8601String();

        final countSnap =
            await firestore
                .collection('stories')
                .where('userId', isEqualTo: userId)
                .where('createdAt', isGreaterThan: twentyFourHoursAgo)
                .count()
                .get();

        final totalStories = (countSnap.count ?? 0) + 1;

        await firestore.collection('stories').add({
          'userId': userId,
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
          'createdAt': now.toIso8601String(),
          'totalStories': totalStories,
          'fileId': fileName, // Storing file path/ID for deletion
        });

        return mediaUrl;
      } catch (e) {
        throw Exception('Unexpected error while posting story: $e');
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFriendsStories(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Use FriendRepository to get friends list
        final friendsResult = await friendRepository.getFriendsList(userId);

        final friendsList = friendsResult.fold(
          (l) => <Map<String, dynamic>>[], // Return empty if error (or throw?)
          (r) => r,
        );

        if (friendsResult.isLeft()) {
          // Maybe we should propagate error, but logic in service was throwing.
          // Impl here: if fetch friends fails, maybe just return empty or throw.
          // Service logic: threw exception if FriendService failed.
          final failure = friendsResult.fold((l) => l, (r) => null);
          throw Exception(failure?.message ?? "Unknown error fetching friends");
        }

        final friendIds =
            friendsList.map((friend) => friend['userId'] as String).toList();
        final allIds = [...friendIds, userId];

        final now = DateTime.now();
        final twentyFourHoursAgo =
            now.subtract(const Duration(hours: 24)).toIso8601String();

        List<Map<String, dynamic>> stories = [];
        int chunkSize = 10;

        for (var i = 0; i < allIds.length; i += chunkSize) {
          List<String> chunk = allIds.sublist(
            i,
            i + chunkSize > allIds.length ? allIds.length : i + chunkSize,
          );
          if (chunk.isEmpty) continue;

          final querySnap =
              await firestore
                  .collection('stories')
                  .where('userId', whereIn: chunk)
                  .where('createdAt', isGreaterThan: twentyFourHoursAgo)
                  .orderBy('createdAt', descending: true)
                  .get();

          for (var doc in querySnap.docs) {
            final data = doc.data();
            stories.add({
              'id': doc.id,
              'userId': data['userId'] as String,
              'mediaUrl': data['mediaUrl'] as String,
              'mediaType': data['mediaType'] as String,
              'createdAt': data['createdAt'] as String,
              'totalStories': data['totalStories'] as int,
              'fileId': data['fileId'] as String?,
            });
          }
        }

        stories.sort(
          (a, b) =>
              (b['createdAt'] as String).compareTo(a['createdAt'] as String),
        );

        return stories;
      } catch (e) {
        throw Exception('Failed to fetch friends\' stories: $e');
      }
    });
  }

  @override
  Future<void> deleteStory(String documentId, String fileId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await supabase.storage.from(_storageBucket).remove([fileId]);
        await firestore.collection('stories').doc(documentId).delete();
      } catch (e) {
        throw Exception('Failed to delete story: $e');
      }
    });
  }
}
