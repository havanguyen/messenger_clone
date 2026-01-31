import 'dart:io';
import 'package:messenger_clone/common/services/friend_service.dart';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StoryService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _storageBucket = 'stories';

  static Future<String> postStory({
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
        await _supabase.storage
            .from(_storageBucket)
            .upload(fileName, mediaFile);

        final mediaUrl = _supabase.storage
            .from(_storageBucket)
            .getPublicUrl(fileName);

        final now = DateTime.now();
        final twentyFourHoursAgo =
            now.subtract(const Duration(hours: 24)).toIso8601String();

        final response = await _supabase
            .from('stories')
            .select('id')
            .eq('userId', userId)
            .gt('createdAt', twentyFourHoursAgo)
            .count(CountOption.exact);

        final totalStories = response.count + 1; // Assuming +1 for new one

        await _supabase.from('stories').insert({
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

  static Future<List<Map<String, dynamic>>> fetchFriendsStories(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final friendsList = await FriendService.getFriendsList(userId);
        final friendIds =
            friendsList.map((friend) => friend['userId'] as String).toList();

        final allIds = [...friendIds, userId];

        final now = DateTime.now();
        final twentyFourHoursAgo =
            now.subtract(const Duration(hours: 24)).toIso8601String();

        final response = await _supabase
            .from('stories')
            .select()
            .inFilter('userId', allIds)
            .gt('createdAt', twentyFourHoursAgo)
            .order('createdAt', ascending: false);

        return (response as List)
            .map(
              (doc) => {
                'id': doc['id'] ?? doc['\$id'],
                'userId': doc['userId'] as String,
                'mediaUrl': doc['mediaUrl'] as String,
                'mediaType': doc['mediaType'] as String,
                'createdAt': doc['createdAt'] as String,
                'totalStories': doc['totalStories'] as int,
                'fileId': doc['fileId'] as String?,
              },
            )
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch friends\' stories: $e');
      }
    });
  }

  static Future<void> deleteStory(String documentId, String fileId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase.storage.from(_storageBucket).remove([fileId]);

        await _supabase.from('stories').delete().eq('id', documentId);
      } catch (e) {
        throw Exception('Failed to delete story: $e');
      }
    });
  }
}
