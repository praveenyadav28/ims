import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/utils/colors.dart';
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
  static String baseurl = "http://192.168.1.15:4000/api";
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseurl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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

class GlowLoader extends StatefulWidget {
  const GlowLoader({super.key});

  @override
  State<GlowLoader> createState() => _GlowLoaderState();
}

class _GlowLoaderState extends State<GlowLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: controller,
      child: CustomPaint(size: const Size(50, 50), painter: GlowPainter()),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColor.primary.withValues(alpha: .4),
          AppColor.primary,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
