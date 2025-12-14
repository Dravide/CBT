import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cbt_app/qr_scanner.dart';
import 'package:cbt_app/app_control.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';

class AssessmentMenuPage extends StatefulWidget {
  const AssessmentMenuPage({super.key});

  @override
  State<AssessmentMenuPage> createState() => _AssessmentMenuPageState();
}

class _AssessmentMenuPageState extends State<AssessmentMenuPage> {
  static const Color _primaryColor = Color.fromRGBO(18, 26, 28, 1);
  static const Color _greyColor = Color.fromRGBO(247, 247, 249, 1);
  static const Color _accentColor = Color.fromRGBO(76, 175, 80, 1);

  int _currentIndex = 1;
  
  // Battery
  final Battery _battery = Battery();
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  late StreamSubscription<BatteryState> _batteryStateSubscription;

  // Network
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  String _connectionType = 'Checking...';
  int _pingMs = -1;
  bool _isOnline = false;
  Timer? _pingTimer;

  // Sample exam schedule data
  final List<Map<String, String>> _examSchedule = [
    {'subject': 'Matematika', 'date': 'Senin, 16 Desember 2024', 'time': '08:00 - 10:00'},
    {'subject': 'Bahasa Indonesia', 'date': 'Selasa, 17 Desember 2024', 'time': '08:00 - 10:00'},
    {'subject': 'IPA', 'date': 'Rabu, 18 Desember 2024', 'time': '08:00 - 10:00'},
    {'subject': 'IPS', 'date': 'Kamis, 19 Desember 2024', 'time': '08:00 - 10:00'},
    {'subject': 'Bahasa Inggris', 'date': 'Jumat, 20 Desember 2024', 'time': '08:00 - 10:00'},
  ];

  @override
  void initState() {
    super.initState();
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
    // Ping every 5 seconds
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
      type = 'Mobile Data';
      online = true;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      type = 'Ethernet';
      online = true;
    }
    
    setState(() {
      _connectionType = type;
      _isOnline = online;
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
      });
    } catch (e) {
      setState(() {
        _pingMs = -1;
      });
    }
  }

  Color _getBatteryColor() {
    if (_batteryState == BatteryState.charging) {
      return _accentColor;
    }
    if (_batteryLevel <= 20) {
      return Colors.red;
    } else if (_batteryLevel <= 50) {
      return Colors.orange;
    }
    return _accentColor;
  }

  IconData _getBatteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full;
    }
    if (_batteryLevel <= 20) {
      return Icons.battery_1_bar;
    } else if (_batteryLevel <= 40) {
      return Icons.battery_2_bar;
    } else if (_batteryLevel <= 60) {
      return Icons.battery_4_bar;
    } else if (_batteryLevel <= 80) {
      return Icons.battery_5_bar;
    }
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
    if (_connectionType == 'Mobile Data') return Icons.signal_cellular_alt;
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
            'Keluar Aplikasi',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Masukkan PIN',
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
              filled: true,
              fillColor: _greyColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
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
                      content: Text('PIN salah!', style: GoogleFonts.plusJakartaSans()),
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
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showScheduleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Jadwal Ujian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _examSchedule.length,
                  itemBuilder: (context, index) {
                    final exam = _examSchedule[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _greyColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam['subject']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  exam['date']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  exam['time']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      _showExitDialog();
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );
    } else if (index == 2) {
      _showScheduleDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back button
      child: Scaffold(
        backgroundColor: _primaryColor,
        body: Column(
          children: [
            CustomPageHeader(
              title: 'SCIPSA CBT',
              showBackButton: false,
              actions: [
                // Battery Status
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getBatteryIcon(),
                        color: _getBatteryColor(),
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$_batteryLevel%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getBatteryColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Network Status
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getNetworkIcon(),
                        color: _getPingColor(),
                        size: 18,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _isOnline ? '${_pingMs}ms' : 'Offline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getPingColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentColor,
                              _accentColor.withAlpha(200),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        'Asesmen SMPN 1 Cipanas',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                      const SizedBox(height: 20),

                      // Status Cards Row (Battery & Network)
                      Row(
                        children: [
                          // Battery Status Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getBatteryIcon(),
                                        color: _getBatteryColor(),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Baterai',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '$_batteryLevel%',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: _getBatteryColor(),
                                        ),
                                      ),
                                      if (_batteryState == BatteryState.charging)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Icon(
                                            Icons.bolt,
                                            color: _accentColor,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Network Status Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getNetworkIcon(),
                                        color: _getPingColor(),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _connectionType,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _isOnline ? '${_pingMs}ms' : 'Offline',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: _getPingColor(),
                                        ),
                                      ),
                                      if (_isOnline && _pingMs > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _getPingColor(),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info Section
                      Text(
                        'Informasi Pelaksanaan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        title: 'Periode Pelaksanaan',
                        subtitle: '16 - 20 Desember 2024',
                      ),
                      _buildInfoCard(
                        icon: Icons.access_time,
                        title: 'Waktu Pengerjaan',
                        subtitle: '120 menit per sesi',
                      ),
                      _buildInfoCard(
                        icon: Icons.assignment,
                        title: 'Jumlah Mata Pelajaran',
                        subtitle: '5 Mapel',
                      ),
                      _buildInfoCard(
                        icon: Icons.info_outline,
                        title: 'Petunjuk',
                        subtitle: 'Scan QR Code untuk memulai ujian',
                      ),

                      const SizedBox(height: 24),

                      // Instructions Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _greyColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Perhatian',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Pastikan baterai perangkat terisi penuh\n'
                              '• Pastikan koneksi internet stabil\n'
                              '• Jangan keluar dari aplikasi saat ujian berlangsung\n'
                              '• Hubungi pengawas jika ada kendala teknis',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              backgroundColor: Colors.white,
              selectedItemColor: _primaryColor,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.exit_to_app),
                  label: 'Keluar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner, size: 28),
                  label: 'Scan QR',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Jadwal',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
