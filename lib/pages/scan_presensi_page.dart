import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; 

import '../services/presensi_service.dart';

class ScanPresensiPage extends StatefulWidget {
  const ScanPresensiPage({Key? key}) : super(key: key);

  @override
  State<ScanPresensiPage> createState() => _ScanPresensiPageState();
}

class _ScanPresensiPageState extends State<ScanPresensiPage> with SingleTickerProviderStateMixin {
  // Service
  final PresensiService _service = PresensiService();
  
  // State
  bool _isLoading = true;
  String _statusMessage = 'Mendeteksi Jadwal...';
  
  Map<String, dynamic>? _autoDetectData;
  String? _scanErrorMessage;
  
  // Logic Flow
  bool _showScanner = false;
  MobileScannerController? _scannerController;
  
  // Final Data
  String? _qrCode;
  File? _selfieFile;

  @override
  void initState() {
    super.initState();
    _startAutoDetect();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  Future<void> _startAutoDetect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Sinkronisasi Server...';
    });

    try {
      final res = await _service.autoDetectPresensi();
      final data = res['data'];
      
      setState(() {
         _autoDetectData = data;
         _isLoading = false;
         
         // Start Scanner immediately if allowed
         if (data['can_checkin'] == true || data['can_checkout'] == true) {
             _initScanner();
         } else {
             _scanErrorMessage = "Presensi Ditutup\n(${data['message'] ?? 'Di luar jadwal'})";
         }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
           _isLoading = false;
           _scanErrorMessage = "Gagal Terhubung\nPeriksa koneksi internet Anda";
        });
      }
    }
  }

  void _initScanner() {
     _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
     );
     setState(() {
       _showScanner = true;
       _statusMessage = 'Arahkan QR Code ke dalam kotak';
     });
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;
      
      final String? code = barcodes.first.rawValue;
      if (code == null || _qrCode != null) return; 

      if (!code.startsWith('rglb-')) {
          _showToast('QR Code tidak valid!', isError: true);
          return;
      }
      
      // Stop scanner
      _scannerController?.stop();
      setState(() {
         _qrCode = code;
         _showScanner = false;
         _statusMessage = 'Verifikasi Wajah...';
      });

      // Proceed to Selfie
      await _takeSelfie();
  }
  
  Future<void> _takeSelfie() async {
    try {
       final ImagePicker picker = ImagePicker();
       // Use Front Camera
       final XFile? photo = await picker.pickImage(
          source: ImageSource.camera, 
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 50,
       );

       if (photo != null) {
          _selfieFile = File(photo.path);
          _submitPresensi();
       } else {
          // User cancelled selfie -> Reset
          setState(() {
             _qrCode = null;
             _initScanner();
          });
       }
    } catch (e) {
       _showToast("Gagal membuka kamera", isError: true);
    }
  }

  Future<void> _submitPresensi() async {
     if (_qrCode == null || _selfieFile == null) return;
     
     setState(() {
        _isLoading = true;
        _statusMessage = 'Mengupload Data...';
     });
     
     try {
       List<int> imageBytes = await _selfieFile!.readAsBytes();
       String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

       await _service.processPresensi(
           qrCode: _qrCode!,
           jenisPresensi: _autoDetectData?['jenis_presensi'] ?? 'masuk',
           base64Image: base64Image,
           locationCode: 'rglb-00b-h8eud836rt7' 
       );
        
       if (mounted) _showSuccessDialog();

     } catch (e) {
        if (mounted) {
           setState(() {
              _isLoading = false;
              _scanErrorMessage = "Gagal Mengirim Data\n$e";
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

  void _showSuccessDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
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
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, color: Colors.green[600], size: 40),
                ),
                const SizedBox(height: 20),
                Text('Scan Berhasil!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  'Presensi ${_autoDetectData?['jenis_presensi']?.toUpperCase()} telah tercatat.', 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); 
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    child: Text('Selesai', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
           // 1. CONTENT LAYER
           if (_showScanner)
              MobileScanner(
                 controller: _scannerController!,
                 onDetect: _onQrDetected,
              )
           else
              Container(color: Colors.black), // Placeholder for loading/error

           // 2. OVERLAY (Focus Frame)
           if (_showScanner)
             _buildScanOverlay(),

           // 3. TOP BAR
           Positioned(
             top: 0, left: 0, right: 0,
             child: _buildTopBar(),
           ),

           // 4. BOTTOM STATUS / ERROR
           if (_isLoading)
              _buildLoadingOverlay()
           else if (_scanErrorMessage != null)
              _buildErrorOverlay()
           else if (_showScanner)
              _buildBottomInstruction()
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
             GestureDetector(
               onTap: () => Navigator.pop(context),
               child: Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: Colors.black45,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.white24)
                 ),
                 child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Text(
                 'Scan QR Presensi',
                 style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(color: Colors.black54, blurRadius: 10)])
               ),
             ),
             // Optional Torch Toggle could go here
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Stack(
      children: [
         ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
         ),
         Center(
           child: Container(
             width: 280, 
             height: 280,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.blueAccent, width: 3),
               boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
               ]
             ),
           ),
         ),
         // Corner Accents
         Center(
            child: SizedBox(
               width: 260, height: 260,
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.white.withOpacity(0.9)),
                     const SizedBox(height: 8),
                     Text('RGLB', style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12, letterSpacing: 4))
                  ],
               ),
            ),
         )
      ],
    );
  }

  Widget _buildBottomInstruction() {
     return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
           margin: const EdgeInsets.only(bottom: 50, left: 24, right: 24),
           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
           decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12)
           ),
           child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                    'Jadwal: ${(_autoDetectData?['jenis_presensi'] ?? '').toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(color: Colors.blue[300], fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)
                 ),
                 const SizedBox(height: 8),
                 Text(
                    _statusMessage, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
                 ),
              ],
           ),
        ),
     );
  }

  Widget _buildLoadingOverlay() {
      return Container(
         color: Colors.black.withOpacity(0.7),
         child: Center(
            child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(_statusMessage, style: GoogleFonts.plusJakartaSans(color: Colors.white))
               ],
            ),
         ),
      );
  }

  Widget _buildErrorOverlay() {
      return Center(
         child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                  Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                     child: Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber[400]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                     _scanErrorMessage!, 
                     textAlign: TextAlign.center,
                     style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16)
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                     onPressed: () {
                        setState(() { _scanErrorMessage = null; });
                        _startAutoDetect();
                     },
                     style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black
                     ),
                     child: const Text('Coba Lagi'),
                  )
               ],
            ),
         ),
      );
  }
}
