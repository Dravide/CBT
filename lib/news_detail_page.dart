import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> post;

  const NewsDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final String title = post['title']['rendered'] ?? 'No Title';
    final String htmlContent = post['content']['rendered'] ?? '';
    final String dateStr = post['date'] ?? '';
    
    DateTime? date = DateTime.tryParse(dateStr);
    final String formattedDate = date != null ? DateFormat('EEEE, dd MMMM yyyy').format(date) : '';

    String? imageUrl;
    try {
      if (post['_embedded'] != null && 
          post['_embedded']['wp:featuredmedia'] != null && 
          post['_embedded']['wp:featuredmedia'].isNotEmpty) {
        imageUrl = post['_embedded']['wp:featuredmedia'][0]['source_url'];
      }
    } catch (e) {
      // Ignore image error
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFF1565C0),
                      child: const Center(
                        child: Icon(Icons.article, size: 80, color: Colors.white54),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1),
                  HtmlWidget(
                    htmlContent,
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: const Color(0xFF374151),
                      height: 1.6,
                    ),
                    onTapUrl: (url) {
                      // Handle link taps if necessary, or let them open in browser
                      return true; 
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
