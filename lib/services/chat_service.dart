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

  /// Mesaj gönderme
  Future<bool> sendMessage(
      int senderId, int receiverId, String message) async {
    try {
      await _dio.post("/messages", data: {
        "sender_id": senderId,
        "receiver_id": receiverId,
        "content": message,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
