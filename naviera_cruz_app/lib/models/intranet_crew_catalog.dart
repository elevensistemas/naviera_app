/// Catálogo oficial de Dotación y Situación de Tripulantes y Personal de Naviera Cruz del Sur
/// Extraído directamente de la Intranet (SGI - Sistema de Gestión Integrado).
///
/// Contiene:
/// 1. 44 Tripulantes "EN TIERRA" (Desembarcados)
/// 2. 45 Tripulantes "A BORDO" (Embarcados en ALFA C, GUSTAVO U y NANY)
/// Total de Dotación de Flota: 89 Tripulantes.
/// Todos los demás usuarios de la compañía corresponden al rol "OFICINA".

import 'intranet_office_catalog.dart';

class IntranetCrewMember {
  final String id;
  final String name;
  final String roleCode;
  final String roleName;
  final bool isOnBoard;
  final String? shipName;
  final int days;
  final String username;

  const IntranetCrewMember({
    required this.id,
    required this.name,
    required this.roleCode,
    required this.roleName,
    required this.isOnBoard,
    this.shipName,
    required this.days,
    required this.username,
  });
}

class IntranetCrewCatalog {
  // --------------------------------------------------------------------------
  // 1. TRIPULANTES EN TIERRA (DESEMBARCADOS) - 44 Miembros
  // --------------------------------------------------------------------------
  static const List<IntranetCrewMember> enTierra = [
    // Columna 1
    IntranetCrewMember(
      id: "ET_01",
      name: "Caballero Diego",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 20,
      username: "d.caballero",
    ),
    IntranetCrewMember(
      id: "ET_02",
      name: "Marenco Rubén Darío",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 4,
      username: "r.marenco",
    ),
    IntranetCrewMember(
      id: "ET_03",
      name: "Gallardo Juan",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 5,
      username: "j.gallardo",
    ),
    IntranetCrewMember(
      id: "ET_04",
      name: "Escalante Jorge",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 16,
      username: "j.escalante",
    ),
    IntranetCrewMember(
      id: "ET_05",
      name: "Zapata Darío",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 45,
      username: "d.zapata",
    ),
    IntranetCrewMember(
      id: "ET_06",
      name: "Lescano Cristian",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 28,
      username: "c.lescano",
    ),
    IntranetCrewMember(
      id: "ET_07",
      name: "Medina Cesar",
      roleCode: "1ER COND",
      roleName: "1er Conductor de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 16,
      username: "c.medina",
    ),
    IntranetCrewMember(
      id: "ET_08",
      name: "Visgarra Javier",
      roleCode: "1ER COND",
      roleName: "1er Conductor de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 46,
      username: "j.visgarra",
    ),
    IntranetCrewMember(
      id: "ET_09",
      name: "Gomez Rodrigo",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 46,
      username: "r.gomez",
    ),
    IntranetCrewMember(
      id: "ET_10",
      name: "Diaz Elvio",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: false,
      shipName: null,
      days: 39,
      username: "e.diaz",
    ),
    IntranetCrewMember(
      id: "ET_11",
      name: "Fernandez Luis",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: false,
      shipName: null,
      days: 236,
      username: "l.fernandez",
    ),
    IntranetCrewMember(
      id: "ET_12",
      name: "Quirolo Juan",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: false,
      shipName: null,
      days: 33,
      username: "j.quirolo",
    ),
    IntranetCrewMember(
      id: "ET_13",
      name: "Marquez Ruben",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: false,
      shipName: null,
      days: 3,
      username: "r.marquez",
    ),
    IntranetCrewMember(
      id: "ET_14",
      name: "Zacarias Walter",
      roleCode: "1 CABO",
      roleName: "Primer Cabo",
      isOnBoard: false,
      shipName: null,
      days: 11,
      username: "w.zacarias",
    ),
    IntranetCrewMember(
      id: "ET_15",
      name: "Peralta Pablo",
      roleCode: "COC",
      roleName: "Cocinero",
      isOnBoard: false,
      shipName: null,
      days: 27,
      username: "p.peralta",
    ),
    IntranetCrewMember(
      id: "ET_16",
      name: "Aquino Marcos",
      roleCode: "BOM",
      roleName: "Bombero",
      isOnBoard: false,
      shipName: null,
      days: 3,
      username: "m.aquino",
    ),

    // Columna 2
    IntranetCrewMember(
      id: "ET_17",
      name: "Escalante Federico",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 0,
      username: "f.escalante",
    ),
    IntranetCrewMember(
      id: "ET_18",
      name: "Fusaro Matias",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 30,
      username: "m.fusaro",
    ),
    IntranetCrewMember(
      id: "ET_19",
      name: "Duarte Rodrigo",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 19,
      username: "r.duarte",
    ),
    IntranetCrewMember(
      id: "ET_20",
      name: "Yedro Mariano",
      roleCode: "2DO OF CUB",
      roleName: "2do Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 29,
      username: "m.yedro",
    ),
    IntranetCrewMember(
      id: "ET_21",
      name: "Bagnasco Antonio",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 121,
      username: "a.bagnasco",
    ),
    IntranetCrewMember(
      id: "ET_22",
      name: "Alday Alexis",
      roleCode: "1ER MAQ",
      roleName: "1er Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 24,
      username: "a.alday",
    ),
    IntranetCrewMember(
      id: "ET_23",
      name: "Pieri Braian",
      roleCode: "1ER MAQ",
      roleName: "1er Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 18,
      username: "b.pieri",
    ),
    IntranetCrewMember(
      id: "ET_24",
      name: "Aguirrezarobe Alexis",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 10,
      username: "a.aguirrezarobe",
    ),
    IntranetCrewMember(
      id: "ET_25",
      name: "Godoy Luis",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: false,
      shipName: null,
      days: 34,
      username: "l.godoy",
    ),
    IntranetCrewMember(
      id: "ET_26",
      name: "Molina Geronimo",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: false,
      shipName: null,
      days: 10,
      username: "g.molina",
    ),
    IntranetCrewMember(
      id: "ET_27",
      name: "Gutierrez Leonel",
      roleCode: "BOM I",
      roleName: "Bombero I",
      isOnBoard: false,
      shipName: null,
      days: 19,
      username: "l.gutierrez",
    ),
    IntranetCrewMember(
      id: "ET_28",
      name: "Quintana Gabriel",
      roleCode: "BOM I",
      roleName: "Bombero I",
      isOnBoard: false,
      shipName: null,
      days: 27,
      username: "g.quintana",
    ),
    IntranetCrewMember(
      id: "ET_29",
      name: "Caprioglio Fernando",
      roleCode: "ENG",
      roleName: "Engrasador",
      isOnBoard: false,
      shipName: null,
      days: 6,
      username: "f.caprioglio",
    ),

    // Columna 3
    IntranetCrewMember(
      id: "ET_30",
      name: "Maciel Jonathan",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 6,
      username: "j.maciel",
    ),
    IntranetCrewMember(
      id: "ET_31",
      name: "Monsalves Jeanette",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 22,
      username: "j.monsalves",
    ),
    IntranetCrewMember(
      id: "ET_32",
      name: "Maidana Francisco",
      roleCode: "2DO OF CUB",
      roleName: "2do Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 1,
      username: "f.maidana",
    ),
    IntranetCrewMember(
      id: "ET_33",
      name: "Alex Silva Palisa",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 111,
      username: "a.silvapalisa",
    ),
    IntranetCrewMember(
      id: "ET_34",
      name: "Valentin Rivero",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 78,
      username: "v.rivero",
    ),
    IntranetCrewMember(
      id: "ET_35",
      name: "Porto Guillermo",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 9,
      username: "g.porto",
    ),
    IntranetCrewMember(
      id: "ET_36",
      name: "Bequir Ivan",
      roleCode: "1ER MAQ",
      roleName: "1er Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 14,
      username: "i.bequir",
    ),
    IntranetCrewMember(
      id: "ET_37",
      name: "Villar Maximiliano",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 28,
      username: "m.villar",
    ),
    IntranetCrewMember(
      id: "ET_38",
      name: "Mormina Juan C.",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 28,
      username: "j.mormina",
    ),
    IntranetCrewMember(
      id: "ET_39",
      name: "Dalinger Damian",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: false,
      shipName: null,
      days: 19,
      username: "d.dalinger",
    ),
    IntranetCrewMember(
      id: "ET_40",
      name: "Gasparri Claudio",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: false,
      shipName: null,
      days: 72,
      username: "c.gasparri",
    ),
    IntranetCrewMember(
      id: "ET_41",
      name: "Llabres Alejandro",
      roleCode: "ENG",
      roleName: "Engrasador",
      isOnBoard: false,
      shipName: null,
      days: 19,
      username: "a.llabres",
    ),
    IntranetCrewMember(
      id: "ET_42",
      name: "Miquelarena Martin",
      roleCode: "AUX MAQ",
      roleName: "Auxiliar de Máquinas",
      isOnBoard: false,
      shipName: null,
      days: 29,
      username: "m.miquelarena",
    ),
    IntranetCrewMember(
      id: "ET_43",
      name: "Fernandez Dario",
      roleCode: "COC",
      roleName: "Cocinero",
      isOnBoard: false,
      shipName: null,
      days: 13,
      username: "d.fernandez",
    ),
    IntranetCrewMember(
      id: "ET_44",
      name: "Medina Felix",
      roleCode: "BOM",
      roleName: "Bombero",
      isOnBoard: false,
      shipName: null,
      days: 1,
      username: "f.medina",
    ),
  ];

