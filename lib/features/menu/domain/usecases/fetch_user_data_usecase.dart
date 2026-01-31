/// Fetch User Data UseCase
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';

class FetchUserDataUseCase
    implements UseCase<Map<String, dynamic>, FetchUserDataParams> {
  final UserRepository repository;

  FetchUserDataUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    FetchUserDataParams params,
  ) async {
    return await repository.fetchUserDataById(params.userId);
  }
}

class FetchUserDataParams {
  final String userId;

  const FetchUserDataParams({required this.userId});
}
