/// Base UseCase class.
///
/// All use cases should extend this class with specific params and return type.
library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';

/// Base UseCase with params
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No params class for use cases that don't need parameters
class NoParams {
  const NoParams();
}
