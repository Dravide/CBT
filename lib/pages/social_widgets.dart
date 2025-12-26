
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/social_post.dart';
import 'package:cbt_app/services/social_service.dart';
import 'package:intl/intl.dart';

// --- SHARED WIDGET: POST CARD ---
class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final Function(SocialPost) onLongPress;
  final VoidCallback? onProfileTap; // Added callback

  const SocialPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onComment,
    required this.onLongPress,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(post.timestamp);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: () => onLongPress(post),
          onTap: onTap, 
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Avatar, Name, Actions)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: CircleAvatar(
                          backgroundColor: _getAvatarColor(post.userName),
                          radius: 20,
                          child: Text(
                            post.userAvatar ?? post.userName.substring(0, 1),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
                              Flexible(
                                child: Text(
                                  post.userName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, 
                                    fontSize: 15,
                                    color: Colors.black87
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.authorType == 'guru') ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 16, color: Colors.blue),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              if (post.className.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100], 
                                    borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Text(
                                    post.className, 
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold)
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '@${post.userHandle}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 6),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(timeAgo, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                              if (post.isEdited)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text('(edit)', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Content
                Text(
                  post.content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, 
                    height: 1.5,
                    color: const Color(0xFF374151), // Grey 700
                  ),
                ),
                
                // Image
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade100),
                          color: Colors.grey[50],
                        ),
                        child: Image.network(
                          post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                
                // Tags
                if (post.taggedClasses.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: post.taggedClasses.map((t) => Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.blue[50], 
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.blue[100]!)
                       ),
                       child: Text('#$t', style: GoogleFonts.plusJakartaSans(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.bold)),
                     )).toList(),
                   )
                ],

                const SizedBox(height: 20),
                Divider(height: 1, color: Colors.grey[100]),
                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onComment,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.grey[600]), // Modern icon
                            const SizedBox(width: 6),
                            Text(
                              post.commentCount > 0 ? '${post.commentCount}' : 'Komentar', 
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, // Modern icon
                              size: 20,
                              color: post.isLiked ? const Color(0xFFEF4444) : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              post.likeCount > 0 ? '${post.likeCount}' : 'Suka', 
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, 
                                color: post.isLiked ? const Color(0xFFEF4444) : Colors.grey[600],
                                fontWeight: FontWeight.w600
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {}, // Share or Bookmark
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.share_outlined, size: 20, color: Colors.grey[400]),
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
  }

  Widget _buildActionIcon(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color ?? Colors.grey[600])),
      ],
    );
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.blue;
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange];
    return colors[name.length % colors.length];
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}h';
    if (diff.inHours > 0) return '${diff.inHours}j';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Baru saja';
  }
}

// --- SHARED WIDGET: POST DETAIL DIALOG ---
class PostDetailDialog extends StatefulWidget {
  final SocialPost post;
  final String? currentUserNis;

  const PostDetailDialog({super.key, required this.post, this.currentUserNis});

  @override
  State<PostDetailDialog> createState() => _PostDetailDialogState();
}

