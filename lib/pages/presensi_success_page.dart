import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daftar_hadir_page.dart';

class PresensiSuccessPage extends StatelessWidget {
  final String jenisPresensi; // 'masuk' or 'pulang'
  final String? userName;
  final String waktu;
  final String status; // 'Tepat Waktu' / 'Terlambat'

  const PresensiSuccessPage({
    Key? key,
    required this.jenisPresensi,
    this.userName,
    required this.waktu,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOnTime = status.toLowerCase().contains('tepat');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Success Animation/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Presensi Berhasil!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[900],
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Anda telah tercatat untuk presensi ${jenisPresensi.toUpperCase()}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Detail Card
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
                    _buildDetailRow(Icons.access_time, 'Waktu', waktu),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      isOnTime ? Icons.verified : Icons.warning_amber_rounded,
                      'Status',
                      status,
                      valueColor: isOnTime ? Colors.green[700] : Colors.orange[700],
                    ),
                    if (userName != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.person, 'Nama', userName!),
                    ],
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DaftarHadirPage()),
                    );
                  },
                  icon: const Icon(Icons.people_alt_rounded),
                  label: Text('Lihat Daftar Hadir Hari Ini', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
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
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Kembali ke Beranda', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
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
                  fontSize: 16,
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
}
