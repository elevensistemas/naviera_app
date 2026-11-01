import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/intranet_crew_catalog.dart';
import '../services/crew_profile_service.dart';
import 'app_navigator.dart';
import 'url_cleaner.dart';

/// Franjas horarias oficiales de Naviera Cruz del Sur:
/// - Mañana: 06:00 a 13:59
/// - Tarde: 14:00 a 19:59
/// - Noche: 20:00 a 05:59
enum DayTimeSlot { manana, tarde, noche }

class NcsHeroSchedule {
  /// Determina la franja horaria según la hora local del dispositivo:
  /// - Mañana: 06:00 (360m) a 13:59 (839m)
  /// - Tarde: 14:00 (840m) a 19:59 (1199m)
  /// - Noche: 20:00 (1200m) a 05:59 (359m)
  static DayTimeSlot getTimeSlot([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    if (hour >= 6 && hour < 14) {
      return DayTimeSlot.manana;
    } else if (hour >= 14 && hour < 20) {
      return DayTimeSlot.tarde;
    } else {
      return DayTimeSlot.noche;
    }
  }

  /// Retorna el asset oficial de Flutter para un buque y horario:
  /// - ALFA C: alfa_dia (mañana), alfa_tarde (tarde), alfa_noche (noche)
  /// - NANY: nany_dia (mañana), nany_tarde (tarde), nany_noche (noche)
  /// - GUSTAVO U: banner_flota.png (asset disponible corporativo sin usar fotos de otro buque)
  /// - Neutral (desembarcado, sin buque o buque no habilitado como MONARCA I): banner_flota.png
  static String getAssetForShip(String? shipName, [DateTime? time]) {
    if (shipName == null || shipName.trim().isEmpty) {
      return 'assets/images/banner_flota.png';
    }

    final s = shipName.toUpperCase().trim();
    final slot = getTimeSlot(time);

    // MONARCA I está estrictamente excluido de la aplicación -> Estado neutral
    if (s.contains('MONARCA')) {
      return 'assets/images/banner_flota.png';
    }

    if (s.contains('ALFA')) {
      switch (slot) {
        case DayTimeSlot.manana:
          return 'assets/images/alfa_dia.png';
        case DayTimeSlot.tarde:
          return 'assets/images/alfa_tarde.png';
        case DayTimeSlot.noche:
          return 'assets/images/alfa_noche.png';
      }
    }

    if (s.contains('NANY')) {
      switch (slot) {
        case DayTimeSlot.manana:
          return 'assets/images/nany_dia.png';
        case DayTimeSlot.tarde:
          return 'assets/images/nany_tarde.png';
        case DayTimeSlot.noche:
          return 'assets/images/nany_noche.png';
      }
    }

    if (s.contains('GUSTAVO')) {
      // Requisito: No utilizar imágenes de otro buque como reemplazo.
      // Reutiliza el asset corporativo oficial de flota disponible para GUSTAVO U.
      return 'assets/images/banner_flota.png';
    }

    // Estado neutral por defecto
    return 'assets/images/banner_flota.png';
  }
}

class SessionManager with ChangeNotifier, WidgetsBindingObserver {
  static final SessionManager shared = SessionManager._internal();
  SessionManager._internal();

  final _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isDarkMode = false;
  Set<String> _blockedUserIds = {};
  int _unreadNotificationCount = 0;
  Timer? _timeSlotTimer;

  // Situación activa de dotación para tripulantes (sincronizada desde API de Intranet)
  String? _activeCrewShip;
  bool? _isCrewOnBoard;

  String? get activeCrewShip => _activeCrewShip;
  bool? get isCrewOnBoard => _isCrewOnBoard;

