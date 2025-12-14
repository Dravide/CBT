import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/pelanggaran_model.dart';

class PelanggaranService {
  static const String _baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api/pelanggaran';

  Future<PelanggaranOptions> getOptions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/options'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return PelanggaranOptions.fromJson(body['data']);
      } else {
        throw Exception('Failed to load options');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<SiswaSearch>> searchSiswa(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/siswa-search?q=$query&limit=15'),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((e) => SiswaSearch.fromJson(e)).toList();
      } else {
        throw Exception('Failed to search siswa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/report'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      final body = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return body;
      } else {
        throw Exception(body['message'] ?? 'Gagal mengirim laporan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
