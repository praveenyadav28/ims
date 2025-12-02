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
  static String baseurl = "http://192.168.1.19:4000/api";
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

  // -------------------- UPLOAD (any files) --------------------
  static Future<dynamic> uploadFiles({
    required String endpoint,
    required Map<String, dynamic> fields,
    Map<String, XFile?>? singleFiles,
    Map<String, List<XFile>>? multiFiles,
  }) async {
    try {
      final form = FormData();

      // Add fields
      fields.forEach((key, value) {
        form.fields.add(MapEntry(key, value.toString()));
      });

      // Single files
      if (singleFiles != null) {
        for (final entry in singleFiles.entries) {
          final file = entry.value;
          if (file != null) {
            form.files.add(MapEntry(entry.key, await toMultipartFile(file)));
          }
        }
      }

      // Multiple files
      if (multiFiles != null) {
        for (final entry in multiFiles.entries) {
          for (final f in entry.value) {
            form.files.add(MapEntry(entry.key, await toMultipartFile(f)));
          }
        }
      }

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
// """
// Hola amigo (Yeah, yeah), kaise ho, theek ho?
// Kya chal raha hai bruv?
// Milte hai jald
// Tell me what's up? (Haan)
// Hola amigo (It's that dollar sign!)
// Kaise ho, theek ho? (Seedhe Maut)
// Ghar pe kaise hai sab?
// Aunty ko bolna "I'm sending my love"

// [Verse 1: KR$NA]
// It's the return of the mack
// Abhi bhi likhu toh karu murder ye rap (Yeah)
// Sune tere word hi hai cap
// Main toh jaanta ni tujhe, never heard of your rap (Na)
// Suna tera crowd bhi na ruke
// Fan bhi ab gaane tere chaav se na sune
// Doubt hai na mujhe, tera daav pe na kuch hai
// Kare ye clown, dekho now, inka mouth bhi ab chup hai
// Kare out bhi na mujhe, yahan boundary na kuch hai
// Chahiye bhaav, khade paav, thoda clout chahiye tujhe
// Better bow to the power, mera paav bhi na jhuke
// Inka baap bana now, bolte baau ji ab mujhe
// Dilli ke londe ki buddhi garam (Haan), dilli ke launde hai kutti rakam (Haan)
// Baaton mein tere na kuch bhi hai dam
// Haan, khainch ke maare tere guddi pe hum
// Dukhti hai nabz, phir na chhupti jalan
// Tu choot ka ghulam, teri fuddi dharm (Huh)
// Aaye karne jang, inki chudgi kalam
// Ye toh khud bhi khatam, kara sudhikaran (Hoo)
// Baap ke paise ni khaata
// Toh kaisa sawaal hai, "Main kaise kamaata?"
// Main laashe bichata, ye kehne main aata
// Pull up with Neena main jaise Masaba (Like damn)
// Get set go, ye hai green light gang
// Karun main whatever, I feel like man
// Saadi inki soorat, mile teen bhai
// Kara saara scene tight, inko na neend aaye chain
// Maine kare kaand, kitne kaam, mera chale naam
// Girebaan mein bhi gire bomb, lage Vietnam
// Dere jaan, dere balidaan, wo bhi sare-aam
// Maine kare harm, katleaam, main na pareshaan (Damn)

// """
