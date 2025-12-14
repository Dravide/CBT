import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/guru.dart';

class GuruService {
  static const String _baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api';

  Future<Map<String, dynamic>> fetchGurus({String? query, int page = 1}) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/gurus').replace(queryParameters: {
        'page': page.toString(),
        'per_page': '10',
        if (query != null && query.isNotEmpty) 'q': query,
      });

      final response = await http.get(uri, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        final List<Guru> gurus = data.map((e) => Guru.fromJson(e)).toList();
        
        final Map<String, dynamic> meta = body['meta'];
        
        return {
          'data': gurus,
          'last_page': meta['last_page'],
          'current_page': meta['current_page'],
        };
      } else {
        throw Exception('Failed to load gurus');
      }
    } catch (e) {
      throw Exception('Error fetching gurus: $e');
    }
  }
}
