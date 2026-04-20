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

  // ─── PROFILE FIELDS ───
  String? _username;
  String? _email;
  String? _about;
  String? _profilePicture;

  String? get username => _username;
  String? get email => _email;
  String? get about => _about;
  String? get profilePicture => _profilePicture;

  Future<void> loadSession() async {
    final savedUserId = await _storage.read(key: 'user_id');

    if (savedUserId != null) {
      _userId = int.tryParse(savedUserId);
      notifyListeners();
      // Profil bilgilerini de yükle
      if (_userId != null) {
        await loadProfile();
      }
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

        // Login sonrası profil yükle
        await loadProfile();

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
    _username = null;
    _email = null;
    _about = null;
    _profilePicture = null;
    await _storage.delete(key: 'user_id');
    notifyListeners();
  }

  // ─── PROFILE ───
  Future<void> loadProfile() async {
    if (_userId == null) return;
    try {
      final data = await _api.getProfile(_userId!);
      if (data["success"] == true && data["profile"] != null) {
        final profile = data["profile"];
        _username = profile["username"];
        _email = profile["email"];
        _about = profile["about"];
        _profilePicture = profile["profile_picture"];
        notifyListeners();
      }
    } catch (e) {
      print("LOAD PROFILE ERROR -> $e");
    }
  }

  Future<void> updateAbout(String about) async {
    if (_userId == null) return;
    try {
      await _api.updateAbout(userId: _userId!, about: about);
      _about = about;
      notifyListeners();
    } catch (e) {
      print("UPDATE ABOUT ERROR -> $e");
    }
  }

  Future<void> updateProfilePicture(String filePath) async {
    if (_userId == null) return;
    try {
      final res = await _api.uploadProfilePicture(userId: _userId!, filePath: filePath);
      if (res["success"] == true) {
        _profilePicture = res["profile_picture"];
        notifyListeners();
      }
    } catch (e) {
      print("UPDATE PROFILE PIC ERROR -> $e");
    }
  }
}
