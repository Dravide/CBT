import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/assessment_menu.dart';
import 'package:cbt_app/webview_page.dart';
import 'package:flutter/services.dart';
import 'package:cbt_app/app_control.dart';
import 'package:cbt_app/pages/pengumuman_list_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  static const String _validQrCode = '5n8fy938t493rfuu04ru3f0ru340n9fr9u09ru34rf3nu09fr3u0f9r0u3f';
  static const String _targetUrl = 'https://assesmen.smpn1cipanas.sch.id/';
  static const Color _primaryColor = Color.fromRGBO(18, 26, 28, 1);
  static const Color _greyColor = Color.fromRGBO(247, 247, 249, 1);
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        if (code == _validQrCode) {
          // Enable secure mode (block screenshots)
          AppControl.setSecure(true);
          setState(() {
            _isScanning = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewPage(url: _targetUrl),
            ),
          );
          break;
        }
      }
    }
  }

  Future<void> _showExitDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Exit App',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter PIN',
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
              filled: true,
              fillColor: _greyColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == '1234') {
                  // Make sure to disable secure mode if we are exiting from here (just in case)
                  AppControl.setSecure(false);
                  AppControl.exitApp();
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Exit',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PengumumanListPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _showExitDialog,
          ),
        ],
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _greyColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/icon.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  'SCIPSA CBT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arahkan kamera ke QR Code ujian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: MobileScanner(
                  onDetect: _onDetect,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Pastikan QR Code terlihat jelas di dalam bingkai',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
