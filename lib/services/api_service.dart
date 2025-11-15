// lib/services/api_service.dart
import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "https://smartchatgraduation.onrender.com";

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      "Content-Type": "application/json",
    },
  ));

  // LOGIN → /login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(
      "/login",
      data: {
        "email": email,
        "password": password,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  // SIGNUP → /signup
  Future<Map<String, dynamic>> signup(
      String username, String email, String password) async {
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
}
