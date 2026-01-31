import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';
import 'package:messenger_clone/features/friend/data/datasources/friend_remote_datasource.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDataSource remoteDataSource;
  final UserRepository userRepository;

  FriendRepositoryImpl({
    required this.remoteDataSource,
    required this.userRepository,
  });

  @override
  Future<Either<Failure, Map<String, String>>> getFriendshipStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final result = await remoteDataSource.getFriendshipStatus(
        currentUserId,
        otherUserId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getFriendsList(
    String userId,
  ) async {
    try {
      final friendRefs = await remoteDataSource.getFriendsListRefs(userId);
      final friendsList = <Map<String, dynamic>>[];

      for (var ref in friendRefs) {
        final friendId = ref['friendId'] as String;
        final requestId = ref['requestId'] as String;

        final userResult = await userRepository.fetchUserDataById(friendId);

        userResult.fold(
          (failure) {
            // Log failure or ignore? For now skipping if user not found or error
            // Or maybe include a partial object?
          },
          (userData) {
            friendsList.add({
              'userId': friendId,
              'name': userData['userName'] as String?,
              'photoUrl': userData['photoUrl'] as String?,
              'aboutMe': userData['aboutMe'] as String? ?? 'No description',
              'requestId': requestId,
            });
          },
        );
      }
      return Right(friendsList);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelFriendRequest(String requestId) async {
    try {
      await remoteDataSource.cancelFriendRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsersByName(
    String name,
  ) async {
    try {
      final result = await remoteDataSource.searchUsersByName(name);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendFriendRequest(
    String currentUserId,
    String friendUserId,
  ) async {
    try {
      await remoteDataSource.sendFriendRequest(currentUserId, friendUserId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getPendingFriendRequestsCount(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getPendingFriendRequestsCount(
        userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingFriendRequests(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.getPendingFriendRequests(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(
    String requestId,
    String userId,
  ) async {
    try {
      await remoteDataSource.acceptFriendRequest(requestId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineFriendRequest(String requestId) async {
    try {
      await remoteDataSource.declineFriendRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
