class PresensiResponse {
  final Guru guru;
  final Stats stats;
  final List<PresensiRecord> records;

  PresensiResponse({required this.guru, required this.stats, required this.records});

  factory PresensiResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['records'] != null ? json['records']['data'] : [];
    List<PresensiRecord> recordsList = [];
    if (dataList != null) {
      recordsList = (dataList as List).map((i) => PresensiRecord.fromJson(i)).toList();
    }

    return PresensiResponse(
      guru: Guru.fromJson(json['guru']),
      stats: Stats.fromJson(json['stats']),
      records: recordsList,
    );
  }
}

class Guru {
  final int id;
  final String nama;
  final String nip;
  final String email;
  final String telepon;
  final String jabatan;
  final String mataPelajaran;
  final String photoUrl;

  Guru({
    required this.id,
    required this.nama,
    required this.nip,
    required this.email,
    required this.telepon,
    required this.jabatan,
    required this.mataPelajaran,
    required this.photoUrl,
  });

  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      id: json['id'] ?? 0,
      nama: json['nama_guru'] ?? '',
      nip: json['nip'] ?? '',
      email: json['email'] ?? '',
      telepon: json['telepon'] ?? '',
      jabatan: json['jabatan'] ?? '',
      mataPelajaran: json['mata_pelajaran'] ?? '-',
      photoUrl: json['photo_url'] ?? '',
    );
  }
}

class Stats {
  final int totalMasuk;
  final int totalTerlambat;
  final int totalPulang;
  final int totalLembur;

  Stats({
    required this.totalMasuk, 
    required this.totalTerlambat,
    required this.totalPulang,
    required this.totalLembur,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      totalMasuk: json['total_masuk'] ?? 0,
      totalTerlambat: json['total_terlambat'] ?? 0,
      totalPulang: json['total_pulang'] ?? 0,
      totalLembur: json['total_lembur'] ?? 0,
    );
  }
}

class PresensiRecord {
  final String jenis;
  final String waktu;
  final bool isTerlambat;
  final String lokasi;
  final String? fotoUrl; 

  PresensiRecord({
    required this.jenis,
    required this.waktu,
    required this.isTerlambat,
    required this.lokasi,
    this.fotoUrl,
  });

  factory PresensiRecord.fromJson(Map<String, dynamic> json) {
    return PresensiRecord(
      jenis: json['jenis_presensi'] ?? '-',
      waktu: json['waktu_presensi'] ?? '-',
      isTerlambat: json['is_terlambat'] == true || json['is_terlambat'] == 1,
      lokasi: json['location'] != null ? json['location']['name'] : '-',
      fotoUrl: json['foto_url'], // Nullable
    );
  }
}
