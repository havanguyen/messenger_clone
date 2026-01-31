abstract class DeviceRemoteDataSource {
  Future<List<Map<String, dynamic>>> getUserDevices(String userId);
  Future<void> removeDevice(String documentId);
  Future<bool> hasUserLoggedInFromThisDevice(String userId);
  Future<void> saveLoginDeviceInfo(String userId);
}
