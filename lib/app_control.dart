import 'package:flutter/services.dart';

class AppControl {
  static const MethodChannel _channel = MethodChannel('com.scipsa.cbt/app_control');

  /// Exit the app by stopping lock task mode and closing
  static Future<void> exitApp() async {
    try {
      await setSecure(false); // Re-enable screenshots
      await _channel.invokeMethod('exitApp');
    } catch (e) {
      // Fallback if native method fails
      SystemNavigator.pop();
    }
  }
  /// Start Lock Task Mode (Screen Pinning)
  static Future<void> startLockTask() async {
    try {
      await _channel.invokeMethod('startLockTask');
    } catch (e) {
      print("Failed to start lock task: $e");
    }
  }

  /// Stop Lock Task Mode
  static Future<void> stopLockTask() async {
    try {
      await setSecure(false); // Re-enable screenshots when lock task stops
      await _channel.invokeMethod('stopLockTask');
    } catch (e) {
      print("Failed to stop lock task: $e");
    }
  }

  /// Enable or Disable Secure Mode (Block Screenshots)
  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } catch (e) {
      print("Failed to set secure mode: $e");
    }
  }
}