class _PostDetailDialogState extends State<PostDetailDialog> {
  final _service = SocialService();
  final _controller = TextEditingController();
  List<SocialComment> _comments = [];
  bool _loading = true;
  bool _isPosting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final data = await _service.getComments(widget.post.id);
      // Sort: Oldest first (Newest at bottom)
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (mounted) setState(() { _comments = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ...



  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    try {
      final newComment = await _service.postComment(widget.post.id, _controller.text);
      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _controller.clear();
          _isPosting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal kirim komentar')));
      }
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
             onPressed: () => Navigator.pop(context, true), 
             child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _service.deletePost(widget.post.id);
        if (mounted) Navigator.pop(context, true); // Return true to signal deletion
      } catch (e) {
        if (mounted) {
           setState(() => _isDeleting = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
        }
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
             onPressed: () => Navigator.pop(context, true), 
             child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
       // We don't have a specific loading state per comment item yet, 
       // but we can set a global or local one. For simplicity, just optimistic update.
       final previousComments = List<SocialComment>.from(_comments);
       setState(() {
         _comments.removeWhere((c) => c.id == commentId);
         // Update post comment count optimistically?
         widget.post.commentCount = (widget.post.commentCount > 0) ? widget.post.commentCount - 1 : 0;
       });
       
       try {
         await _service.deleteComment(widget.post.id, commentId);
       } catch (e) {
         if (mounted) {
           setState(() {
              _comments = previousComments; // Revert
              widget.post.commentCount++;
           });
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus komentar: $e')));
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = widget.currentUserNis != null && widget.post.authorNis == widget.currentUserNis;

    return Dialog(
      backgroundColor: Colors.white, // Light Background
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7), // Compact
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue,
                        child: Text(widget.post.userName[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(widget.post.userName, style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                              if (widget.post.authorType == 'guru') ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 14, color: Colors.blue),
                              ],
                            ],
                          ),
                          Text(widget.post.userHandle, style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 11)),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      if (isMyPost)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: _isDeleting 
                             ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                             : const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: _isDeleting ? null : _deletePost,
                        ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.black54, size: 22),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Divider(color: Colors.grey[100], height: 1),
            
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator()) 
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The Post Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.post.isEdited)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('Diedit: ${DateFormat('dd MMM HH:mm').format(widget.post.updatedAt?.toLocal() ?? DateTime.now())}', 
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                                ),
                              
                              Text(
                                widget.post.content, 
                                style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 15, height: 1.4)
                              ),
                              
                              if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.post.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                       errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                
                              if (widget.post.taggedClasses.isNotEmpty) ...[
                                 const SizedBox(height: 10),
                                 Wrap(
                                   spacing: 6,
                                   children: widget.post.taggedClasses.map((t) => Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                     decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(4)),
                                     child: Text('#$t', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.bold)),
                                   )).toList(),
                                 )
                              ],

                              const SizedBox(height: 16),
                              
                              // Like & Comment Stats
                              Row(
                                children: [
                                  Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${widget.post.likeCount} Suka', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 12)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.chat_bubble, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${widget.post.commentCount} Komentar', style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        Divider(color: Colors.grey[200], height: 8, thickness: 8),
                        
                        // Comments Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text('Komentar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),

                        // Comments List
                        if (_comments.isEmpty)
                           Padding(
                             padding: const EdgeInsets.all(24.0),
                             child: Center(
                               child: Column(
                                 children: [
                                   Icon(Icons.chat_bubble_outline, size: 32, color: Colors.grey[300]),
                                   const SizedBox(height: 8),
                                   Text('Belum ada komentar', style: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 12)),
                                 ],
                               )
                             ),
                           )
                        else
                           ListView.builder(
                             shrinkWrap: true,
                             physics: const NeverScrollableScrollPhysics(),
                             itemCount: _comments.length,
                             itemBuilder: (context, index) {
                               final c = _comments[index];
                               final isMyComment = widget.currentUserNis != null && 
                                                   c.authorNis != null && 
                                                   c.authorNis == widget.currentUserNis;

                               return Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 child: Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     CircleAvatar(
                                       radius: 12,
                                       backgroundColor: Colors.grey[200],
                                       child: Text(c.userName[0], style: TextStyle(color: Colors.grey[800], fontSize: 10, fontWeight: FontWeight.bold)),
                                     ),
                                     const SizedBox(width: 10),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             children: [
                                               Text(c.userName, style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                               const SizedBox(width: 6),
                                               Text(
                                                 DateFormat('HH:mm').format(c.timestamp.toLocal()), 
                                                 style: const TextStyle(color: Colors.grey, fontSize: 10)
                                               ),
                                             ],
                                           ),
                                           const SizedBox(height: 2),
                                           Text(c.content, style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontSize: 12, height: 1.3)),
                                         ],
                                       ),
                                     ),
                                     if (isMyComment)
                                       InkWell(
                                         onTap: () => _deleteComment(c.id),
                                         child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                       )
                                   ],
                                 ),
                               );
                             },
                           ),
                         const SizedBox(height: 16),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
