/// Catálogo oficial de Dotación y Situación de Tripulantes y Personal de Naviera Cruz del Sur
/// Extraído directamente de la Intranet (SGI - Sistema de Gestión Integrado).
///
/// Contiene:
/// 1. 44 Tripulantes "EN TIERRA" (Desembarcados)
/// 2. 45 Tripulantes "A BORDO" (Embarcados en ALFA C, GUSTAVO U y NANY)
/// Total de Dotación de Flota: 89 Tripulantes.
/// Todos los demás usuarios de la compañía corresponden al rol "OFICINA".

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
      name: "Carrá Leonel",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: false,
      shipName: null,
      days: 20,
      username: "l.carra",
    ),
    IntranetCrewMember(
      id: "ET_03",
      name: "Fleitas Emmanuel",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: false,
      shipName: null,
      days: 206,
      username: "e.fleitas",
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
  // 2. TRIPULANTES A BORDO (EMBARCADOS) - 44 Miembros Oficiales
  // --------------------------------------------------------------------------
  static const List<IntranetCrewMember> aBordo = [
    // ALFA C (15 Tripulantes - Dotación mínima completa)
    IntranetCrewMember(
      id: "AC_01",
      name: "Marenco Rubén Darío",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 23,
      username: "r.marenco",
    ),
    IntranetCrewMember(
      id: "AC_02",
      name: "Maldonado Juan",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 23,
      username: "j.maldonado",
    ),
    IntranetCrewMember(
      id: "AC_03",
      name: "Carattoli Pablo",
      roleCode: "2DO OF CUB",
      roleName: "2do Oficial de Cubierta",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 48,
      username: "p.carattoli",
    ),
    IntranetCrewMember(
      id: "AC_04",
      name: "Lambertuchi Pablo",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 23,
      username: "p.lambertuchi",
    ),
    IntranetCrewMember(
      id: "AC_05",
      name: "Sosa Armando",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 31,
      username: "a.sosa",
    ),
    IntranetCrewMember(
      id: "AC_06",
      name: "Molero Jorge",
      roleCode: "1ER MAQ",
      roleName: "1er Oficial de Máquinas",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 19,
      username: "j.molero",
    ),
    IntranetCrewMember(
      id: "AC_07",
      name: "Ledesma Gabriel",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 49,
      username: "g.ledesma",
    ),
    IntranetCrewMember(
      id: "AC_08",
      name: "Sosa Marcelo",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 36,
      username: "m.sosa",
    ),
    IntranetCrewMember(
      id: "AC_09",
      name: "Romero José",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 23,
      username: "j.romero",
    ),
    IntranetCrewMember(
      id: "AC_10",
      name: "Miguel Angel Ramirez",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 36,
      username: "m.ramirez",
    ),
    IntranetCrewMember(
      id: "AC_11",
      name: "Jonatan Albornoz",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 6,
      username: "j.albornoz",
    ),
    IntranetCrewMember(
      id: "AC_12",
      name: "Mosqueda Daniel",
      roleCode: "ENG",
      roleName: "Engrasador",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 14,
      username: "d.mosqueda",
    ),
    IntranetCrewMember(
      id: "AC_13",
      name: "Kretschel Claudio",
      roleCode: "COC",
      roleName: "Cocinero",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 30,
      username: "c.kretschel",
    ),
    IntranetCrewMember(
      id: "AC_14",
      name: "Rodriguez David",
      roleCode: "BOM",
      roleName: "Bombero",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 6,
      username: "d.rodriguez",
    ),
    IntranetCrewMember(
      id: "AC_15",
      name: "Mineo Julio",
      roleCode: "BOM",
      roleName: "Bombero",
      isOnBoard: true,
      shipName: "ALFA C",
      days: 23,
      username: "j.mineo",
    ),

    // GUSTAVO U (14 Tripulantes - Dotación mínima incompleta en Intranet)
    IntranetCrewMember(
      id: "GU_01",
      name: "Percara Marco",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 22,
      username: "m.percara",
    ),
    IntranetCrewMember(
      id: "GU_02",
      name: "Perez Douglas",
      roleCode: "2DO OF CUB",
      roleName: "2do Oficial de Cubierta",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 33,
      username: "d.perez",
    ),
    IntranetCrewMember(
      id: "GU_03",
      name: "Tobias Joaquin",
      roleCode: "PLT",
      roleName: "Pilotín",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 121,
      username: "j.tobias",
    ),
    IntranetCrewMember(
      id: "GU_04",
      name: "Agüero Leandro",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 27,
      username: "l.aguero",
    ),
    IntranetCrewMember(
      id: "GU_05",
      name: "Tomas Ribas Pintos",
      roleCode: "2DO MAQ",
      roleName: "2do Oficial de Máquinas",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 22,
      username: "t.ribaspintos",
    ),
    IntranetCrewMember(
      id: "GU_06",
      name: "Cucurulo Gustavo",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 37,
      username: "g.cucurulo",
    ),
    IntranetCrewMember(
      id: "GU_07",
      name: "Claudio Sotelo",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 13,
      username: "c.sotelo",
    ),
    IntranetCrewMember(
      id: "GU_08",
      name: "Camacho Pablo Ezequias",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 42,
      username: "p.camacho",
    ),
    IntranetCrewMember(
      id: "GU_09",
      name: "Rene Ruben Aceval",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 25,
      username: "r.aceval",
    ),
    IntranetCrewMember(
      id: "GU_10",
      name: "Jacquet Jorge",
      roleCode: "BOM I",
      roleName: "Bombero I",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 33,
      username: "j.jacquet",
    ),
    IntranetCrewMember(
      id: "GU_11",
      name: "Escalante Eduardo",
      roleCode: "BOM II",
      roleName: "Bombero II",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 22,
      username: "e.escalante",
    ),
    IntranetCrewMember(
      id: "GU_12",
      name: "Maximiliano Eduardo Gaetan",
      roleCode: "ENG",
      roleName: "Engrasador",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 9,
      username: "m.gaetan",
    ),
    IntranetCrewMember(
      id: "GU_13",
      name: "Rodriguez Lucas",
      roleCode: "COC",
      roleName: "Cocinero",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 30,
      username: "l.rodriguez",
    ),
    IntranetCrewMember(
      id: "GU_14",
      name: "Ramirez Diego",
      roleCode: "1LR",
      roleName: "1er Oficial / Conductor",
      isOnBoard: true,
      shipName: "GUSTAVO U",
      days: 13,
      username: "d.ramirez",
    ),

    // NANY (15 Tripulantes - Dotación mínima completa)
    IntranetCrewMember(
      id: "NA_01",
      name: "Hernandez Pablo",
      roleCode: "CAP",
      roleName: "Capitán",
      isOnBoard: true,
      shipName: "NANY",
      days: 9,
      username: "p.hernandez",
    ),
    IntranetCrewMember(
      id: "NA_02",
      name: "Gallardo Juan",
      roleCode: "1ER OF CUB",
      roleName: "1er Oficial de Cubierta",
      isOnBoard: true,
      shipName: "NANY",
      days: 5,
      username: "j.gallardo",
    ),
    IntranetCrewMember(
      id: "NA_03",
      name: "Saucedo Nicolás",
      roleCode: "2DO OF CUB",
      roleName: "2do Oficial de Cubierta",
      isOnBoard: true,
      shipName: "NANY",
      days: 27,
      username: "n.saucedo",
    ),
    IntranetCrewMember(
      id: "NA_04",
      name: "Alan Leguiza",
      roleCode: "3ER OF CUB",
      roleName: "3er Oficial de Cubierta",
      isOnBoard: true,
      shipName: "NANY",
      days: 27,
      username: "a.leguiza",
    ),
    IntranetCrewMember(
      id: "NA_05",
      name: "Carlino Hernan",
      roleCode: "JM",
      roleName: "Jefe de Máquinas",
      isOnBoard: true,
      shipName: "NANY",
      days: 12,
      username: "h.carlino",
    ),
    IntranetCrewMember(
      id: "NA_06",
      name: "Bequir Ramiro",
      roleCode: "1ER MAQ",
      roleName: "1er Oficial de Máquinas",
      isOnBoard: true,
      shipName: "NANY",
      days: 17,
      username: "r.bequir",
    ),
    IntranetCrewMember(
      id: "NA_07",
      name: "Rosales Carlos",
      roleCode: "2DO COND",
      roleName: "2do Conductor de Máquinas",
      isOnBoard: true,
      shipName: "NANY",
      days: 31,
      username: "c.rosales",
    ),
    IntranetCrewMember(
      id: "NA_08",
      name: "Torres Ulises",
      roleCode: "CONTRAM",
      roleName: "Contramaestre",
      isOnBoard: true,
      shipName: "NANY",
      days: 22,
      username: "u.torres",
    ),
    IntranetCrewMember(
      id: "NA_09",
      name: "Andrada Emiliano",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "NANY",
      days: 36,
      username: "e.andrada",
    ),
    IntranetCrewMember(
      id: "NA_10",
      name: "Mora Alejandro",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "NANY",
      days: 31,
      username: "a.mora",
    ),
    IntranetCrewMember(
      id: "NA_11",
      name: "Ganduglia Sergio",
      roleCode: "MAR I",
      roleName: "Marinero de Primera",
      isOnBoard: true,
      shipName: "NANY",
      days: 27,
      username: "s.ganduglia",
    ),
    IntranetCrewMember(
      id: "NA_12",
      name: "Correa Motta Nicolas",
      roleCode: "1 CABO",
      roleName: "Primer Cabo",
      isOnBoard: true,
      shipName: "NANY",
      days: 22,
      username: "n.correamotta",
    ),
    IntranetCrewMember(
      id: "NA_13",
      name: "Mariano Vitale",
      roleCode: "AUX MAQ",
      roleName: "Auxiliar de Máquinas",
      isOnBoard: true,
      shipName: "NANY",
      days: 12,
      username: "m.vitale",
    ),
    IntranetCrewMember(
      id: "NA_14",
      name: "Cantore Alejandro",
      roleCode: "COC",
      roleName: "Cocinero",
      isOnBoard: true,
      shipName: "NANY",
      days: 17,
      username: "a.cantore",
    ),
    IntranetCrewMember(
      id: "NA_15",
      name: "Tula Leonardo",
      roleCode: "BOM",
      roleName: "Bombero",
      isOnBoard: true,
      shipName: "NANY",
      days: 5,
      username: "l.tula",
    ),
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
        .replaceAll('.', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .trim();
  }

  /// Busca un miembro de la dotación por nombre, apellido, usuario o código
  static IntranetCrewMember? findCrewMember(String query) {
    if (query.trim().isEmpty) return null;
    final qNorm = _normalize(query);

    // 1. Coincidencia exacta o contenida normalizada
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

    // 1. Usuarios específicos y comprobados de OFICINA / GERENCIA
    if (u == 'a.lopresti' ||
        u == 'alejandro' ||
        u == 'admin' ||
        u == 'm.piccinini' ||
        n.contains('lopresti') ||
        n.contains('lo presti') ||
        n.contains('piccinini') ||
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
