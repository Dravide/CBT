class Guru {
  final int id;
  final String namaGuru;
  final String? nip;
  final String? email;
  final String? telepon;
  final bool isWaliKelas;
  final String? mataPelajaran;
  final int siswaCount;

  Guru({
    required this.id,
    required this.namaGuru,
    this.nip,
    this.email,
    this.telepon,
    required this.isWaliKelas,
    this.mataPelajaran,
    required this.siswaCount,
  });

  factory Guru.fromJson(Map<String, dynamic> json) {
    String? mapelName;
    if (json['mata_pelajaran'] != null) {
      if (json['mata_pelajaran'] is Map) {
         mapelName = json['mata_pelajaran']['nama_mapel'];
      }
    }

    return Guru(
      id: json['id'],
      namaGuru: json['nama_guru'],
      nip: json['nip'],
      email: json['email'],
      telepon: json['telepon'],
      isWaliKelas: json['is_wali_kelas'] ?? false,
      mataPelajaran: mapelName,
      siswaCount: json['siswa_count'] ?? 0,
    );
  }
}
