import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _userId;
  int? get userId => _userId;

  String? lastError; // hata mesajı

 Future<bool> login(String email, String password) async {
  _isLoading = true;
  notifyListeners();

  print("LOGIN REQUEST -> $email  |  $password");

  try {
    final data = await _api.login(email, password);

    print("LOGIN RESPONSE -> $data");

    if (data["success"] == true) {
      _userId = data["user_id"];
      await _storage.write(key: 'user_id', value: _userId.toString());
      lastError = null;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    lastError = data["message"] ?? "Login failed.";
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
    notifyListeners();

    try {
      final data = await _api.signup(username, email, password);

      if (data["success"] == true) {
        lastError = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      lastError = data["message"] ?? "Signup failed.";
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
