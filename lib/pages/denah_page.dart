import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui' as user_ui; // Required for ImageFilter

class RoomZone {
  final String id;
  final String label;
  final double top;
  final double left;
  final double width;
  final double height;
  final String? alias;

  RoomZone({
    required this.id,
    required this.label,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    this.alias,
  });

  factory RoomZone.fromJson(Map<String, dynamic> json) {
    return RoomZone(
      id: json['id'],
      label: json['label'],
      top: (json['top'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      alias: json['alias'],
    );
  }
}

class DenahPage extends StatefulWidget {
  const DenahPage({super.key});

  @override
  State<DenahPage> createState() => _DenahPageState();
}

class _DenahPageState extends State<DenahPage> with TickerProviderStateMixin { // Add Mixin for Animation
  final JadwalService _jadwalService = JadwalService();
  List<Jadwal> _todayJadwal = [];
  bool _isLoading = true;
  Timer? _timer;
  String _currentTime = '';
  List<RoomZone> _roomZones = [];
  
  // New Features State
  bool _teacherMode = false; // "Radar Guru" toggle
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startClock();
    
    // Setup Pulse Animation
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  // ... (Keep existing methods: _startClock, _updateTime, _loadData, _getRoomStatus, _getRoomBaseColor, _getRoomBorderColor)

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
      if (mounted) setState(() {}); 
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm').format(DateTime.now());
    });
  }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/denah_zones.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final zones = jsonList.map((j) => RoomZone.fromJson(j)).toList();

      final allJadwal = await _jadwalService.getJadwal();
      final dayFormatter = DateFormat('EEEE', 'id_ID');
      final currentDay = dayFormatter.format(DateTime.now());
      
      if (mounted) {
        setState(() {
          _roomZones = zones;
          _todayJadwal = allJadwal.where((j) => j.hari.toLowerCase() == currentDay.toLowerCase()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Jadwal? _getRoomStatus(RoomZone zone) {
    if (_todayJadwal.isEmpty) return null;
    final now = DateTime.now();
    final currentTotal = now.hour * 60 + now.minute;

    final roomJadwal = _todayJadwal.where((j) {
      final normalizedJadwalKelas = j.kelas.replaceAll('-', '').replaceAll(' ', '').toLowerCase();
      final normalizedRoomId = zone.id.replaceAll('-', '').replaceAll(' ', '').toLowerCase();
      final normalizedAlias = (zone.alias ?? '').replaceAll('-', '').replaceAll(' ', '').toLowerCase();
      
      return normalizedJadwalKelas == normalizedRoomId || 
             normalizedJadwalKelas.contains(normalizedRoomId) ||
             (normalizedAlias.isNotEmpty && normalizedJadwalKelas.contains(normalizedAlias));
    }).toList();

    for (var jadwal in roomJadwal) {
      try {
        final startParts = jadwal.jamMulai.split(':');
        final endParts = jadwal.jamSelesai.split(':');
        final startTotal = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endTotal = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (currentTotal >= startTotal && currentTotal < endTotal) return jadwal; 
      } catch (_) {}
    }
    return null; 
  }

  // Determine gradient colors for more depth
  Gradient _getRoomGradient(String id, String label, bool isBusy) {
    if (isBusy) {
      return LinearGradient(
        colors: [Colors.red[50]!, Colors.red[100]!],
        begin: Alignment.topLeft, end: Alignment.bottomRight
      );
    }

    id = id.toUpperCase();
    label = label.toUpperCase();
    
    // Default Palette (Soft Technical Colors)
    Color start = Colors.white;
    Color end = Colors.grey[50]!;

    if (id.startsWith('WC') || label.contains('TOILET')) {
      start = const Color(0xFFE3F2FD); end = const Color(0xFFBBDEFB); // Blue
    } else if (label.contains('KANTIN')) {
      start = const Color(0xFFFFF3E0); end = const Color(0xFFFFE0B2); // Orange
    } else if (label.contains('LAB')) {
      start = const Color(0xFFF3E5F5); end = const Color(0xFFE1BEE7); // Purple
    } else if (label.contains('GURU') || label.contains('TU') || label.contains('KS')) {
      start = const Color(0xFFE8EAF6); end = const Color(0xFFC5CAE9); // Indigo
    } else if (label.contains('MASJID') || label.contains('MUSHOLA')) {
      start = const Color(0xFFE0F2F1); end = const Color(0xFFB2DFDB); // Teal
    } else if (label.contains('LAPANGAN')) {
      start = const Color(0xFFE8F5E9); end = const Color(0xFFC8E6C9); // Green
    }

    return LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getRoomBaseColor(String id, String label) {
    id = id.toUpperCase();
    label = label.toUpperCase();

    if (id.startsWith('WC') || label.contains('TOILET')) return const Color(0xFFE3F2FD);
    if (label.contains('KANTIN')) return const Color(0xFFFFF3E0);
    if (label.contains('LAB')) return const Color(0xFFF3E5F5);
    if (label.contains('GURU') || label.contains('TU') || label.contains('KS') || label.contains('DINAS') || label.contains('OSIS')) return const Color(0xFFE8EAF6);
    if (label.contains('MASJID') || label.contains('MUSHOLA')) return const Color(0xFFE0F2F1);
    if (label.contains('LAPANGAN')) return const Color(0xFFE8F5E9);
    
    return Colors.white; 
  }
  
  Color _getRoomBorderColor(String id, String label) {
     id = id.toUpperCase();
     label = label.toUpperCase();
     if (id.startsWith('WC') || label.contains('TOILET')) return Colors.blue[200]!;
     if (label.contains('KANTIN')) return Colors.orange[200]!;
     if (label.contains('LAB')) return Colors.purple[200]!;
     if (label.contains('GURU') || label.contains('TU')) return Colors.indigo[200]!;
     if (label.contains('MASJID') || label.contains('MUSHOLA')) return Colors.teal[200]!;
     if (label.contains('LAPANGAN')) return Colors.green[200]!;
     return Colors.grey[300]!;
  }

  // Zoom to a specific room with animation
  void _zoomToRoom(RoomZone zone) {
    // Canvas Size is 1000 x 1414
    const double canvasW = 1000;
    const double canvasH = 1414;
    
    // Target position on canvas
    final double targetX = (zone.left + zone.width / 2) * canvasW;
    final double targetY = (zone.top + zone.height / 2) * canvasH;
    
    // Zoom scale
    const double targetScale = 2.5;
    
    // Screen Center (Approximate, relying on device width)
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height; // approximate visible height

    // Calculate translation to center the target
    // We want: (TargetX * Scale) + TranslateX = ScreenCenterX
    final double translateX = (screenW / 2) - (targetX * targetScale);
    final double translateY = (screenH / 2) - (targetY * targetScale);

    final Matrix4 endMatrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(targetScale);

    // Animate
    final animation = Matrix4Tween(
      begin: _transformController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _pulseController.reset();
    _pulseController.forward();
    
    // Listen to animation to update controller (Custom listener instead of just binding pulse)
    // Actually simpler: Just set it. The pulse controller is looping, not good for one-off transition. 
    // Let's use a dedicated simplistic approach:
    _transformController.value = endMatrix;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("🔍 Menuju ${zone.label}..."), 
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF0D47A1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text("Cari Ruangan", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
                  ],
                ),
              ),
              
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _roomZones.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final z = _roomZones[i];
                    Color iconColor = Colors.grey;
                    IconData icon = Icons.door_front_door;
                    
                    if (z.label.contains('TOILET') || z.id.startsWith("WC")) { icon = Icons.wc; iconColor = Colors.blue; }
                    else if (z.label.contains('KANTIN')) { icon = Icons.restaurant; iconColor = Colors.orange; }
                    else if (z.label.contains('LAB')) { icon = Icons.computer; iconColor = Colors.purple; }
                    else if (z.label.contains('GURU')) { icon = Icons.school; iconColor = Colors.indigo; }

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _zoomToRoom(z);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Icon(icon, color: iconColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(z.label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (z.id != z.label)
                                  Text("Kode: ${z.id}", style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.grey)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match social_page
      appBar: AppBar(
        title: Text('Digital Map Sekolah', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          )
        ],
      ),
      extendBody: true, // Allow body to perform behind FAB if needed
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _teacherMode = !_teacherMode),
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _teacherMode ? Icons.person : Icons.meeting_room, 
                    color: _teacherMode ? Colors.orange[700] : const Color(0xFF0D47A1),
                    size: 20
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _teacherMode ? "Mode Guru" : "Mode Ruangan",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800]
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack( // Using Stack for overlays
            children: [
               // DIGITAL MAP CANVAS
               Positioned.fill(
                 child: InteractiveViewer(
                   transformationController: _transformController, 
                   constrained: false, 
                   minScale: 0.1,
                   maxScale: 4.0,
                   boundaryMargin: const EdgeInsets.all(500), 
                   child: Container(
                     width: 1000,
                     height: 1414,
                     decoration: BoxDecoration(
                       color: const Color(0xFFF7FAFC), // Very light blueprint
                       border: Border.all(color: Colors.blue[50]!, width: 4),
                     ),
                     child: Stack(
                       children: [
                         Positioned.fill(
                           child: CustomPaint(
                             painter: GridPainter(),
                           ),
                         ),
                         if (_roomZones.isNotEmpty)
                           ..._roomZones.map((zone) => _buildVectorRoom(zone, 1000, 1414)).toList(),
                       ],
                     ),
                   ),
                 ),
               ),
               
               // Status Bar
               Positioned(
                 top: 16, left: 16, right: 16,
                 child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatusChip(Colors.red[50]!, Colors.red, "Sedang Belajar"),
                        const SizedBox(width: 10),
                        _buildStatusChip(Colors.green[50]!, Colors.green, "Kosong"),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1).withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentTime, 
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, 
                              fontSize: 14,
                              color: const Color(0xFF0D47A1)
                            )
                          ),
                        ),
                      ],
                    ),
                 ),
               ),
            ],
          ),
    );
  }

  // ... (Keep existing _buildStatusChip but simpler)
  Widget _buildStatusChip(Color bg, Color border, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 3, backgroundColor: border),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVectorRoom(RoomZone zone, double totalWidth, double totalHeight) {
    final activeJadwal = _getRoomStatus(zone);
    final isBusy = activeJadwal != null;
    
    // Visuals
    Gradient bgGradient = _getRoomGradient(zone.id, zone.label, isBusy);
    Color borderColor = _getRoomBorderColor(zone.id, zone.label);
    if (isBusy) borderColor = Colors.red[300]!;
    
    // Scale font
    double fontSize = (zone.width * totalWidth) * 0.25;
    if (fontSize > 16) fontSize = 16;
    if (fontSize < 10) fontSize = 10;

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isBusy ? Colors.red.withOpacity(0.15) : Colors.black.withOpacity(0.06),
            blurRadius: isBusy ? 8 : 4,
            offset: const Offset(0, 3), // slight elevation
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_teacherMode && isBusy && activeJadwal!.guru.isNotEmpty) ...[
                      const Icon(Icons.person, size: 10, color: Colors.red),
                      Text(
                         activeJadwal.guru.split(' ').take(2).join('\n'),
                         textAlign: TextAlign.center,
                         style: GoogleFonts.plusJakartaSans(
                           color: Colors.red[900], fontSize: fontSize, fontWeight: FontWeight.bold
                         ),
                      )
                    ] else ...[
                      Text(
                        zone.label, 
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[800], 
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.white, offset: const Offset(1,1), blurRadius: 0)]
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          // Activity Indicator Dot
          if (isBusy)
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 4)]
                ),
              ),
            ),
        ],
      ),
    );

    // If busy, add pulse animation
    if (isBusy) {
      return Positioned(
        top: zone.top * totalHeight, 
        left: zone.left * totalWidth,
        width: zone.width * totalWidth,
        height: zone.height * totalHeight,
        child: GestureDetector(
          onTap: () => _showRoomDetails(zone, activeJadwal),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (ctx, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
            child: content,
          ),
        ),
      );
    }

    return Positioned(
      top: zone.top * totalHeight, 
      left: zone.left * totalWidth,
      width: zone.width * totalWidth,
      height: zone.height * totalHeight,
      child: GestureDetector(
        onTap: () => _showRoomDetails(zone, activeJadwal),
        child: content,
      ),
    );
  }

  // Get facility info for non-classroom rooms
  Map<String, dynamic> _getFacilityInfo(RoomZone zone) {
    final id = zone.id.toUpperCase();
    final label = zone.label.toUpperCase();
    
    if (id.startsWith('WC') || label.contains('TOILET') || label.contains('WC')) {
      return {
        'icon': Icons.wc,
        'color': Colors.blue,
        'type': 'Fasilitas Umum',
        'description': 'Toilet siswa dan guru. Harap jaga kebersihan.',
        'info': '🚿 Tersedia wastafel\n🧻 Tersedia tissue',
      };
    }
    if (label.contains('KANTIN')) {
      return {
        'icon': Icons.restaurant,
        'color': Colors.orange,
        'type': 'Fasilitas Kantin',
        'description': 'Tempat jajan dan makan siswa.',
        'info': '⏰ Buka: 07:00 - 14:00\n🍜 Tersedia makanan & minuman',
      };
    }
    if (label.contains('LAB')) {
      return {
        'icon': Icons.science,
        'color': Colors.purple,
        'type': 'Laboratorium',
        'description': 'Ruang praktikum siswa dengan pengawasan guru.',
        'info': '🔬 Wajib memakai jas lab\n⚠️ Dilarang makan/minum',
      };
    }
    if (label.contains('PERPUS')) {
      return {
        'icon': Icons.menu_book,
        'color': Colors.brown,
        'type': 'Perpustakaan',
        'description': 'Tempat membaca dan meminjam buku.',
        'info': '⏰ Buka: 07:30 - 15:00\n📚 Koleksi: 5000+ buku',
      };
    }
    if (label.contains('MESJID') || label.contains('MUSHOLA')) {
      return {
        'icon': Icons.mosque,
        'color': Colors.teal,
        'type': 'Tempat Ibadah',
        'description': 'Tempat sholat berjamaah dan kegiatan keagamaan.',
        'info': '🕌 Sholat Dzuhur berjamaah\n📖 Tadarus setiap Jumat',
      };
    }
    if (label.contains('LAPANGAN')) {
      return {
        'icon': Icons.sports_soccer,
        'color': Colors.green,
        'type': 'Lapangan Olahraga',
        'description': 'Area olahraga dan upacara bendera.',
        'info': '⚽ Futsal, Voli, Basket\n🏃 Senam pagi setiap Jumat',
      };
    }
    if (label.contains('GURU')) {
      return {
        'icon': Icons.school,
        'color': Colors.indigo,
        'type': 'Ruang Guru',
        'description': 'Ruang kerja dan istirahat guru.',
        'info': '👨‍🏫 Konsultasi: Jam istirahat\n📞 Hubungi via piket',
      };
    }
    if (label.contains('AULA')) {
      return {
        'icon': Icons.event,
        'color': Colors.deepPurple,
        'type': 'Aula Serbaguna',
        'description': 'Ruang untuk acara besar sekolah.',
        'info': '🎤 Kapasitas: 500 orang\n🎭 Acara, rapat, pentas seni',
      };
    }
    if (label.contains('OSIS')) {
      return {
        'icon': Icons.groups,
        'color': Colors.red,
        'type': 'Ruang OSIS',
        'description': 'Sekretariat Organisasi Siswa Intra Sekolah.',
        'info': '📋 Rapat setiap Sabtu\n🎯 Program kerja siswa',
      };
    }
    if (label.contains('BK') || label.contains('KONSELING')) {
      return {
        'icon': Icons.psychology,
        'color': Colors.pink,
        'type': 'Bimbingan Konseling',
        'description': 'Layanan konseling dan bimbingan siswa.',
        'info': '💬 Konsultasi gratis\n🤝 Rahasia terjamin',
      };
    }
    if (label.contains('UKS') || label.contains('PMR')) {
      return {
        'icon': Icons.local_hospital,
        'color': Colors.red,
        'type': 'Unit Kesehatan Sekolah',
        'description': 'Pertolongan pertama dan istirahat sakit.',
        'info': '🩺 P3K tersedia\n🛏️ Tempat istirahat',
      };
    }
    if (label.contains('KOPERASI')) {
      return {
        'icon': Icons.store,
        'color': Colors.amber,
        'type': 'Koperasi Siswa',
        'description': 'Toko alat tulis dan kebutuhan sekolah.',
        'info': '⏰ Buka: 07:00 - 14:00\n📝 ATK, seragam, dll',
      };
    }
    if (label.contains('TU')) {
      return {
        'icon': Icons.admin_panel_settings,
        'color': Colors.blueGrey,
        'type': 'Tata Usaha',
        'description': 'Administrasi dan surat-menyurat sekolah.',
        'info': '📄 Surat keterangan\n💳 Pembayaran SPP',
      };
    }
    if (label.contains('KS') || label.contains('KEPALA')) {
      return {
        'icon': Icons.person,
        'color': Colors.indigo,
        'type': 'Ruang Kepala Sekolah',
        'description': 'Kantor pimpinan sekolah.',
        'info': '👔 Audience dengan janji\n📞 Melalui TU',
      };
    }
    if (label.contains('JALAN')) {
      return {
        'icon': Icons.add_road,
        'color': Colors.grey,
        'type': 'Akses Jalan',
        'description': 'Jalan utama menuju sekolah.',
        'info': '🚗 Akses kendaraan\n🚶 Pejalan kaki',
      };
    }
    
    // Default for unknown facilities
    return {
      'icon': Icons.location_on,
      'color': Colors.grey,
      'type': 'Fasilitas Sekolah',
      'description': 'Area fasilitas sekolah.',
      'info': '',
    };
  }
  
  // Check if room is a classroom (has schedule potential)
  bool _isClassroom(RoomZone zone) {
    final id = zone.id.toUpperCase();
    // Classrooms typically have format like "7-A", "8-B", "9-C" etc
    return RegExp(r'^\d+-[A-K]$').hasMatch(id);
  }

  void _showRoomDetails(RoomZone zone, Jadwal? jadwal) {
    final isClassroom = _isClassroom(zone);
    final facilityInfo = _getFacilityInfo(zone);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isClassroom ? "Info Ruangan Kelas" : facilityInfo['type'],
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey)
                  ),
                  if (isClassroom)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: jadwal != null ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(20)
                      ),
                      child: Text(
                        jadwal != null ? "SEDANG BELAJAR" : "KOSONG",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: jadwal != null ? Colors.red[800] : Colors.green[800]
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (facilityInfo['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Icon(facilityInfo['icon'], color: facilityInfo['color'], size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(zone.label, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
              if (zone.id != zone.label)
                 Text("Kode: ${zone.id}", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),

              const Divider(height: 30),
              
              // Content based on room type
              if (jadwal != null) ...[
                // Classroom with active schedule
                _buildDetailRow(Icons.book, "Pelajaran", jadwal.mataPelajaran),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person, "Guru", jadwal.guru),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time, "Waktu", "${jadwal.jamMulai} - ${jadwal.jamSelesai}"),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.people, "Kelas", jadwal.kelas),
              ] else if (isClassroom) ...[
                // Empty classroom
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
                        const SizedBox(height: 10),
                        Text("Ruangan ini sedang kosong.", style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              ] else ...[
                // Non-classroom facility
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (facilityInfo['color'] as Color).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (facilityInfo['color'] as Color).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facilityInfo['description'],
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700]),
                      ),
                      if ((facilityInfo['info'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          facilityInfo['info'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600], height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue[800], size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        )
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double gridSize = 40.0;
    
    // Draw columns
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw rows
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
