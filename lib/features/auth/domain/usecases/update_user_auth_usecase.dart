import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class UpdateUserAuthUseCase {
  final AuthRepository repository;

  UpdateUserAuthUseCase(this.repository);

  Future<Either<Failure, void>> call(UpdateUserAuthParams params) async {
    return await repository.updateUserAuth(
      userId: params.userId,
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class UpdateUserAuthParams extends Equatable {
  final String userId;
  final String? name;
  final String? email;
  final String? password;

  const UpdateUserAuthParams({
    required this.userId,
    this.name,
    this.email,
    this.password,
  });

  @override
  List<Object?> get props => [userId, name, email, password];
}
