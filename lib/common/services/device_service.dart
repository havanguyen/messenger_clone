import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:messenger_clone/common/services/network_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getUserDevices(
    String userId,
  ) async {
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

        final response = await _supabase
            .from('devices')
            .select()
            .eq('userId', userId);

        return (response as List).map((doc) {
          return {
            'documentId': doc['id'] ?? doc['\$id'],
            'deviceId': doc['deviceId'] as String,
            'platform': doc['platform'] as String,
            'lastLogin': doc['lastLogin'] as String,
            'isCurrentDevice': doc['deviceId'] == currentDeviceId,
          };
        }).toList();
      } catch (e) {
        throw Exception('Error fetching user devices: $e');
      }
    });
  }

  static Future<void> removeDevice(String documentId) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        await _supabase.from('devices').delete().eq('id', documentId);
      } catch (e) {
        throw Exception('Failed to remove device: $e');
      }
    });
  }

  static Future<bool> hasUserLoggedInFromThisDevice(String userId) async {
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

        final response =
            await _supabase
                .from('devices')
                .select('id')
                .eq('userId', userId)
                .eq('deviceId', deviceId)
                .maybeSingle();

        return response != null;
      } catch (e) {
        throw Exception('Failed to check device login history: $e');
      }
    });
  }

  static Future<void> saveLoginDeviceInfo(String userId) async {
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

        final existingDevice =
            await _supabase
                .from('devices')
                .select()
                .eq('userId', userId)
                .eq('deviceId', deviceId)
                .maybeSingle();

        if (existingDevice != null) {
          await _supabase
              .from('devices')
              .update({'lastLogin': DateTime.now().toIso8601String()})
              .eq('id', existingDevice['id'] ?? existingDevice['\$id']);
        } else {
          await _supabase.from('devices').insert({
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
