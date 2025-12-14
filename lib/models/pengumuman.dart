class Pengumuman {
  final int id;
  final String judul;
  final String isi;
  final String tanggal;
  final String createdAt;

  Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggal,
    required this.createdAt,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'],
      judul: json['judul'],
      isi: json['isi'],
      tanggal: json['tanggal'],
      createdAt: json['created_at'],
    );
  }
}

class PengumumanListResponse {
  final List<Pengumuman> data;
  final Meta? meta;

  PengumumanListResponse({required this.data, this.meta});

  factory PengumumanListResponse.fromJson(Map<String, dynamic> json) {
    return PengumumanListResponse(
      data: (json['data'] as List).map((i) => Pengumuman.fromJson(i)).toList(),
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }
}

class Meta {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  Meta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['current_page'],
      perPage: json['per_page'],
      total: json['total'],
      lastPage: json['last_page'],
    );
  }
}
