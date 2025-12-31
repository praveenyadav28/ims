import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ims/utils/prefence.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static String baseurl = "http://192.168.1.20:4000/api";
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseurl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // -------------------- HEADERS --------------------
  static Map<String, dynamic> _authHeaders({int? licenceNo}) {
    final headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${Preference.getString(PrefKeys.token)}",
    };

    if (licenceNo != null) headers['licence_no'] = "$licenceNo";
    return headers;
  }

  static Map<String, dynamic> _jsonHeaders({int? licenceNo}) {
    final headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${Preference.getString(PrefKeys.token)}",
    };

    if (licenceNo != null) headers['licence_no'] = "$licenceNo";
    return headers;
  }

  // -------------------- GET --------------------
  static Future<dynamic> fetchData(
    String endpoint, {
    int? licenceNo,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        "/$endpoint",
        queryParameters: queryParameters,
        options: Options(headers: _authHeaders(licenceNo: licenceNo)),
      );
      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- GET with BODY --------------------
  static Future<dynamic> fetchDataWithBody(
    String endpoint, {
    int? licenceNo,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.request(
        "/$endpoint",
        data: body,
        queryParameters: queryParameters,
        options: Options(
          method: "GET",
          headers: _authHeaders(licenceNo: licenceNo),
        ),
      );

      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- POST JSON --------------------
  static Future<dynamic> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    int? licenceNo,
  }) async {
    try {
      final response = await dio.post(
        "/$endpoint",
        data: data,
        options: Options(headers: _jsonHeaders(licenceNo: licenceNo)),
      );
      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  static Future<dynamic> postData(
    String endpoint,
    Map<String, dynamic> data, {
    int? licenceNo,
  }) async {
    try {
      final response = await dio.post(
        "/$endpoint",
        data: data, // <-- send raw JSON
        options: Options(
          headers: {
            ..._authHeaders(licenceNo: licenceNo),
            "Content-Type": "application/json",
          },
        ),
      );

      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- PUT (JSON + Form Auto Detect) --------------------
  static Future<dynamic> putData(
    String endpoint,
    Map<String, dynamic> data, {
    int? licenceNo,
  }) async {
    try {
      final response = await dio.put(
        "/$endpoint",
        data: data,
        options: Options(headers: _jsonHeaders(licenceNo: licenceNo)),
      );
      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- DELETE --------------------
  static Future<dynamic> deleteData(
    String endpoint, {
    int? licenceNo,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await dio.delete(
        "/$endpoint",
        data: body,
        options: Options(headers: _jsonHeaders(licenceNo: licenceNo)),
      );
      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- MULTIPART FILE HELPERS --------------------

  static Future<MultipartFile> toMultipartFile(XFile file) async {
    final mime = lookupMimeType(file.path) ?? "application/octet-stream";
    return MultipartFile.fromFile(
      file.path,
      filename: file.name,
      contentType: MediaType.parse(mime),
    );
  }

  static Future<dynamic> uploadFiles({
    required String endpoint,
    required Map<String, dynamic> fields,
    XFile? singleFile,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {};

      // Add all fields safely
      fields.forEach((key, value) {
        if (value is Map || value is List) {
          dataMap[key] = jsonEncode(value); // encode complex values
        } else {
          dataMap[key] = value;
        }
      });

      // Add image from XFile
      if (singleFile != null) {
        dataMap["signature"] = await MultipartFile.fromFile(
          singleFile.path,
          filename: singleFile.name,
        );
      }

      // Create FormData
      final form = FormData.fromMap(dataMap);

      final response = await dio.post(
        "/$endpoint",
        data: form,
        options: Options(
          headers: _authHeaders()
            ..addAll({"Content-Type": "multipart/form-data"}),
        ),
      );

      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- REUSABLE MULTIPART API CALL --------------------
  static Future<dynamic> uploadMultipart({
    required String endpoint,
    required Map<String, dynamic> fields,
    required bool updateStatus,
    XFile? file,
    String fileKey = "signature",
    int? licenceNo,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {};

      // Convert + encode all fields safely
      fields.forEach((key, value) {
        if (value is Map || value is List) {
          dataMap[key] = jsonEncode(value);
        } else {
          dataMap[key] = value?.toString() ?? "";
        }
      });

      // Add file if available
      if (file != null) {
        dataMap[fileKey] = await toMultipartFile(file);
      }

      final form = FormData.fromMap(dataMap);

      final response = updateStatus
          ? await dio.put(
              "/$endpoint",
              data: form,
              options: Options(
                headers: {
                  ..._authHeaders(licenceNo: licenceNo),
                  "Content-Type": "multipart/form-data",
                },
              ),
            )
          : await dio.post(
              "/$endpoint",
              data: form,
              options: Options(
                headers: {
                  ..._authHeaders(licenceNo: licenceNo),
                  "Content-Type": "multipart/form-data",
                },
              ),
            );

      return response.data;
    } catch (e) {
      throw _formatError(e);
    }
  }

  // -------------------- ERROR HANDLER --------------------
  static ApiException _formatError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode ?? 500;
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? "Server Error")
          : e.message;

      return ApiException(msg.toString(), statusCode: status);
    }
    return ApiException(e.toString(), statusCode: 500);
  }
}
