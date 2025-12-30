import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/assessment_menu.dart';
import 'package:cbt_app/app_control.dart';
import 'package:cbt_app/news_detail_page.dart';
import 'package:cbt_app/pages/guru_list_page.dart';
import 'package:cbt_app/pages/siswa_list_page.dart';
import 'package:cbt_app/pages/pelanggaran_form_page.dart';
import 'package:cbt_app/pages/pelanggaran_form_page.dart';
import 'package:cbt_app/pages/tugas_online_page.dart';
import 'package:cbt_app/pages/about_page.dart';
import 'package:cbt_app/pages/info_page.dart';
import 'package:cbt_app/pages/curhat_page.dart';
import 'package:cbt_app/pages/profile_page.dart';
import 'package:cbt_app/pages/agenda_page.dart'; 
import 'package:cbt_app/pages/jadwal_page.dart';
import 'package:cbt_app/pages/social_page.dart'; 
import 'package:cbt_app/pages/settings_page.dart';
import 'package:cbt_app/pages/denah_page.dart';
import 'package:cbt_app/pages/presensi_page.dart';
import 'package:cbt_app/widgets/top_snack_bar.dart';  
import 'package:cbt_app/widgets/modern_bottom_nav.dart'; // New Nav
import 'package:cbt_app/widgets/skeleton_loading.dart'; // Skeleton Loading
import 'package:cbt_app/qr_scanner.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/services/pengumuman_service.dart';
import 'package:cbt_app/services/local_notification_service.dart';
import 'package:cbt_app/services/jadwal_service.dart';
import 'package:cbt_app/services/update_service.dart'; // In-App Update
import 'package:cbt_app/services/device_service.dart'; // Device Binding
import 'package:cbt_app/models/jadwal_model.dart';
import 'package:cbt_app/models/pengumuman.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Static variable to persist carousel state across re-builds
  static double _lastDeckPage = 0.0;
  
  int _currentIndex = 0;
  bool _hasUnreadAnnouncements = false;
  PengumumanService _pengumumanService = PengumumanService();
  String? _userName;
  String? _userRole;
  Jadwal? _currentTeachingJadwal;
  final JadwalService _jadwalService = JadwalService();
  final DeviceService _deviceService = DeviceService();
  Pengumuman? _latestPengumuman;
  late PageController _pageController;
  late PageController _carouselController;
  late double _deckPage;

  // Deck Animation
  late AnimationController _deckAnimController;
  late Animation<double> _deckAnimation;

  @override
  void initState() {
    super.initState();
    // Restore last position
    _deckPage = _lastDeckPage;
    
    _pageController = PageController(initialPage: 0);
    _carouselController = PageController(
      viewportFraction: 0.92, 
      initialPage: _deckPage.round(), // Restore page index
    );

    
    // Check for app updates from Play Store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdate(context);
      // Check device registration after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        _checkDeviceRegistration();
      });
    });
    
    // Initialize Animation Controller (optimized - no setState in listener)
    _deckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Note: Using AnimatedBuilder in widget tree instead of setState here


    
    // Listen to notification clicks
    LocalNotificationService().onNotificationClick.listen((payload) {
      if (payload != null && payload.startsWith('pengumuman:')) {
        // Navigate to Info (Announcement) Tab
        // Info Tab is index 1
        if (mounted) {
          // Pop any dialogs or routes if not at root
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          setState(() {
            _currentIndex = 1;
          });
          _pageController.animateToPage(
            _logicToVisual(1), 
            duration: const Duration(milliseconds: 600), 
            curve: Curves.fastLinearToSlowEaseIn
          );
          _markAnnouncementsAsRead();
        }
      }
    });

    _loadUserName();
    _loadSettings();
    _checkUnreadAnnouncements();
    // Poll every 2 minutes (optimized from 10 seconds for battery saving)
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _checkUnreadAnnouncements();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _teachingStatusTimer?.cancel();
    _pageController.dispose();
    _carouselController.dispose(); // Dispose here
    _deckAnimController.dispose();
    super.dispose();
  }

  /// Check if device needs to be registered
  Future<void> _checkDeviceRegistration() async {
    if (!mounted) return;
    
    try {
      // Check if already registered locally (skip API call)
      final isRegistered = await _deviceService.isDeviceRegisteredLocally();
      if (isRegistered) return;
      
      // Get user info
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final userRole = prefs.getString('user_role');
      
      if (userId == null || userRole == null) return;
      
      // Check status from server
      final status = await _deviceService.checkDeviceStatus(userId, userRole);
      
      if (status == 'not_registered' && mounted) {
        // Show registration dialog
        _showDeviceRegistrationDialog(userId, userRole);
      } else if (status == 'mismatch' && mounted) {
        // Show mismatch warning
        _showDeviceMismatchDialog();
      }
      // If 'registered' or 'error', do nothing
    } catch (e) {
      debugPrint('Device registration check error: $e');
    }
  }

  /// Show dialog to register device
  void _showDeviceRegistrationDialog(int userId, String userRole) async {
    final deviceInfo = await _deviceService.getDeviceInfo();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.phone_android, color: Colors.blue[700], size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Daftarkan Perangkat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk keamanan, aplikasi ini hanya bisa digunakan di satu perangkat.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📱 ${deviceInfo['brand']} ${deviceInfo['model']}', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${deviceInfo['version']}', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Setelah didaftarkan, Anda tidak bisa login dari perangkat lain.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Nanti Saja', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _registerDevice(userId, userRole);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Daftarkan Sekarang'),
          ),
        ],
      ),
    );
  }

  /// Register device with server
  Future<void> _registerDevice(int userId, String userRole) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    final result = await _deviceService.registerDevice(userId, userRole);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading
    
    if (result['success'] == true) {
      showTopSnackBar(context, '✅ ${result['message']}', backgroundColor: Colors.green);
    } else if (result['mismatch'] == true) {
      _showDeviceMismatchDialog();
    } else {
      showTopSnackBar(context, '❌ ${result['message']}', backgroundColor: Colors.red);
    }
  }

  /// Show device mismatch error dialog
  void _showDeviceMismatchDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Perangkat Berbeda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Akun ini sudah terdaftar di perangkat lain.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hubungi Admin/Operator sekolah untuk reset perangkat.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _checkUnreadAnnouncements() async {
    try {
      final response = await _pengumumanService.getPengumuman(page: 1, perPage: 1);
      if (response.data.isNotEmpty) {
        final latest = response.data.first;
        
        // Update state for UI
        if (_latestPengumuman?.id != latest.id) {
           setState(() {
            _latestPengumuman = latest;
          });
        }

        final latestId = latest.id;
        final prefs = await SharedPreferences.getInstance();
        final lastReadId = prefs.getInt('last_read_announcement_id') ?? 0;
        
        if (latestId > lastReadId) {
          if (!_hasUnreadAnnouncements) {
             // Only update if state changes to avoid unnecessary rebuilds
             setState(() {
              _hasUnreadAnnouncements = true;
            });
            
            // Show snackbar as a "notification" since we removed FCM
            // Check if we should show it (e.g. only if not already shown for this ID)
            final lastNotifiedId = prefs.getInt('last_notified_announcement_id') ?? 0;
            if (latestId > lastNotifiedId) {
               await prefs.setInt('last_notified_announcement_id', latestId);
               
               // Show Local Notification
               LocalNotificationService().showPengumumanNotification(
                 title: 'Pengumuman Baru',
                 body: latest.judul,
                 pengumumanId: latest.id,
               );


            }
          }
        }
      }
    } catch (e) {
      print('Error checking announcements: $e');
    }
  }

  // Teaching Status Timer
  Timer? _teachingStatusTimer;
  List<Jadwal> _cachedJadwalList = [];

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Siswa';
      _userRole = prefs.getString('user_role');
    });

    if (_userRole == 'guru') {
      // Check immediately
      _checkCurrentTeachingStatus(forceRefresh: true);
      
      // Start polling every 5 minutes (optimized from 30 seconds)
      _teachingStatusTimer?.cancel();
      _teachingStatusTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (mounted) {
          _checkCurrentTeachingStatus(forceRefresh: false);
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    // Other settings if any
  }

  Future<void> _markAnnouncementsAsRead() async {
    try {
      final response = await _pengumumanService.getPengumuman(page: 1, perPage: 1);
      if (response.data.isNotEmpty) {
        final latestId = response.data.first.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_read_announcement_id', latestId);
        setState(() {
          _hasUnreadAnnouncements = false;
        });
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _checkCurrentTeachingStatus({bool forceRefresh = false}) async {
    try {
      List<Jadwal> jadwalList;
      
      // Use cache if available and not forced
      if (!forceRefresh && _cachedJadwalList.isNotEmpty) {
        jadwalList = _cachedJadwalList;
      } else {
        jadwalList = await _jadwalService.getJadwal();
        if (mounted) {
          _cachedJadwalList = jadwalList;
        }
      }

      final now = DateTime.now();
      
      // Indonesian Date Format for Day
      final dayFormatter = DateFormat('EEEE', 'id_ID');
      final currentDay = dayFormatter.format(now);
      
      // Filter for today
      final todayJadwal = jadwalList.where((j) => j.hari.toLowerCase() == currentDay.toLowerCase()).toList();

      if (todayJadwal.isNotEmpty) {
        final currentTime = DateFormat('HH:mm').format(now);
        final currentHour = int.parse(currentTime.split(':')[0]);
        final currentMinute = int.parse(currentTime.split(':')[1]);

        Jadwal? activeJadwal;

        for (var jadwal in todayJadwal) {
          try {
            // Parse schedule times directly from jamMulai and jamSelesai (Format "07:00:00" or "07:00")
            final startParts = jadwal.jamMulai.trim().split(':'); 
            final endParts = jadwal.jamSelesai.trim().split(':');

            if (startParts.isNotEmpty && endParts.isNotEmpty) {
               // Handle HH:MM:SS or HH:MM
               final startH = int.parse(startParts[0]);
               final startM = int.parse(startParts.length > 1 ? startParts[1] : '00');
               
               final endH = int.parse(endParts[0]);
               final endM = int.parse(endParts.length > 1 ? endParts[1] : '00');

               // Time comparison
               final startMinutes = startH * 60 + startM;
               final endMinutes = endH * 60 + endM;
               final currentMinutes = currentHour * 60 + currentMinute;

               if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
                 activeJadwal = jadwal;
                 break; 
               }
            }
          } catch (e) {
            print("Error parsing time for jadwal: ${jadwal.jamMulai} - ${jadwal.jamSelesai}");
          }
        }

        if (mounted) {
          // Only rebuild if there's a change
          if (_currentTeachingJadwal?.id != activeJadwal?.id) {
            setState(() {
              _currentTeachingJadwal = activeJadwal;
            });
          }
        }
      } else {
        if (mounted && _currentTeachingJadwal != null) {
           setState(() {
            _currentTeachingJadwal = null;
          });
        }
      }
    } catch (e) {
      print('Error checking teaching status: $e');
    }
  }

  // Mappings for BottomNav (Visual Order: Home, Info, Agenda, Tentang, Profil)
  // Logic Indices: Home=0, Info=1, About=2, Profile=3, Agenda=4
  
  int _logicToVisual(int logicIndex) {
    switch (logicIndex) {
      case 0: return 0; // Home
      case 1: return 1; // Info
      case 4: return 2; // Agenda
      case 2: return 3; // Tentang
      case 3: return 4; // Profil
      default: return 0;
    }
  }

  int _visualToLogic(int visualIndex) {
    switch (visualIndex) {
      case 0: return 0; // Home
      case 1: return 1; // Info
      case 2: return 4; // Agenda
      case 3: return 2; // Tentang
      case 4: return 3; // Profil
      default: return 0;
    }
  }

  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_currentIndex != 0) {
          // If not home, go to home
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
          setState(() {
            _currentIndex = 0;
          });
          _loadSettings();
          return;
        }

        // If at home, just exit
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildBody(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ModernBottomNav(
                currentIndex: _currentIndex,
                hasUnreadInfo: _hasUnreadAnnouncements,
                onTap: (index) {
                  final visualIndex = _logicToVisual(index);
                  _pageController.jumpToPage(visualIndex); // Instant jump
                  
                  setState(() {
                    _currentIndex = index;
                  });
                  
                  if (index == 0) {
                     _loadSettings(); // Refresh settings when going back to home
                  }
                  if (index == 1) { 
                    _markAnnouncementsAsRead();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (visualIndex) {
        final logicIndex = _visualToLogic(visualIndex);
        setState(() {
          _currentIndex = logicIndex;
        });
        
        if (logicIndex == 0) _loadSettings();
        if (logicIndex == 1) _markAnnouncementsAsRead();
      },
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHomeContent(),   // Visual 0 -> Logic 0
        _buildInfoPage(),      // Visual 1 -> Logic 1
        _buildAgendaPage(),    // Visual 2 -> Logic 4
        SocialPage(onBack: () => _goToHome()), // Visual 3 -> Logic 2
        _buildProfilePage(),   // Visual 4 -> Logic 3
      ],
    );
  }

  // Wrapper widgets to handle key/padding
  Widget _buildInfoPage() => InfoPage(onBack: () => _goToHome());
  
  Widget _buildAgendaPage() => JadwalPage(onBack: () => _goToHome()); 

  // Widget _buildAboutPage() => AboutPage(onBack: () => _goToHome()); // Removed


  Widget _buildProfilePage() => ProfilePage(onBack: () => _goToHome());

  void _goToHome() {
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentIndex = 0);
  }

  Widget _buildHomeContent() {
      final statusBarHeight = MediaQuery.of(context).padding.top;
      return SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: statusBarHeight + 16, bottom: 120), // Added status bar padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            // Welcome Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName ?? 'Siswa',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Siap untuk belajar hari ini?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Teaching Status (For Teachers Only)
            if (_userRole == 'guru' && _currentTeachingJadwal != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sedang Mengajar Sekarang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelas ${_currentTeachingJadwal!.kelas}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _currentTeachingJadwal!.mataPelajaran,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Aktif',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Latest Info Card
            if (_latestPengumuman != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF0D47A1), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Info Terakhir',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _latestPengumuman!.tanggal,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _latestPengumuman!.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _removeHtmlTags(_latestPengumuman!.isi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                     const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                         setState(() {
                          _currentIndex = 1; // Go to Info
                        });
                        _pageController.animateToPage(_logicToVisual(1), duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        _markAnnouncementsAsRead();
                      },
                      child: Row(
                        children: [
                          Text(
                            'Selengkapnya',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF0D47A1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D47A1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_latestPengumuman != null) const SizedBox(height: 24),
            
            _buildFeatureCarousel(),
            const SizedBox(height: 24),
            _buildGridCards(),
            const SizedBox(height: 24),
            // Banner card removed
            _buildNewsSection(),
            const SizedBox(height: 24),
            Text(
              'Fitur Lainnya', 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildOtherFeaturesRow(),
          ],
        ),
      );
  }



  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/logosmpn1cipanas.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }



  // Deck Stack State
  // double _deckPage = 0.0; // Moved to class level

  Widget _buildFeatureCarousel() {
    // Card Data
    final List<Map<String, dynamic>> featureCards = [
      {
        'title': 'Assesmen\n/ Ujian',
        'subtitle': 'Masuk Mode Ujian',
        'icon': Icons.assignment,
        'color1': const Color(0xFF1565C0),
        'color2': const Color(0xFF42A5F5),
        'onTap': _onAssesmenTap,
      },
      {
        'title': 'Absensi\nKehadiran',
        'subtitle': 'Cek Kehadiran',
        'icon': Icons.access_time_filled,
        'color1': const Color(0xFF7E57C2),
        'color2': const Color(0xFFB39DDB),
        'onTap': _handleAbsensiTap,
      },
      {
        'title': 'Denah\nSekolah',
        'subtitle': 'Cek Status Kelas',
        'icon': Icons.map_outlined,
        'color1': const Color(0xFF2E7D32),
        'color2': const Color(0xFF66BB6A),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DenahPage())),
      },
      {
        'title': 'Tugas\nOnline',
        'subtitle': 'Lihat Tugas',
        'icon': Icons.book_outlined,
        'color1': const Color(0xFF00897B),
        'color2': const Color(0xFF4DB6AC),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TugasOnlinePage())),
      },
      {
        'title': 'Jadwal\nPelajaran',
        'subtitle': 'Lihat Jadwal',
        'icon': Icons.calendar_today,
        'color1': const Color(0xFFE65100),
        'color2': const Color(0xFFFF9800),
        'onTap': () {
          setState(() => _currentIndex = 4);
          _pageController.animateToPage(_logicToVisual(4), duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      },
      {
        'title': 'Social\nSchool',
        'subtitle': 'Lihat Timeline',
        'icon': Icons.people_outline,
        'color1': const Color(0xFFD81B60),
        'color2': const Color(0xFFF48FB1),
        'onTap': () {
          setState(() => _currentIndex = 2);
          _pageController.animateToPage(_logicToVisual(2), duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            key: const PageStorageKey('featureCarousel'), // Persist scroll position
            itemCount: featureCards.length,
            controller: _carouselController, // Use persisted controller
            onPageChanged: (index) {
              setState(() {
                _deckPage = index.toDouble();
                _lastDeckPage = _deckPage; // Save to static variable
              });
            },
            itemBuilder: (context, index) {
              // Morphing effect: inactive = more rounded, active = less rounded
              final isActive = (_deckPage - index).abs() < 0.5;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  // Morph: full circle → rectangle
                  borderRadius: BorderRadius.circular(isActive ? 20 : 100),
                  gradient: LinearGradient(
                    colors: [featureCards[index]['color1'], featureCards[index]['color2']],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ] : null,
                ),
                child: GestureDetector(
                  onTap: featureCards[index]['onTap'],
                  behavior: HitTestBehavior.opaque, // Catch clicks on empty space
                  child: Stack(
                    fit: StackFit.expand, // Fill the entire container
                    children: [
                      // ICON - Animated Position
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        alignment: isActive ? Alignment.topLeft : Alignment.center,
                        child: Padding(
                           // Add padding only when active (top left), centering needs offset adjustment if padding used
                          padding: isActive ? const EdgeInsets.all(24) : const EdgeInsets.only(bottom: 50), 
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(featureCards[index]['icon'], color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                      
                      // TEXT - Animated Position
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        alignment: isActive ? Alignment.bottomLeft : Alignment.center,
                        child: Padding(
                          padding: isActive ? const EdgeInsets.all(24) : const EdgeInsets.only(top: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: isActive ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                            children: [
                              Text(
                                featureCards[index]['title'],
                                textAlign: isActive ? TextAlign.left : TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: isActive ? 1.0 : 0.0, // Hide subtitle when inactive for cleaner look? Or keep it? Let's hide it for cleaner circle
                                child: Text(
                                  featureCards[index]['subtitle'],
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(featureCards.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _deckPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _deckPage == index 
                  ? const Color(0xFF0D47A1) 
                  : Colors.grey[300],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDeckCardItem(int index, Map<String, dynamic> card) {
    double delta = index - _deckPage;
    
    // PAPER FOLD EFFECT - Cards stack vertically like papers on desk
    double scale = 1.0;
    double offsetY = 0.0;  // Vertical offset for stacking
    double opacity = 1.0;

    if (delta <= 0) {
      // Active card or passed cards - slide up and fade
      offsetY = delta * 50;
      opacity = (1 + delta).clamp(0.0, 1.0);
      scale = 1.0;
    } else {
      // Cards behind (stacked papers effect)
      // Each card slightly lower and smaller
      offsetY = delta * 8;  // Stack downward
      scale = 1.0 - (delta * 0.05);
      scale = scale.clamp(0.85, 1.0);
      opacity = 1.0 - (delta * 0.25);
      opacity = opacity.clamp(0.0, 1.0);
    }

    // Only top card is interactive
    bool isInteractive = (delta.abs() < 0.5);

    return Positioned(
      top: 10,
      bottom: 20,
      width: MediaQuery.of(context).size.width * 0.85,
      child: RepaintBoundary(
        child: Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: isInteractive ? card['onTap'] : null,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [card['color1'], card['color2']],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(card['icon'], color: Colors.white, size: 36),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card['title'],
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card['subtitle'],
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Updated Stack Card for larger display
  Widget _buildStackCard({ // DEPRECATED: Kept to avoid build error during partial replacement if called elsewhere? No, internal.
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
      return const SizedBox.shrink(); // Placeholder
  }

  // Extracted Assesmen tap handler
  Future<void> _onAssesmenTap() async {
    // Check Location first
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showTopSnackBar(
        context, 
        'Layanan lokasi tidak aktif. Mohon aktifkan GPS.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         showTopSnackBar(
            context, 
            'Izin lokasi ditolak. Fitur ini butuh lokasi.',
            backgroundColor: Colors.red,
         );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
       showTopSnackBar(
          context, 
          'Izin lokasi ditolak permanen. Buka pengaturan.',
          backgroundColor: Colors.red,
       );
      return;
    } 

    // Get current position
    showTopSnackBar(context, 'Memeriksa lokasi...');

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Target: -6.728365064640593, 107.03669246915685
    const double targetLat = -6.728365064640593;
    const double targetLong = 107.03669246915685;
    
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLong,
    );

    if (distanceInMeters > 100) {
       showTopSnackBar(
          context, 
          'Anda berada di luar radius ujian (${distanceInMeters.toStringAsFixed(0)}m).',
          backgroundColor: Colors.red,
       );
       return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Masuk Mode Ujian', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Aplikasi akan terkunci dan Anda tidak dapat membuka aplikasi lain selama ujian. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await AppControl.startLockTask(); // Lock screen
              await AppControl.setSecure(true); // Disable screenshot
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessmentMenuPage()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: Text('Lanjut', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCards() {
      return const SizedBox.shrink();
  }

  Widget _buildSquareCard({
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color1.withAlpha(60),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Future<List<dynamic>> _fetchPosts() async {
    try {
      final response = await http.get(
        Uri.parse('https://smpn1cipanas.sch.id/wp-json/wp/v2/posts?per_page=5&_embed'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Berita Terbaru',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<dynamic>>(
            future: _fetchPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Return Skeleton List
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoading(width: double.infinity, height: 140, borderRadius: 16),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SkeletonLoading(width: 200, height: 20),
                                SizedBox(height: 8),
                                SkeletonLoading(width: 150, height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Tidak ada berita.', style: GoogleFonts.plusJakartaSans(color: Colors.grey));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final post = snapshot.data![index];
                  final String title = post['title']['rendered'] ?? 'No Title';
                  final String dateStr = post['date'] ?? '';
                  DateTime? date = DateTime.tryParse(dateStr);
                  final String formattedDate = date != null ? DateFormat('dd MMM', 'id_ID').format(date) : '';
                  
                  String? imageUrl;
                  try {
                    if (post['_embedded'] != null && 
                        post['_embedded']['wp:featuredmedia'] != null && 
                        post['_embedded']['wp:featuredmedia'].isNotEmpty) {
                      imageUrl = post['_embedded']['wp:featuredmedia'][0]['source_url'];
                    }
                  } catch (e) {
                    // Ignore
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(post: post),
                        ),
                      );
                    },
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: imageUrl != null
                                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: imageUrl == null
                                ? Center(child: Icon(Icons.image, color: Colors.grey[400], size: 40))
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 10, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.grey[500],
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
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildOtherFeaturesRow() {
    return GridView.count(
      crossAxisCount: 3, // Changed to 3 columns
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9, // Taller Aspect Ratio for 3 columns
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildGridFeatureCard('Lapor', Icons.warning_amber_rounded, Colors.red[700]!, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PelanggaranFormPage()),
          );
        }),
        _buildGridFeatureCard('Guru', Icons.people, Colors.teal, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GuruListPage()),
          );
        }),
        _buildGridFeatureCard('Siswa', Icons.school, Colors.indigo, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SiswaListPage()),
          );
        }),
        _buildGridFeatureCard('Cek Tugas', Icons.assignment, Colors.blueAccent, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TugasOnlinePage()),
          );
        }),
        _buildGridFeatureCard('Curhat', Icons.chat_bubble_outline, Colors.pink, onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CurhatPage()),
          );
        }),
        _buildGridFeatureCard('Galeri', Icons.photo_library, Colors.teal, onTap: () {
           showTopSnackBar(context, 'Fitur Galeri akan segera hadir!');
        }),
      ],
    );
  }

  Future<void> _handleAbsensiTap() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'siswa' if not set
    final String role = prefs.getString('user_role') ?? 'siswa';
    
    if (!mounted) return;

    if (role == 'guru') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PresensiPage()));
    } else {
      // Show message for non-teachers
      showTopSnackBar(context, 'Fitur Absensi belum tersedia untuk siswa');
    }
  }

  // New method for Grid items (larger/different style than small horizontal cards)
  Widget _buildGridFeatureCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _showComingSoon(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Larger rounded corners
          border: Border.all(color: Colors.grey.shade100, width: 1), // Subtle border
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05), // Ultra soft shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Soft pastel background
                borderRadius: BorderRadius.circular(14), // Squircle shape
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF374151), // Grey 700
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showTopSnackBar(context, 'Fitur $feature belum tersedia');
  }

  String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }
}
