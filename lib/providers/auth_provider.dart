import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _userId;
  int? get userId => _userId;

  String? lastError;

  Future<void> loadSession() async {
    final savedUserId = await _storage.read(key: 'user_id');

    if (savedUserId != null) {
      _userId = int.tryParse(savedUserId);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    lastError = null;
    notifyListeners();

    print("LOGIN REQUEST -> $email | $password");

    try {
      final data = await _api.login(email, password);

      print("LOGIN RESPONSE -> $data");

      if (data["success"] == true) {
        final dynamic rawUserId = data["user_id"] ?? data["userId"];

        if (rawUserId == null) {
          lastError = "Login başarılı ama user_id dönmedi.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _userId = rawUserId is int ? rawUserId : int.tryParse(rawUserId.toString());

        if (_userId == null) {
          lastError = "Geçersiz user_id formatı.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _storage.write(key: 'user_id', value: _userId.toString());

        _isLoading = false;
        notifyListeners();
        return true;
      }

      lastError =
          data["message"]?.toString() ??
          data["error"]?.toString() ??
          "Login failed.";

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stack) {
      print("LOGIN ERROR -> $e");
      print(stack);
      lastError = "Server error: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    _isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      final data = await _api.signup(username, email, password);

      if (data["success"] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      lastError =
          data["message"]?.toString() ??
          data["error"]?.toString() ??
          "Signup failed.";

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      lastError = "Server error: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userId = null;
    await _storage.delete(key: 'user_id');
    notifyListeners();
  }
}