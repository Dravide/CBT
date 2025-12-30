import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presensi_model.dart';

class PresensiService {
  final String baseUrl = "https://digiclass.smpn1cipanas.sch.id/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<PresensiResponse> getRekapPresensi(
    String nip, {
    String? startDate,
    String? endDate,
    String? filterStatus, // terlambat, pulang_awal, lembur, tepat_waktu, all
    String? filterType,   // masuk, pulang, lembur, all
  }) async {
    if (nip.isEmpty) {
       throw Exception("NIP tidak valid");
    }

    try {
      final token = await _getToken();
      
      // Build Query Parameters
      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (filterStatus != null && filterStatus != 'all') queryParams['filter_status'] = filterStatus;
      if (filterType != null && filterType != 'all') queryParams['filter_type'] = filterType;

      final uri = Uri.parse('$baseUrl/presensi-guru/$nip').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return PresensiResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Gagal memuat data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  // QR Attendance API
  
  // 1. Auto Detect
  Future<Map<String, dynamic>> autoDetectPresensi() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/qr-presensi/auto-detect'),
        headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'data': {}};
      } else {
        throw Exception('Gagal mendeteksi status presensi (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi: $e');
    }
  }

  // 2. Process Presensi (Submit) - Legacy QR
  Future<Map<String, dynamic>> processPresensi({
    required String qrCode,
    required String jenisPresensi,
    required String base64Image,
    required String locationCode,
  }) async {
    // ... (Existing QR implementation) ...
    // Just keeping the header for clarity, actual body below
    return _postPresensi('$baseUrl/qr-presensi/process', {
       'qr_code': qrCode,
       'jenis_presensi': jenisPresensi,
       'location_code': locationCode,
       'foto_webcam': base64Image
    });
  }

  // 3. Process Presensi (Submit) - NIP Based
  Future<Map<String, dynamic>> processPresensiByNip({
    required String nip,
    required String jenisPresensi,
    required String base64Image,
    required String locationCode,
    double? latitude,
    double? longitude,
  }) async {
    return _postPresensi('$baseUrl/qr-presensi/process-nip', {
       'nip': nip,
       'jenis_presensi': jenisPresensi,
       'location_code': locationCode,
       'foto_webcam': base64Image,
       'latitude': latitude,
       'longitude': longitude,
    });
  }

  // Refactored Helper
  Future<Map<String, dynamic>> _postPresensi(String url, Map<String, dynamic> bodyData) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(url),
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(bodyData),
      );

      final body = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return body;
      } else {
        throw Exception(body['message'] ?? 'Gagal memproses presensi');
      }
    } catch (e) {
      throw Exception('Gagal mengirim data: $e');
    }
  }

  // 4. Get Daily Attendance (Who checked in today)
  Future<List<dynamic>> getDailyAttendance({String? filterType}) async {
    try {
      final token = await _getToken();
      
      Map<String, String> queryParams = {};
      if (filterType != null && filterType != 'all') {
        queryParams['jenis_presensi'] = filterType;
      }

      final uri = Uri.parse('$baseUrl/qr-presensi/today').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final response = await http.get(
        uri,
        headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final dynamic rawData = body['data'];
        if (rawData is List) {
          return rawData;
        }
        return [];
      } else {
        throw Exception('Gagal memuat daftar hadir (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi: $e');
    }
  }
}
