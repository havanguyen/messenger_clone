library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';

class GetPendingFriendRequestsUseCase
    implements UseCase<int, GetPendingFriendRequestsParams> {
  final FriendRepository repository;

  GetPendingFriendRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(
    GetPendingFriendRequestsParams params,
  ) async {
    return await repository.getPendingFriendRequestsCount(params.userId);
  }
}

class GetPendingFriendRequestsParams {
  final String userId;

  const GetPendingFriendRequestsParams({required this.userId});
}
