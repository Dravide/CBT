import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/siswa.dart';

class SiswaService {
  static const String _baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api';

  Future<Map<String, dynamic>> fetchSiswas({String? query, int? tingkat, int page = 1}) async {
    try {
      final Map<String, String> params = {
        'page': page.toString(),
        'per_page': '15',
        if (query != null && query.isNotEmpty) 'q': query,
        if (tingkat != null) 'tingkat': tingkat.toString(),
      };

      final Uri uri = Uri.parse('$_baseUrl/siswas').replace(queryParameters: params);

      final response = await http.get(uri, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        final List<Siswa> siswas = data.map((e) => Siswa.fromJson(e)).toList();
        
        final Map<String, dynamic> meta = body['meta'];
        
        return {
          'data': siswas,
          'last_page': meta['last_page'],
          'current_page': meta['current_page'],
        };
      } else {
        throw Exception('Failed to load siswas');
      }
    } catch (e) {
      throw Exception('Error fetching siswas: $e');
    }
  }
}
