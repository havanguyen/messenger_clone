import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messenger_clone/common/services/user_service.dart';
import 'network_utils.dart';

class FriendService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Map<String, String>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final sentResponse =
            await _supabase
                .from('friends')
                .select()
                .eq('userId', currentUserId)
                .eq('friendId', otherUserId)
                .maybeSingle();

        if (sentResponse != null) {
          return {
            'status': sentResponse['status'] as String,
            'requestId': sentResponse['id'] ?? sentResponse['\$id'] ?? '',
            'direction': 'sent',
          };
        }

        final receivedResponse =
            await _supabase
                .from('friends')
                .select()
                .eq('userId', otherUserId)
                .eq('friendId', currentUserId)
                .maybeSingle();

        if (receivedResponse != null) {
          return {
            'status': receivedResponse['status'] as String,
            'requestId':
                receivedResponse['id'] ?? receivedResponse['\$id'] ?? '',
            'direction': 'received',
          };
        }

        return {'status': 'none', 'requestId': '', 'direction': ''};
      } catch (e) {
        throw Exception('Failed to check friendship status: $e');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getFriendsList(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final sentFriends = await _supabase
            .from('friends')
            .select()
            .eq('userId', userId)
            .eq('status', 'accepted');

        final receivedFriends = await _supabase
            .from('friends')
            .select()
            .eq('friendId', userId)
            .eq('status', 'accepted');

        final friendIds = <String, String>{};
        for (var doc in sentFriends) {
          friendIds[doc['friendId'] as String] = doc['id'] ?? doc['\$id'];
        }
        for (var doc in receivedFriends) {
          friendIds[doc['userId'] as String] = doc['id'] ?? doc['\$id'];
        }

        final friendsList = await Future.wait(
          friendIds.entries.map((entry) async {
            final friendId = entry.key;
            final requestId = entry.value;
            final friendData = await UserService.fetchUserDataById(friendId);
            return {
              'userId': friendId,
              'name': friendData['userName'] as String?,
              'photoUrl': friendData['photoUrl'] as String?,
              'aboutMe': friendData['aboutMe'] as String? ?? 'No description',
              'requestId': requestId,
            };
          }).toList(),
        );

        return friendsList;
      } catch (e) {
        throw Exception('Error fetching friends list: $e');
      }
    });
  }

  static Future<void> cancelFriendRequest(String requestId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase.from('friends').delete().eq('id', requestId);
      } catch (e) {
        throw Exception('Failed to cancel friend request: $e');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> searchUsersByName(
    String name,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await _supabase
            .from('users')
            .select()
            .ilike('name', '%$name%')
            .limit(20);

        return (response as List)
            .map(
              (doc) => {
                'userId': doc['id'] ?? doc['\$id'],
                'name': doc['name'] as String?,
                'photoUrl': doc['photoUrl'] as String?,
                'aboutMe': doc['aboutMe'] as String?,
                'email': doc['email'] as String?,
                'isActive': doc['isActive'] as bool? ?? false,
              },
            )
            .toList();
      } catch (e) {
        throw Exception('Error searching users: $e');
      }
    });
  }

  static Future<void> sendFriendRequest(
    String currentUserId,
    String friendUserId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        // Check if user exists (Optional optimization, skipping to save RTT)

        final existingRequest =
            await _supabase
                .from('friends')
                .select()
                .or(
                  'and(userId.eq.$currentUserId,friendId.eq.$friendUserId),and(userId.eq.$friendUserId,friendId.eq.$currentUserId)',
                )
                .maybeSingle();

        if (existingRequest != null) {
          final status = existingRequest['status'] as String;
          if (status == 'pending') {
            throw Exception(
              'A friend request is already pending with this user.',
            );
          } else if (status == 'accepted') {
            throw Exception('You are already friends with this user.');
          }
        }

        await _supabase.from('friends').insert({
          'userId': currentUserId,
          'friendId': friendUserId,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (e.toString().contains('duplicate key') ||
            e.toString().contains('unique constraint')) {
          throw Exception('A friend request or friendship already exists.');
        }
        throw Exception('Error sending friend request: $e');
      }
    });
  }

  static Future<int> getPendingFriendRequestsCount(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await _supabase
            .from('friends')
            .select('id')
            .eq('friendId', userId)
            .eq('status', 'pending')
            .count(CountOption.exact);

        return response.count;
      } catch (e) {
        // Supabase select count returns different structure depending on client version
        // Fallback or detailed error check
        return 0;
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingFriendRequests(
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await _supabase
            .from('friends')
            .select()
            .eq('friendId', userId)
            .eq('status', 'pending');

        return (response as List)
            .map(
              (doc) => {
                'requestId': doc['id'] ?? doc['\$id'],
                'userId': doc['userId'] as String,
                'friendId': doc['friendId'] as String,
                'status': doc['status'] as String,
              },
            )
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch friend requests: $e');
      }
    });
  }

  static Future<void> acceptFriendRequest(
    String requestId,
    String userId,
  ) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase
            .from('friends')
            .update({'status': 'accepted'})
            .eq('id', requestId);
      } catch (e) {
        throw Exception('Failed to accept friend request: $e');
      }
    });
  }

  static Future<void> declineFriendRequest(String requestId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase.from('friends').delete().eq('id', requestId);
      } catch (e) {
        throw Exception('Failed to decline friend request: $e');
      }
    });
  }
}
