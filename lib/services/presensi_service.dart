import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/presensi_model.dart';

class PresensiService {
  final String baseUrl = "https://digiclass.smpn1cipanas.sch.id/api";

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
      // Build Query Parameters
      Map<String, String> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (filterStatus != null && filterStatus != 'all') queryParams['filter_status'] = filterStatus;
      if (filterType != null && filterType != 'all') queryParams['filter_type'] = filterType;

      // Construct URI with Query Params
      // URL: /api/presensi-guru/{nip}?param=value...
      // Note: Endpoint /presensi-guru/nip might not automatically handle params if not backend-supported, 
      // but guidelines say query string parameters are supported.
      
      final uri = Uri.parse('$baseUrl/presensi-guru/$nip').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
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
      final response = await http.get(
        // Assuming base URL structure. User said http://127.0.0.1:8000/api, so we stick to current baseUrl
        Uri.parse('$baseUrl/qr-presensi/auto-detect'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mendeteksi status presensi (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi: $e');
    }
  }

  // 2. Process Presensi (Submit)
  Future<Map<String, dynamic>> processPresensi({
    required String qrCode,
    required String jenisPresensi,
    required String base64Image,
    required String locationCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/qr-presensi/process'),
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: json.encode({
          'qr_code': qrCode,
          'jenis_presensi': jenisPresensi,
          'location_code': locationCode,
          'foto_webcam': base64Image
        }),
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
}
