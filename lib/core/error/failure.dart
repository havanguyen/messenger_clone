/// Core application failures for error handling.
///
/// These are used with Either<Failure, T> pattern from dartz package
/// to handle errors in a functional way.
library;
import 'package:equatable/equatable.dart';

/// Base Failure class
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/API related failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Local cache related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

/// Authentication related failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Firebase/Firestore failures
class FirebaseFailure extends Failure {
  const FirebaseFailure({required super.message, super.code});
}

/// Supabase storage failures
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}
