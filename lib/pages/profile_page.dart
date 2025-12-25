import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/pages/login_page.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/models/siswa.dart';
import 'package:cbt_app/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SiswaService _siswaService = SiswaService();
  bool _isLoading = true;
  Siswa? _siswa;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nis = prefs.getString('user_nis');

      if (nis == null) {
        setState(() {
          _errorMessage = 'Data sesi tidak ditemukan. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }

      // Fetch fresh data
      final result = await _siswaService.fetchSiswas(query: nis);
      final List<Siswa> siswas = result['data'];
      
      try {
         final Siswa match = siswas.firstWhere((s) => s.nis == nis);
         setState(() {
           _siswa = match;
           _isLoading = false;
         });
      } catch (e) {
        setState(() {
          _errorMessage = 'Data siswa tidak ditemukan di server.';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat profil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear all data
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPageHeader(
          title: 'Profil Siswa',
          onBack: widget.onBack,
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: GoogleFonts.plusJakartaSans(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            )
          ],
        ),
      );
    }

    if (_siswa == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0D47A1), width: 2),
            ),
            child: const Icon(Icons.person, size: 60, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 16),
          Text(
            _siswa!.namaSiswa,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            _siswa!.nis ?? '-',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildInfoTile('Kelas', _siswa!.className ?? '-'),
          _buildInfoTile('Jenis Kelamin', _siswa!.jk == 'L' ? 'Laki-laki' : 'Perempuan'),
          _buildInfoTile('Status', _siswa!.status ?? '-'),
          _buildInfoTile('NISN', _siswa!.nisn ?? '-'),

          const SizedBox(height: 32),
          
          // Settings Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings, color: Color(0xFF0D47A1)),
              label: Text('Pengaturan Aplikasi', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D47A1)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text('Keluar Aplikasi', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
