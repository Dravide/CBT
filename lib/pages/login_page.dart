import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/home_page.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/services/guru_service.dart';
import 'package:cbt_app/models/guru.dart';
import 'package:cbt_app/models/siswa.dart'; // Added Siswa Import
import 'package:cbt_app/widgets/top_snack_bar.dart'; // Added TopSnackBar Import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final SiswaService _siswaService = SiswaService();
  final GuruService _guruService = GuruService();
  bool _isLoading = false;

  Future<void> _login() async {
    final String inputId = _nisController.text.trim();
    final String token = _tokenController.text.trim();

    if (inputId.isEmpty || token.isEmpty) {
      showTopSnackBar(context, 'NIS/NIP dan Token wajib diisi', backgroundColor: Colors.red);
      return;
    }

    // 1. Validate Token (Hardcoded)
    if (token != 'N6FJ9LK') {
       showTopSnackBar(context, 'Token Sekolah salah!', backgroundColor: Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 2. Try Login as Siswa
      final siswaResult = await _siswaService.fetchSiswas(query: inputId);
      final List<Siswa> siswas = siswaResult['data'];
      final Siswa? siswaMatch = siswas.firstWhere(
        (s) => s.nis == inputId, 
        orElse: () => Siswa(id: 0, namaSiswa: '', nis: ''),
      );

      if (siswaMatch != null && siswaMatch.id != 0) {
        // SISWA FOUND
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_role', 'siswa');
        await prefs.setString('user_nis', siswaMatch.nis ?? '');
        await prefs.setString('user_name', siswaMatch.namaSiswa);
        await prefs.setInt('user_id', siswaMatch.id);
        if (siswaMatch.kelasId != null) await prefs.setInt('kelas_id', siswaMatch.kelasId!);
        if (siswaMatch.className != null) await prefs.setString('user_class_name', siswaMatch.className!);
        
        if (!mounted) return;
        showTopSnackBar(context, 'Login Berhasil sebagai Siswa', backgroundColor: Colors.green);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
        return;
      }

      // 3. If Not Siswa, Try Login as Guru
      final guruResult = await _guruService.fetchGurus(query: inputId);
      final List<Guru> gurus = guruResult['data'];
      // Assuming 'nip' is the unique identifier for Guru matching inputId
      final Iterable<Guru> guruMatches = gurus.where((g) => g.nip == inputId);
      
      if (guruMatches.isNotEmpty) {
        final Guru guruMatch = guruMatches.first;
        // GURU FOUND
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_role', 'guru');
        await prefs.setString('user_nis', guruMatch.nip ?? ''); // Use NIP as NIS identifier
        await prefs.setString('user_name', guruMatch.namaGuru);
        await prefs.setInt('user_id', guruMatch.id);
        // Clean up class specific data if any exists from previous session
        await prefs.remove('kelas_id');
        await prefs.remove('user_class_name');

        if (!mounted) return;
        showTopSnackBar(context, 'Login Berhasil sebagai Guru', backgroundColor: Colors.green);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
        return;
      }
      
      showTopSnackBar(context, 'NIS atau NIP tidak ditemukan', backgroundColor: Colors.red);

    } catch (e) {
      showTopSnackBar(context, 'Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
               Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SATRIA - LOGIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
               Text(
                'Masuk untuk memulai ujian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),

              // Card Input
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _nisController,
                      label: 'NIS / NIP',
                      icon: Icons.person_outline,
                      inputType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tokenController,
                      label: 'Token Sekolah',
                      icon: Icons.vpn_key_outlined,
                      isToken: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Masuk',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SMPN 1 Cipanas',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isToken = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: isToken ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
