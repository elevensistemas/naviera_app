/// Catálogo oficial del Personal de Oficina de Naviera Cruz del Sur
/// Contiene exactamente el personal autorizado de oficina provisto por la administración:
/// 1. Miguel Piccinini (Jefe de Operaciones)
/// 2. Daniel Saffe
/// 3. Marcelo Garcia
/// 4. Julio Zarate
/// 5. Emmanuel Carnevale
/// 6. Nahuel Pedroso
/// 7. Ludia Duarte
/// 8. Miguel Monascal
/// 9. Belen Capara
/// 10. Antonella Mena

class IntranetOfficeMember {
  final String id;
  final String name;
  final String role;
  final String sector;
  final String username;
  final String email;

  const IntranetOfficeMember({
    required this.id,
    required this.name,
    required this.role,
    required this.sector,
    required this.username,
    required this.email,
  });
}

class IntranetOfficeCatalog {
  static const List<IntranetOfficeMember> members = [
    IntranetOfficeMember(
      id: "OF_01",
      name: "Miguel Piccinini",
      role: "Jefe de Operaciones",
      sector: "Operaciones",
      username: "m.piccinini",
      email: "m.piccinini@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_02",
      name: "Daniel Saffe",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "d.saffe",
      email: "d.saffe@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_03",
      name: "Marcelo Garcia",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "m.garcia",
      email: "m.garcia@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_04",
      name: "Julio Zarate",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "j.zarate",
      email: "j.zarate@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_05",
      name: "Emmanuel Carnevale",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "e.carnevale",
      email: "e.carnevale@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_06",
      name: "Nahuel Pedroso",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "n.pedroso",
      email: "n.pedroso@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_07",
      name: "Ludia Duarte",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "l.duarte",
      email: "l.duarte@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_08",
      name: "Miguel Monascal",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "m.monascal",
      email: "m.monascal@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_09",
      name: "Belen Capara",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "b.capara",
      email: "b.capara@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_10",
      name: "Antonella Mena",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "a.mena",
      email: "a.mena@navieracruzdelsur.com",
    ),
  ];

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('.', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .trim();
  }

  /// Busca un miembro del personal de oficina por nombre, apellido, usuario o correo
  static IntranetOfficeMember? findMember(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final normQuery = _normalize(query);
    if (normQuery.isEmpty) return null;

    // Búsqueda directa exacta
    for (final member in members) {
      if (_normalize(member.username) == normQuery ||
          _normalize(member.name) == normQuery ||
          _normalize(member.id) == normQuery ||
          _normalize(member.email) == normQuery) {
        return member;
      }
    }

    // Soporte para variantes de tipeo o nombres en Intranet (ej: Ludia / Lidia)
    if (normQuery.contains('duarte') && (normQuery.contains('ludia') || normQuery.contains('lidia') || normQuery.startsWith('lduarte'))) {
      return members.firstWhere((m) => m.username == 'l.duarte');
    }

    // Búsqueda por subcadena o coincidencia de apellido / nombre
    for (final member in members) {
      final normName = _normalize(member.name);
      final normUser = _normalize(member.username);
      if (normName.contains(normQuery) ||
          normQuery.contains(normName) ||
          normUser.contains(normQuery) ||
          normQuery.contains(normUser)) {
        return member;
      }
    }

    return null;
  }

  /// Indica si una consulta dada corresponde a personal de oficina
  static bool isOfficeMember(String? query) {
    return findMember(query) != null;
  }
}

