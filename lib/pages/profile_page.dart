import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/pages/login_page.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/services/siswa_service.dart';
import 'package:cbt_app/models/siswa.dart';
import 'package:cbt_app/pages/settings_page.dart';
import 'package:cbt_app/pages/about_page.dart';
import 'package:cbt_app/models/social_post.dart';
import 'package:cbt_app/widgets/skeleton_loading.dart';
import 'package:shimmer/shimmer.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final SiswaService _siswaService = SiswaService();
  bool _isLoading = true;
  Siswa? _siswa;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    // Artificial delay to ensure skeleton is visible
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? nis = prefs.getString('user_nis');

      if (nis == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Data sesi tidak ditemukan. Silakan login ulang.';
            _isLoading = false;
          });
        }
        return;
      }

      final result = await _siswaService.fetchSiswas(query: nis);
      final List<Siswa> siswas = result['data'];
      
      try {
         final Siswa match = siswas.firstWhere((s) => s.nis == nis);
         if (mounted) {
           setState(() {
             _siswa = match;
             _isLoading = false;
           });
         }
      } catch (e) {
         if (mounted) {
           setState(() {
            _errorMessage = 'Data siswa tidak ditemukan di server.';
            _isLoading = false;
           });
         }
      }
      
    } catch (e) {
       if (mounted) {
         setState(() {
          _errorMessage = 'Gagal memuat profil: $e';
          _isLoading = false;
         });
       }
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
    // Filter my posts
    final myPosts = SocialPost.dummyPosts.where((p) => p.userName == 'Siswa (Saya)' || p.userHandle == '@siswa_satria').toList();

    return Column(
      children: [
        CustomPageHeader(
          title: 'Profil Siswa',
          showBackButton: false,
          leadingIcon: Icons.person,
        ),
        Expanded(
          child: _isLoading 
            ? _buildSkeleton()
            : _buildContent(myPosts),
        ),
      ],
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
            // Header Skeleton
            Row(
              children: [
                const SkeletonLoading(width: 80, height: 80, borderRadius: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoading(width: 150, height: 20),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 100, height: 14),
                      SizedBox(height: 8),
                      SkeletonLoading(width: 180, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Stats Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                 SkeletonLoading(width: 60, height: 40),
                 SkeletonLoading(width: 60, height: 40),
                 SkeletonLoading(width: 60, height: 40),
              ],
            ),
            const SizedBox(height: 32),
            // Buttons
            Row(
              children: const [
                Expanded(child: SkeletonLoading(width: double.infinity, height: 40)),
                SizedBox(width: 8),
                Expanded(child: SkeletonLoading(width: double.infinity, height: 40)),
              ],
            ),
            const SizedBox(height: 32),
            // Content Skeleton
            Column(
               children: List.generate(3, (index) => Padding(
                 padding: const EdgeInsets.only(bottom: 16),
                 child: const SkeletonLoading(width: double.infinity, height: 100),
               )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<SocialPost> myPosts) {
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
     
     return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Avatar & Basic Info
                        Row(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                                image: const DecorationImage(
                                   // Placeholder for avatar image
                                   image: AssetImage('assets/avatar_placeholder.png'), 
                                   fit: BoxFit.cover, 
                                ),
                              ),
                              child: const Center(
                                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: _buildProfileDetails()),
                          ],
                        ),
                        // Stats & Buttons
                        const SizedBox(height: 24),
                        _buildStatsRow(myPosts), 
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF0D47A1),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF0D47A1),
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
                _buildPostsTab(myPosts),
                _buildInfoTab(),
              ],
            ),
     );
  }
  
  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _siswa?.namaSiswa ?? 'Siswa',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${_siswa?.nis ?? "user"}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Siswa SMP Negeri 1 Cipanas\nKelas ${_siswa?.className ?? "-"}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<SocialPost> myPosts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Postingan', myPosts.length.toString()),
        _buildStatItem('Kelas', _siswa?.className ?? '-'),
        _buildStatItem('Status', _siswa?.status ?? 'Aktif'),
      ],
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

  Widget _buildPostsTab(List<SocialPost> myPosts) {
      if (myPosts.isEmpty) {
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
           itemCount: myPosts.length,
           itemBuilder: (context, index) => _buildPostCard(myPosts[index]),
      );
  }

  Widget _buildInfoTab() {
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
     return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(post.content, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
           const SizedBox(height: 8),
           Row(
             children: [
               Icon(Icons.favorite, size: 16, color: Colors.pink[400]),
               const SizedBox(width: 4),
               Text('${post.likeCount}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
               const SizedBox(width: 16),
               Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[400]),
               const SizedBox(width: 4),
               Text('${post.commentCount}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
             ],
           )
        ],
      ),
     );
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
      color: Colors.grey[50], // Match background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
