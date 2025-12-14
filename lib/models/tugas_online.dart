class KelasTugasOnlineResponse {
  final List<TugasItem> data;
  final Meta? meta;
  final KelasInfo? kelas;
  final NISSummary? nisSummary;

  KelasTugasOnlineResponse({
    required this.data,
    this.meta,
    this.kelas,
    this.nisSummary,
  });

  factory KelasTugasOnlineResponse.fromJson(Map<String, dynamic> json) {
    return KelasTugasOnlineResponse(
      data: (json['data'] as List?)?.map((e) => TugasItem.fromJson(e)).toList() ?? [],
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
      kelas: json['kelas'] != null ? KelasInfo.fromJson(json['kelas']) : null,
      nisSummary: json['nis_summary'] != null ? NISSummary.fromJson(json['nis_summary']) : null,
    );
  }
}

class TugasItem {
  final int id;
  final String judul;
  final String mapel;
  final String guru;
  final String periode;
  final String periodeShort;
  final String status;
  final String magicLink;
  final bool? submitted;
  final int jumlahSudah;
  final int jumlahBelum;
  final int totalSiswa;
  final int? nilaiSiswa;
  final bool sudahDinilai;
  final String? statusPengumpulanSiswa;

  TugasItem({
    required this.id,
    required this.judul,
    required this.mapel,
    required this.guru,
    required this.periode,
    required this.periodeShort,
    required this.status,
    required this.magicLink,
    this.submitted,
    required this.jumlahSudah,
    required this.jumlahBelum,
    required this.totalSiswa,
    this.nilaiSiswa,
    required this.sudahDinilai,
    this.statusPengumpulanSiswa,
  });

  factory TugasItem.fromJson(Map<String, dynamic> json) {
    return TugasItem(
      id: json['id'],
      judul: json['judul'] ?? '',
      mapel: json['mapel'] ?? '',
      guru: json['guru'] ?? '',
      periode: json['periode'] ?? '',
      periodeShort: json['periode_short'] ?? '',
      status: json['status'] ?? 'Menunggu',
      magicLink: json['magic_link'] ?? '',
      submitted: json['submitted'],
      jumlahSudah: json['jumlah_sudah'] ?? 0,
      jumlahBelum: json['jumlah_belum'] ?? 0,
      totalSiswa: json['total_siswa'] ?? 0,
      nilaiSiswa: json['nilai_siswa'],
      sudahDinilai: json['sudah_dinilai'] ?? false,
      statusPengumpulanSiswa: json['status_pengumpulan_siswa'],
    );
  }
}

class Meta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  Meta({required this.currentPage, required this.perPage, required this.total, required this.lastPage});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
    );
  }
}

class KelasInfo {
  final int id;
  final String namaKelas;
  final String tingkat;
  final int totalSiswa;

  KelasInfo({required this.id, required this.namaKelas, required this.tingkat, required this.totalSiswa});

  factory KelasInfo.fromJson(Map<String, dynamic> json) {
    return KelasInfo(
      id: json['id'],
      namaKelas: json['nama_kelas'] ?? '',
      tingkat: json['tingkat'] ?? '',
      totalSiswa: json['total_siswa'] ?? 0,
    );
  }
}

class NISSummary {
  final String nis;
  final String namaSiswa;
  final int jumlahTugasKelas;
  final int jumlahTugasDinilai;
  final double? rataRataNilaiDinilai;
  final double? rataRataNilai;
  final List<int> submittedTaskIds;

  NISSummary({
    required this.nis,
    required this.namaSiswa,
    required this.jumlahTugasKelas,
    required this.jumlahTugasDinilai,
    this.rataRataNilaiDinilai,
    this.rataRataNilai,
    required this.submittedTaskIds,
  });

  factory NISSummary.fromJson(Map<String, dynamic> json) {
    return NISSummary(
      nis: json['nis'] ?? '',
      namaSiswa: json['nama_siswa'] ?? '',
      jumlahTugasKelas: json['jumlah_tugas_kelas'] ?? 0,
      jumlahTugasDinilai: json['jumlah_tugas_dinilai'] ?? 0,
      rataRataNilaiDinilai: (json['rata_rata_nilai_dinilai'] as num?)?.toDouble(),
      rataRataNilai: (json['rata_rata_nilai'] as num?)?.toDouble(),
      submittedTaskIds: (json['submitted_task_ids'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }
}
