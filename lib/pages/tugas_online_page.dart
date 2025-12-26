import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/tugas_online.dart';
import 'package:cbt_app/services/tugas_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/pages/webview_page.dart';

class TugasOnlinePage extends StatefulWidget {
  const TugasOnlinePage({super.key});

  @override
  State<TugasOnlinePage> createState() => _TugasOnlinePageState();
}

class _TugasOnlinePageState extends State<TugasOnlinePage> {
  final _service = TugasService();
  final _kelasIdController = TextEditingController();
  final _nisController = TextEditingController();

  bool _isLoading = false;
  bool _hasSearched = false;
  KelasTugasOnlineResponse? _data;
  List<TugasItem> _allTugas = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkAutoLoad();
  }

  Future<void> _checkAutoLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final int? kelasId = prefs.getInt('kelas_id');
    final String? nis = prefs.getString('user_nis');

    if (kelasId != null) {
      _kelasIdController.text = kelasId.toString();
      if (nis != null) _nisController.text = nis;
      
      // Auto search
      _search();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _kelasIdController.dispose();
    _nisController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    if (_kelasIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Kelas wajib diisi')));
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _allTugas = [];
      _currentPage = 1;
      _hasMore = true;
      _data = null;
    });

    try {
      final kelasId = int.parse(_kelasIdController.text);
      final response = await _service.fetchTugas(
        kelasId,
        page: _currentPage,
        nis: _nisController.text.isNotEmpty ? _nisController.text : null,
      );

      setState(() {
        _data = response;
        _allTugas = response.data;
        _hasMore = response.meta!.currentPage < response.meta!.lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final kelasId = int.parse(_kelasIdController.text);
      final response = await _service.fetchTugas(
        kelasId,
        page: _currentPage + 1,
        nis: _nisController.text.isNotEmpty ? _nisController.text : null,
      );

      setState(() {
        _allTugas.addAll(response.data);
        _currentPage++;
        _hasMore = response.meta!.currentPage < response.meta!.lastPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat lebih banyak: $e')));
    }
  }
  
  void _launchUrl(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomPageHeader(title: 'Cek Tugas Online'),
          // Build Search Form only if not auto-loaded or explicitly desired
          // For now, let's keep it visible but maybe collapsed or optional?
          // User said "tidak usah cek lagi", implying they just want to see the tasks.
          // We can hide the form if _hasSearched is true, but provide a way to show it?
          // Or just keep it but since it auto-searches, user sees results immediately.
          // Let's keep it simplified.
          if (!_hasSearched) _buildSearchForm(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cari Tugas',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Masukkan ID Kelas untuk melihat tugas.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _kelasIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ID Kelas',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'Contoh: 12',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nisController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NIS',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: 'Opsional',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _search,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.search, color: Colors.white),
              label: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Tampilkan Tugas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _allTugas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Masukan ID Kelas untuk melihat tugas', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Check if data is null (error state usually) but _hasSearched is true
    if (_data == null && _allTugas.isEmpty) {
       return const Center(child: Text('Tidak ada data'));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (_data?.kelas != null) ...[
          Text(
            'Kelas: ${_data!.kelas!.namaKelas} (${_data!.kelas!.totalSiswa} Siswa)',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
        
        if (_data?.nisSummary != null) _buildNisSummary(_data!.nisSummary!),
        
        if (_allTugas.isEmpty)
           const Padding(
             padding: EdgeInsets.only(top: 40),
             child: Center(child: Text('Belum ada tugas online')),
           )
        else
          ..._allTugas.map((tugas) => _buildTugasCard(tugas)),

        if (_isLoadingMore)
          const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildNisSummary(NISSummary summary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFF1565C0), 
                  child: Icon(Icons.person, color: Colors.white)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.namaSiswa, 
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: Colors.white,
                      )
                    ),
                    Text(
                      'NIS: ${summary.nis}', 
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.8), 
                        fontSize: 14
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Tugas', '${summary.jumlahTugasKelas}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Dinilai', '${summary.jumlahTugasDinilai}'),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Rata-rata', summary.rataRataNilaiDinilai?.toStringAsFixed(1) ?? '-'),
            ],
          ),
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
            fontWeight: FontWeight.w800, 
            fontSize: 22, 
            color: Colors.white
          )
        ),
        Text(
          label, 
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, 
            color: Colors.white.withOpacity(0.8)
          )
        ),
      ],
    );
  }

  Widget _buildTugasCard(TugasItem tugas) {
    Color statusColor = Colors.grey;
    Color statusBg = Colors.grey.withOpacity(0.1);
    
    if (tugas.status == 'Aktif') {
      statusColor = Colors.green[700]!;
      statusBg = Colors.green.withOpacity(0.1);
    }
    if (tugas.status == 'Selesai') {
      statusColor = Colors.orange[800]!;
      statusBg = Colors.orange.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tugas.status.toUpperCase(), 
                    style: GoogleFonts.plusJakartaSans(
                      color: statusColor, 
                      fontWeight: FontWeight.w700, 
                      fontSize: 10,
                      letterSpacing: 0.5
                    ),
                  ),
                ),
                Text(
                  tugas.periodeShort, 
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, 
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tugas.judul, 
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, 
                fontSize: 18,
                height: 1.2
              )
            ),
            const SizedBox(height: 6),
            Text(
              '${tugas.mapel} • ${tugas.guru}', 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, 
                color: Colors.grey[600]
              )
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),

            if (_data?.nisSummary != null) ...[
               if (tugas.submitted == true)
                 Row(
                   children: [
                     const Icon(Icons.check_circle, color: Colors.green, size: 20),
                     const SizedBox(width: 8),
                     Text('Sudah dikerjakan', style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                     if (tugas.sudahDinilai) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                             color: Colors.blue[50],
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Colors.blue[100]!)
                          ),
                          child: Text(
                            'Nilai: ${tugas.nilaiSiswa ?? "-"}', 
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue[800])
                          ),
                        ),
                     ]
                   ],
                 )
               else
                 Row(
                   children: [
                     Icon(Icons.cancel, color: Colors.red[300], size: 20),
                     const SizedBox(width: 8),
                     Text('Belum dikerjakan', style: GoogleFonts.plusJakartaSans(color: Colors.red[300], fontWeight: FontWeight.w600, fontSize: 13)),
                   ],
                 ),
            ] else ...[
               Row(
                 children: [
                   Expanded(
                     child: LinearProgressIndicator(
                       value: tugas.totalSiswa > 0 ? tugas.jumlahSudah / tugas.totalSiswa : 0,
                       backgroundColor: Colors.grey[100],
                       valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400),
                       minHeight: 6,
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Text(
                     '${tugas.jumlahSudah}/${tugas.totalSiswa}', 
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: 12, 
                       color: Colors.grey[600],
                       fontWeight: FontWeight.bold
                      )
                   ),
                 ],
               ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _launchUrl(tugas.magicLink, tugas.judul),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)
                ),
                child: const Text('Buka Tugas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
