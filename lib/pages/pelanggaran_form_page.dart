import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/pelanggaran_model.dart';
import 'package:cbt_app/services/pelanggaran_service.dart';
import 'package:intl/intl.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PelanggaranFormPage extends StatefulWidget {
  const PelanggaranFormPage({super.key});

  @override
  State<PelanggaranFormPage> createState() => _PelanggaranFormPageState();
}

class _PelanggaranFormPageState extends State<PelanggaranFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PelanggaranService();

  // Data
  PelanggaranOptions? _options;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Form Fields
  SiswaSearch? _selectedSiswa;
  KategoriPelanggaran? _selectedKategori;
  JenisPelanggaran? _selectedJenis;
  String? _selectedStatus;
  
  final _deskripsiController = TextEditingController();
  final _tindakLanjutController = TextEditingController();
  final _catatanController = TextEditingController();
  final _pelaporController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();

  // Search
  final _searchController = TextEditingController();
  List<SiswaSearch> _siswaSearchResults = [];
  bool _isSearchingSiswa = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userName = prefs.getString('user_name');
    if (userName != null) {
      setState(() {
        _pelaporController.text = userName;
      });
    }
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _service.getOptions();
      setState(() {
        _options = options;
        _isLoading = false;
        
        // Set default status if available
        // Force default status
        _selectedStatus = 'belum_ditangani';
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat opsi: $e')));
    }
  }

  Future<void> _searchSiswa(String query) async {
    if (query.length < 2) return;
    setState(() => _isSearchingSiswa = true);
    try {
      final results = await _service.searchSiswa(query);
      setState(() {
        _siswaSearchResults = results;
        _isSearchingSiswa = false;
      });
    } catch (e) {
      setState(() => _isSearchingSiswa = false);
    }
  }

  void _showSiswaSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setStateSheet) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Cari Siswa', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Nama Siswa (min 2 huruf)...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () async {
                                 if (_searchController.text.length < 2) return;
                                 // We need to call search and update this sheet's state
                                 // But since _searchSiswa updates parent state, we might need a local var here or just rely on parent list
                                 // Let's implement local logic for sheet or just use parent's list
                                 // Better: use parent list but trigger rebuild of this sheet
                                 
                                 // Workaround: Call parent search, then manually call setStateSheet
                                 // This is tricky. Let's make search logic local to the sheet builder if possible?
                                 // No, let's keep it simple.
                                 
                                 // We'll mimic _searchSiswa logic here slightly for immediate feedback
                                 // Or just use the parent's function and check results
                              },
                          ),
                        ),
                        onChanged: (val) {
                          if (val.length >= 2) {
                             // Debounce manually or just search
                             _searchSiswa(val).then((_) => setStateSheet((){}));
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _isSearchingSiswa
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _siswaSearchResults.length,
                                itemBuilder: (context, index) {
                                  final s = _siswaSearchResults[index];
                                  return ListTile(
                                    title: Text(s.namaSiswa, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${s.kelas ?? "-"} | NIS: ${s.nis ?? "-"}'),
                                    onTap: () {
                                      setState(() {
                                        _selectedSiswa = s;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  void _showJenisSearchSheet(List<JenisPelanggaran> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            String query = '';
            return StatefulBuilder(
              builder: (context, setStateSheet) {
                // Filter items based on query
                final filteredItems = items.where((item) {
                  return item.namaPelanggaran.toLowerCase().contains(query.toLowerCase());
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Pilih Jenis Pelanggaran', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari jenis pelanggaran...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          setStateSheet(() => query = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(child: Text('Tidak ditemukan', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filteredItems.length,
                                separatorBuilder: (ctx, i) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final isSelected = _selectedJenis?.id == item.id;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      item.namaPelanggaran,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF0D47A1) : Colors.black87,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF0D47A1).withOpacity(0.1) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${item.poin} Poin',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedJenis = item;
                                      });
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Future<void> _submitFormat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiswa == null || _selectedKategori == null || _selectedJenis == null || _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi data')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'siswa_id': _selectedSiswa!.id,
        'kategori_pelanggaran_id': _selectedKategori!.id,
        'jenis_pelanggaran_id': _selectedJenis!.id,
        'deskripsi_pelanggaran': _deskripsiController.text,
        'tanggal_pelanggaran': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'pelapor': _pelaporController.text,
        'tindak_lanjut': _tindakLanjutController.text,
        'status_penanganan': _selectedStatus,
        'catatan': _catatanController.text,
      };

      final response = await _service.submitReport(data);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Berhasil')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Status Dropdown Items
    final statusItems = _options?.statusOptions.entries.map((e) {
      return DropdownMenuItem(value: e.key, child: Text(e.value));
    }).toList() ?? [];

    // Kategori Items
    final kategoriItems = _options?.kategori.map((e) {
      return DropdownMenuItem(value: e, child: Text(e.namaKategori));
    }).toList() ?? [];

    // Jenis Items (Filtered)
    List<DropdownMenuItem<JenisPelanggaran>> jenisItems = [];
    if (_selectedKategori != null) {
      jenisItems = _selectedKategori!.jenis.map((e) {
        return DropdownMenuItem(value: e, child: Text('${e.namaPelanggaran} (${e.poin} Poin)'));
      }).toList();
    }

    return Scaffold(
      body: Column(
        children: [
           const CustomPageHeader(title: 'Lapor Pelanggaran'), // Uniform blue header
           Expanded(
             child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Siswa Selection
              _buildLabel('Siswa'),
              InkWell(
                onTap: _showSiswaSearchSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSiswa != null ? '${_selectedSiswa!.namaSiswa} (${_selectedSiswa!.kelas})' : 'Pilih Siswa...',
                        style: GoogleFonts.plusJakartaSans(color: _selectedSiswa != null ? Colors.black : Colors.grey),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tanggal
              _buildLabel('Tanggal'),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate), style: GoogleFonts.plusJakartaSans()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kategori
              _buildLabel('Kategori Pelanggaran'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (_options?.kategori ?? []).map((kategori) {
                   final bool isSelected = _selectedKategori?.id == kategori.id;
                   return InkWell(
                     onTap: () {
                        setState(() {
                          _selectedKategori = kategori;
                          _selectedJenis = null;
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
                         kategori.namaKategori,
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

              // Jenis
              _buildLabel('Jenis Pelanggaran'),
              InkWell(
                onTap: () {
                   if (_selectedKategori == null) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Kategori terlebih dahulu')));
                     return;
                   }
                   _showJenisSearchSheet(jenisItems.map((e) => e.value as JenisPelanggaran).toList());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedJenis != null 
                             ? '${_selectedJenis!.namaPelanggaran} (${_selectedJenis!.poin} Poin)' 
                             : (_selectedKategori == null ? 'Pilih Kategori Dulu' : 'Pilih Jenis Pelanggaran...'),
                          style: GoogleFonts.plusJakartaSans(
                            color: _selectedJenis != null ? Colors.black : Colors.grey[600],
                            fontSize: 14, // Match form field
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status
              // Status (Read Only Default)
              _buildLabel('Status Penanganan'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Belum Ditangani',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fields
              _buildTextField('Deskripsi Pelanggaran', _deskripsiController, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Pelapor', _pelaporController, isReadOnly: true),
              const SizedBox(height: 16),
              _buildTextField('Tindak Lanjut', _tindakLanjutController, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField('Catatan', _catatanController, maxLines: 2),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFormat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting 
                     ? const CircularProgressIndicator(color: Colors.white)
                     : Text('Kirim Laporan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
                ),
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
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          enabled: !isReadOnly, 
          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
          decoration: _inputDecoration('Masukan $label').copyWith(
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey[200] : null,
          ),
          style: GoogleFonts.plusJakartaSans(),
        ),
      ],
    );
  }
}
