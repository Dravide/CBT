import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/widgets/top_snack_bar.dart';
import 'package:cbt_app/models/pengumuman.dart';
import 'package:cbt_app/services/pengumuman_service.dart';
import 'package:cbt_app/pages/pengumuman_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class InfoPage extends StatefulWidget {
  final VoidCallback? onBack;

  const InfoPage({super.key, this.onBack});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
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
        // Client-side sort to ensure newest first
        _announcements.sort((a, b) {
           final dateA = DateTime.tryParse(a.createdAt) ?? DateTime.now();
           final dateB = DateTime.tryParse(b.createdAt) ?? DateTime.now();
           return dateB.compareTo(dateA);
        });
        
        if (response.meta != null) {
          _hasMore = response.meta!.currentPage < response.meta!.lastPage;
          _currentPage++;
        } else {
          _hasMore = false;
        }
      });
    } catch (e) {
      showTopSnackBar(context, 'Error loading announcements: $e', backgroundColor: Colors.red);
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
    return Column(
      children: [
        CustomPageHeader(
          title: 'Pengumuman',
          onBack: widget.onBack,
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
            child: _announcements.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _announcements.isEmpty && !_isLoading
                    ? Center(
                        child: Text(
                          'Tidak ada pengumuman.',
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showAnnouncementDetail(context, item.id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D47A1).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.campaign, color: Color(0xFF0D47A1), size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item.judul,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: const Color(0xFF1F2937),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item.isi,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            formattedDate,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
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
    );
  }

  void _showAnnouncementDetail(BuildContext context, int id) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<Pengumuman>(
            future: _service.getPengumumanDetail(id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final item = snapshot.data!;
                final date = DateTime.tryParse(item.tanggal) ?? DateTime.now();
                final formattedDate =
                    DateFormat('EEEE, dd MMMM yyyy').format(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item.judul,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(18, 26, 28, 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: HtmlWidget(
                          item.isi,
                          textStyle:
                              GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return const Center(child: Text('No data'));
              }
            },
          ),
        ),
      ),
    );
  }
}
