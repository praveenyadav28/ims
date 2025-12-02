import 'dart:convert';
import 'dart:io';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class CompanyProfileAPi {
  static  String baseurl = ApiService.baseurl;

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

  static Future<Map<String, dynamic>> createCompanyProfile({
    required Map<String, dynamic> data,
    Map<String, File>? images,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseurl/company'),
      );

      // Headers
      request.headers.addAll({
        'Accept': 'application/json',
        'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
      });

      // Add fields to request safely
      data.forEach((key, value) {
        if (value == null) return;

        if (value is List) {
          // ✅ Send arrays correctly
          for (int i = 0; i < value.length; i++) {
            request.fields["$key[$i]"] = value[i].toString();
          }
        } else if (value is Map) {
          // ✅ For nested objects
          request.fields[key] = jsonEncode(value);
        } else {
          // ✅ For strings, ints, bools
          request.fields[key] = value.toString();
        }
      });

      // Add image files
      if (images != null && images.isNotEmpty) {
        for (var entry in images.entries) {
          final file = entry.value;
          final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
          final parts = mimeType.split('/');
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: MediaType(parts[0], parts[1]),
            ),
          );
        }
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } catch (e) {
      throw Exception('Failed to post company data: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCompanyProfile({
    required Map<String, dynamic> data,
    Map<String, File>? images,
    String? id,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseurl/company/$id'),
      );

      // Headers
      request.headers.addAll({
        'Accept': 'application/json',
        'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
      });

      // Add fields to request safely
      data.forEach((key, value) {
        if (value == null) return;

        if (value is List) {
          // ✅ Send arrays correctly
          for (int i = 0; i < value.length; i++) {
            request.fields["$key[$i]"] = value[i].toString();
          }
        } else if (value is Map) {
          // ✅ For nested objects
          request.fields[key] = jsonEncode(value);
        } else {
          // ✅ For strings, ints, bools
          request.fields[key] = value.toString();
        }
      });

      // Add image files
      if (images != null && images.isNotEmpty) {
        for (var entry in images.entries) {
          final file = entry.value;
          final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
          final parts = mimeType.split('/');
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: MediaType(parts[0], parts[1]),
            ),
          );
        }
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } catch (e) {
      throw Exception('Failed to update company profile: $e');
    }
  }
}