  void updateCrewShipStatus({String? shipName, bool? isOnBoard}) {
    bool changed = false;
    if (_activeCrewShip != shipName) {
      _activeCrewShip = shipName;
      changed = true;
    }
    if (_isCrewOnBoard != isOnBoard) {
      _isCrewOnBoard = isOnBoard;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

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
  static const String _officeShipKey = "com.navieracruz.officeSelectedShip";

  // Catálogo oficial de buques seleccionables para Oficina (MONARCA I estrictamente excluido)
  static const List<String> officeShips = ['ALFA C', 'NANY', 'GUSTAVO U'];

  // Catálogo histórico de portadas para compatibilidad
  static const List<Map<String, String>> officeCoversList = [
    {'name': 'Alfa C - Día', 'asset': 'assets/images/alfa_dia.png', 'ship': 'ALFA C'},
    {'name': 'Alfa C - Atardecer', 'asset': 'assets/images/alfa_tarde.png', 'ship': 'ALFA C'},
    {'name': 'Alfa C - Noche', 'asset': 'assets/images/alfa_noche.png', 'ship': 'ALFA C'},
    {'name': 'Nany - Día', 'asset': 'assets/images/nany_dia.png', 'ship': 'NANY'},
    {'name': 'Nany - Tarde', 'asset': 'assets/images/nany_tarde.png', 'ship': 'NANY'},
    {'name': 'Nany - Noche', 'asset': 'assets/images/nany_noche.png', 'ship': 'NANY'},
  ];

  String _officeSelectedShip = 'ALFA C';
  String get officeSelectedShip => _officeSelectedShip;

  void setOfficeShip(String ship) {
    final sUpper = ship.toUpperCase().trim();
    String? matched;
    for (final s in officeShips) {
      if (s == sUpper || s.contains(sUpper) || sUpper.contains(s)) {
        matched = s;
        break;
      }
    }
    if (matched == null) return;
    _officeSelectedShip = matched;
    try {
      _prefs.setString(_officeShipKey, _officeSelectedShip);
    } catch (_) {}
    notifyListeners();
  }

  void nextOfficeShip() {
    final idx = officeShips.indexOf(_officeSelectedShip);
    final nextIdx = (idx + 1) % officeShips.length;
    setOfficeShip(officeShips[nextIdx]);
  }

  void previousOfficeShip() {
    final idx = officeShips.indexOf(_officeSelectedShip);
    final prevIdx = (idx - 1 + officeShips.length) % officeShips.length;
    setOfficeShip(officeShips[prevIdx]);
  }

  // Compatibilidad con código previo de portadas y gestos de cabecera
  void nextOfficeCover() => nextOfficeShip();
  void previousOfficeCover() => previousOfficeShip();
  void cycleOfficeCover() => nextOfficeShip();
  void toggleOfficeShipCover() => nextOfficeShip();

  int get officeCoverIndex => officeShips.indexOf(_officeSelectedShip);
  String get currentOfficeShipName => _officeSelectedShip;
  String get currentOfficeCoverName {
    final slot = NcsHeroSchedule.getTimeSlot();
    final slotStr = slot == DayTimeSlot.manana ? 'Mañana' : (slot == DayTimeSlot.tarde ? 'Tarde' : 'Noche');
    return "$_officeSelectedShip - $slotStr";
  }

  /// Retorna si el usuario actual pertenece a la dotación/tripulación del buque NANY
  bool get isUserNanyCrew {
    final u = _currentUser;
    if (u == null) return false;

    if (_activeCrewShip != null) {
      return _activeCrewShip!.toUpperCase().contains('NANY');
    }

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'NANY') return true;
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C' || shipParam == 'GUSTAVO' || shipParam == 'GUSTAVO U') return false;
    } catch (_) {}

    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('ALFA') || sectorUpper.contains('GUSTAVO')) return false;
    if (sectorUpper.contains('NANY')) return true;

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

