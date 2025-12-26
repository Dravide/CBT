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
      backgroundColor: Colors.grey[50], // Light background
      body: Column(
        children: [
          // Custom Header Lookalike (since we are inside Scaffold, we build it manually or use SafeArea)
          Container(
            padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Pengumuman',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _announcements.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                await _fetchAnnouncements();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
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
                  final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PengumumanDetailPage(id: item.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50], // Soft Blue Badge
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          formattedDate,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.judul,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF1F2937),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.isi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
