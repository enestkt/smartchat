// lib/services/api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:9000";

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
  Future<List<Map<String, dynamic>>> getSmartReplies({
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
        return List<Map<String, dynamic>>.from(
          (res.data["replies"] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return [];
    } catch (e) {
      print("getSmartReplies error: $e");
      return [];
    }
  }

  // -------------------------------------------------------------
  // PROFILE → /profile/{user_id}
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getProfile(int userId) async {
    final res = await _dio.get("/profile/$userId");
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> updateAbout({
    required int userId,
    required String about,
  }) async {
    final res = await _dio.patch(
      "/profile/$userId",
      data: {"about": about},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> uploadProfilePicture({
    required int userId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post(
      "/profile/$userId/picture",
      data: formData,
      options: Options(
        headers: {"Content-Type": "multipart/form-data"},
      ),
    );
    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // SUGGESTION ANALYTICS → /suggestion_analytics/{user_id}
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getSuggestionAnalytics(int userId) async {
    try {
      final res = await _dio.get("/suggestion_analytics/$userId");
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      return {};
    }
  }

  // -------------------------------------------------------------
  // CONVERSATION STATS → /conversation_stats/{user1_id}/{user2_id}
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getConversationStats({
    required int user1Id,
    required int user2Id,
  }) async {
    try {
      final res = await _dio.get("/conversation_stats/$user1Id/$user2Id");
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      return {};
    }
  }

  // -------------------------------------------------------------
  // REPHRASE → /rephrase
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRephrase({
    required String text,
    required int senderId,
    required int receiverId,
  }) async {
    final res = await _dio.post(
      "/rephrase",
      data: {
        "text": text,
        "sender_id": senderId,
        "receiver_id": receiverId,
      },
    );
    if (res.data != null && res.data["versions"] != null) {
      return List<Map<String, dynamic>>.from(
        (res.data["versions"] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    return [];
  }

  // -------------------------------------------------------------
  // CONVERSATION SUMMARY → /conversation_summary
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getConversationSummary({
    required int senderId,
    required int receiverId,
    int limit = 50,
  }) async {
    final res = await _dio.post(
      "/conversation_summary",
      data: {
        "sender_id": senderId,
        "receiver_id": receiverId,
        "limit": limit,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  // -------------------------------------------------------------
  // MOOD FORECAST → /mood_forecast
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> getMoodForecast({
    required int senderId,
    required int receiverId,
  }) async {
    try {
      final res = await _dio.get("/mood_forecast/$senderId/$receiverId");
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print("getMoodForecast error: $e");
      return {"mood": "neutral", "warning": ""};
    }
  }
}
