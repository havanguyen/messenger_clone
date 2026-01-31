/// MetaAI Repository Interface
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';

/// Abstract repository for Meta AI chat operations
abstract class MetaAiRepository {
  /// Send a message to Meta AI and get response
  Future<Either<Failure, String>> sendMessage(
    String message,
    String conversationId,
  );

  /// Create a new conversation
  Future<Either<Failure, String>> createConversation({String? title});

  /// Get all conversations
  Future<Either<Failure, List<Map<String, dynamic>>>> getConversations();

  /// Delete a conversation
  Future<Either<Failure, void>> deleteConversation(String conversationId);

  /// Load messages for a conversation
  Future<Either<Failure, List<Map<String, dynamic>>>> loadConversationMessages(
    String conversationId,
  );

  /// Sync local messages with server
  Future<Either<Failure, void>> syncWithServer();
}
