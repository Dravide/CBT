import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/siswa.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'dart:async';

import 'package:cbt_app/widgets/custom_page_header.dart'; // Import Header

class SiswaListPage extends StatefulWidget {
  const SiswaListPage({super.key});

  @override
  State<SiswaListPage> createState() => _SiswaListPageState();
}

class _SiswaListPageState extends State<SiswaListPage> {
  final SiswaService _siswaService = SiswaService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Siswa> _siswas = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  int? _selectedTingkat; // 7, 8, 9, or null

  @override
  void initState() {
    super.initState();
    _loadSiswas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
          _resetList();
        });
        _loadSiswas();
      }
    });
  }

  void _onFilterTingkat(int? tingkat) {
    if (_selectedTingkat != tingkat) {
      setState(() {
        _selectedTingkat = tingkat;
        _resetList();
      });
      _loadSiswas();
    }
  }

  void _resetList() {
    _currentPage = 1;
    _siswas.clear();
    _hasMore = true;
  }

  Future<void> _loadSiswas() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _siswaService.fetchSiswas(
        query: _searchQuery,
        tingkat: _selectedTingkat,
        page: _currentPage,
      );

      final List<Siswa> newSiswas = result['data'];
      final int lastPage = result['last_page'];
      final int currentPage = result['current_page'];

      setState(() {
        _siswas.addAll(newSiswas);
        _lastPage = lastPage;
        _currentPage = currentPage;
        _hasMore = _currentPage < _lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tingkat Kelas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Semua Tingkat'),
                leading: Radio<int?>(
                  value: null,
                  groupValue: _selectedTingkat,
                  onChanged: (val) {
                    Navigator.pop(context);
                    _onFilterTingkat(val);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _onFilterTingkat(null);
                },
              ),
              ListTile(
                title: const Text('Kelas 7'),
                leading: Radio<int?>(
                  value: 7,
                  groupValue: _selectedTingkat,
                  onChanged: (val) {
                    Navigator.pop(context);
                    _onFilterTingkat(val);
                  },
                ),
                 onTap: () {
                  Navigator.pop(context);
                  _onFilterTingkat(7);
                },
              ),
              ListTile(
                title: const Text('Kelas 8'),
                leading: Radio<int?>(
                  value: 8,
                  groupValue: _selectedTingkat,
                  onChanged: (val) {
                    Navigator.pop(context);
                    _onFilterTingkat(val);
                  },
                ),
                 onTap: () {
                  Navigator.pop(context);
                  _onFilterTingkat(8);
                },
              ),
              ListTile(
                title: const Text('Kelas 9'),
                leading: Radio<int?>(
                  value: 9,
                  groupValue: _selectedTingkat,
                  onChanged: (val) {
                    Navigator.pop(context);
                    _onFilterTingkat(val);
                  },
                ),
                 onTap: () {
                  Navigator.pop(context);
                  _onFilterTingkat(9);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomPageHeader(
            title: 'Data Siswa',
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list, color: _selectedTingkat != null ? Colors.amber : Colors.white),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          
          // Search Bar moved to body
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Siswa...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    _hasMore &&
                    scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  setState(() {
                    _currentPage++;
                  });
                  _loadSiswas();
                }
                return false;
              },
              child: _siswas.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'Tidak ada data siswa ditemukan.',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _siswas.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _siswas.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final siswa = _siswas[index];
                        return _buildSiswaCard(siswa);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiswaCard(Siswa siswa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.indigo.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(siswa.namaSiswa),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        siswa.namaSiswa,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (siswa.className != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          siswa.className!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                 if (siswa.nis != null)
                Text(
                  'NIS: ${siswa.nis}',
                   style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (siswa.status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Status: ${siswa.status!}',
                       style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: siswa.status == 'aktif' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
