import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/tugas_online.dart';

class TugasService {
  final String _baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api';

  Future<KelasTugasOnlineResponse> fetchTugas(int kelasId, {int page = 1, int perPage = 10, String? nis}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (nis != null && nis.isNotEmpty) 'nis': nis,
    };

    final uri = Uri.parse('$_baseUrl/kelas/$kelasId/tugas-online').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KelasTugasOnlineResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kelas tidak ditemukan');
      } else {
        throw Exception('Gagal memuat tugas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
