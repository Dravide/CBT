import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/presensi_service.dart';
import 'presensi_success_page.dart';
import 'daftar_hadir_page.dart';

class SelfieCameraPage extends StatefulWidget {
  final String jenisPresensi;
  final Map<String, dynamic>? autoDetectData;

  const SelfieCameraPage({
    Key? key,
    required this.jenisPresensi,
    this.autoDetectData,
  }) : super(key: key);

  @override
  State<SelfieCameraPage> createState() => _SelfieCameraPageState();
}

class _SelfieCameraPageState extends State<SelfieCameraPage> {
  final PresensiService _service = PresensiService();
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  
  // Face Detection with proper lock
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  bool _faceDetected = false;
  Timer? _faceDetectionTimer;
  Completer<void>? _detectionLock;
  
  // Location with Geofencing
  static const double _schoolLatitude = -6.728338615118334; 
  static const double _schoolLongitude = 107.03671141098333;
  static const double _maxRadiusMeters = 500.0; // 500 meter radius
  
  Position? _currentPosition;
  String _locationName = 'Mencari lokasi...';
  double? _distanceFromSchool;
  bool _isWithinRadius = false;
  StreamSubscription<Position>? _positionStream;
  
  // Time
  late Timer _clockTimer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startLocationStream();
    _startClock();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _faceDetectionTimer?.cancel();
    _faceDetector.close();
    _cameraController?.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  void _startClock() {
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('Tidak ada kamera tersedia');
        return;
      }

