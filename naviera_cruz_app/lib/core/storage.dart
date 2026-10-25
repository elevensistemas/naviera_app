import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/intranet_crew_catalog.dart';
import '../services/crew_profile_service.dart';
import 'app_navigator.dart';
import 'url_cleaner.dart';

class SessionManager with ChangeNotifier {
  static final SessionManager shared = SessionManager._internal();
  SessionManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isDarkMode = false;
  Set<String> _blockedUserIds = {};
  int _unreadNotificationCount = 0;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  Set<String> get blockedUserIds => _blockedUserIds;
  int get unreadNotificationCount => _unreadNotificationCount;
  bool get hasUnreadNotifications => _unreadNotificationCount > 0;

  void setUnreadCount(int count) {
    _unreadNotificationCount = count < 0 ? 0 : count;
    notifyListeners();
  }

  void decrementUnreadCount() {
    if (_unreadNotificationCount > 0) {
      _unreadNotificationCount--;
      notifyListeners();
    }
  }

  void clearUnreadCount() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  static const String _tokenKey = "com.navieracruz.authToken";
  static const String _userKey = "com.navieracruz.currentUser";
  static const String _themeKey = "com.navieracruz.isDarkMode";
  static const String _blockedKey = "com.navieracruz.blockedUsers";
  static const String _officeCoverIndexKey = "com.navieracruz.officeCoverIndex";

  int _officeCoverIndex = 0;
  int get officeCoverIndex => _officeCoverIndex;

