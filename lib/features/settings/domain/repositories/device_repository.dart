import 'package:messenger_clone/core/error/failure.dart';
import 'package:dartz/dartz.dart';

abstract class DeviceRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserDevices(
    String userId,
  );
  Future<Either<Failure, void>> removeDevice(String documentId);
  Future<Either<Failure, bool>> hasUserLoggedInFromThisDevice(String userId);
  Future<Either<Failure, void>> saveLoginDeviceInfo(String userId);
}
