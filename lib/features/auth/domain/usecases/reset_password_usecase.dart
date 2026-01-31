import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      userId: params.userId,
      newPassword: params.newPassword,
    );
  }
}

class ResetPasswordParams extends Equatable {
  final String userId;
  final String newPassword;

  const ResetPasswordParams({required this.userId, required this.newPassword});

  @override
  List<Object?> get props => [userId, newPassword];
}
