import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<String?> call() async {
    return await repository.isLoggedIn();
  }
}
