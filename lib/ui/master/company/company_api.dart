import 'dart:convert';
import 'dart:typed_data';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class CompanyProfileAPi {
  static String baseurl = ApiService.baseurl;

  static Future<Map<String, dynamic>> getCompanyProfile() async {
    final response = await http.get(
      Uri.parse('$baseurl/get/company'),
      headers: {
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
        'Accept': 'application/json',
        'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to fetch company profile: ${response.statusCode}',
      );
    }
  }

  // ================= CREATE =================
  static Future<Map<String, dynamic>> createCompanyProfile({
    required Map<String, dynamic> data,
    Map<String, Uint8List>? images,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseurl/company'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
      });

      _attachFields(request, data);
      await _attachImages(request, images);

      final response = await request.send();
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } catch (e) {
      throw Exception('Failed to post company data: $e');
    }
  }

  // ================= UPDATE =================
  static Future<Map<String, dynamic>> updateCompanyProfile({
    required Map<String, dynamic> data,
    Map<String, Uint8List>? images,
    String? id,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseurl/company/$id'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
      });

      _attachFields(request, data);
      await _attachImages(request, images);

      final response = await request.send();
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } catch (e) {
      throw Exception('Failed to update company profile: $e');
    }
  }

  // ================= HELPERS =================

  static void _attachFields(
    http.MultipartRequest request,
    Map<String, dynamic> data,
  ) {
    data.forEach((key, value) {
      if (value == null) return;

      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          request.fields["$key[$i]"] = value[i].toString();
        }
      } else if (value is Map) {
        request.fields[key] = jsonEncode(value);
      } else {
        request.fields[key] = value.toString();
      }
    });
  }

  static Future<void> _attachImages(
    http.MultipartRequest request,
    Map<String, Uint8List>? images,
  ) async {
    if (images == null || images.isEmpty) return;

    for (final entry in images.entries) {
      final mimeType = lookupMimeType(entry.key) ?? 'image/jpeg';
      final parts = mimeType.split('/');

      request.files.add(
        http.MultipartFile.fromBytes(
          entry.key,
          entry.value,
          filename: '${entry.key}.jpg',
          contentType: MediaType(parts[0], parts[1]),
        ),
      );
    }
  }
}
