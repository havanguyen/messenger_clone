library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';

class SendMessageUseCase implements UseCase<MessageModel, SendMessageParams> {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, MessageModel>> call(SendMessageParams params) async {
    return await repository.sendMessage(params.message, params.groupMessage);
  }
}

class SendMessageParams {
  final MessageModel message;
  final GroupMessage groupMessage;

  const SendMessageParams({required this.message, required this.groupMessage});
}
