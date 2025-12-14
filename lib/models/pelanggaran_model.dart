class KategoriPelanggaran {
  final int id;
  final String namaKategori;
  final List<JenisPelanggaran> jenis;

  KategoriPelanggaran({required this.id, required this.namaKategori, required this.jenis});

  factory KategoriPelanggaran.fromJson(Map<String, dynamic> json) {
    var list = json['jenis'] as List;
    List<JenisPelanggaran> jenisList = list.map((i) => JenisPelanggaran.fromJson(i)).toList();
    return KategoriPelanggaran(
      id: json['id'],
      namaKategori: json['nama_kategori'],
      jenis: jenisList,
    );
  }
}

class JenisPelanggaran {
  final int id;
  final String namaPelanggaran;
  final int poin;

  JenisPelanggaran({required this.id, required this.namaPelanggaran, required this.poin});

  factory JenisPelanggaran.fromJson(Map<String, dynamic> json) {
    return JenisPelanggaran(
      id: json['id'],
      namaPelanggaran: json['nama_pelanggaran'],
      poin: json['poin_pelanggaran'] ?? 0,
    );
  }
}

class SiswaSearch {
  final int id;
  final String namaSiswa;
  final String? nis;
  final String? kelas;

  SiswaSearch({required this.id, required this.namaSiswa, this.nis, this.kelas});

  factory SiswaSearch.fromJson(Map<String, dynamic> json) {
    String? cls;
    if (json['kelas'] != null && json['kelas'] is Map) {
      cls = json['kelas']['nama_kelas'];
    }
    return SiswaSearch(
      id: json['id'],
      namaSiswa: json['nama_siswa'],
      nis: json['nis'],
      kelas: cls,
    );
  }
}

class PelanggaranOptions {
  final Map<String, dynamic> tahunAjaran;
  final Map<String, String> statusOptions;
  final List<KategoriPelanggaran> kategori;

  PelanggaranOptions({
    required this.tahunAjaran,
    required this.statusOptions,
    required this.kategori,
  });

  factory PelanggaranOptions.fromJson(Map<String, dynamic> json) {
    var catList = json['kategori'] as List;
    List<KategoriPelanggaran> kategoriList = catList.map((i) => KategoriPelanggaran.fromJson(i)).toList();
    
    return PelanggaranOptions(
      tahunAjaran: json['tahun_pelajaran_aktif'],
      statusOptions: Map<String, String>.from(json['status_options']),
      kategori: kategoriList,
    );
  }
}