      CameraDescription frontCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() { _isCameraInitialized = true; });
        _startFaceDetection();
      }
    } catch (e) {
      _showError('Gagal inisialisasi kamera: $e');
    }
  }

  void _startFaceDetection() {
    // Use 2 second interval to avoid conflicts
    _faceDetectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _detectFace();
    });
  }

  Future<void> _detectFace() async {
    // Skip if already detecting, capturing, or camera not ready  
    if (_detectionLock != null || _isCapturing || !_isCameraInitialized || _cameraController == null) {
      return;
    }

    // Set lock
    _detectionLock = Completer<void>();
    
    try {
      // Take picture for detection
      final XFile image = await _cameraController!.takePicture();
      
      // Process with ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          _faceDetected = faces.isNotEmpty;
        });
      }
      
      // Clean up temp file
      try {
        await File(image.path).delete();
      } catch (_) {}
      
    } catch (e) {
      // Silent fail - just means no face detected this cycle
      // Silent fail
    } finally {
      // Release lock
      _detectionLock?.complete();
      _detectionLock = null;
    }
  }

  Future<void> _startLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _locationName = 'GPS Mati'; });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() { _locationName = 'Izin Lokasi Ditolak'; });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _locationName = 'Izin Lokasi Ditolak Permanen'; });
        return;
      }

      // Start Stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, 
          distanceFilter: 5
        )
      ).listen((Position position) {
        _updateLocation(position);
      }, onError: (e) {
        if (mounted) setState(() { _locationName = 'Gagal memuat lokasi'; });
      });

    } catch (e) {
      if (mounted) setState(() { _locationName = 'Error GPS'; });
    }
  }

  void _updateLocation(Position position) {
    if (!mounted) return;
    
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _schoolLatitude,
      _schoolLongitude,
    );

    setState(() {
      _currentPosition = position;
      _distanceFromSchool = distance;
      _isWithinRadius = distance <= _maxRadiusMeters;
      
      if (_isWithinRadius) {
        _locationName = 'Dalam Area • ${distance.toInt()}m';
      } else {
        _locationName = 'Di Luar Area • ${distance.toInt()}m';
      }
    });
  }

  Future<void> _captureAndSubmit() async {
    if (!_isCameraInitialized || _cameraController == null || _isCapturing) return;
    
    // Check location radius first
    if (!_isWithinRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda di luar radius ${_maxRadiusMeters.toInt()}m. Jarak: ${_distanceFromSchool?.toInt() ?? 0}m', 
            style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    
    if (!_faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wajah tidak terdeteksi. Posisikan wajah di dalam bingkai.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() { _isCapturing = true; });
    
    // Stop face detection timer
    _faceDetectionTimer?.cancel();
    
    // Wait for any ongoing detection to complete
    if (_detectionLock != null) {
      await _detectionLock!.future;
    }
    
    // Small delay to ensure camera is ready
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      final prefs = await SharedPreferences.getInstance();
      final nip = prefs.getString('user_nis');
      
      if (nip == null) throw Exception("NIP tidak ditemukan");

      final result = await _service.processPresensiByNip(
        nip: nip,
        jenisPresensi: widget.jenisPresensi,
        base64Image: base64Image,
        locationCode: 'rglb-00b-h8eud836rt7',
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      // Safely extract data from result
      final dynamic data = result['data'];
      String waktuResult = 'N/A';
      String? userName;
      String status = 'Tercatat';
      
      if (data is Map) {
        waktuResult = data['waktu_presensi']?.toString() ?? data['waktu']?.toString() ?? 'N/A';
        if (waktuResult.contains(' ')) {
          final parts = waktuResult.split(' ');
          if (parts.length > 1 && parts.last.length >= 5) {
            waktuResult = parts.last.substring(0, 5);
          }
        }
        userName = data['user_name']?.toString();
        final isTerlambat = data['is_terlambat'];
        status = (isTerlambat == true || isTerlambat == 1 || isTerlambat == '1') 
            ? 'Terlambat' 
            : (data['status']?.toString() ?? 'Tercatat');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PresensiSuccessPage(
              jenisPresensi: widget.jenisPresensi,
              userName: userName,
              waktu: waktuResult,
              status: status,
            ),
          ),
        );
      }

      await File(image.path).delete();
    } catch (e) {
      _handleError(e);
      setState(() { _isCapturing = false; });
      // Restart face detection to try again
      _startFaceDetection();
    }
  }

  void _handleError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    String title, message;
    MaterialColor color;
    IconData icon;

    if (errorStr.contains('tunggu') || errorStr.contains('menit')) {
      title = 'Harap Tunggu';
      message = 'Tunggu beberapa menit sebelum mencoba lagi.';
      color = Colors.orange;
      icon = Icons.hourglass_top_rounded;
    } else if (errorStr.contains('sudah') || errorStr.contains('already')) {
      title = 'Sudah Presensi';
      message = 'Anda sudah melakukan presensi ${widget.jenisPresensi} hari ini.';
      color = Colors.blue;
      icon = Icons.info_outline_rounded;
    } else {
      title = 'Gagal';
      message = e.toString().replaceAll('Exception:', '').trim();
      color = Colors.red;
      icon = Icons.error_outline_rounded;
    }

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
                child: Icon(icon, color: color[600], size: 36),
              ),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: color[700], foregroundColor: Colors.white),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Dark Overlay with Face Cutout
          if (_isCameraInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: FaceOverlayPainter(faceDetected: _faceDetected),
              ),
            ),

          // Top Info Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Location with radius indicator
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _currentPosition == null 
                          ? Colors.grey[800] 
                          : (_isWithinRadius ? Colors.green[900]!.withOpacity(0.5) : Colors.red[900]!.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isWithinRadius ? Icons.check_circle : Icons.warning_rounded, 
                            color: _isWithinRadius ? Colors.green[400] : Colors.red[400], 
                            size: 20
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_locationName, 
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white, 
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!_isWithinRadius && _distanceFromSchool != null)
                                  Text(
                                    'Wajib dalam radius ${_maxRadiusMeters.toInt()}m untuk presensi', 
                                    style: GoogleFonts.plusJakartaSans(color: Colors.red[300], fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[400], size: 18),
                        const SizedBox(width: 8),
                        Text(_currentTime, style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24
                        )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.jenisPresensi == 'masuk' 
                                ? [Colors.blue[600]!, Colors.blue[800]!]
                                : [Colors.orange[600]!, Colors.orange[800]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(widget.jenisPresensi.toUpperCase(), 
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 26),
                        Text(_currentDate, style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Face Status Text
          Positioned(
            bottom: 180,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _faceDetected ? Colors.green[700] : Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_faceDetected ? Icons.face : Icons.face_retouching_off, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _faceDetected ? 'Wajah Terdeteksi ✓' : 'Posisikan Wajah di Bingkai',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // OUT OF RADIUS WARNING OVERLAY
          if (!_isWithinRadius && _currentPosition != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_off_rounded, color: Colors.red[600], size: 48),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Di Luar Area Presensi',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey[900]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Anda berada ${_distanceFromSchool?.toInt() ?? 0} meter dari sekolah',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Radius maksimal: ${_maxRadiusMeters.toInt()} meter',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red[700]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Kembali', style: GoogleFonts.plusJakartaSans(color: Colors.grey[700])),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Trigger immediate update if possible or show toast
                                  setState(() { _locationName = 'Memperbarui lokasi...'; });
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text('Cek Ulang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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

          // Bottom Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureAndSubmit,
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _faceDetected ? Colors.green : Colors.white, width: 5),
                          gradient: _isCapturing ? null : (_faceDetected 
                            ? LinearGradient(colors: [Colors.green[400]!, Colors.green[700]!])
                            : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[800]!])
                          ),
                          color: _isCapturing ? Colors.grey : null,
                        ),
                        child: _isCapturing
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Icon(Icons.camera_alt, color: Colors.white, size: 40),
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DaftarHadirPage())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final bool faceDetected;
  
  FaceOverlayPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: 280,
      height: 360,
    );
    
    final ovalPath = Path()..addOval(ovalRect);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final combinedPath = Path.combine(PathOperation.difference, fullPath, ovalPath);
    
    canvas.drawPath(combinedPath, paint);
    
    // Border color based on face detection
    final borderPaint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceDetected ? 4 : 3;
    
    canvas.drawOval(ovalRect, borderPaint);
    
    // Glow effect when face detected
    if (faceDetected) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawOval(ovalRect, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) => 
    oldDelegate.faceDetected != faceDetected;
}
