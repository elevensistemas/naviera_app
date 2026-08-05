import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SessionManager with ChangeNotifier {
  static final SessionManager shared = SessionManager._internal();
  SessionManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isDarkMode = false;
  Set<String> _blockedUserIds = {};

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  Set<String> get blockedUserIds => _blockedUserIds;

  static const String _tokenKey = "com.navieracruz.authToken";
  static const String _userKey = "com.navieracruz.currentUser";
  static const String _themeKey = "com.navieracruz.isDarkMode";
  static const String _blockedKey = "com.navieracruz.blockedUsers";

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await checkSession();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    _blockedUserIds = (_prefs.getStringList(_blockedKey) ?? []).toSet();
  }

  Future<void> checkSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        final userJson = _prefs.getString(_userKey);
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
        } else {
          _currentUser = User(id: "1", name: "Usuario Autenticado", role: "Personal Naviera");
        }
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> login(String token, User user) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    _currentUser = user;
    _isAuthenticated = true;
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _prefs.remove(_userKey);
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_themeKey, value);
    notifyListeners();
  }

  Future<void> blockUser(String userId) async {
    _blockedUserIds.add(userId);
    await _prefs.setStringList(_blockedKey, _blockedUserIds.toList());
    notifyListeners();
  }

  Future<void> unblockUser(String userId) async {
    _blockedUserIds.remove(userId);
    await _prefs.setStringList(_blockedKey, _blockedUserIds.toList());
    notifyListeners();
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
}
