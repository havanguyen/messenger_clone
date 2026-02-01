library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/network/network_info.dart';
import 'package:messenger_clone/features/meta_ai/data/datasources/meta_ai_remote_datasource.dart';
import 'package:messenger_clone/features/meta_ai/data/datasources/meta_ai_local_datasource.dart';
import 'package:messenger_clone/features/meta_ai/domain/repositories/meta_ai_repository.dart';

class MetaAiRepositoryImpl implements MetaAiRepository {
  final MetaAiRemoteDataSource remoteDataSource;
  final MetaAiLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MetaAiRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, String>> sendMessage(
    String message,
    String conversationId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }
    try {
      final response = await remoteDataSource.sendMessage(
        message,
        conversationId,
      );
      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createConversation({String? title}) async {
    try {
      final conversationId = await remoteDataSource.createConversation(
        title: title,
      );
      return Right(conversationId);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getConversations() async {
    try {
      if (!await networkInfo.isConnected) {
        final localConversations =
            await localDataSource.getLocalConversations();
        return Right(localConversations);
      }
      final conversations = await remoteDataSource.getConversations();
      return Right(conversations);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(
    String conversationId,
  ) async {
    try {
      await remoteDataSource.deleteConversation(conversationId);
      await localDataSource.deleteLocalConversation(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> loadConversationMessages(
    String conversationId,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        final localMessages = await localDataSource.getLocalMessages(
          conversationId,
        );
        return Right(localMessages);
      }
      final messages = await remoteDataSource.loadConversationMessages(
        conversationId,
      );
      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
