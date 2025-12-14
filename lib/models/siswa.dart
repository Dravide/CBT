class Siswa {
  final int id;
  final String namaSiswa;
  final String? jk;
  final String? nis;
  final String? nisn;
  final String? email;
  final String? status;
  final String? keterangan;
  final String? className;

  Siswa({
    required this.id,
    required this.namaSiswa,
    this.jk,
    this.nis,
    this.nisn,
    this.email,
    this.status,
    this.keterangan,
    this.className,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    String? clsName;
    if (json['kelas'] != null && json['kelas'] is Map) {
      clsName = json['kelas']['nama_kelas'];
    }

    return Siswa(
      id: json['id'],
      namaSiswa: json['nama_siswa'],
      jk: json['jk'],
      nis: json['nis'],
      nisn: json['nisn'],
      email: json['email'],
      status: json['status'],
      keterangan: json['keterangan'],
      className: clsName,
    );
  }
}
