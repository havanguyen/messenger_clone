import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';

abstract class FriendRepository {
  Future<Either<Failure, Map<String, String>>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  );
  Future<Either<Failure, List<Map<String, dynamic>>>> getFriendsList(
    String userId,
  );
  Future<Either<Failure, void>> cancelFriendRequest(String requestId);
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsersByName(
    String name,
  );
  Future<Either<Failure, void>> sendFriendRequest(
    String currentUserId,
    String friendUserId,
  );
  Future<Either<Failure, int>> getPendingFriendRequestsCount(String userId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingFriendRequests(
    String userId,
  );
  Future<Either<Failure, void>> acceptFriendRequest(
    String requestId,
    String userId,
  );
  Future<Either<Failure, void>> declineFriendRequest(String requestId);
}
