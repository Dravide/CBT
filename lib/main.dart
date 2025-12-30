import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cbt_app/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:cbt_app/services/local_notification_service.dart';
// import 'package:cbt_app/services/fcm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler disabled
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   await FcmService.firebaseMessagingBackgroundHandler(message);
// }




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // Initialize 'id_ID' locale
  await LocalNotificationService().initialize(); // Initialize local notifications
  // await Firebase.initializeApp(); // Disabled as requested
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Fixed orientation removed for Android 16+ Large Screen support
  /* SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]); */

  // Android 15 Edge-to-Edge Compliance
  // Use edgeToEdge instead of immersiveSticky globally.
  // We will enable immersiveSticky only on specific exam pages if needed.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const Color primaryColor = Color.fromRGBO(18, 26, 28, 1);
  // final FcmService _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    // _fcmService.initialize(); // Disabled as requested
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SATRIA',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
