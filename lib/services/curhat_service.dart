import 'dart:convert';
import 'package:http/http.dart' as http;

class CurhatService {
  final String baseUrl = 'https://digiclass.smpn1cipanas.sch.id'; 

  Future<bool> submitCurhat({
    required String judul,
    required String isi,
    required String kategori,
    required bool isAnonim,
    String? namaSiswa,
    String? kelasSiswa,
  }) async {
    final url = Uri.parse('$baseUrl/curhat-siswa-public');
    
    final Map<String, dynamic> body = {
      'judul': judul,
      'isi_curhat': isi,
      'kategori': kategori,
      'is_anonim': isAnonim,
    };

    if (!isAnonim) {
      body['nama_siswa'] = namaSiswa;
      body['kelas_siswa'] = kelasSiswa;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to submit curhat: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting curhat: $e');
      return false;
    }
  }
}
