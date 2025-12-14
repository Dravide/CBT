import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/guru.dart';
import 'package:cbt_app/services/guru_service.dart';
import 'package:cbt_app/widgets/custom_page_header.dart'; // Import
import 'dart:async';

class GuruListPage extends StatefulWidget {
  const GuruListPage({super.key});

  @override
  State<GuruListPage> createState() => _GuruListPageState();
}

class _GuruListPageState extends State<GuruListPage> {
  final GuruService _guruService = GuruService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Guru> _gurus = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGurus();
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
          _currentPage = 1;
          _gurus.clear();
          _hasMore = true;
        });
        _loadGurus();
      }
    });
  }

  Future<void> _loadGurus() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _guruService.fetchGurus(
        query: _searchQuery,
        page: _currentPage,
      );

      final List<Guru> newGurus = result['data'];
      final int lastPage = result['last_page'];
      final int currentPage = result['current_page'];

      setState(() {
        _gurus.addAll(newGurus);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomPageHeader(title: 'Data Guru'),
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
                  hintText: 'Cari Guru...',
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
                  _loadGurus();
                }
                return false;
              },
              child: _gurus.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'Tidak ada data guru ditemukan.',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _gurus.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _gurus.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final guru = _gurus[index];
                        return _buildGuruCard(guru);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuruCard(Guru guru) {
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
              color: const Color(0xFF0D47A1).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(guru.namaGuru),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
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
                        guru.namaGuru,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (guru.isWaliKelas)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Wali Kelas',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                  ],
                ),
                if (guru.mataPelajaran != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      guru.mataPelajaran!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                if (guru.nip != null && guru.nip!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'NIP: ${guru.nip}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
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
