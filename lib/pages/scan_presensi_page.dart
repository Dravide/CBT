import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/presensi_service.dart';
import 'presensi_success_page.dart';
import 'daftar_hadir_page.dart';
import 'selfie_camera_page.dart';

class ScanPresensiPage extends StatefulWidget {
  const ScanPresensiPage({Key? key}) : super(key: key);

  @override
  State<ScanPresensiPage> createState() => _ScanPresensiPageState();
}

class _ScanPresensiPageState extends State<ScanPresensiPage> {
  final PresensiService _service = PresensiService();
  
  bool _isLoading = true;
  String _statusMessage = 'Mendeteksi Status...';
  
  Map<String, dynamic>? _autoDetectData;
  String? _errorMessage;
  
  // Status flags
  bool _canCheckin = false;
  bool _canCheckout = false;
  String _jenisPresensi = 'masuk';
  bool _noScheduleToday = false;
  
  // Already attended flags
  bool _hasCheckedInToday = false;
  bool _hasCheckedOutToday = false;
  String? _checkinTime;
  String? _checkoutTime;
  
  File? _selfieFile;
  bool _isTakingSelfie = false;

  @override
  void initState() {
    super.initState();
    _startAutoDetect();
  }

  Future<void> _startAutoDetect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sinkronisasi dengan Server...';
      _errorMessage = null;
    });

    try {
      // Fetch auto-detect status
      final res = await _service.autoDetectPresensi();
      final dynamic rawData = res['data'];
      final Map<String, dynamic> data = (rawData is Map<String, dynamic>) ? rawData : {};
      
      // Also fetch today's attendance to check if already attended
      List<dynamic> todayData = [];
      try {
        final result = await _service.getDailyAttendance();
        if (result is List) {
          todayData = result;
        }
      } catch (_) {
        // Silent fail - todayData remains empty
      }
      
      // Get current user NIP to filter
      final prefs = await SharedPreferences.getInstance(); 
      final currentNip = prefs.getString('user_nis') ?? '';
      
      // Check if current user already has masuk/pulang today
      bool hasCheckedInToday = false;
      bool hasCheckedOutToday = false;
      String? checkinTime;
      String? checkoutTime;
      
      for (var item in todayData) {
        if (item is! Map) continue;
        
        final userEmail = item['user_email']?.toString() ?? '';
        final userName = item['user_name']?.toString() ?? '';
        // Match by checking if NIP is part of email or name contains current user
        if (userEmail.contains(currentNip) || userName.toUpperCase().contains(currentNip.toUpperCase()) || item['user_id']?.toString() == currentNip) {
          final jenis = item['jenis_presensi']?.toString().toLowerCase() ?? '';
          
          // Safe waktu extraction
          String waktu = '';
          final rawWaktu = item['waktu_presensi']?.toString() ?? '';
          if (rawWaktu.isNotEmpty) {
            final parts = rawWaktu.split(' ');
            final timePart = parts.isNotEmpty ? parts.last : rawWaktu;
            waktu = timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
          }
          
          if (jenis == 'masuk') {
            hasCheckedInToday = true;
            checkinTime = waktu;
          } else if (jenis == 'pulang') {
            hasCheckedOutToday = true;
            checkoutTime = waktu;
          }
        }
      }
      
      if (mounted) {
        // Determine if there's no schedule today
        final canCI = data['can_checkin'] == true;
        final canCO = data['can_checkout'] == true;
        final hasJamSetting = data['jam_setting'] is Map && (data['jam_setting'] as Map).isNotEmpty;
        
        setState(() {
           _autoDetectData = data;
           _canCheckin = canCI;
           _canCheckout = canCO;
           _jenisPresensi = data['jenis_presensi']?.toString() ?? 'masuk';
           _noScheduleToday = !canCI && !canCO && !hasJamSetting;
           _hasCheckedInToday = hasCheckedInToday;
           _hasCheckedOutToday = hasCheckedOutToday;
           _checkinTime = checkinTime;
           _checkoutTime = checkoutTime;
           _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _isLoading = false;
           _errorMessage = "Gagal Terhubung\nPeriksa koneksi internet Anda";
        });
      }
    }
  }

  Future<void> _takeSelfie() async {
    // Navigate to custom camera page with face detection
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SelfieCameraPage(
          jenisPresensi: _jenisPresensi,
          autoDetectData: _autoDetectData,
        ),
      ),
    );
  }

  Future<void> _submitPresensi() async {
     if (_selfieFile == null) return;
     
     setState(() {
        _isLoading = true;
        _statusMessage = 'Mengupload Data Presensi...';
     });
     
     try {
       final prefs = await SharedPreferences.getInstance(); 
       final nip = prefs.getString('user_nis'); 
       
       if (nip == null) throw Exception("NIP tidak ditemukan. Silakan login ulang.");

       List<int> imageBytes = await _selfieFile!.readAsBytes();
       String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

       final result = await _service.processPresensiByNip(
           nip: nip,
           jenisPresensi: _jenisPresensi,
           base64Image: base64Image,
           locationCode: 'rglb-00b-h8eud836rt7',
           latitude: -6.728338615118334,
           longitude: 107.03671141098333, 
       );
        
       if (mounted) {
         // Extract waktu from response (try multiple field names)
         String waktuResult = result['data']?['waktu_presensi'] ?? result['data']?['waktu'] ?? 'N/A';
         if (waktuResult.contains(' ')) waktuResult = waktuResult.split(' ').last.substring(0, 5);
         
         Navigator.of(context).pushReplacement(
           MaterialPageRoute(
             builder: (_) => PresensiSuccessPage(
               jenisPresensi: _jenisPresensi,
               userName: result['data']?['user_name'],
               waktu: waktuResult,
               status: (result['data']?['is_terlambat'] == true) ? 'Terlambat' : (result['data']?['status'] ?? 'Tercatat'),
             ),
           ),
         );
       }

     } catch (e) {
        if (mounted) {
           final errorStr = e.toString().toLowerCase();
           String friendlyTitle;
           String friendlyMessage;
           IconData friendlyIcon;
           MaterialColor friendlyColor;
           
           // Detect common error types
           if (errorStr.contains('tunggu') || errorStr.contains('menit') || errorStr.contains('detik')) {
             // Rate limiting error
             friendlyTitle = 'Harap Tunggu';
             friendlyMessage = 'Anda baru saja melakukan presensi.\nTunggu beberapa menit sebelum mencoba lagi.';
             friendlyIcon = Icons.hourglass_top_rounded;
             friendlyColor = Colors.orange;
           } else if (errorStr.contains('sudah') || errorStr.contains('already') || errorStr.contains('duplicate')) {
             // Already attended error
             friendlyTitle = 'Sudah Presensi';
             friendlyMessage = 'Anda sudah melakukan presensi ${_jenisPresensi} hari ini.';
             friendlyIcon = Icons.info_outline_rounded;
             friendlyColor = Colors.blue;
           } else if (errorStr.contains('tidak ditemukan') || errorStr.contains('not found')) {
             // User not found
             friendlyTitle = 'Data Tidak Ditemukan';
             friendlyMessage = 'NIP Anda tidak terdaftar di sistem.\nHubungi admin untuk bantuan.';
             friendlyIcon = Icons.person_off_rounded;
             friendlyColor = Colors.red;
           } else {
             // Generic error
             friendlyTitle = 'Gagal Mengirim Data';
             friendlyMessage = e.toString().replaceAll('Exception:', '').trim();
             friendlyIcon = Icons.error_outline_rounded;
             friendlyColor = Colors.red;
           }
           
           // Show friendly dialog instead of raw error
           _showFriendlyErrorDialog(friendlyTitle, friendlyMessage, friendlyIcon, friendlyColor);
           
           setState(() {
              _isLoading = false;
              _isTakingSelfie = false;
              // Don't set _errorMessage, we show dialog instead
           });
        }
     }
  }

  void _showToast(String msg, {bool isError = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.plusJakartaSans()),
          backgroundColor: isError ? Colors.red[800] : Colors.blue[800],
          behavior: SnackBarBehavior.floating,
        )
      );
  }

  void _showFriendlyErrorDialog(String title, String message, IconData icon, MaterialColor color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
                child: Icon(icon, color: color[600], size: 40),
              ),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                message, 
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 14)
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Reload status to refresh attendance data
                    _startAutoDetect();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
                  child: Text('Mengerti', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DaftarHadirPage()));
                },
                child: Text('Lihat Daftar Hadir', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading 
                  ? _buildLoadingContent()
                  : _errorMessage != null 
                      ? _buildErrorContent()
                      : _buildStatusContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
           GestureDetector(
             onTap: () => Navigator.pop(context),
             child: Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey[200]!),
                 boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
               ),
               child: Icon(Icons.arrow_back_rounded, color: Colors.blue[800], size: 24),
             ),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Text(
               'Presensi',
               style: GoogleFonts.plusJakartaSans(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 18)
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           const CircularProgressIndicator(color: Colors.blue),
           const SizedBox(height: 24),
           Text(_statusMessage, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.grey[700]))
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                 child: Icon(Icons.warning_amber_rounded, size: 40, color: Colors.red[400]),
              ),
              const SizedBox(height: 20),
              Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey[800], fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton(
                 onPressed: _startAutoDetect,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                 child: const Text('Coba Lagi'),
              )
           ],
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    // Determine if user can do attendance:
    // 1. Time must allow it (_canCheckin/_canCheckout)
    // 2. User must NOT have already done it for this jenis today
    final bool alreadyDoneForThisType = (_jenisPresensi == 'masuk' && _hasCheckedInToday) || 
                                         (_jenisPresensi == 'pulang' && _hasCheckedOutToday);
    final bool canDoPresensi = ((_jenisPresensi == 'masuk' && _canCheckin) || (_jenisPresensi == 'pulang' && _canCheckout)) 
                               && !alreadyDoneForThisType;
    
    // Safe access for current_time
    String currentTime = '--:--';
    final rawCurrentTime = _autoDetectData?['current_time'];
    if (rawCurrentTime is String && rawCurrentTime.contains(' ')) {
      currentTime = rawCurrentTime.split(' ').last;
    } else if (rawCurrentTime is String) {
      currentTime = rawCurrentTime;
    }
    
    // Safe access for jam_setting (might be Map or something else)
    String jamSetting = '-';
    final rawJamSetting = _autoDetectData?['jam_setting'];
    if (rawJamSetting is Map) {
      final jamKey = _jenisPresensi == 'masuk' ? 'jam_masuk' : 'jam_pulang';
      jamSetting = rawJamSetting[jamKey]?.toString() ?? '-';
    }
    
    final String validationMessage = _autoDetectData?['validation_message']?.toString() ?? '';

    // Determine display state
    MaterialColor primaryColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;
    
    if (_noScheduleToday) {
      // No schedule - ORANGE warning state
      primaryColor = Colors.orange;
      statusIcon = Icons.event_busy_rounded;
      statusTitle = 'Tidak Ada Jadwal Presensi';
      statusSubtitle = 'Tidak ada jadwal presensi untuk hari ini';
    } else if (alreadyDoneForThisType) {
      // Already attended - GREEN SUCCESS state
      primaryColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusTitle = 'Presensi ${_jenisPresensi.toUpperCase()} Selesai!';
      statusSubtitle = 'Anda sudah melakukan presensi hari ini';
    } else if (canDoPresensi) {
      // Can attend - BLUE state
      primaryColor = Colors.blue;
      statusIcon = _jenisPresensi == 'masuk' ? Icons.login_rounded : Icons.logout_rounded;
      statusTitle = 'Presensi ${_jenisPresensi.toUpperCase()}';
      statusSubtitle = validationMessage;
    } else {
      // Cannot attend - GREY state
      primaryColor = Colors.grey;
      statusIcon = Icons.schedule_rounded;
      statusTitle = 'Presensi ${_jenisPresensi.toUpperCase()}';
      statusSubtitle = validationMessage.isNotEmpty ? validationMessage : 'Di luar jadwal presensi';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          
          // Status Icon - Now changes based on state
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.shade400, primaryColor.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 8,
                )
              ],
            ),
            child: Icon(statusIcon, color: Colors.white, size: 56),
          ),
          
          const SizedBox(height: 28),
          
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey[900]),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            statusSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: primaryColor.shade700),
          ),
          
          const SizedBox(height: 32),
          
          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.access_time, 'Waktu Sekarang', currentTime),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.schedule, 'Jam ${_jenisPresensi.toUpperCase()}', jamSetting),
                const SizedBox(height: 16),
                _buildInfoRow(
                  canDoPresensi ? Icons.check_circle : Icons.info,
                  'Status',
                  canDoPresensi ? 'Bisa Presensi' : 'Tidak Bisa Presensi',
                  valueColor: canDoPresensi ? Colors.green[700] : Colors.orange[700],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Already Attended Card
          if (_hasCheckedInToday || _hasCheckedOutToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text('Presensi Hari Ini', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.green[800])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_hasCheckedInToday)
                    _buildAttendanceChip('MASUK', _checkinTime ?? '-', Colors.blue),
                  if (_hasCheckedInToday && _hasCheckedOutToday)
                    const SizedBox(height: 8),
                  if (_hasCheckedOutToday)
                    _buildAttendanceChip('PULANG', _checkoutTime ?? '-', Colors.orange),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Action Buttons
          if (canDoPresensi)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTakingSelfie ? null : _takeSelfie,
                icon: _isTakingSelfie 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.camera_alt_rounded),
                label: Text(_isTakingSelfie ? 'Membuka Kamera...' : 'Ambil Foto Selfie', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DaftarHadirPage()));
                },
                icon: const Icon(Icons.people_alt_rounded),
                label: Text('Lihat Daftar Hadir', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChip(String label, String time, MaterialColor color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: color[700])),
        ),
        const SizedBox(width: 12),
        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
        const SizedBox(width: 4),
        Text('Tercatat pukul $time', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }
}