  // --------------------------------------------------------------------------
  // 2. TRIPULANTES A BORDO (EMBARCADOS) - 42 Miembros Oficiales
  // --------------------------------------------------------------------------
  static const List<IntranetCrewMember> aBordo = [
    // === ALFA C (15 Tripulantes - Dotación mínima completa) ===
    IntranetCrewMember(id: "108", name: "Carrá Leonel", roleCode: "CAP", roleName: "Capitán", isOnBoard: true, shipName: "ALFA C", days: 12, username: "c.leonel"),
    IntranetCrewMember(id: "103", name: "Caballero Diego", roleCode: "1ER OF CUB", roleName: "1er Oficial Cubierta", isOnBoard: true, shipName: "ALFA C", days: 12, username: "c.diego"),
    IntranetCrewMember(id: "128", name: "Zapata Darío", roleCode: "2DO OF CUB", roleName: "2do Oficial Cubierta", isOnBoard: true, shipName: "ALFA C", days: 18, username: "z.dario"),
    IntranetCrewMember(id: "30234", name: "Lambertuchi Pablo", roleCode: "3ER OF CUB", roleName: "3er Oficial Cubierta", isOnBoard: true, shipName: "ALFA C", days: 39, username: "l.pablo"),
    IntranetCrewMember(id: "154", name: "Lescano Cristian", roleCode: "JM", roleName: "Jefe de Máquinas", isOnBoard: true, shipName: "ALFA C", days: 12, username: "l.cristian"),
    IntranetCrewMember(id: "208", name: "Ledesma Gabriel", roleCode: "2DO MAQ", roleName: "2do Oficial Máquinas", isOnBoard: true, shipName: "ALFA C", days: 65, username: "l.gabriel"),
    IntranetCrewMember(id: "147", name: "Quirolo Juan", roleCode: "CONTRAM", roleName: "Contramaestre", isOnBoard: true, shipName: "ALFA C", days: 18, username: "q.juan"),
    IntranetCrewMember(id: "40235", name: "Romero José", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "ALFA C", days: 39, username: "r.jose"),
    IntranetCrewMember(id: "90349", name: "Lucas Arias", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "ALFA C", days: 12, username: "l.arias"),
    IntranetCrewMember(id: "80344", name: "Jonatan Albornoz", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "ALFA C", days: 22, username: "j.albornoz"),
    IntranetCrewMember(id: "100", name: "Mosqueda Daniel", roleCode: "ENG", roleName: "1er Cabo Engrasador", isOnBoard: true, shipName: "ALFA C", days: 30, username: "m.daniel"),
    IntranetCrewMember(id: "141", name: "Peralta Pablo", roleCode: "COC", roleName: "Cocinero", isOnBoard: true, shipName: "ALFA C", days: 12, username: "p.pablo"),
    IntranetCrewMember(id: "102", name: "Visgarra Javier", roleCode: "1LR", roleName: "1er Oficial de Máquinas", isOnBoard: true, shipName: "ALFA C", days: 12, username: "v.javier"),
    IntranetCrewMember(id: "20218", name: "Mineo Julio", roleCode: "BOM", roleName: "Bombero", isOnBoard: true, shipName: "ALFA C", days: 39, username: "m.julio"),
    IntranetCrewMember(id: "97", name: "Rodriguez David", roleCode: "BOM", roleName: "Bombero", isOnBoard: true, shipName: "ALFA C", days: 22, username: "r.david"),

    // === GUSTAVO U (13 Tripulantes - Dotación mínima completa) ===
    IntranetCrewMember(id: "104", name: "Escalante Federico", roleCode: "1ER OF CUB", roleName: "1er Oficial Cubierta", isOnBoard: true, shipName: "GUSTAVO U", days: 11, username: "e.federico"),
    IntranetCrewMember(id: "122", name: "Yedro Mariano", roleCode: "2DO OF CUB", roleName: "2do Oficial Cubierta", isOnBoard: true, shipName: "GUSTAVO U", days: 12, username: "y.mariano"),
    IntranetCrewMember(id: "70305", name: "Tobias Joaquin", roleCode: "PLT", roleName: "Pilotín", isOnBoard: true, shipName: "GUSTAVO U", days: 137, username: "t.joaquin"),
    IntranetCrewMember(id: "109", name: "Alday Alexis", roleCode: "JM", roleName: "Jefe de Máquinas", isOnBoard: true, shipName: "GUSTAVO U", days: 14, username: "a.alexis"),
    IntranetCrewMember(id: "80317", name: "Tomas Ribas Pintos", roleCode: "2DO MAQ", roleName: "2do Oficial Máquinas", isOnBoard: true, shipName: "GUSTAVO U", days: 38, username: "t.pintos"),
    IntranetCrewMember(id: "146", name: "Godoy Luis", roleCode: "CONTRAM", roleName: "Contramaestre", isOnBoard: true, shipName: "GUSTAVO U", days: 12, username: "g.luis"),
    IntranetCrewMember(id: "90348", name: "Nestor Carlevaris", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "GUSTAVO U", days: 14, username: "n.carlevaris"),
    IntranetCrewMember(id: "90352", name: "Escalada Raul", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "GUSTAVO U", days: 14, username: "e.raul"),
    IntranetCrewMember(id: "100352", name: "Giurlando Alejandro", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "GUSTAVO U", days: 12, username: "g.alejandro"),
    IntranetCrewMember(id: "114", name: "Escalante Eduardo", roleCode: "BOM II", roleName: "2do Bombero", isOnBoard: true, shipName: "GUSTAVO U", days: 38, username: "e.eduardo"),
    IntranetCrewMember(id: "80325", name: "Maximiliano Eduardo Gaetan", roleCode: "ENG", roleName: "1er Cabo Engrasador", isOnBoard: true, shipName: "GUSTAVO U", days: 25, username: "m.gaetan"),
    IntranetCrewMember(id: "142", name: "Rodriguez Lucas", roleCode: "COC", roleName: "Cocinero", isOnBoard: true, shipName: "GUSTAVO U", days: 46, username: "r.lucas"),
    IntranetCrewMember(id: "125", name: "Ramirez Diego", roleCode: "1LR", roleName: "1er Oficial de Máquinas", isOnBoard: true, shipName: "GUSTAVO U", days: 29, username: "r.diego"),

    // === NANY (14 Tripulantes - Dotación mínima completa) ===
    IntranetCrewMember(id: "134", name: "Hernandez Pablo", roleCode: "CAP", roleName: "Capitán", isOnBoard: true, shipName: "NANY", days: 25, username: "h.pablo"),
    IntranetCrewMember(id: "106", name: "Gallardo Juan", roleCode: "1ER OF CUB", roleName: "1er Oficial Cubierta", isOnBoard: true, shipName: "NANY", days: 21, username: "g.juan"),
    IntranetCrewMember(id: "105", name: "Fleitas Emmanuel", roleCode: "2DO OF CUB", roleName: "2do Oficial Cubierta", isOnBoard: true, shipName: "NANY", days: 6, username: "f.emmanuel"),
    IntranetCrewMember(id: "90347", name: "Valentin Rabassa", roleCode: "3ER OF CUB", roleName: "3er Oficial Cubierta", isOnBoard: true, shipName: "NANY", days: 15, username: "v.rabassa"),
    IntranetCrewMember(id: "151", name: "Porto Guillermo", roleCode: "JM", roleName: "Jefe de Máquinas", isOnBoard: true, shipName: "NANY", days: 3, username: "p.guillermo"),
    IntranetCrewMember(id: "110", name: "Bequir Ivan", roleCode: "1ER MAQ", roleName: "1er Oficial Máquinas", isOnBoard: true, shipName: "NANY", days: 6, username: "b.ivan"),
    IntranetCrewMember(id: "126", name: "Villar Maximiliano", roleCode: "2DO MAQ", roleName: "2do Oficial Máquinas", isOnBoard: true, shipName: "NANY", days: 18, username: "v.maximiliano"),
    IntranetCrewMember(id: "143", name: "Dalinger Damian", roleCode: "CONTRAM", roleName: "Contramaestre", isOnBoard: true, shipName: "NANY", days: 6, username: "d.damian"),
    IntranetCrewMember(id: "80311", name: "Flores mariano gaston", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "NANY", days: 12, username: "f.gaston"),
    IntranetCrewMember(id: "90351", name: "Santiago Vargas", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "NANY", days: 15, username: "s.vargas"),
    IntranetCrewMember(id: "100353", name: "Nehemias Bellomo", roleCode: "MAR I", roleName: "Marinero", isOnBoard: true, shipName: "NANY", days: 12, username: "n.bellomo"),
    IntranetCrewMember(id: "99", name: "Llabres Alejandro", roleCode: "ENG", roleName: "1er Cabo Engrasador", isOnBoard: true, shipName: "NANY", days: 6, username: "l.alejandro"),
    IntranetCrewMember(id: "80345", name: "Mariano Vitale", roleCode: "AUX MAQ", roleName: "Auxiliar de Máquinas", isOnBoard: true, shipName: "NANY", days: 28, username: "m.vitale"),
    IntranetCrewMember(id: "138", name: "Cantore Alejandro", roleCode: "COC", roleName: "Cocinero", isOnBoard: true, shipName: "NANY", days: 33, username: "c.alejandro"),
  ];

