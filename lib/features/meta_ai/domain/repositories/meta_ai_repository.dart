library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
abstract class MetaAiRepository {
  Future<Either<Failure, String>> sendMessage(
    String message,
    String conversationId,
  );
  Future<Either<Failure, String>> createConversation({String? title});
  Future<Either<Failure, List<Map<String, dynamic>>>> getConversations();
  Future<Either<Failure, void>> deleteConversation(String conversationId);
  Future<Either<Failure, List<Map<String, dynamic>>>> loadConversationMessages(
    String conversationId,
  );
  Future<Either<Failure, void>> syncWithServer();
}
