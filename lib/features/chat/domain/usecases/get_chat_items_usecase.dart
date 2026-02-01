/// Use case to get chat items for a user.
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/chat/model/chat_item.dart';

import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';

class GetChatItemsUseCase
    implements UseCase<List<ChatItem>, GetChatItemsParams> {
  final ChatRepository repository;

  GetChatItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatItem>>> call(
    GetChatItemsParams params,
  ) async {
    final result = await repository.getGroupMessagesByUserId(params.userId);

    return result.fold((failure) => Left(failure), (groupMessages) {
      groupMessages.sort((a, b) {
        if (a.lastMessage == null && b.lastMessage == null) {
          return 0;
        } else if (a.lastMessage == null) {
          return 1;
        } else if (b.lastMessage == null) {
          return -1;
        } else {
          return b.lastMessage!.vietnamTime.compareTo(
            a.lastMessage!.vietnamTime,
          );
        }
      });
      final chatItems =
          groupMessages
              .map((gm) => ChatItem(groupMessage: gm, meId: params.userId))
              .toList();

      return Right(chatItems);
    });
  }
}

class GetChatItemsParams {
  final String userId;

  const GetChatItemsParams({required this.userId});
}