  /// Lista consolidada de los 89 tripulantes oficiales de la empresa
  static List<IntranetCrewMember> get allCrew => [...aBordo, ...enTierra];

  /// Normaliza texto para comparaciones insensibles a tildes y mayúsculas
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
  }

  /// Busca un miembro de la dotación por nombre, apellido, usuario o código
  static IntranetCrewMember? findCrewMember(String query) {
    if (query.trim().isEmpty) return null;

    // 0. Si pertenece al personal oficial de oficina, NO es tripulante marítimo
    if (IntranetOfficeCatalog.isOfficeMember(query)) {
      return null;
    }

    // 1. Si contiene punto (ej: l.duarte, r.duarte), es un nombre de usuario de Intranet estricto
    if (query.contains('.')) {
      final clean = query.trim().toLowerCase();
      for (final member in allCrew) {
        if (member.username.toLowerCase() == clean) {
          return member;
        }
      }
      return null; // Si no coincide exactamente con el username del tripulante, no buscar por partes
    }

    final qNorm = _normalize(query);

    // 2. Coincidencia exacta o contenida normalizada
    for (final member in allCrew) {
      final nameNorm = _normalize(member.name);
      final userNorm = _normalize(member.username);
      final idNorm = _normalize(member.id);

      if (nameNorm == qNorm || userNorm == qNorm || idNorm == qNorm) {
        return member;
      }
      if (nameNorm.contains(qNorm) || qNorm.contains(nameNorm)) {
        return member;
      }
      if (userNorm.contains(qNorm) || qNorm.contains(userNorm)) {
        return member;
      }
    }

    // 2. Coincidencia por partes (primer apellido o nombre completo)
    final parts = query.toLowerCase().split(' ').where((p) => p.length > 2).toList();
    if (parts.length > 1) {
      for (final member in allCrew) {
        final memberParts = member.name.toLowerCase().split(' ');
        final allMatched = parts.every((p) => memberParts.any((mp) => mp.contains(p) || p.contains(mp)));
        if (allMatched) return member;
      }
    } else if (parts.length == 1) {
      final p = parts.first;
      for (final member in allCrew) {
        final memberParts = member.name.toLowerCase().split(' ');
        if (memberParts.any((mp) => mp.contains(p) || p.contains(mp))) {
          return member;
        }
      }
    }

    return null;
  }

  /// Determina fehacientemente si una identidad dada pertenece a la dotación de tripulantes.
  /// Cualquier usuario no perteneciente a este padrón corresponde a PERSONAL DE OFICINA.
  static bool isTripulanteUser({
    String? name,
    String? role,
    String? sector,
    String? username,
  }) {
    final s = (sector ?? '').toLowerCase();
    final r = (role ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();
    final u = (username ?? '').toLowerCase();

    // 1. Usuarios específicos y comprobados de OFICINA (Catálogo oficial de los 10 miembros)
    if (IntranetOfficeCatalog.isOfficeMember(u) ||
        IntranetOfficeCatalog.isOfficeMember(n) ||
        u == 'admin' ||
        s.contains('gerencia') ||
        s.contains('directorio') ||
        r.contains('gerente') ||
        r.contains('director') ||
        r.contains('jefe de operaciones')) {
      return false;
    }

    // 2. Comprobación contra el padrón oficial de 89 tripulantes (MÁXIMA PRIORIDAD PARA PERSONAL EMBARCADO)
    if (name != null && name.trim().isNotEmpty) {
      if (findCrewMember(name) != null) return true;
    }
    if (username != null && username.trim().isNotEmpty) {
      if (findCrewMember(username) != null) return true;
    }

    // 3. Indicadores claros de personal embarcado/marítimo
    if (s.contains('buque') || s.contains('flota') || s.contains('embarcad') || s.contains('tripula')) {
      return true;
    }
    if (r.contains('capit') ||
        r.contains('patron') ||
        r.contains('patrón') ||
        r.contains('oficial') ||
        r.contains('marinero') ||
        r.contains('maquin') ||
        r.contains('cocinero') ||
        r.contains('contramaestre') ||
        r.contains('timonel') ||
        r.contains('motorista') ||
        r.contains('pilot') ||
        r.contains('bombero') ||
        r.contains('engrasador') ||
        r.contains('cabo') ||
        r.contains('conductor') ||
        r.contains('tripulant')) {
      return true;
    }

    // 4. Roles y sectores explícitos de OFICINA
    if (s.contains('operaciones') ||
        s.contains('administra') ||
        s.contains('oficina') ||
        s.contains('sistemas') ||
        s.contains('finanzas') ||
        s.contains('contabilidad') ||
        s.contains('recursos humanos') ||
        s.contains('rrhh') ||
        s.contains('compras') ||
        r.contains('administrat') ||
        r.contains('analista')) {
      return false;
    }

    // Todo el resto pertenece a OFICINA
    return false;
  }
}
