library;
class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}
class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}
class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code,
  });
}
class FirebaseException extends AppException {
  const FirebaseException({required super.message, super.code});
}
