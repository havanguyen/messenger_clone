import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class CheckCredentialsUseCase {
  final AuthRepository repository;

  CheckCredentialsUseCase(this.repository);

  Future<Either<Failure, String?>> call(String email, String password) async {
    return await repository.checkCredentials(email, password);
  }
}
