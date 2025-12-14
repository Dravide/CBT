import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cbt_app/services/pengumuman_service.dart';
import 'package:cbt_app/pages/pengumuman_detail_page.dart';
import 'package:cbt_app/main.dart'; // import for navigatorKey
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final PengumumanService _pengumumanService = PengumumanService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
         if (response.payload != null) {
           // Handle notification tap
           final int? id = int.tryParse(response.payload!);
           if (id != null) {
             navigatorKey.currentState?.push(
               MaterialPageRoute(builder: (context) => PengumumanDetailPage(id: id)),
             );
           }
         }
      },
    );

    // 2. Create Notification Channel (Required for Android 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _pengumumanService.registerDeviceToken(token, null);
      }

      // Handle token rotation
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _pengumumanService.registerDeviceToken(newToken, null);
      });

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // If 'notification' block is present, show local notification
        if (notification != null && android != null) {
          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
                // other properties...
              ),
            ),
            payload: message.data['pengumuman_id'] ?? '', // Pass ID as payload
          );
        }
      });

      // Handle message open (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message);
      });
      
      // Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

    } else {
      print('User declined or has not accepted permission');
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'pengumuman') {
      final String? idStr = message.data['pengumuman_id'];
      if (idStr != null) {
        final int? id = int.tryParse(idStr);
        if (id != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => PengumumanDetailPage(id: id)),
          );
        }
      }
    }
  }
  
  // Static method for background handling (must be top-level)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }
}
