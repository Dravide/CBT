import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/jadwal_model.dart';
import 'package:cbt_app/services/jadwal_service.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/widgets/skeleton_loading.dart';
import 'package:shimmer/shimmer.dart';

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
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                     return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                     );
                  },
                ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        border: Border(
          left: BorderSide(
            color: _getColorSubject(jadwal.mataPelajaran),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          // Time Column
          Column(
            children: [
              Text(
                jadwal.jamMulai,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Container(
                height: 16,
                width: 2,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
              Text(
                jadwal.jamSelesai,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.mataPelajaran,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        jadwal.guru,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (jadwal.kelas.isNotEmpty) ...[
                   const SizedBox(height: 2),
                   Row(
                    children: [
                      Icon(Icons.class_, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        jadwal.kelas,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
