import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 

import '../services/presensi_service.dart';
import '../models/presensi_model.dart';
import '../widgets/custom_page_header.dart'; 
import 'scan_presensi_page.dart';
import 'daftar_hadir_page.dart';

class PresensiPage extends StatefulWidget {
  final String? nip; 

  const PresensiPage({Key? key, this.nip}) : super(key: key);

  @override
  State<PresensiPage> createState() => _PresensiPageState();
}

class _PresensiPageState extends State<PresensiPage> {
  late Future<PresensiResponse> _futurePresensi;
  final PresensiService _service = PresensiService();
  String _activeNip = '';

  // STATE: Filters
  DateTime _currentDate = DateTime.now();
  String _filterStatus = 'all'; // all, terlambat, lembur, tepat_waktu
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null); 
    _initData();
  }
  
  Future<void> _initData() async {
    String nipToUse = widget.nip ?? '';
    if (nipToUse.isEmpty) {
       final prefs = await SharedPreferences.getInstance();
       nipToUse = prefs.getString('user_nis') ?? ''; 
    }
    _activeNip = nipToUse;
    
    // Calculate Date Range for current Month
    DateTime firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    DateTime lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0); // Day 0 of next month = last day of current

    String startStr = DateFormat('yyyy-MM-dd').format(firstDay);
    String endStr = DateFormat('yyyy-MM-dd').format(lastDay);

    if (mounted) {
       setState(() {
         _futurePresensi = _service.getRekapPresensi(
            _activeNip,
            startDate: startStr,
            endDate: endStr,
            filterStatus: _filterStatus
         );
       });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
       _currentDate = DateTime(_currentDate.year, _currentDate.month + offset);
    });
    _initData();
  }

  void _updateFilter(String status) {
    setState(() => _filterStatus = status);
    _initData();
  }

  // Format Helpers
  String _formatDate(String dateTimeStr) {
    try {
      if (!dateTimeStr.endsWith('Z') && !dateTimeStr.contains('+')) {
        dateTimeStr += 'Z';
      }
      DateTime dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('EEEE, d MMM y', 'id_ID').format(dt); 
    } catch (e) {
      return dateTimeStr.split(' ').first;
    }
  }

  String _formatTime(String dateTimeStr) {
     try {
      if (!dateTimeStr.endsWith('Z') && !dateTimeStr.contains('+')) {
        dateTimeStr += 'Z';
      }
      DateTime dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('HH.mm').format(dt); 
    } catch (e) {
      return dateTimeStr.split(' ').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomPageHeader(
             title: 'Rekap Presensi', 
             showBackButton: true,
             actions: [
                // Daftar Hadir Button
                Container(
                   margin: const EdgeInsets.only(right: 4),
                   child: IconButton(
                     onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const DaftarHadirPage()));
                     },
                     icon: const Icon(Icons.people_alt_rounded, color: Color(0xFF0D47A1)),
                     tooltip: 'Daftar Hadir Hari Ini',
                   ),
                ),
                // Camera Button
                Container(
                   margin: const EdgeInsets.only(right: 8),
                   child: IconButton(
                     onPressed: () async {
                         final result = await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const ScanPresensiPage())
                         );
                         if (result == true) _initData();
                     },
                     icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D47A1)),
                     tooltip: 'Foto Presensi',
                   ),
                )
             ],
          ),
          
          Expanded(
            child: _activeNip.isEmpty 
              ? Center(child: Text('NIP tidak ditemukan.', style: GoogleFonts.plusJakartaSans()))
              : FutureBuilder<PresensiResponse>(
                future: _futurePresensi,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  } else if (snapshot.hasError) {
                    return _buildError(snapshot.error);
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('Tidak ada data'));
                  }

                  final data = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _initData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(data.guru),
                          const SizedBox(height: 24),
                          
                          // FILTER SECTION
                          _buildMonthFilter(),
                          const SizedBox(height: 16),
                          _buildStatusFilter(),
                          
                          const SizedBox(height: 24),

                          // STATS
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Hadir', data.stats.totalMasuk.toString(), const Color(0xFF4CAF50), Icons.check_circle_outline)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Terlambat', data.stats.totalTerlambat.toString(), const Color(0xFFF44336), Icons.timer_off_outlined)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Pulang', data.stats.totalPulang.toString(), const Color(0xFF2196F3), Icons.logout)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Lembur', data.stats.totalLembur.toString(), const Color(0xFFFF9800), Icons.access_time)),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // History Header
                          Row(
                            children: [
                               Container(width: 4, height: 24, decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(2))),
                               const SizedBox(width: 8),
                               Text('Riwayat Log', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (data.records.isEmpty)
                             Center(
                               child: Padding(
                                 padding: const EdgeInsets.symmetric(vertical: 40),
                                 child: Column(
                                   children: [
                                     Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey[300]),
                                     const SizedBox(height: 16),
                                     Text('Tidak ada riwayat presensi', style: GoogleFonts.plusJakartaSans(color: Colors.grey[500]))
                                   ],
                                 ),
                               ),
                             )
                          else
                            _buildGroupedList(data.records), // New Method
                          
                          const SizedBox(height: 48), 
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  
  // New Grouping Builder
  Widget _buildGroupedList(List<PresensiRecord> records) {
      // 1. Group by Date
      Map<String, List<PresensiRecord>> grouped = {};
      for (var record in records) {
          // Parse Date to ensure correct key (handling the Z fix I made earlier)
          String dateKey; 
          try {
             String dateTimeStr = record.waktu;
             if (!dateTimeStr.endsWith('Z') && !dateTimeStr.contains('+'))  dateTimeStr += 'Z';
             DateTime dt = DateTime.parse(dateTimeStr).toLocal();
             dateKey = DateFormat('yyyy-MM-dd').format(dt);
          } catch (e) {
             dateKey = record.waktu.split(' ').first;
          }

          if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
          grouped[dateKey]!.add(record);
      }

      // 2. Sort Keys Descending (Newest First)
      var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      return ListView.separated(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         itemCount: sortedKeys.length,
         separatorBuilder: (c, i) => const SizedBox(height: 16),
         itemBuilder: (context, index) {
            String dateKey = sortedKeys[index];
            List<PresensiRecord> dailyRecords = grouped[dateKey]!;
            return _buildDailyCard(dateKey, dailyRecords);
         },
      );
  }
  
  Widget _buildDailyCard(String dateKey, List<PresensiRecord> dailyRecords) {
    // Identify Records
    PresensiRecord? masuk;
    PresensiRecord? pulang;
    PresensiRecord? lembur;

    for (var r in dailyRecords) {
       String type = r.jenis.toLowerCase();
       if (type == 'masuk') masuk = r;
       else if (type == 'pulang') pulang = r;
       else if (type == 'lembur') lembur = r;
    }

    // Format Date Header (e.g. "Senin, 20 Feb 2024") through helper
    String displayDate = _formatDate((masuk ?? pulang ?? lembur)!.waktu);

    return Container(
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.grey.shade200),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.03),
             blurRadius: 15,
             offset: const Offset(0, 4),
           )
         ]
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // HEADER: Date & Summary Row
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                 displayDate, 
                 style: GoogleFonts.plusJakartaSans(
                   fontSize: 14, 
                   fontWeight: FontWeight.bold, 
                   color: Colors.blue[800]
                 )
               ),
               const SizedBox(height: 12),
               // Summary Row
               Row(
                 children: [
                    Expanded(child: _buildTimeSlot('Masuk', masuk, Colors.green)),
                    Container(width: 1, height: 24, color: Colors.grey[200]),
                    Expanded(child: _buildTimeSlot('Pulang', pulang, Colors.blue)),
                    if (lembur != null || dailyRecords.any((r) => r.jenis.toLowerCase() == 'lembur')) ...[
                       Container(width: 1, height: 24, color: Colors.grey[200]),
                       Expanded(child: _buildTimeSlot('Lembur', lembur, Colors.orange)),
                    ]
                 ],
               )
            ],
          ),
          children: [
             const Divider(),
             if (masuk != null) _buildDetailRow(masuk),
             if (masuk != null && (pulang != null || lembur != null)) const Divider(height: 1),
             if (pulang != null) _buildDetailRow(pulang),
             if (pulang != null && lembur != null) const Divider(height: 1),
             if (lembur != null) _buildDetailRow(lembur),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String label, PresensiRecord? record, Color color) {
     String time = '- - : - -';
     if (record != null) {
        time = _formatTime(record.waktu);
     }
     
     return Column(
       children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
               color: record != null ? color.withOpacity(0.1) : Colors.grey[50],
               borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              label, 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10, 
                color: record != null ? color : Colors.grey[400],
                fontWeight: FontWeight.bold
              )
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(
               fontSize: 16, 
               fontWeight: FontWeight.w800,
               color: record != null ? const Color(0xFF1F2937) : Colors.grey[300]
            ),
          ),
          if (record != null && record.isTerlambat)
             Text('Terlambat', style: GoogleFonts.plusJakartaSans(fontSize: 8, color: Colors.red, fontWeight: FontWeight.bold))
       ],
     );
  }

  Widget _buildDetailRow(PresensiRecord record) {
     bool isMasuk = record.jenis.toLowerCase() == 'masuk';
     Color color = isMasuk ? Colors.green : (record.jenis.toLowerCase() == 'pulang' ? Colors.blue : Colors.orange);
     
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                 Icon(
                   isMasuk ? Icons.login : (record.jenis.toLowerCase() == 'pulang' ? Icons.logout : Icons.access_time), 
                   size: 16, 
                   color: color
                 ),
                 const SizedBox(width: 8),
                 Text(
                   'Detail ${record.jenis[0].toUpperCase()}${record.jenis.substring(1)}',
                   style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                 ),
                 const Spacer(),
                 Text(
                    _formatTime(record.waktu) + ' WIB',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                 )
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                 Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                 const SizedBox(width: 4),
                 Expanded(child: Text(record.lokasi, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
            if (record.fotoUrl != null && record.fotoUrl!.isNotEmpty) ...[
               const SizedBox(height: 8),
               ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                     imageUrl: record.fotoUrl!,
                     height: 120,
                     width: double.infinity,
                     fit: BoxFit.cover,
                     placeholder: (c, u) => Container(height: 120, color: Colors.grey[100], child: const Center(child: CircularProgressIndicator())),
                     errorWidget: (c, u, e) => Container(height: 120, color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
                  ),
               )
            ]
         ],
       ),
     );
  }

  Widget _buildMonthFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.grey[700],
          ),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(_currentDate),
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
          ),
           IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final filters = [
      {'label': 'Semua', 'val': 'all'},
      {'label': 'Terlambat', 'val': 'terlambat'},
      {'label': 'Lembur', 'val': 'lembur'},
      {'label': 'Tepat Waktu', 'val': 'tepat_waktu'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
           final bool isSelected = _filterStatus == f['val'];
           return Padding(
             padding: const EdgeInsets.only(right: 8),
             child: FilterChip(
               label: Text(f['label'] as String),
               selected: isSelected,
               onSelected: (bool selected) {
                 if (selected) _updateFilter(f['val'] as String);
               },
               // Style
               backgroundColor: Colors.white,
               selectedColor: Colors.blue[50],
               checkmarkColor: Colors.blue,
               labelStyle: GoogleFonts.plusJakartaSans(
                 color: isSelected ? Colors.blue[700] : Colors.grey[600],
                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
               ),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20),
                 side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!)
               ),
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
             ),
           );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: Colors.blue[800]));
  }
  
  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Gagal memuat data', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              child: const Text('Coba Lagi'),
            )
          ],
        ),
      ),
    );
  }

  // Initials Helper
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
       // Take first letter of first and last name if available, or just first two parts
       return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else if (nameParts.isNotEmpty) {
       return nameParts[0].length > 1 
          ? nameParts[0].substring(0, 2).toUpperCase() 
          : nameParts[0][0].toUpperCase();
    }
    return '?';
  }

  Widget _buildProfileCard(Guru guru) {
    // Check if we should use the image (Not empty AND NOT ui-avatars)
    bool useImage = guru.photoUrl.isNotEmpty && !guru.photoUrl.contains('ui-avatars.com');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: Colors.blue[100]!, width: 3),
             ),
             child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue[50],
              backgroundImage: useImage 
                  ? CachedNetworkImageProvider(guru.photoUrl)
                  : null,
              child: !useImage
                  ? Text(
                      _getInitials(guru.nama), 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, 
                        fontWeight: FontWeight.w800, 
                        color: Colors.blue[800]
                      )
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guru.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    height: 1.2
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guru.jabatan.isEmpty ? 'Guru Pengajar' : guru.jabatan,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!)
                  ),
                  child: Text(
                    'NIP. ${guru.nip}',
                    style: GoogleFonts.plusJakartaSans(color: Colors.blue[800], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PresensiRecord record) {
     final bool isMasuk = record.jenis.toLowerCase() == 'masuk';
     final Color themeColor = isMasuk ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);
     
     String timeString = _formatTime(record.waktu);
     String dateString = _formatDate(record.waktu);

     return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    isMasuk ? Icons.login_rounded : Icons.logout_rounded,
                    color: themeColor,
                    size: 20,
                  ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                           isMasuk ? 'Absen Masuk' : 'Absen Pulang',
                           style: GoogleFonts.plusJakartaSans(
                             fontWeight: FontWeight.w800,
                             fontSize: 15,
                             color: const Color(0xFF1F2937),
                           ),
                        ),
                        Text(
                          dateString,
                          style: GoogleFonts.plusJakartaSans(
                             fontSize: 12,
                             color: Colors.grey[600],
                          ),
                        ),
                     ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                         timeString,
                         style: GoogleFonts.plusJakartaSans(
                           fontWeight: FontWeight.w900,
                           fontSize: 18,
                           color: record.isTerlambat ? Colors.red : themeColor,
                         ),
                      ),
                      Text(
                         'WIB',
                         style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold),
                      )
                    ],
                  )
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                     Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                     const SizedBox(width: 4),
                     Expanded(
                       child: Text(
                         record.lokasi,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                         style: GoogleFonts.plusJakartaSans(
                           fontSize: 12,
                           color: Colors.grey[500]
                         ),
                       ),
                     ),
                     if (record.isTerlambat)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[100]!)
                          ),
                          child: Text(
                            'TERLAMBAT', 
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)
                          ),
                        )
                  ],
                ),
              ),
              children: [
                 if (record.fotoUrl != null && record.fotoUrl!.isNotEmpty)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Divider(),
                       const SizedBox(height: 8),
                       Text(
                         'Bukti Foto:', 
                         style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])
                       ),
                       const SizedBox(height: 8),
                       ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: record.fotoUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200, 
                              color: Colors.grey[50],
                              child: const Center(child: CircularProgressIndicator())
                            ),
                            // User requested profile page like fallback logic
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_rounded, color: Colors.grey[400], size: 40),
                                  const SizedBox(height: 8),
                                  Text('Gagal memuat foto', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey))
                                ],
                              )
                            ),
                          ),
                       ),
                     ],
                   )
                 else 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tidak ada bukti foto.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                    )
              ],
            ),
          ),
        ),
     );
  }
}
