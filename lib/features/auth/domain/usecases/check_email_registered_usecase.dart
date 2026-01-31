import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class CheckEmailRegisteredUseCase {
  final AuthRepository repository;

  CheckEmailRegisteredUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email) async {
    return await repository.isEmailRegistered(email);
  }
}
