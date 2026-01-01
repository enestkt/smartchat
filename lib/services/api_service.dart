// lib/services/api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      "https://smartchatgraduation.onrender.com";

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

  
}
