import 'package:flutter/foundation.dart';
import '../models/crew_profile.dart';
import '../models/models.dart';
import '../models/intranet_crew_catalog.dart';
import '../core/network.dart';
import '../core/storage.dart';

abstract class CrewProfileService {
  Future<CrewProfile> fetchCurrentCrewProfile({required User? currentUser});

  factory CrewProfileService() {
    return ProductionCrewProfileService.shared;
  }
}

class ProductionCrewProfileService implements CrewProfileService {
  static final ProductionCrewProfileService shared = ProductionCrewProfileService._internal();
  ProductionCrewProfileService._internal();

  factory ProductionCrewProfileService() => shared;

  CrewProfile? _cachedProfile;
  String? _cachedUserId;

  /// Limpia la memoria caché de datos personales al cerrar sesión o cambiar de cuenta
  static void clearCache() {
    shared._cachedProfile = null;
    shared._cachedUserId = null;
  }

  @override
  Future<CrewProfile> fetchCurrentCrewProfile({required User? currentUser}) async {
    final uid = currentUser?.id ?? '';

    if (currentUser == null || uid.isEmpty) {
      return CrewProfile.unlinked(name: "Usuario no autenticado", userId: "anon");
    }

    // Si ya lo tenemos en memoria para el mismo usuario autenticado, retornarlo
    if (_cachedProfile != null && _cachedUserId == uid) {
      return _cachedProfile!;
    }

    try {
      // 1. Intentar endpoint directo de perfil de sesión /api/v1/profile/
      try {
        final profileRes = await APIClient.shared.request(endpoint: '/api/v1/profile/');
        if (profileRes is Map<String, dynamic>) {
          if (profileRes['crew_member_detail'] is Map<String, dynamic>) {
            final crewData = profileRes['crew_member_detail'] as Map<String, dynamic>;
            final profile = CrewProfile.fromIntranet(json: crewData);
            _cachedProfile = profile;
            _cachedUserId = uid;
            SessionManager.shared.updateCrewShipStatus(
              shipName: profile.shipName,
              isOnBoard: profile.isOnBoard,
            );
            return profile;
          } else if (profileRes['crew_member'] is Map<String, dynamic>) {
            final crewData = profileRes['crew_member'] as Map<String, dynamic>;
            final profile = CrewProfile.fromIntranet(json: crewData);
            _cachedProfile = profile;
            _cachedUserId = uid;
            SessionManager.shared.updateCrewShipStatus(
              shipName: profile.shipName,
              isOnBoard: profile.isOnBoard,
            );
            return profile;
          } else if (profileRes['crew_member'] != null) {
            // El backend devuelve el ID entero de crew_member (ej: 108)
            final cmId = profileRes['crew_member'].toString();
            try {
              final cmRes = await APIClient.shared.request(endpoint: '/api/v1/crew-members/$cmId/');
              if (cmRes is Map<String, dynamic>) {
                final profile = CrewProfile.fromIntranet(json: cmRes);
                _cachedProfile = profile;
                _cachedUserId = uid;
                SessionManager.shared.updateCrewShipStatus(
                  shipName: profile.shipName,
                  isOnBoard: profile.isOnBoard,
                );
                return profile;
              }
            } catch (e) {
              debugPrint("Notice: /api/v1/crew-members/$cmId/ query: $e");
            }
          }
        }
      } catch (e) {
        debugPrint("Notice: /api/v1/profile/ direct crew info: $e");
      }

      // 2. Consultar /api/v1/crew-members/ vinculando con la identidad del usuario
      Map<String, dynamic>? matchedCrewJson;
      try {
        final userParam = Uri.encodeComponent(uid);
        dynamic crewRes;
        try {
          crewRes = await APIClient.shared.request(endpoint: '/api/v1/crew-members/?user=$userParam');
        } catch (_) {
          crewRes = await APIClient.shared.request(endpoint: '/api/v1/crew-members/');
        }

        List rawList = [];
        if (crewRes is List) {
          rawList = crewRes;
        } else if (crewRes is Map<String, dynamic>) {
          rawList = (crewRes['results'] ?? crewRes['data']) as List? ?? [];
        }

        if (rawList.isEmpty) {
          final allCrew = await APIClient.shared.request(endpoint: '/api/v1/crew-members/');
          if (allCrew is List) {
            rawList = allCrew;
          } else if (allCrew is Map<String, dynamic>) {
            rawList = (allCrew['results'] ?? allCrew['data']) as List? ?? [];
          }
        }

        String normalize(String input) {
          var s = input.toLowerCase().trim();
          s = s.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
          return s;
        }

        final uIdLower = normalize(uid);
        final uNameNorm = normalize(currentUser.name);
        final uWords = uNameNorm.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

        for (final item in rawList) {
          if (item is! Map<String, dynamic>) continue;
          final cUserId = item['user']?.toString().toLowerCase();
          final userDetail = item['user_detail'] as Map<String, dynamic>?;
          final cUsername = userDetail?['username']?.toString().toLowerCase();
          final cNameRaw = (item['name']?.toString() ?? '');
          final cNameNorm = normalize(cNameRaw);
          final cWords = cNameNorm.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();

          final bool wordsMatch = cWords.isNotEmpty && uWords.isNotEmpty &&
              (cWords.containsAll(uWords) || uWords.containsAll(cWords));

          if (cUserId == uIdLower ||
              cUsername == uIdLower ||
              (cUsername != null && uIdLower.contains(cUsername)) ||
              (cNameNorm.isNotEmpty && (cNameNorm == uNameNorm || wordsMatch))) {
            matchedCrewJson = item;
            break;
          }
        }
      } catch (e) {
        debugPrint("Notice: /api/v1/crew-members/ query: $e");
      }

      // 3. Si se localizó el registro del tripulante, consultar su situación de embarque oficial
      if (matchedCrewJson != null) {
        Map<String, dynamic>? situationJson =
            matchedCrewJson['current_situation_detail'] as Map<String, dynamic>?;

        final crewMemberId = matchedCrewJson['id']?.toString();
        if (situationJson == null && crewMemberId != null && crewMemberId.isNotEmpty) {
          try {
            final sitRes = await APIClient.shared.request(endpoint: '/api/v1/crew-situations/?crew_member=$crewMemberId');
            if (sitRes is List && sitRes.isNotEmpty) {
              situationJson = sitRes.first as Map<String, dynamic>;
            } else if (sitRes is Map<String, dynamic> && sitRes['results'] is List && (sitRes['results'] as List).isNotEmpty) {
              situationJson = sitRes['results'][0] as Map<String, dynamic>;
            }
          } catch (e) {
            debugPrint("Notice: /api/v1/crew-situations/?crew_member= query: $e");
          }
        }

        final profile = CrewProfile.fromIntranet(json: matchedCrewJson, situationJson: situationJson);
        _cachedProfile = profile;
        _cachedUserId = uid;
        SessionManager.shared.updateCrewShipStatus(
          shipName: profile.shipName,
          isOnBoard: profile.isOnBoard,
        );
        return profile;
      }

      // 4. Si la API remota no arrojó resultado, consultar en el padrón oficial de la Intranet (89 tripulantes)
      final catalogMember = IntranetCrewCatalog.findCrewMember(currentUser.name) ??
          IntranetCrewCatalog.findCrewMember(currentUser.id);
      if (catalogMember != null) {
        final profile = CrewProfile.fromCatalog(catalogMember);
        _cachedProfile = profile;
        _cachedUserId = uid;
        SessionManager.shared.updateCrewShipStatus(
          shipName: profile.shipName,
          isOnBoard: profile.isOnBoard,
        );
        return profile;
      }

      // 5. Si el usuario está autenticado pero no tiene registro de tripulante en la intranet (ej: oficina)
      final unlinkedProfile = CrewProfile.unlinked(
        name: currentUser.name,
        userId: currentUser.id,
      );
      _cachedProfile = unlinkedProfile;
      _cachedUserId = uid;
      SessionManager.shared.updateCrewShipStatus(
        shipName: null,
        isOnBoard: false,
      );
      return unlinkedProfile;

    } catch (e) {
      // 6. En caso de error de red o timeout, consultar padrón oficial de la Intranet antes de dar error
      debugPrint("Error fetching crew profile: $e");
      final catalogMember = IntranetCrewCatalog.findCrewMember(currentUser.name) ??
          IntranetCrewCatalog.findCrewMember(currentUser.id);
      if (catalogMember != null) {
        final profile = CrewProfile.fromCatalog(catalogMember);
        _cachedProfile = profile;
        _cachedUserId = uid;
        SessionManager.shared.updateCrewShipStatus(
          shipName: profile.shipName,
          isOnBoard: profile.isOnBoard,
        );
        return profile;
      }

      return CrewProfile.error(
        name: currentUser.name,
        errorMessage: e.toString(),
      );
    }
  }
}
