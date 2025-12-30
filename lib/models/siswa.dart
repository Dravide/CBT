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
  final int? kelasId;
  final String? jabatan; // Added field

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
    this.kelasId,
    this.jabatan,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    String? clsName;
    int? clsId;
    
    if (json['kelas'] != null && json['kelas'] is Map) {
      clsName = json['kelas']['nama_kelas'];
      clsId = json['kelas']['id'];
    }
    // Backup check if 'kelas_id' is at root
    if (clsId == null && json['kelas_id'] != null) {
      clsId = int.tryParse(json['kelas_id'].toString());
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
      kelasId: clsId,
      jabatan: json['jabatan'], // Added jabatan
    );
  }
}
