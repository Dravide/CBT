import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/jadwal_model.dart';
import 'package:cbt_app/services/jadwal_service.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/widgets/skeleton_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JadwalPage extends StatefulWidget {
  final VoidCallback? onBack;

  const JadwalPage({super.key, this.onBack});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> with SingleTickerProviderStateMixin {
  final JadwalService _jadwalService = JadwalService();
  late TabController _tabController;
  List<Jadwal> _allJadwal = [];
  bool _isLoading = true;
  
  // Define days for Tabs
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _loadJadwal();
    _selectTodayTab();
  }

  void _selectTodayTab() {
    // Get current day index (1=Mon, 7=Sun)
    // DateTime.weekday returns 1 for Monday
    int weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 6) {
      _tabController.index = weekday - 1; // 0-indexed
    }
  }

  Future<void> _loadJadwal() async {
    final data = await _jadwalService.getJadwal();
    if (mounted) {
      setState(() {
        _allJadwal = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPageHeader(
          title: 'Jadwal Pelajaran',
          showBackButton: false,
          leadingIcon: Icons.calendar_month,
        ),
        
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF0D47A1),
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            indicatorColor: const Color(0xFF0D47A1),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),

        Expanded(
          child: _isLoading 
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) {
                   return Shimmer.fromColors(
                     baseColor: Colors.grey[300]!,
                     highlightColor: Colors.grey[100]!,
                     child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: const [
                                SkeletonLoading(width: 40, height: 14),
                                SizedBox(height: 4),
                                SkeletonLoading(width: 30, height: 12),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  SkeletonLoading(width: 150, height: 16),
                                  SizedBox(height: 8),
                                  SkeletonLoading(width: 100, height: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                     ),
                   );
                },
              )
            : TabBarView(
                controller: _tabController,
                children: _days.map((day) => _buildDaySchedule(day)).toList(),
              ),
        ),
      ],
    );
  }

  Widget _buildDaySchedule(String day) {
    // Filter jadwal for this day
    final daySchedule = _allJadwal.where((j) => j.hari.toLowerCase() == day.toLowerCase()).toList();

    // Sort by jam_ke
    daySchedule.sort((a, b) => a.jamKe.compareTo(b.jamKe));

    if (daySchedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal hari ini',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daySchedule.length,
      itemBuilder: (context, index) {
        final jadwal = daySchedule[index];
        return _buildJadwalCard(jadwal);
      },
    );
  }

  Widget _buildJadwalCard(Jadwal jadwal) {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        final isGuru = snapshot.data == 'guru';
        final baseColor = _getColorSubject(jadwal.mataPelajaran);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Time Column (Colored Block)
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        jadwal.jamMulai,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: baseColor,
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 2,
                        color: baseColor.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Text(
                        jadwal.jamSelesai,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: baseColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. Info Column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mapel Title (Larger)
                        Text(
                          jadwal.mataPelajaran,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 20, // Enlarged
                            color: const Color(0xFF1F2937),
                            height: 1.2
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Class Badge & Teacher
                        if (isGuru) ...[
                          Row(
                            children: [
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[100]!)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.meeting_room_rounded, size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      jadwal.kelas,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14, // Enlarged
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w800
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ] else ...[
                          // STUDENT VIEW
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[100],
                                child: Icon(Icons.person, size: 14, color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  jadwal.guru,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (jadwal.kelas.isNotEmpty) ...[
                             const SizedBox(height: 10),
                             Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Kelas ${jadwal.kelas}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                             ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'siswa';
  }

  Color _getColorSubject(String subject) {
    // Generate constant color based on subject string length/hash
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[subject.length % colors.length];
  }
}
