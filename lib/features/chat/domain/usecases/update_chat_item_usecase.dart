library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';

class UpdateChatItemUseCase
    implements UseCase<GroupMessage, UpdateChatItemParams> {
  final ChatRepository repository;

  UpdateChatItemUseCase(this.repository);

  @override
  Future<Either<Failure, GroupMessage>> call(
    UpdateChatItemParams params,
  ) async {
    return await repository.getGroupMessageById(params.groupChatId);
  }
}

class UpdateChatItemParams {
  final String groupChatId;

  const UpdateChatItemParams({required this.groupChatId});
}
