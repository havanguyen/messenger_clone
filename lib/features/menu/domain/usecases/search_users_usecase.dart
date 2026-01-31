/// Search Users UseCase
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';

class SearchUsersUseCase
    implements UseCase<List<Map<String, dynamic>>, SearchUsersParams> {
  final FriendRepository repository;

  SearchUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    SearchUsersParams params,
  ) async {
    return await repository.searchUsersByName(params.query);
  }
}

class SearchUsersParams {
  final String query;
  final String currentUserId;

  const SearchUsersParams({required this.query, required this.currentUserId});
}
