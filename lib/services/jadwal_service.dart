import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/models/jadwal_model.dart';
import 'package:cbt_app/services/siswa_service.dart'; // Reusing BASE_URL logic if needed, or define here

class JadwalService {
  // Replace with your actual base URL or import from a config file
  // For now assuming existing convention
  final String baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api'; 

  Future<List<Jadwal>> getJadwal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final userRole = prefs.getString('user_role') ?? 'siswa'; // Default to siswa
      
      if (userId == null) return [];

      // Construct URL
      // Endpoint: /jadwal?user_id=123&user_type=siswa_or_guru
      final uri = Uri.parse('$baseUrl/jadwal').replace(queryParameters: {
        'user_id': userId.toString(),
        'user_type': userRole,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Jadwal.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching jadwal: $e');
      return [];
    }
  }

  // Helper to filter valid days
  static const List<String> validDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  // Fetch active semester from API
  Future<Map<String, dynamic>?> getActiveSemester() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tahun-pelajaran/active'));
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
