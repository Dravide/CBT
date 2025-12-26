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
import 'package:cbt_app/pages/social_page.dart'; // Import Social Page
import 'package:cbt_app/pages/settings_page.dart';
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
import 'package:cbt_app/models/pengumuman.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _hasUnreadAnnouncements = false;
  PengumumanService _pengumumanService = PengumumanService();
  String? _userName;
  Pengumuman? _latestPengumuman;
  late PageController _pageController;

  // Deck Animation
  late AnimationController _deckAnimController;
  late Animation<double> _deckAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Initialize Animation Controller
    _deckAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _deckAnimController.addListener(() {
      setState(() {
        _deckPage = _deckAnimation.value;
      });
    });

    _loadUserName();
    _loadSettings();
    _checkUnreadAnnouncements();
    // Poll every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkUnreadAnnouncements();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _deckAnimController.dispose();
    super.dispose();
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
               showTopSnackBar(
                 context, 
                 'Pengumuman Baru: ${latest.judul}',
                 backgroundColor: Colors.red,
                 actionLabel: 'Lihat',
                 onActionPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                    _pageController.animateToPage(_logicToVisual(1), duration: const Duration(milliseconds: 600), curve: Curves.fastLinearToSlowEaseIn);
                    _markAnnouncementsAsRead();
                 },
               );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking announcements: $e');
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Siswa';
    });
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
      return SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120), // Added bottom padding
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
  double _deckPage = 0.0;

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

    return SizedBox(
      height: 260, // Height for the stack
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _deckAnimController.stop(); // Stop any running animation
        },
        onHorizontalDragUpdate: (details) {
          // Adjust sensitivity to match screen width better. 
          // Width * 0.85 is card width. 
          // 350 seems like a good "weight" for the swipe.
          setState(() {
            _deckPage -= details.primaryDelta! / 350; 
            // Allow rubber banding or clamp? Clamp for now
            if (_deckPage < 0) _deckPage = 0;
            if (_deckPage > featureCards.length - 1) _deckPage = (featureCards.length - 1).toDouble();
          });
        },
        onHorizontalDragEnd: (details) {
          // Snap to nearest page
          int targetPage = _deckPage.round();
          
          // Velocity check for flick
          if (details.primaryVelocity! < -500) { // Higher threshold for flick
            targetPage = _deckPage.floor() + 1; // Swipe Left -> Next
          } else if (details.primaryVelocity! > 500) {
             targetPage = _deckPage.ceil() - 1; // Swipe Right -> Prev
          }
          
          targetPage = targetPage.clamp(0, featureCards.length - 1);
          
          // Animate Snap - Ultra Smooth
          _deckAnimation = Tween<double>(
            begin: _deckPage,
            end: targetPage.toDouble(),
          ).animate(CurvedAnimation(
            parent: _deckAnimController,
            curve: Curves.easeOutCubic, // Very smooth deceleration
          ));
          
          _deckAnimController.reset();
          _deckAnimController.forward();
        },
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(featureCards.length, (index) {
             // Stack Order: Last index is TOP. 
             // We want current active card (0) to be TOP.
             // So reversedIndex loop is correct.
             int reversedIndex = featureCards.length - 1 - index;
             return _buildDeckCardItem(reversedIndex, featureCards[reversedIndex]);
          }),
        ),
      ),
    );
  }

  Widget _buildDeckCardItem(int index, Map<String, dynamic> card) {
    double delta = index - _deckPage;
    
    // VISUAL LOGIC
    // delta 0: Active Card -> Scale 1.0, X=0, visible.
    // delta < 0 (Previous): Slide Left, fade out.
    // delta > 0 (Next): Slide Right slightly, Scale Down, Rotate slightly.
    
    double scale = 1.0;
    double offsetX = 0.0;
    double opacity = 1.0;
    double rotation = 0.0;

    if (delta == 0) {
      // Setup default
    } else if (delta < 0) {
      // Cards that have passed (Left side)
      // Slide completely off screen to left
      offsetX = delta * 500; 
      opacity = (1 + delta).clamp(0.0, 1.0); // Quick fade
      rotation = delta * 0.1;
    } else {
      // Cards coming up (Right side, Behind)
      // Stack effect: spacing 40px, scale down 0.05 per step
      offsetX = delta * 40; 
      scale = 1.0 - (delta * 0.1);
      if (scale < 0.0) scale = 0.0;
      
      // Slight vertical offset to show depth?
      // rotation = -delta * 0.05; // Slight tilt
      
      // Opacity: Fade out deep cards
      opacity = 1.0 - (delta * 0.2);
      if (opacity < 0.0) opacity = 0.0;
    }

    // Ignore touch on back cards (simple check)
    bool isInteractive = (delta.abs() < 0.5);

    return Positioned(
      // Centered Stack
      top: 10,
      bottom: 20,
      width: MediaQuery.of(context).size.width * 0.85, // Card Width fixed
      child: Transform(
        transform: Matrix4.identity()
          ..translate(offsetX)
          ..scale(scale)
          ..rotateZ(rotation),
        alignment: Alignment.center,
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
                    color: Colors.black.withOpacity(0.2), // Darker shadow for depth
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
                      // Text(
                      //   '#${index+1}', // Debug Index
                      //   style: TextStyle(color: Colors.white24, fontSize: 40, fontWeight: FontWeight.bold),
                      // )
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