    if (_activeCrewShip != null) {
      return _activeCrewShip!.toUpperCase().contains('ALFA');
    }

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C') return true;
      if (shipParam == 'NANY' || shipParam == 'GUSTAVO' || shipParam == 'GUSTAVO U') return false;
    } catch (_) {}

    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('NANY') || sectorUpper.contains('GUSTAVO')) return false;
    if (sectorUpper.contains('ALFA')) return true;

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

    if (_activeCrewShip != null) {
      return _activeCrewShip!.toUpperCase().contains('GUSTAVO');
    }

    try {
      final shipParam = Uri.base.queryParameters['ship']?.toUpperCase();
      if (shipParam == 'GUSTAVO' || shipParam == 'GUSTAVOU' || shipParam == 'GUSTAVO U') return true;
      if (shipParam == 'ALFA' || shipParam == 'ALFAC' || shipParam == 'ALFA C' || shipParam == 'NANY') return false;
    } catch (_) {}

    if (!isTripulanteMode || isUserAdmin) return false;

    final sectorUpper = u.sector.toUpperCase();
    if (sectorUpper.contains('ALFA') || sectorUpper.contains('NANY')) return false;
    if (sectorUpper.contains('GUSTAVO')) return true;

    final member = IntranetCrewCatalog.findCrewMember(u.name);
    if (member != null &&
        member.shipName != null &&
        member.shipName!.toUpperCase().contains('GUSTAVO')) {
      return true;
    }

    return false;
  }

  @visibleForTesting
  void setCurrentUserForTesting(User? user) {
    _forceLoggedOut = false;
    _overrideTripulante = null;
    _currentUser = user;
    _isAuthenticated = user != null;
    _activeCrewShip = null;
    _isCrewOnBoard = null;
    notifyListeners();
  }

  /// Resuelve dinámicamente el asset del Hero:
  /// - Para tripulantes: según situación oficial vigente de la Intranet y franja horaria.
  ///   - Desembarcado / En tierra: estado neutral ('assets/images/banner_flota.png')
  ///   - Embarcado en ALFA C: alfa_dia (06:00-13:59), alfa_tarde (14:00-19:59), alfa_noche (20:00-05:59)
  ///   - Embarcado en NANY: nany_dia (06:00-13:59), nany_tarde (14:00-19:59), nany_noche (20:00-05:59)
  ///   - Embarcado en GUSTAVO U: 'assets/images/banner_flota.png' (asset propio de flota)
  ///   - Buque no habilitado (ej: MONARCA I): estado neutral
  /// - Para oficina: buque libremente seleccionado (ALFA C, NANY o GUSTAVO U) según la franja horaria.
  String get activeCoverAsset {
    try {
      final qCover = Uri.base.queryParameters['cover']?.toLowerCase();
      final qShip = Uri.base.queryParameters['ship']?.toUpperCase();
      final qTime = Uri.base.queryParameters['time']?.toLowerCase();

      if (qCover != null) {
        if (qCover.contains('alfa')) {
          if (qCover.contains('dia')) return 'assets/images/alfa_dia.png';
          if (qCover.contains('noche')) return 'assets/images/alfa_noche.png';
          return 'assets/images/alfa_tarde.png';
        }
        if (qCover.contains('nany')) {
          if (qCover.contains('dia')) return 'assets/images/nany_dia.png';
          if (qCover.contains('tarde')) return 'assets/images/nany_tarde.png';
          if (qCover.contains('noche')) return 'assets/images/nany_noche.png';
          return 'assets/images/nany_dia.png';
        }
        if (qCover.contains('gustavo') || qCover.contains('neutral') || qCover.contains('flota')) {
          return 'assets/images/banner_flota.png';
        }
      }

      if (qShip != null) {
        DateTime? mockTime;
        if (qTime == 'dia' || qTime == 'manana') mockTime = DateTime(2026, 11, 1, 9, 0);
        if (qTime == 'tarde') mockTime = DateTime(2026, 11, 1, 15, 0);
        if (qTime == 'noche') mockTime = DateTime(2026, 11, 1, 22, 0);
        return NcsHeroSchedule.getAssetForShip(qShip, mockTime);
      }
    } catch (_) {}

    final now = DateTime.now();

    // 1. Perfil de Tripulación
    if (isTripulanteMode) {
      // Si está registrado como desembarcado / en tierra -> Estado neutral
      if (_isCrewOnBoard == false) {
        return 'assets/images/banner_flota.png';
      }

      // Si tenemos buque confirmado por la API
      if (_activeCrewShip != null && _activeCrewShip!.trim().isNotEmpty) {
        if (_activeCrewShip!.toUpperCase().contains('MONARCA')) {
          return 'assets/images/banner_flota.png'; // Buque no habilitado
        }
        return NcsHeroSchedule.getAssetForShip(_activeCrewShip, now);
      }

      // Fallback a detección por catálogo mientras se completa la consulta de perfil
      if (isUserNanyCrew) {
        return NcsHeroSchedule.getAssetForShip('NANY', now);
      } else if (isUserAlfaCrew) {
        return NcsHeroSchedule.getAssetForShip('ALFA C', now);
      } else if (isUserGustavoCrew) {
        return NcsHeroSchedule.getAssetForShip('GUSTAVO U', now);
      }

      // Estado neutral por defecto para tripulantes sin buque asignado o desembarcados
      return 'assets/images/banner_flota.png';
    }

    // 2. Perfil de Oficina: buque seleccionado libremente por el usuario
    return NcsHeroSchedule.getAssetForShip(_officeSelectedShip, now);
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

    _officeSelectedShip = _prefs.getString(_officeShipKey) ?? 'ALFA C';
    if (!officeShips.contains(_officeSelectedShip)) {
      _officeSelectedShip = 'ALFA C';
    }

    // Registro de observador de ciclo de vida para refresco al regresar de segundo plano
    WidgetsBinding.instance.addObserver(this);

    // Temporizador de baja frecuencia (1 minuto) para verificar franjas horarias
    _startTimeSlotTimer();

    await checkSession();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    _blockedUserIds = (_prefs.getStringList(_blockedKey) ?? []).toSet();
  }

  void _startTimeSlotTimer() {
    _timeSlotTimer?.cancel();
    _timeSlotTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeSlotTimer?.cancel();
    super.dispose();
  }

  Future<void> checkSession() async {
    if (_forceLoggedOut) {
      _isAuthenticated = false;
      _currentUser = null;
      _activeCrewShip = null;
      _isCrewOnBoard = null;
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
          _activeCrewShip = 'NANY';
          _isCrewOnBoard = true;
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
            _activeCrewShip = catalogMember.shipName;
            _isCrewOnBoard = catalogMember.isOnBoard;
            notifyListeners();
            return;
          }
          if (userParam.toLowerCase().contains('lopresti') || userParam.toLowerCase() == 'ale') {
            _currentUser = User(
              id: "1",
              name: "Alejandro Lo Presti",
              role: "Personal de Oficina",
              sector: "Oficina Central",
              avatarURL: "https://i.pravatar.cc/150?img=60",
            );
            _isAuthenticated = true;
            _activeCrewShip = null;
            _isCrewOnBoard = false;
            notifyListeners();
            return;
          }
        }

        if (role == 'tripulante') {
          _currentUser = User(
            id: "108",
            name: "Carrá Leonel",
            role: "Capitán",
            sector: "Buque ALFA C",
            avatarURL: "",
          );
          _isAuthenticated = true;
          _activeCrewShip = 'ALFA C';
          _isCrewOnBoard = true;
          notifyListeners();
          return;
        } else if (role == 'oficina') {
          _currentUser = User(
            id: "1",
            name: "Alejandro Lo Presti",
            role: "Personal de Oficina",
            sector: "Oficina Central",
            avatarURL: "https://i.pravatar.cc/150?img=60",
          );
          _isAuthenticated = true;
          _activeCrewShip = null;
          _isCrewOnBoard = false;
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
            role: "Personal de Oficina",
            sector: "Oficina Central",
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
    _activeCrewShip = null;
    _isCrewOnBoard = null;
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
    _activeCrewShip = null;
    _isCrewOnBoard = null;
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
