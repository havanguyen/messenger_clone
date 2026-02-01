library;
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/core/usecases/usecase.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserCredential, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserCredential>> call(LoginParams params) async {
    return await repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}
