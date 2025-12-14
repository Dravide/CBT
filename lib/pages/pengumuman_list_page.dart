import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cbt_app/models/pengumuman.dart';
import 'package:cbt_app/services/pengumuman_service.dart';
import 'package:cbt_app/pages/pengumuman_detail_page.dart';

class PengumumanListPage extends StatefulWidget {
  const PengumumanListPage({super.key});

  @override
  State<PengumumanListPage> createState() => _PengumumanListPageState();
}

class _PengumumanListPageState extends State<PengumumanListPage> {
  final PengumumanService _service = PengumumanService();
  final List<Pengumuman> _announcements = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchAnnouncements();
      }
    });
  }

  Future<void> _fetchAnnouncements() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.getPengumuman(page: _currentPage);
      setState(() {
        _announcements.addAll(response.data);
        if (response.meta != null) {
          _hasMore = response.meta!.currentPage < response.meta!.lastPage;
          _currentPage++;
        } else {
          _hasMore = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading announcements: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengumuman',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _announcements.clear();
            _currentPage = 1;
            _hasMore = true;
          });
          await _fetchAnnouncements();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _announcements.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _announcements.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final item = _announcements[index];
            final date = DateTime.tryParse(item.tanggal) ?? DateTime.now();
            final formattedDate = DateFormat('dd MMM yyyy').format(date);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  item.judul,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.isi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PengumumanDetailPage(id: item.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
