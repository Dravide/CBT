import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to get and manage unique device ID for login binding
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  static const String _deviceIdKey = 'cached_device_id';
  static const String _deviceRegisteredKey = 'device_registered';
  static const String _baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api';
  
  String? _cachedDeviceId;

  /// Get unique device identifier
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getString(_deviceIdKey);
    if (cachedId != null && cachedId.isNotEmpty) {
      _cachedDeviceId = cachedId;
      return cachedId;
    }

    final deviceId = await _generateDeviceId();
    _cachedDeviceId = deviceId;
    await prefs.setString(_deviceIdKey, deviceId);
    
    return deviceId;
  }

  /// Generate device ID from hardware info
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final components = [
          android.brand,
          android.model,
          android.id,
          android.fingerprint,
        ];
        return 'ANDROID-${components.join('-').hashCode.toRadixString(16).toUpperCase()}';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final vendorId = ios.identifierForVendor ?? 'unknown';
        return 'IOS-$vendorId';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if device is already registered locally
  Future<bool> isDeviceRegisteredLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deviceRegisteredKey) ?? false;
  }

  /// Mark device as registered locally
  Future<void> setDeviceRegisteredLocally(bool registered) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceRegisteredKey, registered);
  }

  /// Check device status from server
  /// Returns: 'registered', 'not_registered', 'mismatch', or 'error'
  Future<String> checkDeviceStatus(int userId, String userType) async {
    try {
      final deviceId = await getDeviceId();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/device-status?user_id=$userId&user_type=$userType&device_id=$deviceId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['has_device'] == false) {
          return 'not_registered';
        } else if (data['is_current_device'] == true) {
          await setDeviceRegisteredLocally(true);
          return 'registered';
        } else {
          return 'mismatch';
        }
      }
      return 'error';
    } catch (e) {
      debugPrint('Error checking device status: $e');
      return 'error';
    }
  }

  /// Register device with server
  /// Returns success status and message
  Future<Map<String, dynamic>> registerDevice(int userId, String userType) async {
    try {
      final deviceId = await getDeviceId();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register-device'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_type': userType,
          'device_id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await setDeviceRegisteredLocally(true);
        return {'success': true, 'message': data['message'] ?? 'Perangkat berhasil didaftarkan'};
      } else if (response.statusCode == 403) {
        return {'success': false, 'message': data['message'] ?? 'Perangkat sudah terdaftar di akun lain', 'mismatch': true};
      }
      
      return {'success': false, 'message': data['message'] ?? 'Gagal mendaftarkan perangkat'};
    } catch (e) {
      debugPrint('Error registering device: $e');
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  /// Get device info for display purposes
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'brand': android.brand,
          'model': android.model,
          'version': 'Android ${android.version.release}',
          'device_id': await getDeviceId(),
        };
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'brand': 'Apple',
          'model': ios.model,
          'version': 'iOS ${ios.systemVersion}',
          'device_id': await getDeviceId(),
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {
      'platform': 'Unknown',
      'device_id': await getDeviceId(),
    };
  }

  /// Clear cached device ID
  Future<void> clearCachedDeviceId() async {
    _cachedDeviceId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceRegisteredKey);
  }
}
