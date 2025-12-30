import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String?> _onNotificationClick = StreamController<String?>.broadcast();
  
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;
  
  // Singleton
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  // Initialize
  Future<void> initialize() async {
    // Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions on Android 13+
    await _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    // Add payload to stream so listeners can handle it
    _instance._onNotificationClick.add(response.payload);
  }

  // Show simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pengumuman_channel',
      'Pengumuman',
      channelDescription: 'Notifikasi untuk pengumuman baru',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      color: Color(0xFF0D47A1),
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _plugin.show(id, title, body, details, payload: payload);
  }
  
  // Show pengumuman notification
  Future<void> showPengumumanNotification({
    required String title,
    required String body,
    int? pengumumanId,
  }) async {
    await showNotification(
      id: pengumumanId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📢 $title',
      body: body,
      payload: pengumumanId != null ? 'pengumuman:$pengumumanId' : null,
    );
  }
  
  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
  
  // Cancel all
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
