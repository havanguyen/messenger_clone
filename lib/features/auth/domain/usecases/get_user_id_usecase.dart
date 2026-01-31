import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class GetUserIdUseCase {
  final AuthRepository repository;

  GetUserIdUseCase(this.repository);

  Future<Either<Failure, String?>> call(String email) async {
    return await repository.getUserIdFromEmail(email);
  }
}
