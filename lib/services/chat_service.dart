import 'package:dio/dio.dart';

class ChatService {
  static const String baseUrl = "https://smartchatgraduation.onrender.com";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
  ));

  /// Kullanıcı arama
  Future<Map<String, dynamic>?> searchUser(String username) async {
    try {
      final res = await _dio.get("/user_by_username/$username");

      if (res.data["success"] == true) {
        return res.data["user"];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mesaj yükleme
  Future<List<dynamic>> fetchMessages(int senderId, int receiverId) async {
    final res = await _dio.get(
      "/messages",
      queryParameters: {
        "sender_id": senderId,
        "receiver_id": receiverId,
      },
    );
    return res.data["messages"] ?? [];
  }

  /// Chat partner listesi
  Future<List<dynamic>> getChatPartners(int userId) async {
    final res = await _dio.get("/chat_partners/$userId");
    return res.data ?? [];
  }

  /// Mesaj gönderme (text)
  Future<bool> sendMessage(int senderId, int receiverId, String message) async {
    try {
      await _dio.post("/messages", data: {
        "sender_id": senderId,
        "receiver_id": receiverId,
        "content": message,
      });
      return true;
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

      return res.statusCode == 200;
    } catch (e) {
      print("UPLOAD MEDIA ERROR: $e");
      return false;
    }
  }
}
