import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class ReauthenticateUseCase {
  final AuthRepository repository;

  ReauthenticateUseCase(this.repository);

  Future<Either<Failure, void>> call(String password) async {
    return await repository.reauthenticate(password);
  }
}
