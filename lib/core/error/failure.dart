library;
import 'package:equatable/equatable.dart';
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}
class FirebaseFailure extends Failure {
  const FirebaseFailure({required super.message, super.code});
}
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}
