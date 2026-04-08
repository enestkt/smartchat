import 'package:dio/dio.dart';

class ChatService {
  static const String baseUrl = "http://10.0.2.2:5000";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
  ));

  /// Kullanıcı arama
   Future<Map<String, dynamic>?> searchUser(String username) async {
    try {
      final res = await _dio.get("/user_by_username/$username");
      final data = Map<String, dynamic>.from(res.data);

      if (data["success"] == true) {
        if (data["user"] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data["user"]);
        }
        if (data["data"] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data["data"]);
        }
      }

      return null;
    } catch (e) {
      print("SEARCH USER ERROR: $e");
      return null;
    }
  }

  /// Mesaj yükleme
  Future<List<dynamic>> fetchMessages(int senderId, int receiverId) async {
    try {
      final res = await _dio.get(
        "/messages",
        queryParameters: {
          "sender_id": senderId,
          "receiver_id": receiverId,
        },
      );

      final data = Map<String, dynamic>.from(res.data);

      if (data["messages"] is List) {
        return List<dynamic>.from(data["messages"]);
      }

      if (data["data"] is List) {
        return List<dynamic>.from(data["data"]);
      }

      return [];
    } catch (e) {
      print("FETCH MESSAGES ERROR: $e");
      return [];
    }
  }

  /// Chat partner listesi
  Future<List<dynamic>> getChatPartners(int userId) async {
    try {
      final res = await _dio.get("/chat_partners/$userId");

      if (res.data is List) {
        return List<dynamic>.from(res.data);
      }

      if (res.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(res.data);

        if (data["partners"] is List) {
          return List<dynamic>.from(data["partners"]);
        }

        if (data["data"] is List) {
          return List<dynamic>.from(data["data"]);
        }
      }

      return [];
    } catch (e) {
      print("GET CHAT PARTNERS ERROR: $e");
      return [];
    }
  }


  /// Mesaj gönderme (text)
  Future<bool> sendMessage(int senderId, int receiverId, String message) async {
    try {
      final res = await _dio.post(
        "/messages",
        data: {
          "sender_id": senderId,
          "receiver_id": receiverId,
          "content": message,
        },
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("SEND MESSAGE ERROR: $e");
      return false;
    }
  }

  // -------------------------------------------------------------
  //  MEDIA UPLOAD (image, file, audio, video)
  // -------------------------------------------------------------
  Future<bool> uploadMedia({
    required int senderId,
    required int receiverId,
    required String filePath,
    required String mediaType,
  }) async {
    try {
      final fileName = filePath.split('/').last;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
        "media_type": mediaType,
        "sender_id": senderId.toString(),
        "receiver_id": receiverId.toString(),
      });

      final res = await _dio.post(
        "/upload_media",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
        ),
      );

      return res.statusCode == 200 || res.statusCode == 201; 
    } catch (e) {
      print("UPLOAD MEDIA ERROR: $e");
      return false;
    }
  }
}
