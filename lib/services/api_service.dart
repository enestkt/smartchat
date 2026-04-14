// lib/services/api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      "http://10.0.2.2:5000";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        "Content-Type": "application/json",
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // -------------------------------------------------------------
  // LOGIN → /login
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final res = await _dio.post(
      "/login",
      data: {
        "email": email,
        "password": password,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // SIGNUP → /signup
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> signup(
      String username,
      String email,
      String password,
      ) async {
    final res = await _dio.post(
      "/signup",
      data: {
        "username": username,
        "email": email,
        "password": password,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // AI QUICK INFO (BALONCUK) → /predict
  // Küçük bilgi baloncuğu (duygu / stil / kısa analiz)
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> predictMessage({
    required String text,
    required int senderId,
    required int receiverId,
  }) async {
    final res = await _dio.post(
      "/predict",
      data: {
        "text": text,
        "sender_id": senderId,
        "receiver_id": receiverId,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // AI MESSAGE SUGGESTION → /complete
  // Mesajı yeniden yazma / tamamlama (ana AI öneri)
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> completeMessage({
    required String text,
    required int senderId,
    required int receiverId,
    required String receiverUsername,
  }) async {
    final res = await _dio.post(
      "/complete",
      data: {
        "text": text,
        "sender_id": senderId,
        "receiver_id": receiverId,
        "receiver_username": receiverUsername,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // SUGGESTION ACCEPT / REJECT → /suggestions/{id}
  // (ŞİMDİ KULLANILMAYACAK, SONRA)
  // -------------------------------------------------------------
  Future<void> updateSuggestionStatus({
    required int suggestionId,
    required bool accepted,
  }) async {
    await _dio.patch(
      "/suggestions/$suggestionId",
      data: {
        "accepted": accepted,
      },
    );
  }

  // -------------------------------------------------------------
  // RELATIONSHIP HISTORY → /relationships/{user1_id}/{user2_id}/history
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getRelationshipHistory({
    required int user1Id,
    required int user2Id,
  }) async {
    final res = await _dio.get(
      "/relationships/$user1Id/$user2Id/history",
    );
    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // SMART REPLIES → /smart_replies
  // -------------------------------------------------------------
  Future<List<String>> getSmartReplies({
    required int senderId,
    required int receiverId,
    required String lastMessage,
  }) async {
    try {
      final res = await _dio.post(
        "/smart_replies",
        data: {
          "sender_id": senderId,
          "receiver_id": receiverId,
          "last_message": lastMessage,
        },
      );
      
      if (res.data != null && res.data["replies"] != null) {
        return List<String>.from(res.data["replies"]);
      }
      return [];
    } catch (e) {
      print("getSmartReplies error: $e");
      return [];
    }
  }
}