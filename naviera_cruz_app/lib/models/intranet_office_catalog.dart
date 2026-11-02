/// Catálogo oficial del Personal de Oficina de Naviera Cruz del Sur
/// Contiene exactamente el listado oficial provisto por la administración:
/// 1. Altamiranda Daniel
/// 2. Assalone Silvana
/// 3. Awdziej Nicolás
/// 4. Capara Belén
/// 5. Carnevale Emmanuel
/// 6. Carrillo Gustavo
/// 7. Di Tondo Gino
/// 8. Duarte Ludia
/// 9. García Marcelo
/// 10. Jacobs Monica Elizabeth
/// 11. Lo Presti Alejandro
/// 12. Mena Antonella
/// 13. Monascal Miguel
/// 14. Nunes Nicole
/// 15. Pedroso Nahuel
/// 16. Pires Fabricio
/// 17. Roldan Pablo
/// 18. Salaverri JuanMartín
/// 19. Sarasúa Javier
/// 20. Torres Karen Denise
/// 21. Veron Patricia
/// 22. Zarate Julio
/// Más miembros directivos/operativos:
/// - Miguel Piccinini (Jefe de Operaciones)
/// - Daniel Saffe
class IntranetOfficeMember {
  final String id;
  final String name;
  final String lastNameFirstName;
  final String role;
  final String sector;
  final String username;
  final String email;

  const IntranetOfficeMember({
    required this.id,
    required this.name,
    this.lastNameFirstName = "",
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
      lastNameFirstName: "Piccinini Miguel",
      role: "Jefe de Operaciones",
      sector: "Operaciones",
      username: "m.piccinini",
      email: "m.piccinini@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_02",
      name: "Daniel Saffe",
      lastNameFirstName: "Saffe Daniel",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "d.saffe",
      email: "d.saffe@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_03",
      name: "Daniel Altamiranda",
      lastNameFirstName: "Altamiranda Daniel",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "d.altamiranda",
      email: "d.altamiranda@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_04",
      name: "Silvana Assalone",
      lastNameFirstName: "Assalone Silvana",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "s.assalone",
      email: "s.assalone@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_05",
      name: "Nicolás Awdziej",
      lastNameFirstName: "Awdziej Nicolás",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "n.awdziej",
      email: "n.awdziej@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_06",
      name: "Belén Capara",
      lastNameFirstName: "Capara Belén",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "b.capara",
      email: "b.capara@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_07",
      name: "Emmanuel Carnevale",
      lastNameFirstName: "Carnevale Emmanuel",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "e.carnevale",
      email: "e.carnevale@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_08",
      name: "Gustavo Carrillo",
      lastNameFirstName: "Carrillo Gustavo",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "g.carrillo",
      email: "g.carrillo@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_09",
      name: "Gino Di Tondo",
      lastNameFirstName: "Di Tondo Gino",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "g.ditondo",
      email: "g.ditondo@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_10",
      name: "Ludia Duarte",
      lastNameFirstName: "Duarte Ludia",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "l.duarte",
      email: "l.duarte@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_11",
      name: "Marcelo García",
      lastNameFirstName: "García Marcelo",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "m.garcia",
      email: "m.garcia@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_12",
      name: "Monica Elizabeth Jacobs",
      lastNameFirstName: "Jacobs Monica Elizabeth",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "m.jacobs",
      email: "m.jacobs@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_13",
      name: "Alejandro Lo Presti",
      lastNameFirstName: "Lo Presti Alejandro",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "a.lopresti",
      email: "a.lopresti@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_14",
      name: "Antonella Mena",
      lastNameFirstName: "Mena Antonella",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "a.mena",
      email: "a.mena@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_15",
      name: "Miguel Monascal",
      lastNameFirstName: "Monascal Miguel",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "m.monascal",
      email: "m.monascal@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_16",
      name: "Nicole Nunes",
      lastNameFirstName: "Nunes Nicole",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "n.nunes",
      email: "n.nunes@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_17",
      name: "Nahuel Pedroso",
      lastNameFirstName: "Pedroso Nahuel",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "n.pedroso",
      email: "n.pedroso@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_18",
      name: "Fabricio Pires",
      lastNameFirstName: "Pires Fabricio",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "f.pires",
      email: "f.pires@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_19",
      name: "Pablo Roldan",
      lastNameFirstName: "Roldan Pablo",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "p.roldan",
      email: "p.roldan@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_20",
      name: "Juan Martín Salaverri",
      lastNameFirstName: "Salaverri JuanMartín",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "j.salaverri",
      email: "j.salaverri@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_21",
      name: "Javier Sarasúa",
      lastNameFirstName: "Sarasúa Javier",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "j.sarasua",
      email: "j.sarasua@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_22",
      name: "Karen Denise Torres",
      lastNameFirstName: "Torres Karen Denise",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "k.torres",
      email: "k.torres@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_23",
      name: "Patricia Veron",
      lastNameFirstName: "Veron Patricia",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "p.veron",
      email: "p.veron@navieracruzdelsur.com",
    ),
    IntranetOfficeMember(
      id: "OF_24",
      name: "Julio Zarate",
      lastNameFirstName: "Zarate Julio",
      role: "Personal de Oficina",
      sector: "Oficina Central",
      username: "j.zarate",
      email: "j.zarate@navieracruzdelsur.com",
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
    final trimmed = query.trim().toLowerCase();
    final normQuery = _normalize(trimmed);
    if (normQuery.isEmpty) return null;

    // Exclusión explícita de tripulantes de flota conocidos con similaridad de apellido:
    // Rodrigo Duarte (Tripulante r.duarte)
    if ((trimmed.startsWith('r.') && normQuery.contains('duarte')) ||
        (normQuery.contains('rodrigo') && normQuery.contains('duarte'))) {
      return null;
    }
    // Ulises Torres (Tripulante u.torres)
    if ((trimmed.startsWith('u.') && normQuery.contains('torres')) ||
        (normQuery.contains('ulises') && normQuery.contains('torres'))) {
      return null;
    }

    // 1. Coincidencia exacta por username, name, lastNameFirstName, id o email
    for (final member in members) {
      if (_normalize(member.username) == normQuery ||
          _normalize(member.name) == normQuery ||
          (member.lastNameFirstName.isNotEmpty && _normalize(member.lastNameFirstName) == normQuery) ||
          _normalize(member.id) == normQuery ||
          _normalize(member.email) == normQuery) {
        return member;
      }
    }

    // 2. Soporte específico para variantes de tipeo en Intranet (ej: Ludia / Lidia)
    if (normQuery.contains('duarte') &&
        (normQuery.contains('ludia') || normQuery.contains('lidia') || normQuery.startsWith('lduarte') || normQuery == 'lduarte')) {
      return members.firstWhere((m) => m.username == 'l.duarte');
    }

    // 3. Coincidencia por subcadena o tokens de nombre / apellido / usuario
    for (final member in members) {
      final normName = _normalize(member.name);
      final normLastNameFirst = member.lastNameFirstName.isNotEmpty ? _normalize(member.lastNameFirstName) : '';
      final normUser = _normalize(member.username);

      if (normName.contains(normQuery) ||
          normQuery.contains(normName) ||
          (normLastNameFirst.isNotEmpty && (normLastNameFirst.contains(normQuery) || normQuery.contains(normLastNameFirst))) ||
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
