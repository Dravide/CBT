import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/services/wellbeing_service.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart'; // app_usage doesn't use standard permission handler for USAGE_STATS

class WellbeingCard extends StatefulWidget {
  const WellbeingCard({super.key});

  @override
  State<WellbeingCard> createState() => _WellbeingCardState();
}

class _WellbeingCardState extends State<WellbeingCard> {
  final WellbeingService _service = WellbeingService();
  Duration _totalUsage = Duration.zero;
  bool _loading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // There is no direct "checkPermission" in app_usage 4.0.0 that returns bool without exception
    // We try to fetch. If it returns empty or fails, it might be permission.
    // Actually, getAppUsage throws exception if permission denied.
    try {
      final usage = await _service.getTotalScreenTimeToday();
      if (mounted) {
        setState(() {
          _totalUsage = usage;
          _loading = false;
          _hasPermission = true; // Succeeded
        });
      }
    } catch (e) {
      // Assuming error means no permission or other issue
      if (mounted) {
        setState(() {
          _loading = false;
          _hasPermission = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return "${d.inHours}j ${twoDigitMinutes}m";
  }

  @override
  Widget build(BuildContext context) {
    // Style matching _buildSquareCard in HomePage
    const Color color1 = Color(0xFF00897B); // Teal 600
    const Color color2 = Color(0xFF4DB6AC); // Teal 300

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color1.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon Top
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timelapse, color: Colors.white, size: 24),
          ),
          
          // Content Bottom
          if (_loading)
            const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else if (!_hasPermission)
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh Izin',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                 Text(
                  'Tap untuk aktifkan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                // Wrap prompt in InkWell or just use the card tap if we want.
                // Since this is a widget, let's keep it simple.
                // We'll wrap the whole specific text area in InkWell for permission
                 const SizedBox(height: 4),
                 InkWell(
                   onTap: _loadData,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                     child: Text('Buka Setting', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color1, fontWeight: FontWeight.bold)),
                   ),
                 ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDuration(_totalUsage),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Waktu Layar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
