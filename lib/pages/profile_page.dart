import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/pages/login_page.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/services/guru_service.dart';
import 'package:cbt_app/models/guru.dart';

import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/models/siswa.dart';
import 'package:cbt_app/pages/settings_page.dart';
import 'package:cbt_app/pages/about_page.dart';
import 'package:cbt_app/models/social_post.dart';
import 'package:cbt_app/services/social_service.dart'; 
import 'package:cbt_app/pages/social_widgets.dart'; // Shared Widgets
import 'package:cbt_app/widgets/skeleton_loading.dart';
import 'package:shimmer/shimmer.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  final String? otherUserNis; // Optional: If set, view this user's profile
  final String? otherUserRole; // Optional: To distinguish Guru vs Siswa

  const ProfilePage({super.key, this.onBack, this.otherUserNis, this.otherUserRole}); // Updated constructor

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final SiswaService _siswaService = SiswaService();
  final GuruService _guruService = GuruService(); // Add Service
  final SocialService _socialService = SocialService();
  
  bool _isLoading = true;
  bool _isLoadingPosts = false;
  Siswa? _siswa;
  Guru? _guru; // Add Guru Model
  bool _isTeacher = false; // Add Role flag
  String? _errorMessage;
  late TabController _tabController;
  List<SocialPost> _myPosts = [];
  bool _isMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? nis = prefs.getString('user_nis');
      String? role = prefs.getString('user_role'); // Check role
      
      String? targetNis;

      if (widget.otherUserNis != null) {
         targetNis = widget.otherUserNis;
         _isMe = (widget.otherUserNis == nis);
         
         if (widget.otherUserRole != null) {
            // Explicit role passed
            _isTeacher = (widget.otherUserRole == 'guru');
         } else {
            // Fallback: If no role passed, assume student (Legacy behavior)
            _isTeacher = false; 
         }

      } else {
         targetNis = nis;
         _isMe = true;
         _isTeacher = (role == 'guru');
      }

      // Update UI immediately with role info before fetching data
      if (mounted) setState(() {});

      if (targetNis == null) {
        if (mounted) setState(() { _errorMessage = 'Sesi habis'; _isLoading = false; });
        return;
      }

      // LOAD BASED ON ROLE
      bool tryGuruFirst = _isTeacher;

      // Helper function to try loading Guru
      Future<bool> loadGuru() async {
        try {
          final result = await _guruService.fetchGurus(query: targetNis);
          final List<Guru> gurus = result['data'];
          if (gurus.isEmpty) return false;
          
          final Guru match = gurus.firstWhere((g) => g.nip == targetNis, orElse: () => throw Exception("Not found"));
          if (mounted) {
            setState(() {
              _guru = match;
              _siswa = null;
              _isTeacher = true; // Update state to reflect reality
              _isLoading = false;
            });
            _loadMyPosts(match.id, match.nip);
          }
          return true;
        } catch (e) {
          return false;
        }
      }

      // Helper function to try loading Siswa
      Future<bool> loadSiswa() async {
        try {
          final result = await _siswaService.fetchSiswas(query: targetNis);
          final List<Siswa> siswas = result['data'];
          if (siswas.isEmpty) return false;

          final Siswa match = siswas.firstWhere((s) => s.nis == targetNis, orElse: () => throw Exception("Not found"));
          if (mounted) {
            setState(() {
              _siswa = match;
              _guru = null;
              _isTeacher = false; // Update state to reflect reality
              _isLoading = false;
            });
            _loadMyPosts(match.id, match.nis);
          }
          return true;
        } catch (e) {
          return false;
        }
      }

      // Execute Strategy
      bool found = false;
      if (tryGuruFirst) {
        found = await loadGuru();
        if (!found) found = await loadSiswa();
      } else {
        found = await loadSiswa();
        if (!found) found = await loadGuru();
      }

      if (!found) {
         if (mounted) setState(() { _errorMessage = 'User tidak ditemukan'; _isLoading = false; });
      }

    } catch (e) {
       if (mounted) setState(() { _errorMessage = 'Gagal load: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadMyPosts(int userId, String? userNis) async {
    if (userNis == null) return;
    setState(() => _isLoadingPosts = true);
    try {
      final response = await _socialService.getTimeline(
        page: 1, 
        userFilter: userNis,
        userFilterType: _isTeacher ? 'guru' : 'siswa',
      );
      if (mounted) {
        setState(() {
          var filteredPosts = response.posts.where((p) => 
            p.authorNis == userNis || 
            p.userHandle == '@$userNis' ||
            p.userHandle == userNis
          ).toList();
          
          if (_isTeacher) {
            _myPosts = filteredPosts.map((p) => p.copyWith(authorType: 'guru')).toList();
          } else {
            _myPosts = filteredPosts;
          }
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          CustomPageHeader(
            title: _isTeacher ? 'Profil Guru' : 'Profil Siswa',
            showBackButton: !_isMe,
            leadingIcon: Icons.person_rounded,
            onBack: widget.onBack,
          ),
          Expanded(
            child: _isLoading 
              ? _buildSkeleton()
              : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
     if (_errorMessage != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: GoogleFonts.plusJakartaSans(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              )
            ],
          ),
        );
     }
     
     final String name = _isTeacher ? (_guru?.namaGuru ?? '') : (_siswa?.namaSiswa ?? '');
     final String idNumber = _isTeacher ? (_guru?.nip ?? '-') : (_siswa?.nis ?? 'user');
     final String initial = name.isNotEmpty ? name[0] : '?';

     return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // 1. Avatar Section
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFF5F5F5),
                        backgroundImage: null,
                        child: Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 40, 
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 2. Name & Role
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isTeacher ? 'NIP. $idNumber' : 'NIS. $idNumber',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // 3. Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.03),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           ) 
                        ],
                      ),
                      child: _buildStatsRow(),
                    ),
                    
                    // 4. Action Buttons
                    if (_isMe) ...[
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ],
                ),
              ),
            ),
            
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1565C0),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF1565C0),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Postingan'),
                    Tab(text: 'Info Detail'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
             _buildPostsTab(),
             _buildInfoTab(),
          ],
        ),
     );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const SkeletonLoading(width: 80, height: 80, borderRadius: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: const [
                      SkeletonLoading(width: 150, height: 20),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Text('Edit Profil', style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Text('Tentang', style: GoogleFonts.plusJakartaSans(color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red[100]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.red[50],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.logout, size: 20, color: Colors.red),
            onPressed: _logout,
          ),
        )
      ],
    );
  }

  Widget _buildPostsTab() {
      if (_isLoadingPosts) {
         return const Center(child: CircularProgressIndicator());
      }
      if (_myPosts.isEmpty) {
         return Center(child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.feed_outlined, size: 50, color: Colors.grey[300]),
             const SizedBox(height: 10),
             Text('Belum ada postingan', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
           ],
         ));
      }
      return ListView.builder(
           padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
           itemCount: _myPosts.length,
           itemBuilder: (context, index) => _buildPostCard(_myPosts[index]),
      );
  }

  Widget _buildStatsRow() {
    if (_isTeacher && _guru != null) {
       return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Postingan', _myPosts.length.toString()),
          _buildStatItem('Siswa Ajar', _guru!.siswaCount.toString()),
          _buildStatItem('Status', 'Guru'),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Postingan', _myPosts.length.toString()),
        _buildStatItem('Kelas', _siswa?.className ?? '-'),
        _buildStatItem('Status', _siswa?.status ?? 'Aktif'),
      ],
    );
  }

  Widget _buildInfoTab() {
    if (_isTeacher && _guru != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildInfoRow('NIP', _guru!.nip ?? '-'),
             _buildInfoRow('Email', _guru!.email ?? '-'),
             _buildInfoRow('Telepon', _guru!.telepon ?? '-'),
             if (_guru!.isWaliKelas)
               _buildInfoRow('Tugas Tambahan', 'Wali Kelas'),
             _buildInfoRow('Mata Pelajaran', _guru!.mataPelajaran ?? '-'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildInfoRow('NIS', _siswa?.nis ?? '-'),
           _buildInfoRow('NISN', _siswa?.nisn ?? '-'),
           _buildInfoRow('Jenis Kelamin', _siswa?.jk == 'L' ? 'Laki-laki' : 'Perempuan'),
           _buildInfoRow('Wali Kelas', 'Bpk. Ahmad (Wali 9A)'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
  
  Widget _buildPostCard(SocialPost post) {
    return SocialPostCard(
      post: post,
      onTap: () {},
      onLike: () async {
         setState(() { post.isLiked = !post.isLiked; post.likeCount += post.isLiked ? 1 : -1; });
         try { await _socialService.toggleLike(post.id); } 
         catch(e) { 
           setState(() { post.isLiked = !post.isLiked; post.likeCount += post.isLiked ? 1 : -1; });
         }
      },
      onComment: () {
         _showPostDetailPopup(post);
      },
      onLongPress: (p) => _showPostDetailPopup(p),
    );
  }

  void _showPostDetailPopup(SocialPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final currentNis = prefs.getString('user_nis');
    
    if (!mounted) return;

    final result = await showDialog(
      context: context,
      builder: (context) => PostDetailDialog(
        post: post, 
        currentUserNis: currentNis
      ),
    );

    if (result == true) {
       if (_siswa != null) _loadMyPosts(_siswa!.id, _siswa!.nis);
       if (_guru != null) _loadMyPosts(_guru!.id, _guru!.nip);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
