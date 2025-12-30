import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/presensi_service.dart';
import '../widgets/custom_page_header.dart';

class DaftarHadirPage extends StatefulWidget {
  const DaftarHadirPage({Key? key}) : super(key: key);

  @override
  State<DaftarHadirPage> createState() => _DaftarHadirPageState();
}

class _DaftarHadirPageState extends State<DaftarHadirPage> {
  final PresensiService _service = PresensiService();
  
  late Future<List<dynamic>> _futureAttendance;
  String _filterType = 'all'; // 'all', 'masuk', 'pulang'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Load all data, filter will be applied client-side
    _futureAttendance = _service.getDailyAttendance();
  }

  List<dynamic> _applyFilter(List<dynamic> data) {
    if (_filterType == 'all') return data;
    return data.where((item) => 
      (item['jenis_presensi'] ?? '').toString().toLowerCase() == _filterType
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          CustomPageHeader(
            title: 'Daftar Hadir Hari Ini',
            showBackButton: true,
          ),
          
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Masuk', 'masuk'),
                const SizedBox(width: 8),
                _buildFilterChip('Pulang', 'pulang'),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() { _loadData(); });
              },
              child: FutureBuilder<List<dynamic>>(
                future: _futureAttendance,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() { _loadData(); }),
                              child: const Text('Coba Lagi'),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final List<dynamic> rawList = snapshot.data ?? [];
                  final List<dynamic> attendanceList = _applyFilter(rawList);
                  
                  if (attendanceList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _filterType == 'all' 
                                ? 'Belum ada data presensi hari ini' 
                                : 'Tidak ada data presensi "${_filterType.toUpperCase()}"',
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: attendanceList.length,
                    itemBuilder: (context, index) {
                      final item = attendanceList[index];
                      return _buildAttendanceCard(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = value;
            // No need to reload data, filter is applied client-side
          });
        }
      },
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(color: isSelected ? Colors.blue[800] : Colors.grey[700]),
      checkmarkColor: Colors.blue[800],
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final String name = item['user_name'] ?? 'Unknown';
    final String type = item['jenis_presensi'] ?? '-';
    final String? waktuPresensi = item['waktu_presensi'];
    final String time = waktuPresensi != null ? waktuPresensi.split(' ').last.substring(0, 5) : '-'; // Extract HH:mm
    final bool isTerlambat = item['is_terlambat'] ?? false;
    final String status = isTerlambat ? 'Terlambat' : 'Tepat Waktu';
    final String? fotoUrl = item['foto_url'];
    final bool isMasuk = type.toLowerCase() == 'masuk';
    final bool isOnTime = !isTerlambat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: isMasuk ? Colors.blue[50] : Colors.orange[50],
            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
            child: fotoUrl == null 
                ? Icon(isMasuk ? Icons.login_rounded : Icons.logout_rounded, color: isMasuk ? Colors.blue[700] : Colors.orange[700])
                : null,
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMasuk ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: isMasuk ? Colors.blue[700] : Colors.orange[700]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOnTime ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: isOnTime ? Colors.green[700] : Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}
