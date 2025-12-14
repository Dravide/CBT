import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cbt_app/models/tugas_online.dart';
import 'package:cbt_app/services/tugas_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';

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
  
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomPageHeader(title: 'Cek Tugas Online'),
          _buildSearchForm(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _kelasIdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ID Kelas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nisController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NIS (Opsional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _search,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.search, color: Colors.white),
              label: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Cari Tugas', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
    return Card(
      color: Colors.indigo[50],
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.indigo.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.namaSiswa, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('NIS: ${summary.nis}', style: GoogleFonts.plusJakartaSans(color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tugas', '${summary.jumlahTugasKelas}'),
                _buildStatItem('Dinilai', '${summary.jumlahTugasDinilai}'),
                _buildStatItem('Rata-rata', summary.rataRataNilaiDinilai?.toStringAsFixed(1) ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTugasCard(TugasItem tugas) {
    Color statusColor = Colors.grey;
    if (tugas.status == 'Aktif') statusColor = Colors.green;
    if (tugas.status == 'Selesai') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(tugas.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Text(tugas.periodeShort, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(tugas.judul, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${tugas.mapel} • ${tugas.guru}', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[700])),
            
            if (_data?.nisSummary != null) ...[
               const SizedBox(height: 12),
               if (tugas.submitted == true)
                 Row(
                   children: [
                     const Icon(Icons.check_circle, color: Colors.green, size: 16),
                     const SizedBox(width: 4),
                     Text('Sudah dikerjakan', style: GoogleFonts.plusJakartaSans(color: Colors.green, fontSize: 12)),
                     if (tugas.sudahDinilai) ...[
                        const SizedBox(width: 8),
                        Text('• Nilai: ${tugas.nilaiSiswa ?? "-"}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                     ]
                   ],
                 )
               else
                 Row(
                   children: [
                     Icon(Icons.cancel, color: Colors.red[300], size: 16),
                     const SizedBox(width: 4),
                     Text('Belum dikerjakan', style: GoogleFonts.plusJakartaSans(color: Colors.red[300], fontSize: 12)),
                   ],
                 ),
            ] else ...[
               const SizedBox(height: 12),
               LinearProgressIndicator(
                 value: tugas.totalSiswa > 0 ? tugas.jumlahSudah / tugas.totalSiswa : 0,
                 backgroundColor: Colors.grey[200],
                 valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade300),
               ),
               const SizedBox(height: 4),
               Text('${tugas.jumlahSudah} dari ${tugas.totalSiswa} siswa sudah mengumpulkan', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _launchUrl(tugas.magicLink),
                child: const Text('Buka Tugas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
