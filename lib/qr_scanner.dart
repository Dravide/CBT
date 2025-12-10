import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cbt_app/webview_page.dart';
import 'package:flutter/services.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  static const String _validQrCode = '5n8fy938t493rfuu04ru3f0ru340n9fr9u09ru34rf3nu09fr3u0f9r0u3f';
  static const String _targetUrl = 'https://assesmen.smpn1cipanas.sch.id/';
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        if (code == _validQrCode) {
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
          title: const Text('Exit App'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter PIN'),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text == '1234') {
                  SystemNavigator.pop();
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showExitDialog,
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
