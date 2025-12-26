import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/services/curhat_service.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/widgets/top_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurhatPage extends StatefulWidget {
  const CurhatPage({super.key});

  @override
  State<CurhatPage> createState() => _CurhatPageState();
}

class _CurhatPageState extends State<CurhatPage> {
  final _formKey = GlobalKey<FormState>();
  final _curhatService = CurhatService();

  // Controllers
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();

  // State
  bool _isAnonim = true;
  bool _isSubmitting = false;
  String? _selectedKategori;

  final List<String> _kategoriOptions = [
    'akademik',
    'sosial',
    'keluarga',
    'pribadi',
    'bullying',
    'kesehatan',
    'karir',
    'lainnya'
  ];
  
  // User Data
  String? _savedName;
  String? _savedClass;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedName = prefs.getString('user_name');
      _savedClass = prefs.getString('user_class_name');
    });

    // If class is missing but we have NIS, try to fetch it (Self-repair for existing logins)
    if (_savedClass == null && prefs.getString('user_nis') != null) {
      _fetchUserClass(prefs.getString('user_nis')!);
    }
  }

  Future<void> _fetchUserClass(String nis) async {
    try {
      final siswaService = SiswaService();
      final result = await siswaService.fetchSiswas(query: nis);
      final List<dynamic> siswas = result['data'];
      
      if (siswas.isNotEmpty) {
        // Assume first match is correct since NIS is unique
        final siswa = siswas.first; // Siswa object
        if (siswa.className != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_class_name', siswa.className!);
          setState(() {
            _savedClass = siswa.className;
          });
          // Update controller if currently exposed and empty
          if (!_isAnonim && _kelasController.text.isEmpty) {
             _kelasController.text = _savedClass!;
          }
        }
      }
    } catch (e) {
      // Ignore background fetch error
      print('Auto-fetch class failed: $e');
    }
  }

  void _autofillIdentity() {
    if (_savedName != null) _namaController.text = _savedName!;
    if (_savedClass != null) _kelasController.text = _savedClass!;
  }

  Future<void> _submitCurhat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      showTopSnackBar(context, 'Pilih kategori terlebih dahulu', backgroundColor: Colors.red);
      return;
    }


    setState(() => _isSubmitting = true);

    try {
      final success = await _curhatService.submitCurhat(
        judul: _judulController.text,
        isi: _isiController.text,
        kategori: _selectedKategori!,
        isAnonim: _isAnonim,
        namaSiswa: _isAnonim ? null : _namaController.text,
        kelasSiswa: _isAnonim ? null : _kelasController.text,
      );

      if (!mounted) return;

      if (success) {
        showTopSnackBar(context, 'Curhat berhasil dikirim!', backgroundColor: Colors.green);
        Navigator.pop(context);
      } else {
        showTopSnackBar(context, 'Gagal mengirim curhat. Coba lagi.', backgroundColor: Colors.red);
      }
    } catch (e) {
      showTopSnackBar(context, 'Terjadi kesalahan: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    _namaController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const CustomPageHeader(title: 'Ruang Curhat'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    
                    _buildLabel('Judul Curhat'),
                    _buildTextField(
                      controller: _judulController,
                      hint: 'Berikan judul singkat...',
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Kategori'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _kategoriOptions.map((kategori) {
                         final bool isSelected = _selectedKategori == kategori;
                         // Capitalize display label
                         final displayLabel = kategori.replaceFirst(kategori[0], kategori[0].toUpperCase());
                         
                         return InkWell(
                           onTap: () {
                              setState(() {
                                _selectedKategori = kategori;
                              });
                           },
                           borderRadius: BorderRadius.circular(12),
                           child: AnimatedContainer(
                             duration: const Duration(milliseconds: 200),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                             decoration: BoxDecoration(
                               color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(
                                 color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[300]!,
                                 width: 1.5,
                               ),
                               boxShadow: isSelected 
                                  ? [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                                  : [],
                             ),
                             child: Text(
                               displayLabel,
                               style: GoogleFonts.plusJakartaSans(
                                 color: isSelected ? Colors.white : Colors.grey[700],
                                 fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                               ),
                             ),
                           ),
                         );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Isi Curhat'),
                    _buildTextField(
                      controller: _isiController,
                      hint: 'Tuliskan curhatmu di sini...',
                      maxLines: 6,
                    ),
                    const SizedBox(height: 20),

                    // Anonim Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isAnonim ? Colors.teal[50] : Colors.grey[50], // Change color based on state
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isAnonim ? Colors.teal[200]! : Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                           Checkbox(
                             value: _isAnonim,
                             activeColor: Colors.teal,
                             onChanged: (val) {
                               setState(() {
                                 _isAnonim = val ?? true;
                                 if (!_isAnonim) {
                                   _autofillIdentity();
                                 }
                               });
                             },
                           ),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Kirim sebagai Anonim',
                                   style: GoogleFonts.plusJakartaSans(
                                     fontWeight: FontWeight.bold,
                                     fontSize: 14,
                                   ),
                                 ),
                                 Text(
                                   'Identitasmu akan disembunyikan',
                                   style: GoogleFonts.plusJakartaSans(
                                     fontSize: 12,
                                     color: Colors.grey[600],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                        ],
                      ),
                    ),
                    
                    if (!_isAnonim) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Nama Lengkap'),
                      _buildTextField(
                        controller: _namaController,
                        hint: 'Nama kamu...',
                        isReadOnly: true,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Kelas'),
                      _buildTextField(
                        controller: _kelasController,
                        hint: 'Contoh: IX A...',
                        isReadOnly: true,
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCurhat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63), // Pink for Curhat
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Kirim Curhat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ceritakan masalahmu, kami siap mendengarkan. Privasi terjaga jika memilih anonim.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: isReadOnly,
      style: GoogleFonts.plusJakartaSans(),
      validator: (val) {
        if (!_isAnonim && (val == null || val.isEmpty)) return 'Wajib diisi';
        if (_isAnonim && (val == null || val.isEmpty) && controller != _namaController && controller != _kelasController) return 'Wajib diisi';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
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
          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
        ),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[200] : Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
