import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/social_post.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:intl/intl.dart';

class SocialPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SocialPage({super.key, this.onBack});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SocialPost> _posts = SocialPost.dummyPosts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNewPost(String content, List<String> tags) {
    setState(() {
      _posts.insert(0, SocialPost(
        id: DateTime.now().toString(),
        userName: 'Siswa (Saya)', // Diambil dari real user nanti
        userHandle: '@siswa_satria',
        userAvatar: 'ME',
        className: '9A', // Diambil dari real user
        content: content,
        timestamp: DateTime.now(),
        taggedClasses: tags,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background like Twitter
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Avoid Bottom Nav overlapping
        child: FloatingActionButton(
          onPressed: () => _showCreatePostModal(context),
          backgroundColor: const Color(0xFF0D47A1),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Header
          CustomPageHeader(
            title: 'Social School',
            showBackButton: false,
            leadingIcon: Icons.tag, // Hashtag icon
          ),
          
          // Tab Bar Container
          Container(
             color: Colors.white,
             child: Column(
               children: [

                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0D47A1),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF0D47A1),
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Timeline'),
                    Tab(text: 'Class Update'),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: All Timeline
                _buildFeedList(_posts),
                
                // Tab 2: Class Updates (Filtered by User Class)
                // Filter: Posts tagged with User's Class (e.g. "9A") or "OSIS" (Global announcements usually relevant)
                _buildFeedList(_posts.where((p) {
                  final userClass = '9A'; // Mock User Class
                  return p.taggedClasses.contains(userClass) || p.taggedClasses.contains('OSIS'); 
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<SocialPost> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'Belum ada update.',
          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100), // Bottom padding for Nav
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(posts[index]);
      },
    );
  }

  Widget _buildPostCard(SocialPost post) {
    final timeAgo = _formatTimeAgo(post.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 1), // Divider thin line effect
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: _getAvatarColor(post.userName),
            radius: 20,
            child: Text(
              post.userAvatar,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Name, Handle, Time)
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (post.className == 'Guru' || post.className == 'OSIS') 
                       const Icon(Icons.verified, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${post.userHandle} · $timeAgo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Tags if any
                if (post.taggedClasses.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: post.taggedClasses.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 4),
                // Text Content
                Text(
                  post.content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Actions (Like, Comment, etc)
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showCommentsModal(context, post),
                      child: _buildActionIcon(Icons.chat_bubble_outline, post.commentCount.toString()),
                    ),
                    const SizedBox(width: 24), // Spacing between actions
                    _buildActionIcon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      post.likeCount.toString(),
                      color: post.isLiked ? Colors.pink : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo
    ];
    return colors[name.length % colors.length];
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}h';
    if (diff.inHours > 0) return '${diff.inHours}j';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Baru saja';
  }

  void _showCreatePostModal(BuildContext context) {
    final textController = TextEditingController();
    String? selectedTag; // Changed to single String
    final availableTags = ['7A', '7B', '8A', '8B', '9A', '9B', 'OSIS'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9, // Almost full screen
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            // Convert single tag to list for Model compatibility
                            final tags = selectedTag != null ? [selectedTag!] : <String>[];
                            _addNewPost(textController.text, tags);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Posting', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: Text('ME', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: textController,
                              maxLines: 5,
                              decoration: InputDecoration.collapsed(
                                hintText: 'Apa yang sedang terjadi di sekolah?',
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                              ),
                              style: GoogleFonts.plusJakartaSans(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Mention Kelas (Pilih Satu)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)), // Updated Label
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: availableTags.map((tag) {
                          final isSelected = selectedTag == tag;
                          return ChoiceChip( // Changed to ChoiceChip
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedTag = tag;
                                } else {
                                  selectedTag = null; // Toggle off
                                }
                              });
                            },
                            selectedColor: const Color(0xFF0D47A1).withOpacity(0.2), // Lighter selection
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: isSelected ? const Color(0xFF0D47A1) : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[300]!,
                              ),
                            ),
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCommentsModal(BuildContext context, SocialPost post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Komentar (${post.commentCount})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Comments List
                Expanded(
                  child: post.commentsList.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada komentar.',
                            style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: post.commentsList.length,
                          itemBuilder: (context, index) {
                            final comment = post.commentsList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _getAvatarColor(comment.userName),
                                    child: Text(
                                      comment.userAvatar,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.userName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimeAgo(comment.timestamp),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.content,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Input Field
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Tulis komentar...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D47A1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              setModalState(() {
                                post.commentsList.add(SocialComment(
                                  id: DateTime.now().toString(),
                                  userName: 'Siswa (Saya)',
                                  userAvatar: 'ME',
                                  content: commentController.text.trim(),
                                  timestamp: DateTime.now(),
                                ));
                                commentController.clear();
                              });
                              // Update Parent
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
