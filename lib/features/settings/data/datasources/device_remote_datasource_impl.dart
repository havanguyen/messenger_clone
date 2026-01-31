import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:messenger_clone/core/network/network_utils.dart';
import 'package:messenger_clone/features/settings/data/datasources/device_remote_datasource.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final FirebaseFirestore _firestore;

  DeviceRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final deviceInfo = DeviceInfoPlugin();
        String currentDeviceId;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          currentDeviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          currentDeviceId = iosInfo.identifierForVendor ?? '';
        } else {
          throw PlatformException(
            code: 'UNSUPPORTED_PLATFORM',
            message: 'Device info is only supported on Android and iOS',
          );
        }

        final querySnapshot =
            await _firestore
                .collection('devices')
                .where('userId', isEqualTo: userId)
                .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'documentId': doc.id,
            'deviceId': data['deviceId'] as String,
            'platform': data['platform'] as String,
            'lastLogin': data['lastLogin'] as String,
            'isCurrentDevice': data['deviceId'] == currentDeviceId,
          };
        }).toList();
      } catch (e) {
        throw Exception('Error fetching user devices: $e');
      }
    });
  }

  @override
  Future<bool> hasUserLoggedInFromThisDevice(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final deviceInfo = DeviceInfoPlugin();
        String deviceId;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? '';
        } else {
          return false;
        }

        final snapshot =
            await _firestore
                .collection('devices')
                .where('userId', isEqualTo: userId)
                .where('deviceId', isEqualTo: deviceId)
                .limit(1)
                .get();

        return snapshot.docs.isNotEmpty;
      } catch (e) {
        throw Exception('Failed to check device login history: $e');
      }
    });
  }

  @override
  Future<void> removeDevice(String documentId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _firestore.collection('devices').doc(documentId).delete();
      } catch (e) {
        throw Exception('Failed to remove device: $e');
      }
    });
  }

  @override
  Future<void> saveLoginDeviceInfo(String userId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final deviceInfo = DeviceInfoPlugin();
        String deviceId;
        String platform;

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          platform = 'Android';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? '';
          platform = 'iOS';
        } else {
          throw PlatformException(
            code: 'UNSUPPORTED_PLATFORM',
            message: 'Device info is only supported on Android and iOS',
          );
        }

        final existingDeviceSnap =
            await _firestore
                .collection('devices')
                .where('userId', isEqualTo: userId)
                .where('deviceId', isEqualTo: deviceId)
                .limit(1)
                .get();

        if (existingDeviceSnap.docs.isNotEmpty) {
          final docId = existingDeviceSnap.docs.first.id;
          await _firestore.collection('devices').doc(docId).update({
            'lastLogin': DateTime.now().toIso8601String(),
          });
        } else {
          await _firestore.collection('devices').add({
            'userId': userId,
            'deviceId': deviceId,
            'platform': platform,
            'lastLogin': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        throw Exception('Failed to save device info: $e');
      }
    });
  }
}