  /// Retorna si el usuario actual pertenece a la dotación/tripulación del buque NANY
  bool get isUserNanyCrew {
    final u = _currentUser;
    if (u == null) return false;

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'NANY') return true;
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C' || shipParam == 'GUSTAVO' || shipParam == 'GUSTAVO U') return false;
    } catch (_) {}

    // Usuarios de oficina / gerencia nunca son tripulación del Nany
    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('ALFA') || sectorUpper.contains('GUSTAVO')) return false;
    if (sectorUpper.contains('NANY')) return true;

    // Si coincide en el catálogo oficial de la Intranet con el buque NANY
    final member = IntranetCrewCatalog.findCrewMember(u.name);
    if (member != null &&
        member.shipName != null &&
        member.shipName!.toUpperCase().contains('NANY')) {
      return true;
    }

    return false;
  }

  /// Retorna si el usuario actual pertenece a la dotación/tripulación del buque ALFA C
  bool get isUserAlfaCrew {
    final u = _currentUser;
    if (u == null) return false;

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C') return true;
      if (shipParam == 'NANY' || shipParam == 'GUSTAVO' || shipParam == 'GUSTAVO U') return false;
    } catch (_) {}

    // Usuarios de oficina / gerencia nunca son tripulación
    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('NANY') || sectorUpper.contains('GUSTAVO')) return false;
    if (sectorUpper.contains('ALFA')) return true;

    // Si coincide en el catálogo oficial de la Intranet con el buque ALFA C
    final member = IntranetCrewCatalog.findCrewMember(u.name);
    if (member != null &&
        member.shipName != null &&
        member.shipName!.toUpperCase().contains('ALFA')) {
      return true;
    }

    return false;
  }

  /// Retorna si el usuario actual pertenece a la dotación/tripulación del buque GUSTAVO U
  bool get isUserGustavoCrew {
    final u = _currentUser;
    if (u == null) return false;

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'GUSTAVO' || shipParam == 'GUSTAVOU' || shipParam == 'GUSTAVO U') return true;
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C' || shipParam == 'NANY') return false;
    } catch (_) {}

    // Usuarios de oficina / gerencia nunca son tripulación
    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('ALFA') || sectorUpper.contains('NANY')) return false;
    if (sectorUpper.contains('GUSTAVO')) return true;

    // Si coincide en el catálogo oficial de la Intranet con el buque GUSTAVO U
    final member = IntranetCrewCatalog.findCrewMember(u.name);
    if (member != null &&
        member.shipName != null &&
        member.shipName!.toUpperCase().contains('GUSTAVO')) {
      return true;
    }

    return false;
  }

  /// Catálogo de portadas disponibles para oficina (Alfa C y Nany)
  static const List<Map<String, String>> officeCoversList = [
    {'name': 'Alfa C - Día', 'asset': 'assets/images/alfa_dia.png', 'ship': 'ALFA C'},
    {'name': 'Alfa C - Atardecer', 'asset': 'assets/images/header_bg.png', 'ship': 'ALFA C'},
    {'name': 'Alfa C - Noche', 'asset': 'assets/images/alfa_noche.png', 'ship': 'ALFA C'},
    {'name': 'Nany - Día', 'asset': 'assets/images/nany_dia.png', 'ship': 'NANY'},
    {'name': 'Nany - Tarde', 'asset': 'assets/images/nany_tarde.png', 'ship': 'NANY'},
    {'name': 'Nany - Noche', 'asset': 'assets/images/nany_noche.png', 'ship': 'NANY'},
  ];

  String get currentOfficeCoverName {
    final idx = _officeCoverIndex % officeCoversList.length;
    return officeCoversList[idx]['name']!;
  }

  String get currentOfficeShipName {
    final idx = _officeCoverIndex % officeCoversList.length;
    return officeCoversList[idx]['ship'] ?? 'ALFA C';
  }

  /// Alterna la portada de oficina al hacer doble clic o deslizar
  void cycleOfficeCover() {
    _officeCoverIndex = (_officeCoverIndex + 1) % officeCoversList.length;
    try {
      _prefs.setInt(_officeCoverIndexKey, _officeCoverIndex);
    } catch (_) {}
    notifyListeners();
  }

  /// Desliza hacia la siguiente portada (Alfa C y Nany)
  void nextOfficeCover() {
    cycleOfficeCover();
  }

  /// Desliza hacia la portada anterior (Alfa C y Nany)
  void previousOfficeCover() {
    _officeCoverIndex = (_officeCoverIndex - 1 + officeCoversList.length) % officeCoversList.length;
    try {
      _prefs.setInt(_officeCoverIndexKey, _officeCoverIndex);
    } catch (_) {}
    notifyListeners();
  }

  /// Conmuta directamente entre el buque Alfa C y Nany
  void toggleOfficeShipCover() {
    final current = officeCoversList[_officeCoverIndex % officeCoversList.length];
    final currentShip = current['ship'];
    for (int i = 0; i < officeCoversList.length; i++) {
      if (officeCoversList[i]['ship'] != currentShip) {
        _officeCoverIndex = i;
        try {
          _prefs.setInt(_officeCoverIndexKey, _officeCoverIndex);
        } catch (_) {}
        notifyListeners();
        return;
      }
    }
  }

  @visibleForTesting
  void setCurrentUserForTesting(User? user) {
    _forceLoggedOut = false;
    _overrideTripulante = null;
    _currentUser = user;
    _isAuthenticated = user != null;
    notifyListeners();
  }

  /// Resuelve la portada a utilizar según rol, buque y hora:
  /// - Para tripulantes de ALFA C:
  ///   - Día (06:00 a 17:00): 'assets/images/alfa_dia.png'
  ///   - Tarde (17:00 a 20:30): 'assets/images/header_bg.png' (Atardecer)
  ///   - Noche (20:30 a 06:00): 'assets/images/alfa_noche.png'
  /// - Para tripulantes de GUSTAVO U:
  ///   - Utiliza las portadas de ALFA C hasta conseguir fotos nuevas
  /// - Para tripulantes de NANY:
  ///   - Día (06:00 a 17:00): 'assets/images/nany_dia.png'
  ///   - Tarde (17:00 a 20:30): 'assets/images/nany_tarde.png'
  ///   - Noche (20:30 a 06:00): 'assets/images/nany_noche.png'
  /// - Para usuarios de oficina:
  ///   - Portadas deslizables entre Alfa C y Nany
  String get activeCoverAsset {
    try {
      final qCover = Uri.base.queryParameters['cover']?.toLowerCase();
      final qShip = Uri.base.queryParameters['ship']?.toLowerCase();
      final qTime = Uri.base.queryParameters['time']?.toLowerCase();

      if (qCover != null) {
        if (qCover.contains('alfa') || qCover.contains('gustavo')) {
          if (qCover.contains('dia')) return 'assets/images/alfa_dia.png';
          if (qCover.contains('noche')) return 'assets/images/alfa_noche.png';
          return 'assets/images/header_bg.png';
        }
        if (qCover.contains('dia')) return 'assets/images/nany_dia.png';
        if (qCover.contains('tarde')) return 'assets/images/nany_tarde.png';
        if (qCover.contains('noche')) return 'assets/images/nany_noche.png';
      }
      if (qShip != null) {
        if (qShip.contains('alfa') || qShip.contains('gustavo')) {
          if (qTime == 'dia') return 'assets/images/alfa_dia.png';
          if (qTime == 'tarde') return 'assets/images/header_bg.png';
          if (qTime == 'noche') return 'assets/images/alfa_noche.png';
          return 'assets/images/alfa_dia.png';
        } else if (qShip.contains('nany')) {
          if (qTime == 'dia') return 'assets/images/nany_dia.png';
          if (qTime == 'tarde') return 'assets/images/nany_tarde.png';
          if (qTime == 'noche') return 'assets/images/nany_noche.png';
          return 'assets/images/nany_dia.png';
        }
      }
      if (qTime == 'dia') return (isUserAlfaCrew || isUserGustavoCrew) ? 'assets/images/alfa_dia.png' : 'assets/images/nany_dia.png';
      if (qTime == 'tarde') return (isUserAlfaCrew || isUserGustavoCrew) ? 'assets/images/header_bg.png' : 'assets/images/nany_tarde.png';
      if (qTime == 'noche') return (isUserAlfaCrew || isUserGustavoCrew) ? 'assets/images/alfa_noche.png' : 'assets/images/nany_noche.png';
    } catch (_) {}

    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;

    // Tripulación de ALFA C y GUSTAVO U (Gustavo U utiliza las de Alfa C hasta fotos nuevas)
    if (isUserAlfaCrew || isUserGustavoCrew) {
      // Día: 06:00 (360m) a 17:00 (1020m)
      // Tarde: 17:00 (1020m) a 20:30 (1230m)
      // Noche: 20:30 (1230m) a 06:00 (360m)
      if (minutes >= 360 && minutes < 1020) {
        return 'assets/images/alfa_dia.png';
      } else if (minutes >= 1020 && minutes < 1230) {
        return 'assets/images/header_bg.png';
      } else {
        return 'assets/images/alfa_noche.png';
      }
    }

    // Tripulación exclusiva del NANY
    if (isUserNanyCrew) {
      if (minutes >= 360 && minutes < 1020) {
        return 'assets/images/nany_dia.png';
      } else if (minutes >= 1020 && minutes < 1230) {
        return 'assets/images/nany_tarde.png';
      } else {
        return 'assets/images/nany_noche.png';
      }
    }

    // Oficina: selección de portadas deslizables entre Alfa C y Nany
    final idx = _officeCoverIndex % officeCoversList.length;
    return officeCoversList[idx]['asset']!;
  }

  /// Verifica si el usuario autenticado tiene rol de administración o gerencia
  bool get isUserAdmin {
    final u = _currentUser;
    if (u == null) return false;
    final s = u.sector.toLowerCase();
    final r = u.role.toLowerCase();
    return s == 'gerencia' || r.contains('admin') || r.contains('director') || r.contains('gerente');
  }

  /// Determina si el usuario autenticado pertenece al rol de tripulación
  /// Utiliza el padrón oficial de 89 tripulantes (44 en tierra, 45 a bordo) de la Intranet.
  /// Cualquier usuario fuera de dicho padrón corresponde a OFICINA.
  bool get isUserTripulanteRole {
    final u = _currentUser;
    if (u == null) return false;
    return IntranetCrewCatalog.isTripulanteUser(
      name: u.name,
      role: u.role,
      sector: u.sector,
      username: u.id,
    );
  }

  bool? _overrideTripulante;
  bool _forceLoggedOut = false;

  /// Separación estricta de vistas según el rol del usuario:
  /// - Tripulantes -> Vista Tripulante ("Mi espacio a bordo", 4 pestañas).
  /// - Oficina / Gerencia -> Vista Oficina original (6 pestañas, sin asistente ni datos de buque).
  bool get isTripulanteMode {
    if (_forceLoggedOut) return false;
    if (_overrideTripulante != null) return _overrideTripulante!;

    // Si el usuario actual es de tripulación según el catálogo oficial,
    // tiene prioridad directa sobre parámetros de URL
    if (_currentUser != null) {
      if (isUserTripulanteRole) return true;
      if (isUserAdmin) return false;
    }

    try {
      final role = Uri.base.queryParameters['role'];
      if (role == 'tripulante' || role == 'nany') return true;
      if (role == 'oficina') return false;
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'NANY') return true;
    } catch (_) {}
    return isUserTripulanteRole;
  }

  void setTripulanteModeOverride(bool? override) {
    _overrideTripulante = override;
    notifyListeners();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Limpieza de cualquier persistencia previa para garantizar rol limpio
    await _prefs.remove("com.navieracruz.overrideTripulanteMode");
    _officeCoverIndex = _prefs.getInt(_officeCoverIndexKey) ?? 0;
    await checkSession();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    _blockedUserIds = (_prefs.getStringList(_blockedKey) ?? []).toSet();
  }

  Future<void> checkSession() async {
    if (_forceLoggedOut) {
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
      return;
    }

    try {
      final role = Uri.base.queryParameters['role'];
      final userParam = Uri.base.queryParameters['user'];
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (!_forceLoggedOut && (userParam != null || role != null || shipParam != null)) {
        if (shipParam == 'NANY') {
          _currentUser = User(
            id: "NA_01",
            name: "Hernandez Pablo",
            role: "Capitán",
            sector: "Buque NANY",
            avatarURL: "",
          );
          _isAuthenticated = true;
          notifyListeners();
          return;
        }
        if (userParam != null && userParam.isNotEmpty) {
          final catalogMember = IntranetCrewCatalog.findCrewMember(userParam);
          if (catalogMember != null) {
            _currentUser = User(
              id: catalogMember.id,
              name: catalogMember.name,
              role: catalogMember.roleName,
              sector: catalogMember.isOnBoard ? "Buque ${catalogMember.shipName}" : "En Tierra",
              avatarURL: "",
            );
            _isAuthenticated = true;
            notifyListeners();
            return;
          }
          if (userParam.toLowerCase().contains('lopresti') || userParam.toLowerCase() == 'ale') {
            _currentUser = User(
              id: "1",
              name: "Alejandro Lo Presti",
              role: "Gerencia General",
              sector: "Gerencia",
              avatarURL: "https://i.pravatar.cc/150?img=60",
            );
            _isAuthenticated = true;
            notifyListeners();
            return;
          }
        }

        if (role == 'tripulante') {
          _currentUser = User(
            id: "13",
            name: "Marenco Rubén Darío",
            role: "Capitán",
            sector: "Buque ALFA C",
            avatarURL: "",
          );
          _isAuthenticated = true;
          notifyListeners();
          return;
        } else if (role == 'oficina') {
          _currentUser = User(
            id: "1",
            name: "Alejandro Lo Presti",
            role: "Gerencia General",
            sector: "Gerencia",
            avatarURL: "https://i.pravatar.cc/150?img=60",
          );
          _isAuthenticated = true;
          notifyListeners();
          return;
        }
      }

      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        final userJson = _prefs.getString(_userKey);
        if (userJson != null) {
          _currentUser = User.fromJson(jsonDecode(userJson));
        } else {
          _currentUser = User(
            id: "1",
            name: "Alejandro Lo Presti",
            role: "Gerencia General",
            sector: "Gerencia",
            avatarURL: "https://i.pravatar.cc/150?img=60",
          );
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
    _forceLoggedOut = false;
    _overrideTripulante = null;
    cleanBrowserUrl();
    // Limpiar caché de datos personales previos
    ProductionCrewProfileService.clearCache();
    await _secureStorage.write(key: _tokenKey, value: token);
    _currentUser = user;
    _isAuthenticated = true;
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
    navigateToMain();
  }

  Future<void> logout() async {
    _forceLoggedOut = true;
    _overrideTripulante = null;
    cleanBrowserUrl();
    ProductionCrewProfileService.clearCache();
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Error deleting secure token: $e');
    }
    try {
      await _prefs.remove(_userKey);
      await _prefs.clear();
    } catch (e) {
      debugPrint('Error clearing prefs: $e');
    }
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
    navigateToLogin();
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
