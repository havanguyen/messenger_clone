/// Use case to get friends list for a user.
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';

class GetFriendsUseCase implements UseCase<List<User>, GetFriendsParams> {
  final ChatRepository repository;

  GetFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<User>>> call(GetFriendsParams params) async {
    return await repository.getFriendsList(params.userId);
  }
}

class GetFriendsParams {
  final String userId;

  const GetFriendsParams({required this.userId});
}
