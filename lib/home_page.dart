import 'package:flutter/material.dart';
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
import 'package:cbt_app/pages/agenda_page.dart'; // Import Agenda Page
import 'package:cbt_app/qr_scanner.dart';
import 'package:cbt_app/models/prayer_schedule.dart'; // Import Model
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/services/pengumuman_service.dart';
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
  final PengumumanService _pengumumanService = PengumumanService();



  @override
  void initState() {
    super.initState();
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
        final latestId = response.data.first.id;
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
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengumuman Baru: ${response.data.first.judul}'),
                    action: SnackBarAction(
                      label: 'Lihat',
                      onPressed: () {
                         setState(() {
                           _currentIndex = 1;
                         });
                         _markAnnouncementsAsRead();
                      },
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
               );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking announcements: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      floatingActionButton: _buildScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // Slide from right
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      child: _getPageContent(),
    );
  }

  Widget _getPageContent() {
    // Key is required for AnimatedSwitcher to identify widget changes
    if (_currentIndex == 0) {
      return SingleChildScrollView(
        key: const ValueKey<int>(0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildPrayerCard(),
            const SizedBox(height: 24),
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
    } else if (_currentIndex == 1) {
      return SizedBox(
        key: const ValueKey<int>(1),
        child: InfoPage(
          onBack: () {
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
      );
    } else if (_currentIndex == 3) {
      return AboutPage(
        key: const ValueKey<int>(3),
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      );
    } else if (_currentIndex == 4) {
      return AgendaPage(
        key: const ValueKey<int>(4),
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      );
    }
    return Container(key: const ValueKey<int>(99));
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


  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Cari Menu...',
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
          icon: Icon(Icons.search, color: Colors.grey[500]),
        ),
      ),
    );
  }

  Future<PrayerSchedule?> _fetchPrayerSchedule() async {
    try {
      final response = await http.get(Uri.parse('https://api.myquran.com/v3/sholat/jadwal/006f52e9102a8d3be2fe5614f42ba989/today?tz=Asia%2FJakarta'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final jadwalMap = data['data']['jadwal'] as Map<String, dynamic>;
          if (jadwalMap.isNotEmpty) {
            // The API returns the schedule keyed by date (e.g. "2025-12-13")
            // Since we requested 'today', we just take the first value.
            return PrayerSchedule.fromJson(jadwalMap.values.first);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching prayer schedule: $e');
      return null;
    }
  }

  Widget _buildPrayerCard() {
    return FutureBuilder<PrayerSchedule?>(
      future: _fetchPrayerSchedule(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink(); // Hide if failed
        }

        final jadwal = snapshot.data!;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Sholat',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getIndonesianDate(), // Use custom formatter
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.mosque, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView( // Make horizontal scrollable if needed on small screens
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeItem('Subuh', jadwal.subuh),
                    const SizedBox(width: 12),
                    _buildTimeItem('Dzuhur', jadwal.dzuhur),
                    const SizedBox(width: 12),
                    _buildTimeItem('Ashar', jadwal.ashar),
                    const SizedBox(width: 12),
                    _buildTimeItem('Maghrib', jadwal.maghrib),
                    const SizedBox(width: 12),
                    _buildTimeItem('Isya', jadwal.isya),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getIndonesianDate() {
    final now = DateTime.now();
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _buildTimeItem(String label, String time) {
    return Column(
      children: [
        Text(
          time,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCarousel() {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        padEnds: false, // Start from left
        children: [
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Layanan lokasi tidak aktif. Mohon aktifkan GPS.')));
                  return;
                }

                permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Izin lokasi ditolak. Fitur ini butuh lokasi.')));
                    return;
                  }
                }
                
                if (permission == LocationPermission.deniedForever) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Izin lokasi ditolak permanen. Buka pengaturan.')));
                  return;
                } 

                // Get current position
                // Note: Getting position might take a moment, showing loading indicator is better UX 
                // but for now we block with await (UI might freeze slightly)
                // Consider adding a simple loading dialog if needed.
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Memeriksa lokasi...'),
                  duration: Duration(seconds: 1),
                ));

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
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Anda berada di luar radius ujian (${distanceInMeters.toStringAsFixed(0)}m).'),
                      backgroundColor: Colors.red,
                   ));
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
                 setState(() {
                   _currentIndex = 1;
                 });
              },
            ),
          ),

          // Card 3: Agenda Sekolah
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildSquareCard(
              title: 'Agenda\nSekolah',
              subtitle: 'Kalender Kegiatan',
              color1: const Color(0xFF7B1FA2), // Purple
              color2: const Color(0xFFBA68C8),
              icon: Icons.calendar_month,
              onTap: () {
                setState(() {
                  _currentIndex = 4; // Switch to Agenda Page
                });
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
                return const Center(child: CircularProgressIndicator());
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
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Fitur Jadwal akan segera hadir!', style: GoogleFonts.plusJakartaSans())),
          );
        }),
        _buildGridFeatureCard('Galeri', Icons.photo_library, Colors.teal, onTap: () {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Fitur Galeri akan segera hadir!', style: GoogleFonts.plusJakartaSans())),
          );
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


  Widget _buildScanButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)], // Gradient Blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D47A1).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScannerPage()),
            );
          },
          backgroundColor: Colors.transparent, // Transparent to show gradient
          elevation: 0, // Remove FAB elevation
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0, // Handle shadow in Container
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildNavItem(Icons.campaign, 'Info', 1), // Changed icon to campaign
                if (_hasUnreadAnnouncements)
                  Positioned(
                    top: 5,
                    right: 15, // Adjusted for centering over icon
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.calendar_month, 'Agenda', 4), // Swapped
            _buildNavItem(Icons.info_outline, 'Tentang', 3), // Swapped
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 1) { // If Info is clicked
          _markAnnouncementsAsRead();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey,
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $feature belum tersedia'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
