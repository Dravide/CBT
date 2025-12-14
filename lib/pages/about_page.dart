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
    return Column(
      children: [
        CustomPageHeader(
          title: 'Tentang Aplikasi',
          onBack: onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo smpn 1 cipanas.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (ctx, err, _) => const Icon(Icons.school, size: 80, color: Color(0xFF0D47A1)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SATRIA',
                  style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
                ),
                Text(
                  'Sistem Aplikasi Terpadu & Interaktif Siswa',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600]),
                ),
                 const SizedBox(height: 8),
                Text(
                  'Versi 1.0.0',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[500]),
                ),
                
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                
                // Credits
                Text(
                  'Dibuat oleh:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dery Supriady',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                ),
                
                const SizedBox(height: 40),
                
                // Social Media
                Text(
                  'Ikuti SMPN 1 Cipanas:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      label: 'Facebook',
                      onTap: () => _launchUrl('https://www.facebook.com/smpn1cipanas'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE4405F),
                      label: 'Instagram',
                      onTap: () => _launchUrl('https://www.instagram.com/smpn1cipanas.official'),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      icon: Icons.language,
                      color: Colors.blueAccent,
                      label: 'Website',
                      onTap: () => _launchUrl('https://smpn1cipanas.sch.id'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                Text(
                  '© ${DateTime.now().year} SMPN 1 Cipanas',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
