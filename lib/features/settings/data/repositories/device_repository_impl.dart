import 'package:dartz/dartz.dart';
import 'package:messenger_clone/core/error/failure.dart';
import 'package:messenger_clone/features/settings/data/datasources/device_remote_datasource.dart';
import 'package:messenger_clone/features/settings/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource remoteDataSource;

  DeviceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserDevices(
    String userId,
  ) async {
    try {
      final devices = await remoteDataSource.getUserDevices(userId);
      return Right(devices);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUserLoggedInFromThisDevice(
    String userId,
  ) async {
    try {
      final result = await remoteDataSource.hasUserLoggedInFromThisDevice(
        userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeDevice(String documentId) async {
    try {
      await remoteDataSource.removeDevice(documentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveLoginDeviceInfo(String userId) async {
    try {
      await remoteDataSource.saveLoginDeviceInfo(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
