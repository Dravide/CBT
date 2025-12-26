import 'package:cbt_app/widgets/skeleton_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/social_post.dart';
import 'package:cbt_app/services/social_service.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/pages/social_widgets.dart'; // Shared Widgets
import 'package:cbt_app/widgets/top_snack_bar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/pages/profile_page.dart'; // Import ProfilePage
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';

class SocialPage extends StatefulWidget {
  final VoidCallback? onBack;

  const SocialPage({super.key, this.onBack});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SocialService _socialService = SocialService();
  
  // Data State
  List<SocialPost> _posts = [];
  List<SocialPost> _classPosts = []; // Separate list for class updates
  bool _isLoading = true;
  bool _isLoadingClass = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _userClassName;
  String? _currentUserNis;
  
  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserClass();
    _loadTimeline();
  }

  // ... existing ...

  Future<void> _loadUserClass() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userClassName = prefs.getString('user_class_name');
      _currentUserNis = prefs.getString('user_nis');
    });
    // Load class feed if we have the class name
    if (_userClassName != null) {
      _loadClassTimeline();
    }
  }
  
  Future<void> _loadTimeline({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _posts.clear();
    }

    try {
      if (_currentPage == 1) setState(() => _isLoading = true);

      // Pass search query if searching
      final searchQuery = _isSearching ? _searchController.text : null;

      final response = await _socialService.getTimeline(
        page: _currentPage,
        search: searchQuery
      );
      
      if (mounted) {
        setState(() {
          if (refresh) {
             _posts = response.posts;
          } else {
             _posts.addAll(response.posts);
          }
          _lastPage = response.lastPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Don't show snackbar on init if not critical, or show only debug
        print('Error loading timeline: $e'); 
      }
    }
  }

  void _onSearchSubmitted(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
    });
    _loadTimeline(refresh: true);
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _loadTimeline(refresh: true); // Reset to all
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _loadClassTimeline() async {
    if (_userClassName == null) return;
    try {
      setState(() => _isLoadingClass = true);
      final response = await _socialService.getTimeline(page: 1, classFilter: _userClassName);
      if (mounted) {
        setState(() {
          _classPosts = response.posts;
          _isLoadingClass = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClass = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadTimeline();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createPostUI(String content, List<String> tags, {File? image}) async { // Updated signature
     // This method solely handles the Logic + State Update. UI (Dialogs) are handled by caller.
    try {
      final newPost = await _socialService.createPost(content, tags, image: image);
      
      if (mounted) {
        setState(() {
          _posts.insert(0, newPost);
        });
        showTopSnackBar(context, 'Status terkirim!', backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
         showTopSnackBar(context, 'Gagal kirim: $e', backgroundColor: Colors.red);
      }
      rethrow; // Re-throw so caller knows it failed
    }
  }

  Future<void> _updatePostUI(String postId, String content, List<String> tags, {File? image, SocialPost? oldPost}) async {
    try {
      final updatedPost = await _socialService.updatePost(postId, content, tags, image: image);
      
      if (mounted) {
        setState(() {
          final index = _posts.indexWhere((p) => p.id == postId);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
           // Also update class posts if present
          final indexClass = _classPosts.indexWhere((p) => p.id == postId);
          if (indexClass != -1) {
            _classPosts[indexClass] = updatedPost;
          }
        });
        showTopSnackBar(context, 'Postingan diperbarui!', backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
         showTopSnackBar(context, 'Gagal update: $e', backgroundColor: Colors.red);
      }
      rethrow;
    }
  }

  Future<void> _toggleLike(SocialPost post) async {
    // Optimistic Update
    setState(() {
      post.isLiked = !post.isLiked;
      post.likeCount += post.isLiked ? 1 : -1;
    });

    try {
      await _socialService.toggleLike(post.id);
      // Success, do nothing as UI is already updated
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          post.isLiked = !post.isLiked;
           post.likeCount += post.isLiked ? 1 : -1;
        });
        showTopSnackBar(context, 'Gagal like', backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), 
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
            leadingIcon: Icons.tag,
            // Add Search Toggle
            actionIcon: _isSearching ? Icons.close : Icons.search,
            onActionPressed: _toggleSearch,
          ),
          
          // Search Bar (Visible only when searching)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onSubmitted: _onSearchSubmitted,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari postingan...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
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
                _buildFeedView(),
                
                // Tab 2: Class Updates
                _isLoadingClass 
                   ? _buildSkeletonFeed()
                   : _buildClassFeedView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassFeedView() {
    if (_userClassName == null) {
      return Center(child: Text("Data kelas tidak ditemukan.", style: GoogleFonts.plusJakartaSans()));
    }
    
    if (_classPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada update untuk kelas $_userClassName.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            TextButton(
              onPressed: _loadClassTimeline, 
              child: const Text('Refresh'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassTimeline,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: _classPosts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_classPosts[index]);
        },
      ),
    );
  }

  Widget _buildFeedView() {
    if (_isLoading && _posts.isEmpty) return _buildSkeletonFeed();

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Belum ada update.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
            TextButton(
              onPressed: () => _loadTimeline(refresh: true), 
              child: const Text('Refresh'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTimeline(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        itemCount: _posts.length + 1, // +1 for loader
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return _currentPage < _lastPage 
               ? Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Center(
                     child: ElevatedButton(
                       onPressed: _loadMore,
                       child: _isLoadingMore 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                         : const Text('Muat Lebih Banyak'),
                     ),
                   ),
                 )
               : const SizedBox.shrink();
          }
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }

  Widget _buildSkeletonFeed() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 150,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(SocialPost post) {
    return SocialPostCard(
      post: post,
      onTap: () => _showPostDetailPopup(context, post), // Single Tap -> Detail Popup
      onLike: () => _toggleLike(post),
      onComment: () => _showCommentsModal(context, post),
      onLongPress: (p) => _showPostOptions(context, p), // Long Press -> Bottom Sheet Options
      onProfileTap: () {
         if (post.authorNis != null) {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => ProfilePage(
                 otherUserNis: post.authorNis,
                 otherUserRole: post.authorType, // Pass authorType
               ),
             ),
           );
         } else {
           showTopSnackBar(context, 'Profil tidak ditemukan', backgroundColor: Colors.red);
         }
      },
    );
  }

  // ... (existing helper methods like _buildActionIcon, _getAvatarColor, _formatTimeAgo) ...

  // MODALS
  void _showPostDetailPopup(BuildContext context, SocialPost post) async {
    final result = await showDialog(
      context: context,
      builder: (context) => PostDetailDialog( // Use shared widget
        post: post, 
        currentUserNis: _currentUserNis
      ),
    );

    if (result == true && mounted) {
       // Post was deleted, refresh timeline
       _loadTimeline(refresh: true);
       // Use addPostFrameCallback to ensure context is valid after dialog closes
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           showTopSnackBar(context, 'Postingan dihapus', backgroundColor: Colors.green);
         }
       });
    }
  }
  
  void _showPostOptions(BuildContext context, SocialPost post) {
    // Check ownership
    // Note: If using strict NIS ownership:
    final isMyPost = post.authorNis != null && post.authorNis == _currentUserNis; 
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.visibility, size: 20),
              title: Text('Lihat Detail', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _showPostDetailPopup(context, post);
              },
            ),
            if (isMyPost) ...[
               ListTile(
                dense: true,
                leading: const Icon(Icons.edit, size: 20),
                title: Text('Edit Postingan', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostModal(context, post);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete, color: Colors.red, size: 20),
                title: Text('Hapus Postingan', style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 14)),
                onTap: () {
                   Navigator.pop(context);
                   _confirmDeletePost(context, post);
                },
              ),
            ] else 
              ListTile(
                dense: true,
                leading: const Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                title: Text('Laporkan', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  showTopSnackBar(context, 'Laporan dikirim', backgroundColor: Colors.green);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(BuildContext _, SocialPost post) async {
     // Use the widget's context, not the passed one (which may be from closed bottom sheet)
     final confirm = await showDialog<bool>(
       context: context,  // Use widget context
       builder: (dialogContext) => AlertDialog(
         title: const Text('Hapus Postingan?'),
         content: const Text('Tindakan ini tidak dapat dibatalkan.'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
           TextButton(
              onPressed: () => Navigator.pop(dialogContext, true), 
              child: const Text('Hapus', style: TextStyle(color: Colors.red))
           ),
         ],
       ),
     );
     
     if (confirm == true) {
        try {
          await _socialService.deletePost(post.id);
          _loadTimeline(refresh: true);
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showTopSnackBar(context, 'Postingan berhasil dihapus!', backgroundColor: Colors.green);
            });
          }
        } catch (e) {
          if (mounted) showTopSnackBar(context, 'Gagal hapus: $e', backgroundColor: Colors.red);
        }
     }
  }

  void _showEditPostModal(BuildContext context, SocialPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheetContent(
        initialContent: post.content,
        initialTags: post.taggedClasses,
        // Image editing: If URL exists, we might need to handle showing it or replacing it.
        // For now, simpler implementation: passing available tags and handling submission
        onSubmit: (content, tags, {image}) => _updatePostUI(post.id, content, tags, image: image, oldPost: post),
        availableTags: const [],
        isEditing: true,
      ),
    );
  }

  // ... (existing modals _showCreatePostModal, _showCommentsModal) ...


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

  void _showCreatePostModal(BuildContext context) {
    // ... code ...
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheetContent(
        onSubmit: (content, tags, {image}) => _createPostUI(content, tags, image: image),
        availableTags: const [], 
      ),
    );
  }

  void _showCommentsModal(BuildContext context, SocialPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsModal(
        postId: post.id,
        onCommentAdded: () {
          setState(() {
            post.commentCount++;
          });
        },
      ),
    );
  }
}

