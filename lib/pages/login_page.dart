import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/home_page.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/services/guru_service.dart';
import 'package:cbt_app/models/guru.dart';
import 'package:cbt_app/models/siswa.dart';
import 'package:cbt_app/widgets/top_snack_bar.dart';

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
        if (siswaMatch.jabatan != null) await prefs.setString('user_jabatan', siswaMatch.jabatan!);
        
        if (!mounted) return;
        showTopSnackBar(context, 'Login Berhasil sebagai Siswa', backgroundColor: Colors.green);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
        return;
      }

      // 3. If Not Siswa, Try Login as Guru
      final guruResult = await _guruService.fetchGurus(query: inputId);
      final List<Guru> gurus = guruResult['data'];
      final Iterable<Guru> guruMatches = gurus.where((g) => g.nip == inputId);
      
      if (guruMatches.isNotEmpty) {
        final Guru guruMatch = guruMatches.first;
        // GURU FOUND
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_role', 'guru');
        await prefs.setString('user_nis', guruMatch.nip ?? '');
        await prefs.setString('user_name', guruMatch.namaGuru);
        await prefs.setInt('user_id', guruMatch.id);
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
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Header
              Container(
                height: MediaQuery.of(context).size.height * 0.5, // Increased Height
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
              
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20), // Added top spacing
                      // Logo Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Color(0xFF0D47A1))
                          : Image.asset(
                              'assets/logo smpn 1 cipanas.png',
                              width: 80,
                              height: 80,
                              errorBuilder: (ctx, err, _) => const Icon(Icons.school_rounded, size: 60, color: Color(0xFF0D47A1)),
                            ),
                      ),
                      
                      const SizedBox(height: 16), // Reduced Spacing
                      
                      Text(
                        'SATRIA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Akses Layanan Akademik Sekolah',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D47A1).withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Login Pengguna',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            _buildTextField(
                              controller: _nisController,
                              label: 'NIS / NIP',
                              icon: Icons.person_rounded,
                              inputType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _tokenController,
                              label: 'Token Sekolah',
                              icon: Icons.vpn_key_rounded,
                              isToken: true,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Masuk Aplikasi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Text(
                        '© ${DateTime.now().year} SMPN 1 Cipanas',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
