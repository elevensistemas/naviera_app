import 'package:flutter/foundation.dart';
import '../models/crew_profile.dart';
import '../models/models.dart';
import '../models/intranet_crew_catalog.dart';
import '../core/network.dart';

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
          if (profileRes['crew_member'] != null || profileRes['crew_member_detail'] != null) {
            final crewData = (profileRes['crew_member_detail'] ?? profileRes['crew_member']) as Map<String, dynamic>;
            final profile = CrewProfile.fromIntranet(json: crewData);
            _cachedProfile = profile;
            _cachedUserId = uid;
            return profile;
          }
        }
      } catch (e) {
        debugPrint("Notice: /api/v1/profile/ direct crew info: $e");
      }

      // 2. Consultar /api/v1/crew-members/ vinculando con la identidad del usuario
      Map<String, dynamic>? matchedCrewJson;
      try {
        final userParam = Uri.encodeComponent(uid);
        final crewRes = await APIClient.shared.request(endpoint: '/api/v1/crew-members/?user=$userParam');
        List rawList = [];
        if (crewRes is List) {
          rawList = crewRes;
        } else if (crewRes is Map<String, dynamic>) {
          rawList = (crewRes['results'] ?? crewRes['data']) as List? ?? [];
        }

        final uIdLower = uid.toLowerCase();
        final uNameLower = currentUser.name.toLowerCase();

        for (final item in rawList) {
          if (item is! Map<String, dynamic>) continue;
          final cUserId = item['user']?.toString().toLowerCase();
          final userDetail = item['user_detail'] as Map<String, dynamic>?;
          final cUsername = userDetail?['username']?.toString().toLowerCase();
          final cName = (item['name']?.toString() ?? '').toLowerCase();

          if (cUserId == uIdLower ||
              cUsername == uIdLower ||
              (cUsername != null && uIdLower.contains(cUsername)) ||
              (cName.isNotEmpty && (cName == uNameLower || uNameLower.contains(cName) || cName.contains(uNameLower)))) {
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
        return profile;
      }

      // 4. Si la API remota no arrojó resultado, consultar en el padrón oficial de la Intranet (89 tripulantes)
      final catalogMember = IntranetCrewCatalog.findCrewMember(currentUser.name) ??
          IntranetCrewCatalog.findCrewMember(currentUser.id);
      if (catalogMember != null) {
        final profile = CrewProfile.fromCatalog(catalogMember);
        _cachedProfile = profile;
        _cachedUserId = uid;
        return profile;
      }

      // 5. Si el usuario está autenticado pero no tiene registro de tripulante en la intranet
      //    Diferenciamos ausencia de registro de tripulante (ej: usuario administrativo o sin legajo)
      final unlinkedProfile = CrewProfile.unlinked(
        name: currentUser.name,
        userId: currentUser.id,
      );
      _cachedProfile = unlinkedProfile;
      _cachedUserId = uid;
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
        return profile;
      }

      return CrewProfile.error(
        name: currentUser.name,
        errorMessage: e.toString(),
      );
    }
  }
}
