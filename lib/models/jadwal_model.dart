class Jadwal {
  final int id;
  final String hari;
  final String semester;
  final int jamKe;
  final String jamMulai;
  final String jamSelesai;
  final String mataPelajaran;
  final String guru;
  final String kelas;
  final String? keterangan;
  final bool isActive;

  Jadwal({
    required this.id,
    required this.hari,
    required this.semester,
    required this.jamKe,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mataPelajaran,
    required this.guru,
    required this.kelas,
    this.keterangan,
    required this.isActive,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'] ?? 0,
      hari: json['hari'] ?? '',
      semester: json['semester'] ?? 'ganjil',
      jamKe: json['jam_ke'] is int ? json['jam_ke'] : int.tryParse(json['jam_ke'].toString()) ?? 0,
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      mataPelajaran: json['mata_pelajaran'] ?? '-',
      guru: json['guru'] ?? '-',
      kelas: json['kelas'] ?? '',
      keterangan: json['keterangan'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
