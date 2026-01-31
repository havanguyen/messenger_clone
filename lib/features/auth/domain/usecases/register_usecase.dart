/// Register UseCase
library;
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<User?, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call(RegisterParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
  });
}
