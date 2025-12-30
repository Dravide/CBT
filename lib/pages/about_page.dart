import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cbt_app/widgets/custom_page_header.dart'; // Import Header

class AboutPage extends StatelessWidget {
  final VoidCallback? onBack;

  const AboutPage({super.key, this.onBack});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          CustomPageHeader(
            title: 'Tentang Aplikasi',
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Main Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/logo smpn 1 cipanas.png',
                            width: 72,
                            height: 72,
                            errorBuilder: (ctx, err, _) => const Icon(Icons.school_rounded, size: 50, color: Color(0xFF0D47A1)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Title
                        Text(
                          'SATRIA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24, 
                            fontWeight: FontWeight.w800, 
                            color: const Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tagline
                        Text(
                          'Sistem Aplikasi Terpadu & Interaktif Siswa',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, 
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Version Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: const Color(0xFFBBDEFB)),
                          ),
                          child: Text(
                            'Versi 1.2.2',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700, 
                              color: const Color(0xFF0D47A1)
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 32),

                        // Description Text
                        Text(
                          'SATRIA adalah platform digital resmi SMP Negeri 1 Cipanas yang dirancang untuk memudahkan aktivitas akademik siswa. Aplikasi ini mengintegrasikan presensi digital, jadwal pelajaran, informasi sekolah, dan pengelolaan tugas dalam satu genggaman.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, 
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Developer & Contact Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Dikembangkan Oleh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dery Supriady',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFF1F2937)
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                         Text(
                          'Ikuti Kami',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Social Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: Icons.facebook,
                              color: const Color(0xFF1877F2),
                              onTap: () => _launchUrl('https://www.facebook.com/smpn1cipanas'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: Icons.camera_alt,
                              color: const Color(0xFFE4405F),
                              onTap: () => _launchUrl('https://www.instagram.com/smpn1cipanas'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: Icons.language,
                              color: const Color(0xFF0D47A1),
                              onTap: () => _launchUrl('https://smpn1cipanas.sch.id'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: Icons.music_video, // TikTok placeholder
                              color: Colors.black,
                              onTap: () => _launchUrl('https://www.tiktok.com/@smpn1cipanas'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                   Text(
                    '© ${DateTime.now().year} SMPN 1 Cipanas\nAll Rights Reserved',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
