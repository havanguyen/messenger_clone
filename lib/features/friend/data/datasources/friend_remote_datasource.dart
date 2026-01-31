import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FriendRemoteDataSource {
  Future<Map<String, String>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  );
  Future<List<Map<String, dynamic>>> getFriendsListRefs(
    String userId,
  ); // Returns pairs of friendId and requestId
  Future<void> cancelFriendRequest(String requestId);
  Future<List<Map<String, dynamic>>> searchUsersByName(String name);
  Future<void> sendFriendRequest(String currentUserId, String friendUserId);
  Future<int> getPendingFriendRequestsCount(String userId);
  Future<List<Map<String, dynamic>>> getPendingFriendRequests(String userId);
  Future<void> acceptFriendRequest(String requestId, String userId);
  Future<void> declineFriendRequest(String requestId);
}

class FriendRemoteDataSourceImpl implements FriendRemoteDataSource {
  final FirebaseFirestore firestore;

  FriendRemoteDataSourceImpl({required this.firestore});

  @override
  Future<Map<String, String>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    final sentSnapshot =
        await firestore
            .collection('friends')
            .where('userId', isEqualTo: currentUserId)
            .where('friendId', isEqualTo: otherUserId)
            .limit(1)
            .get();

    if (sentSnapshot.docs.isNotEmpty) {
      final data = sentSnapshot.docs.first.data();
      return {
        'status': data['status'] as String,
        'requestId': sentSnapshot.docs.first.id,
        'direction': 'sent',
      };
    }

    final receivedSnapshot =
        await firestore
            .collection('friends')
            .where('userId', isEqualTo: otherUserId)
            .where('friendId', isEqualTo: currentUserId)
            .limit(1)
            .get();

    if (receivedSnapshot.docs.isNotEmpty) {
      final data = receivedSnapshot.docs.first.data();
      return {
        'status': data['status'] as String,
        'requestId': receivedSnapshot.docs.first.id,
        'direction': 'received',
      };
    }

    return {'status': 'none', 'requestId': '', 'direction': ''};
  }

  @override
  Future<List<Map<String, dynamic>>> getFriendsListRefs(String userId) async {
    final sentFriendsSnap =
        await firestore
            .collection('friends')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final receivedFriendsSnap =
        await firestore
            .collection('friends')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .get();

    final friends = <Map<String, dynamic>>[];

    for (var doc in sentFriendsSnap.docs) {
      friends.add({'friendId': doc.data()['friendId'], 'requestId': doc.id});
    }
    for (var doc in receivedFriendsSnap.docs) {
      friends.add({
        'friendId':
            doc.data()['userId'], // The other user is the one who sent it
        'requestId': doc.id,
      });
    }
    return friends;
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    await firestore.collection('friends').doc(requestId).delete();
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsersByName(String name) async {
    final response =
        await firestore
            .collection('users')
            .orderBy('name')
            .startAt([name])
            .endAt(['$name\uf8ff'])
            .limit(20)
            .get();

    return response.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': doc.id,
        'name': data['name'] as String?,
        'photoUrl': data['photoUrl'] as String?,
        'aboutMe': data['aboutMe'] as String?,
        'email': data['email'] as String?,
        'isActive': data['isActive'] as bool? ?? false,
      };
    }).toList();
  }

  @override
  Future<void> sendFriendRequest(
    String currentUserId,
    String friendUserId,
  ) async {
    final existingSent =
        await firestore
            .collection('friends')
            .where('userId', isEqualTo: currentUserId)
            .where('friendId', isEqualTo: friendUserId)
            .limit(1)
            .get();
    final existingReceived =
        await firestore
            .collection('friends')
            .where('userId', isEqualTo: friendUserId)
            .where('friendId', isEqualTo: currentUserId)
            .limit(1)
            .get();

    if (existingSent.docs.isNotEmpty) {
      final data = existingSent.docs.first.data();
      final status = data['status'] as String;
      if (status == 'pending') {
        throw Exception('A friend request is already pending with this user.');
      }
      if (status == 'accepted') {
        throw Exception('You are already friends with this user.');
      }
    }
    if (existingReceived.docs.isNotEmpty) {
      final data = existingReceived.docs.first.data();
      final status = data['status'] as String;
      if (status == 'pending') {
        throw Exception('A friend request is already pending with this user.');
      }
      if (status == 'accepted') {
        throw Exception('You are already friends with this user.');
      }
    }

    await firestore.collection('friends').add({
      'userId': currentUserId,
      'friendId': friendUserId,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<int> getPendingFriendRequestsCount(String userId) async {
    final snapshot =
        await firestore
            .collection('friends')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .count()
            .get();
    return snapshot.count ?? 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingFriendRequests(
    String userId,
  ) async {
    final response =
        await firestore
            .collection('friends')
            .where('friendId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

    return response.docs.map((doc) {
      final data = doc.data();
      return {
        'requestId': doc.id,
        'userId': data['userId'] as String,
        'friendId': data['friendId'] as String,
        'status': data['status'] as String,
      };
    }).toList();
  }

  @override
  Future<void> acceptFriendRequest(String requestId, String userId) async {
    await firestore.collection('friends').doc(requestId).update({
      'status': 'accepted',
    });
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await firestore.collection('friends').doc(requestId).delete();
  }
}
