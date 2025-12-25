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
import 'package:cbt_app/pages/profile_page.dart';
import 'package:cbt_app/pages/agenda_page.dart'; 
import 'package:cbt_app/pages/jadwal_page.dart'; // Import Jadwal Page
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
import 'package:cbt_app/widgets/wellbeing_card.dart'; // Import Model
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _hasUnreadAnnouncements = false;
  PengumumanService _pengumumanService = PengumumanService();
  String? _userName;
  Pengumuman? _latestPengumuman;
  bool _showWellbeing = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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

  Future<void> _checkUnreadAnnouncements() async {
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
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showWellbeing = prefs.getBool('is_wellbeing_enabled') ?? false;
      });
    }
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
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastLinearToSlowEaseIn,
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
                  _pageController.animateToPage(
                    visualIndex,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastLinearToSlowEaseIn,
                  );
                  
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
        _buildAboutPage(),     // Visual 3 -> Logic 2
        _buildProfilePage(),   // Visual 4 -> Logic 3
      ],
    );
  }

  // Wrapper widgets to handle key/padding
  Widget _buildInfoPage() => InfoPage(onBack: () => _goToHome());
  
  Widget _buildAgendaPage() => JadwalPage(onBack: () => _goToHome()); // Switch to JadwalPage

  Widget _buildAboutPage() => AboutPage(onBack: () => _goToHome());

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
                      _latestPengumuman!.isi,
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
            _buildBannerCard(),
            const SizedBox(height: 24),
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








  Widget _buildFeatureCarousel() {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        padEnds: false, // Start from left
        children: [
          // Digital Wellbeing Card (New)
          if (_showWellbeing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(width: 250, child: const WellbeingCard()),
            ),

          // Card 1: Assesmen (Existing Logic)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSquareCard(
              title: 'Assesmen\n/ Ujian',
              subtitle: 'Masuk Mode Ujian',
              color1: const Color(0xFF1565C0),
              color2: const Color(0xFF42A5F5),
              icon: Icons.assignment,
              onTap: () async {
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
                // Note: Getting position might take a moment, showing loading indicator is better UX 
                // but for now we block with await (UI might freeze slightly)
                // Consider adding a simple loading dialog if needed.
                
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
              },
            ),
          ),
          
          // Card 2: Info Sekolah
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSquareCard(
              title: 'Info\nSekolah',
              subtitle: 'Pengumuman & Update',
              color1: const Color(0xFFEF6C00), // Orange
              color2: const Color(0xFFFFA726),
              icon: Icons.campaign,
              onTap: () {
                 // Navigate to Info Page (Index 1)
                 setState(() => _currentIndex = 1);
                 _pageController.animateToPage(_logicToVisual(1), duration: const Duration(milliseconds: 600), curve: Curves.fastLinearToSlowEaseIn);
              },
            ),
          ),

          // Card 3: Jadwal Pelajaran (Formerly Agenda)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSquareCard(
              title: 'Jadwal\nPelajaran',
              subtitle: 'Senin - Sabtu',
              color1: const Color(0xFF7B1FA2), // Purple
              color2: const Color(0xFFBA68C8),
              icon: Icons.calendar_month,
              onTap: () {
                setState(() => _currentIndex = 4); // Switch to Jadwal Page
                 _pageController.animateToPage(_logicToVisual(4), duration: const Duration(milliseconds: 600), curve: Curves.fastLinearToSlowEaseIn);
              },
            ),
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

  Widget _buildBannerCard() {
    return GestureDetector(
      onTap: () => _showComingSoon('Absensi'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF7E57C2), Color(0xFFB39DDB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withAlpha(80),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absensi',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cek kehadiran siswa',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Masuk',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF7E57C2),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  final String formattedDate = date != null ? DateFormat('dd MMM').format(date) : '';
                  
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
        _buildGridFeatureCard('Jadwal', Icons.schedule, Colors.purple, onTap: () {
          showTopSnackBar(context, 'Fitur Jadwal akan segera hadir!');
        }),
        _buildGridFeatureCard('Galeri', Icons.photo_library, Colors.teal, onTap: () {
           showTopSnackBar(context, 'Fitur Galeri akan segera hadir!');
        }),
      ],
    );
  }

  // New method for Grid items (larger/different style than small horizontal cards)
  Widget _buildGridFeatureCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _showComingSoon(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12), // Reduced from 16
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28), // Reduced from 32
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
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
}
