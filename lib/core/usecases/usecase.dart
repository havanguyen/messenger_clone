library;
import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
class NoParams {
  const NoParams();
}
