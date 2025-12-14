import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/pengumuman.dart';

class PengumumanService {
  // Updated domain as requested by user
  static const String baseUrl = 'https://digiclass.smpn1cipanas.sch.id';

  Future<PengumumanListResponse> getPengumuman({int page = 1, int perPage = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pengumuman?page=$page&per_page=$perPage'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return PengumumanListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  Future<Pengumuman> getPengumumanDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/pengumuman/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return Pengumuman.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Failed to load announcement detail');
    }
  }

  Future<void> registerDeviceToken(String token, int? userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/device-tokens/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
        'platform': 'android',
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to register token: ${response.body}');
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/device-tokens/unregister'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to unregister token: ${response.body}');
    }
  }
}
