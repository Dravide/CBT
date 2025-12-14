import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cbt_app/models/pengumuman.dart';
import 'package:cbt_app/services/pengumuman_service.dart';

class PengumumanDetailPage extends StatefulWidget {
  final int id;
  const PengumumanDetailPage({super.key, required this.id});

  @override
  State<PengumumanDetailPage> createState() => _PengumumanDetailPageState();
}

class _PengumumanDetailPageState extends State<PengumumanDetailPage> {
  final PengumumanService _service = PengumumanService();
  late Future<Pengumuman> _pengumumanFuture;

  @override
  void initState() {
    super.initState();
    _pengumumanFuture = _service.getPengumumanDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pengumuman',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<Pengumuman>(
        future: _pengumumanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final item = snapshot.data!;
            final date = DateTime.tryParse(item.tanggal) ?? DateTime.now();
            final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(date);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.judul,
                    style: GoogleFonts.openSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(18, 26, 28, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Divider(height: 32),
                  HtmlWidget(
                    item.isi,
                    textStyle: GoogleFonts.openSans(fontSize: 16),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data'));
          }
        },
      ),
    );
  }
}
