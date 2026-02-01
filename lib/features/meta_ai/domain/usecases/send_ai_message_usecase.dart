library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/meta_ai/domain/repositories/meta_ai_repository.dart';

class SendAiMessageUseCase implements UseCase<String, SendAiMessageParams> {
  final MetaAiRepository repository;

  SendAiMessageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(SendAiMessageParams params) async {
    return await repository.sendMessage(params.message, params.conversationId);
  }
}

class SendAiMessageParams {
  final String message;
  final String conversationId;

  const SendAiMessageParams({
    required this.message,
    required this.conversationId,
  });
}
