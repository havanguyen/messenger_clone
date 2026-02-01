library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/domain/repositories/chat_repository.dart';

class CreateGroupUseCase implements UseCase<GroupMessage, CreateGroupParams> {
  final ChatRepository repository;

  CreateGroupUseCase(this.repository);

  @override
  Future<Either<Failure, GroupMessage>> call(CreateGroupParams params) async {
    return await repository.createGroupMessages(
      groupName: params.groupName,
      userIds: params.userIds,
      avatarGroupUrl: params.avatarGroupUrl,
      isGroup: params.isGroup,
      groupId: params.groupId,
      createrId: params.createrId,
    );
  }
}

class CreateGroupParams {
  final String? groupName;
  final List<String> userIds;
  final String? avatarGroupUrl;
  final bool isGroup;
  final String groupId;
  final String? createrId;

  const CreateGroupParams({
    this.groupName,
    required this.userIds,
    this.avatarGroupUrl,
    this.isGroup = false,
    required this.groupId,
    this.createrId,
  });
}
