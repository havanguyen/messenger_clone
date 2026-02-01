library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';

class LoadMessagesUseCase
    implements UseCase<List<MessageModel>, LoadMessagesParams> {
  final MessageRepository repository;

  LoadMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<MessageModel>>> call(
    LoadMessagesParams params,
  ) async {
    return await repository.getMessages(
      params.groupChatId,
      params.limit,
      params.offset,
      params.newerThan,
    );
  }
}

class LoadMessagesParams {
  final String groupChatId;
  final int limit;
  final int offset;
  final DateTime? newerThan;

  const LoadMessagesParams({
    required this.groupChatId,
    required this.limit,
    required this.offset,
    this.newerThan,
  });
}
