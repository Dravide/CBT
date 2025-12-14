import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cbt_app/app_control.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage({super.key, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  static const Color _primaryColor = Color.fromRGBO(18, 26, 28, 1);
  static const Color _accentColor = Color.fromRGBO(76, 175, 80, 1);

  // Battery
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  late StreamSubscription<BatteryState> _batteryStateSubscription;

  // Network
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  String _connectionType = 'Checking...';
  int _pingMs = -1;
  bool _isOnline = false;
  Timer? _pingTimer;

  // Warning thresholds
  static const int _lowBatteryThreshold = 20;
  static const int _highPingThreshold = 500;

  // Warning state
  bool _showBatteryWarning = false;
  bool _showPingWarning = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
    
    _initBattery();
    _initConnectivity();
  }

  void _initBattery() {
    _getBatteryLevel();
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      setState(() {
        _batteryState = state;
      });
      _getBatteryLevel();
    });
  }

  void _initConnectivity() {
    _checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _measurePing();
    });
    _measurePing();
  }

  @override
  void dispose() {
    _batteryStateSubscription.cancel();
    _connectivitySubscription.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
      _showBatteryWarning = level <= _lowBatteryThreshold && _batteryState != BatteryState.charging;
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    String type = 'Offline';
    bool online = false;
    
    if (results.contains(ConnectivityResult.wifi)) {
      type = 'WiFi';
      online = true;
    } else if (results.contains(ConnectivityResult.mobile)) {
      type = 'Mobile';
      online = true;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      type = 'Ethernet';
      online = true;
    }
    
    setState(() {
      _connectionType = type;
      _isOnline = online;
      if (!online) {
        _showPingWarning = true;
      }
    });
    
    if (online) {
      _measurePing();
    } else {
      setState(() {
        _pingMs = -1;
      });
    }
  }

  Future<void> _measurePing() async {
    if (!_isOnline) return;
    
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 3));
      stopwatch.stop();
      socket.destroy();
      
      setState(() {
        _pingMs = stopwatch.elapsedMilliseconds;
        _showPingWarning = _pingMs > _highPingThreshold || _pingMs < 0;
      });
    } catch (e) {
      setState(() {
        _pingMs = -1;
        _showPingWarning = true;
      });
    }
  }

  Color _getBatteryColor() {
    if (_batteryState == BatteryState.charging) return _accentColor;
    if (_batteryLevel <= 20) return Colors.red;
    if (_batteryLevel <= 50) return Colors.orange;
    return _accentColor;
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging) return Icons.battery_charging_full;
    if (_batteryLevel <= 20) return Icons.battery_1_bar;
    if (_batteryLevel <= 40) return Icons.battery_2_bar;
    if (_batteryLevel <= 60) return Icons.battery_4_bar;
    if (_batteryLevel <= 80) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  Color _getPingColor() {
    if (!_isOnline || _pingMs < 0) return Colors.red;
    if (_pingMs <= 50) return _accentColor;
    if (_pingMs <= 150) return Colors.orange;
    return Colors.red;
  }

  IconData _getNetworkIcon() {
    if (!_isOnline) return Icons.wifi_off;
    if (_connectionType == 'WiFi') return Icons.wifi;
    if (_connectionType == 'Mobile') return Icons.signal_cellular_alt;
    return Icons.lan;
  }

  Future<void> _showExitDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Keluar Ujian',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Masukkan PIN',
              hintStyle: GoogleFonts.openSans(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            style: GoogleFonts.openSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == '1234') {
                  AppControl.exitApp();
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PIN salah!', style: GoogleFonts.openSans()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Keluar',
                style: GoogleFonts.openSans(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            // WebView - Full screen
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
            
            // Warning Banners (above bottom bar)
            if (_showBatteryWarning)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange[700],
                child: Row(
                  children: [
                    const Icon(Icons.battery_alert, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Baterai rendah ($_batteryLevel%)! Segera hubungkan charger.',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showBatteryWarning = false),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            if (_showPingWarning)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red[700],
                child: Row(
                  children: [
                    const Icon(Icons.signal_wifi_bad, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isOnline 
                          ? 'Koneksi lambat (${_pingMs}ms)! Periksa jaringan.'
                          : 'Tidak ada koneksi internet!',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showPingWarning = false),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            
            // Bottom Status Bar
            Container(
              padding: EdgeInsets.only(
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: _primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Exit button
                  GestureDetector(
                    onTap: _showExitDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.exit_to_app, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Keluar',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right: Status indicators
                  Row(
                    children: [
                      // Battery
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getBatteryIcon(), color: _getBatteryColor(), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$_batteryLevel%',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getBatteryColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Network
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getNetworkIcon(), color: _getPingColor(), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _isOnline ? '${_pingMs}ms' : 'Offline',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getPingColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