class _CreatePostSheetContent extends StatefulWidget {
  final Future<void> Function(String, List<String>, {File? image}) onSubmit; // Updated signature
  final List<String> availableTags;
  final String? initialContent;
  final List<String>? initialTags;
  final bool isEditing;

  const _CreatePostSheetContent({
    required this.onSubmit, 
    required this.availableTags, 
    this.initialContent,
    this.initialTags,
    this.isEditing = false,
  });

  @override
  State<_CreatePostSheetContent> createState() => _CreatePostSheetContentState();
}

class _CreatePostSheetContentState extends State<_CreatePostSheetContent> {
  late TextEditingController _textController;
  final _searchController = TextEditingController(); // For tag search
  
  // Selected tags AND Image
  List<String> _selectedTags = [];
  File? _selectedImage; // Newly added
  bool _isPosting = false;

  // Full list of available tags
  final List<String> _allTags = [
    // ... existing tags ...
    ...['7A','7B','7C','7D','7E','7F','7G','7H','7I','7J','7K'],
    ...['8A','8B','8C','8D','8E','8F','8G','8H','8I','8J','8K'],
    ...['9A','9B','9C','9D','9E','9F','9G','9H','9I','9J','9K'],
    'OSIS', 'EKSKUL', 'DEFAULT'
  ];

  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialContent ?? '');
    if (widget.initialTags != null) {
      _selectedTags.addAll(widget.initialTags!);
    }
    _filteredTags = [];
    _searchController.addListener(_onSearchChanged);
  }

  // ... dispose ...
  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toUpperCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTags = [];
      } else {
        _filteredTags = _allTags.where((tag) => 
          tag.contains(query) && !_selectedTags.contains(tag)
        ).toList();
      }
    });
  }

  void _submit() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return; // Allow image only?
    
    setState(() => _isPosting = true);
    
    try {
      await widget.onSubmit(_textController.text, _selectedTags, image: _selectedImage);
      
      if (mounted) {
         Navigator.pop(context); // Close only on success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _searchController.clear(); 
        _filteredTags = [];
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Compress and convert to WebP
      final compressedFile = await _compressToWebP(File(pickedFile.path));
      setState(() {
        _selectedImage = compressedFile ?? File(pickedFile.path);
      });
    }
  }

  Future<File?> _compressToWebP(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.webp,
        quality: 80, // 80% quality for good balance
        minWidth: 1080,
        minHeight: 1080,
      );
      
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null; // Return null, original will be used
    }
  }

  @override
  Widget build(BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _isPosting ? null : () => Navigator.pop(context),
                      child: Text(
                       'Batal', 
                       style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 16)
                      ),
                    ),
                    Text(
                      widget.isEditing ? 'Edit Postingan' : 'Buat Postingan',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: _isPosting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        disabledBackgroundColor: const Color(0xFF0D47A1).withOpacity(0.6),
                      ),
                      child: _isPosting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                             widget.isEditing ? 'Simpan' : 'Posting',
                             style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Profile & Input
                Expanded( // Use Expanded to allow scrolling or just taking up space
                 child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue,
                            child: Text('ME', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null, // Auto expand
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.5),
                              decoration: InputDecoration.collapsed(
                                hintText: 'Apa yang sedang terjadi di sekolah?',
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Filtered Image Preview
                      if (_selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedImage = null),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                 ),
                ),
                
                const Divider(),
                
                // Action Bar (Image + Tags)
                Row(
                  children: [
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, color: Color(0xFF0D47A1)),
                      tooltip: 'Tambah Gambar',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tag Kelas:',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),

                // Selected Tags Display
                if (_selectedTags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(tag, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white)),
                        backgroundColor: const Color(0xFF0D47A1),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onDeleted: () => _removeTag(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.all(4),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 8),

                // Search Box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari & pilih kelas (misal: 7A)...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),

                // Suggestions List
                if (_filteredTags.isNotEmpty)
                  Container(
                    height: 120, // Limited height for suggestions
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];
                        return ListTile(
                          title: Text(tag, style: GoogleFonts.plusJakartaSans()),
                          onTap: () => _addTag(tag),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                
                // Keyboard spacer
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
              ],
            ),
          );
  }
}




class _CommentsModal extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const _CommentsModal({required this.postId, required this.onCommentAdded});

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  final _service = SocialService();
  final _controller = TextEditingController();
  List<SocialComment> _comments = [];
  bool _loading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final data = await _service.getComments(widget.postId);
      // Sort Oldest -> Newest
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (mounted) setState(() { _comments = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    try {
      final newComment = await _service.postComment(widget.postId, _controller.text);
      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _controller.clear();
          _isPosting = false;
        });
        widget.onCommentAdded(); // Notify parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal kirim komentar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Komentar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),

            // List
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty 
                    ? Center(child: Text('Belum ada komentar', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) => _buildCommentItem(_comments[i]),
                      ),
            ),
            
            // Input Area
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Tulis balasan...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D47A1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isPosting 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                      onPressed: _isPosting ? null : _postComment,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
  }

  Widget _buildCommentItem(SocialComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: Text(
               comment.userName.isNotEmpty ? comment.userName[0] : '?',
               style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),

                    Text(
                      _formatTime(comment.timestamp.toLocal()),
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[800], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    return '${diff.inDays}h';
  }
}

