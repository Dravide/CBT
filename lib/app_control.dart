import 'package:flutter/services.dart';

class AppControl {
  static const MethodChannel _channel = MethodChannel('com.example.cbt/app_control');

  /// Exit the app by stopping lock task mode and closing
  static Future<void> exitApp() async {
    try {
      await _channel.invokeMethod('exitApp');
    } catch (e) {
      // Fallback if native method fails
      SystemNavigator.pop();
    }
  }
}
