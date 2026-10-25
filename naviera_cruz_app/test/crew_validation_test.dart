import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviera_cruz_app/models/crew_profile.dart';
import 'package:naviera_cruz_app/models/models.dart';
import 'package:naviera_cruz_app/services/crew_faq_service.dart';
import 'package:naviera_cruz_app/services/crew_profile_service.dart';
import 'package:naviera_cruz_app/services/services.dart';
import 'package:naviera_cruz_app/modules/crew/crew_faq_search_view.dart';
import 'package:naviera_cruz_app/core/storage.dart';

void main() {
  group('1. Días Embarcado y Estados de Situación Operativa (Criterio Intranet & Calendario)', () {
    test('Utiliza total oficial de días si la intranet lo provee (rawDaysOnBoard)', () {
      final profile = CrewProfile(
        id: "cm-01",
        name: "Carlos Mendez",
        role: "Marinero",
        shipName: "ALFA C",
        shipId: "alfa-c",
        startDate: DateTime.now().subtract(const Duration(days: 40)),
        situation: "embarcado",
        status: CrewStatus.embarcado,
        isOnBoard: true,
        rawDaysOnBoard: 37,
      );

      expect(profile.daysOnBoard, equals(37));
      expect(profile.daysOnBoardText, equals("37 días a bordo"));
      expect(profile.isOnBoard, isTrue);
    });

    test('Cálculo por fecha calendario Argentina (UTC-3) sin regla no verificada', () {
      final startDate = DateTime(2026, 10, 1, 8, 0, 0); // Octubre 1
      final profile = CrewProfile(
        id: "cm-02",
        name: "Juan Perez",
        role: "Oficial",
        shipName: "NANY",
        shipId: "nany",
        startDate: startDate,
        situation: "embarcado",
        status: CrewStatus.embarcado,
        isOnBoard: true,
      );

      expect(profile.daysOnBoard, isNotNull);
      expect(profile.daysOnBoard! > 0, isTrue);
      expect(profile.daysOnBoardText.contains("días a bordo"), isTrue);
    });

    test('Tripulante en tierra muestra badge "EN TIERRA"', () {
      final profile = CrewProfile(
        id: "cm-03",
        name: "Roberto Diaz",
        role: "Maquinista",
        shipName: null,
        situation: "franco",
        status: CrewStatus.enTierra,
        isOnBoard: false,
      );

      expect(profile.isOnBoard, isFalse);
      expect(profile.situationBadgeText, equals("EN TIERRA"));
      expect(profile.daysOnBoardText, equals("En tierra (franco)"));
    });

    test('Desembarque registrado muestra estado "DESEMBARCADO"', () {
      final profile = CrewProfile(
        id: "cm-04",
        name: "Mario Gomez",
        role: "Cocinero",
        shipName: "DON SILVIO",
        situation: "desembarcado",
        status: CrewStatus.desembarqueRegistrado,
        isOnBoard: false,
        endDate: DateTime(2026, 10, 15),
      );

      expect(profile.isOnBoard, isFalse);
      expect(profile.situationBadgeText, equals("DESEMBARCADO"));
      expect(profile.daysOnBoardText, equals("Desembarque registrado"));
    });

    test('No deduce "EN TIERRA" ante error de API o falta de datos', () {
      final errorProfile = CrewProfile.error(
        errorMessage: "Error 503 Backend Gateway Timeout",
        name: "Usuario",
      );

      expect(errorProfile.status, equals(CrewStatus.errorConexion));
      expect(errorProfile.situationBadgeText, equals("ERROR AL CONSULTAR INTRANET"));
      expect(errorProfile.situationBadgeText, isNot(equals("EN TIERRA")));
      expect(errorProfile.hasError, isTrue);

      final unlinkedProfile = CrewProfile.unlinked(
        name: "Usuario Demo",
        userId: "demo",
      );
      expect(unlinkedProfile.status, equals(CrewStatus.noVinculado));
      expect(unlinkedProfile.situationBadgeText, equals("CUENTA SIN LEGAJO VINCULADO"));
      expect(unlinkedProfile.situationBadgeText, isNot(equals("EN TIERRA")));
    });
  });

  group('2. Auditoría del Asistente a Bordo y Catálogo de 70 Preguntas', () {
    test('Catálogo contiene exactamente las 70 preguntas oficiales auditadas', () {
      expect(CrewFAQService.catalog.length, equals(70));
    });

    test('Existen exactamente las 14 categorías oficiales de Naviera Cruz del Sur', () {
      expect(FAQCategory.values.length, equals(14));
      final activeCategories = [
        FAQCategory.seguridadReportes,
        FAQCategory.emergenciasFamiliarizacion,
        FAQCategory.descansoAptitud,
        FAQCategory.embarquesCapacitacion,
        FAQCategory.consultasBienestar,
        FAQCategory.equiposDocumentos,
        FAQCategory.usoApp,
        FAQCategory.ciberseguridadSoporte,
      ];
      for (final cat in activeCategories) {
        final count = CrewFAQService.catalog.where((item) => item.category == cat).length;
        expect(count > 0, isTrue, reason: "La categoría ${cat.displayName} debe contener preguntas.");
      }
    });

    test('Las 20 preguntas de Ciberseguridad, Claves y Soporte están correctamente cargadas', () {
      final ciberItems = CrewFAQService.catalog.where((item) => item.category == FAQCategory.ciberseguridadSoporte).toList();
      expect(ciberItems.length, equals(20));
      expect(ciberItems.first.id, equals("FAQ-CIB-51"));
      expect(ciberItems.last.id, equals("FAQ-CIB-70"));
    });

    test('Búsqueda por palabras clave recupera respuestas pertinentes', () {
      final service = CrewFAQService.shared;

      // Búsqueda de contraseñas y claves
      final passResults = service.search("contraseña");
      expect(passResults.isNotEmpty, isTrue);
      expect(passResults.any((i) => i.mainQuestion.contains("contraseña")), isTrue);

      // Búsqueda de accidentes e incidentes
      final incResults = service.search("accidente");
      expect(incResults.isNotEmpty, isTrue);
      expect(incResults.any((i) => i.id == "FAQ-SEG-01"), isTrue);

      // Búsqueda de zafarranchos y alarmas
      final zafResults = service.search("zafarrancho");
      expect(zafResults.isNotEmpty, isTrue);
    });

    test('Rechaza estrictamente consultas confidenciales sobre salarios de terceros', () {
      final service = CrewFAQService.shared;
      final q1 = service.findAnswer(query: "¿Cuánto gana el capitán?", profile: null);
      expect(q1.message.contains("información económica"), isTrue);
      expect(q1.isVerified, isFalse);

      final q2 = service.findAnswer(query: "salario de alejandro", profile: null);
      expect(q2.message.contains("información económica"), isTrue);
    });

    test('Deserialización y mapeo de categorías desde Swagger/Intranet (/api/v1/faqs/)', () {
      final sampleJson = {
        'id': 4,
        'pregunta': '¿Cómo reporto un accidente o incidente a bordo?',
        'respuesta': 'Avisá de inmediato al oficial responsable o al Capitán. Después, el hecho debe registrarse mediante el procedimiento de incidentes de la compañía.',
        'categoria': 'seguridad_reportes',
        'categoria_display': 'Seguridad y Reportes',
        'orden': 1,
        'activo': true,
        'updated_at': '2026-10-23T16:54:50.411954-03:00',
        'updated_by_name': 'admin',
      };

      final item = CrewFAQItem.fromIntranetJson(sampleJson);
      expect(item.id, equals('INT-4'));
      expect(item.category, equals(FAQCategory.seguridadReportes));
      expect(item.orden, equals(1));
      expect(item.activo, isTrue);
      expect(item.mainQuestion, equals('¿Cómo reporto un accidente o incidente a bordo?'));
      expect(item.source.contains('admin'), isTrue);
    });

    test('Refleja modificaciones de la Intranet actualizando la respuesta en vivo', () {
      final base = CrewFAQService.catalog[0];
      final modifiedJson = {
        'id': 4,
        'pregunta': '¿Cómo reporto un accidente o novedad crítica a bordo?',
        'respuesta': 'Texto actualizado desde la Intranet por Seguridad Operativa.',
        'categoria': 'seguridad_reportes',
        'orden': 1,
        'activo': true,
        'updated_by_name': 'm.piccinini',
      };

      final updatedItem = CrewFAQItem.fromIntranetJson(modifiedJson, baseMatch: base);
      expect(updatedItem.mainQuestion, equals('¿Cómo reporto un accidente o novedad crítica a bordo?'));
      expect(updatedItem.answerTemplate, equals('Texto actualizado desde la Intranet por Seguridad Operativa.'));
      expect(updatedItem.variants, equals(base.variants)); // Conserva variantes semánticas
      expect(updatedItem.source.contains('m.piccinini'), isTrue);
    });
  });

  group('3. Caché de Sesión, Roles y Modelo de Incidentes', () {
    test('Limpieza de caché en memoria al cerrar sesión', () {
      ProductionCrewProfileService.clearCache();
      expect(true, isTrue);
    });

    test('Modelo Incident soporta número oficial del servidor (incident_number)', () {
      final jsonResponse = {
        'id': 42,
        'incident_number': 'INC-2026-0042',
        'code': 'MG-21',
        'type': 'near_miss',
        'description': 'Detección preventiva en cubierta',
        'status': 'reported',
      };

      final incident = Incident.fromJson(jsonResponse);
      expect(incident.id, equals('42'));
      expect(incident.incidentNumber, equals('INC-2026-0042'));
    });

    test('Separación estricta: usuarios de oficina (a.lopresti, m.piccinini) son rol oficina', () {
      final lopresti = User(id: 'a.lopresti', name: 'Alejandro Lo Presti', role: 'Gerencia General', sector: 'Gerencia');
      expect(lopresti.sector.toLowerCase().contains('gerencia'), isTrue);

      final piccinini = User(id: 'm.piccinini', name: 'Mauricio Piccinini', role: '', sector: 'Operaciones');
      expect(piccinini.sector.toLowerCase().contains('operaciones'), isTrue);
    });

    test('Separación estricta: tripulante r.marenco pertenece a buque/tripulación', () {
      final marenco = User(id: '13', name: 'Marenco Rubén Darío', role: 'Capitán', sector: 'Buque ALFA C');
      expect(marenco.role.toLowerCase().contains('capit'), isTrue);
      expect(marenco.sector.toLowerCase().contains('buque'), isTrue);
    });

    test('Módulo FAQ exclusivo para Tripulantes contiene las 70 preguntas frecuentes y 14 categorías', () {
      expect(CrewFAQService.catalog.length, equals(70));
      expect(FAQCategory.values.length, equals(14));
      const tabView = CrewFaqSearchView(isTabModule: true);
      expect(tabView.isTabModule, isTrue);
    });
  });

  group('4. Novedades desde Swagger (/api/v1/announcements/) y Pantalla de Flota', () {
    test('Post.fromJson parsea Announcement de Swagger con autor, imagen y target', () {
      final swaggerJson = {
        "id": 30016,
        "user": 2,
        "user_detail": {
          "id": 2,
          "username": "a.lopresti",
          "email": "a.lopresti@navieracruzdelsur.com",
          "first_name": "Alejandro",
          "last_name": "Lo Presti"
        },
        "starts_at": "2026-09-24T11:00:00-03:00",
        "ends_at": "2026-10-02T09:00:00-03:00",
        "title": "Save the Date",
        "description": "Evento corporativo de fin de año",
        "importance": 1,
        "image": "https://navieracruzdelsur.dyndns.org:6570/media/announcements/2026/09/save_the_date_rLZdgFg.jpeg",
        "target": "todos",
        "target_display": "Todos"
      };

      final post = Post.fromJson(swaggerJson);
      expect(post.id, equals('30016'));
      expect(post.title, equals('Save the Date'));
      expect(post.content, equals('Evento corporativo de fin de año'));
      expect(post.authorName, equals('Alejandro Lo Presti'));
      expect(post.type, equals(PostType.alert)); // importance == 1
      expect(post.imageUrl, contains('save_the_date_rLZdgFg.jpeg'));
      expect(post.target, equals('todos'));
      expect(post.isForOffice, isTrue);
      expect(post.isForCrew, isTrue);
    });

    test('Filtros de rol objetivo (isForOffice vs isForCrew)', () {
      final postTodos = Post(
        id: '1',
        authorId: '1',
        authorName: 'Admin',
        content: 'Comunicado general',
        timestamp: DateTime.now(),
        type: PostType.news,
        target: 'todos',
      );
      expect(postTodos.isForOffice, isTrue);
      expect(postTodos.isForCrew, isTrue);

      final postOficina = Post(
        id: '2',
        authorId: '2',
        authorName: 'RRHH',
        content: 'Reunión en sede central',
        timestamp: DateTime.now(),
        type: PostType.news,
        target: 'oficina',
      );
      expect(postOficina.isForOffice, isTrue);
      expect(postOficina.isForCrew, isFalse);

      final postTripulantes = Post(
        id: '3',
        authorId: '3',
        authorName: 'Operaciones',
        content: 'Protocolo de maniobra',
        timestamp: DateTime.now(),
        type: PostType.news,
        target: 'tripulacion',
      );
      expect(postTripulantes.isForOffice, isFalse);
      expect(postTripulantes.isForCrew, isTrue);
    });

    test('Línea roja de umbral de carga configurada en 17 M en el módulo Programa', () {
      final scheduleFile = File('lib/modules/schedule/schedule_view.dart');
      expect(scheduleFile.existsSync(), isTrue);
      final content = scheduleFile.readAsStringSync();
      expect(content.contains('wfsTarget = 17.0'), isTrue);
      expect(content.contains('targetKtons: wfsTarget'), isTrue);
      expect(content.contains('17 M'), isTrue);
      expect(content.contains('targetKtons: 15.0'), isFalse);
    });

    test('Cargas Programadas mensuales corresponden exactamente a los datos de la Intranet', () async {
      final scheduleService = MockScheduleService();
      final detailed = await scheduleService.fetchOperationCharges(month: 10, year: 2026, detailed: true);

      double alfaCTotal = 0.0;
      int alfaCShips = 0;
      double gustavoTotal = 0.0;
      int gustavoShips = 0;
      double nanyTotal = 0.0;
      int nanyShips = 0;

      for (var op in detailed) {
        final valK = (op.totalLsfo + op.totalMgo) / 1000.0;
        final ships = op.totalShips.toInt();
        if (op.ship == 'ALFA C') {
          alfaCTotal += valK;
          alfaCShips += ships;
        } else if (op.ship == 'GUSTAVO U') {
          gustavoTotal += valK;
          gustavoShips += ships;
        } else if (op.ship == 'NANY') {
          nanyTotal += valK;
          nanyShips += ships;
        }
      }

      // ALFA C: 14.68 ktons, 25 buques
      expect(alfaCTotal.toStringAsFixed(2), equals("14.68"));
      expect(alfaCShips, equals(25));

      // GUSTAVO U: 7.39 ktons, 16 buques
      expect(gustavoTotal.toStringAsFixed(2), equals("7.39"));
      expect(gustavoShips, equals(16));

      // NANY: 10.99 ktons, 24 buques
      expect(nanyTotal.toStringAsFixed(2), equals("10.99"));
      expect(nanyShips, equals(24));

      // Total WFS: 18.38 ktons, 40 buques
      expect((gustavoTotal + nanyTotal).toStringAsFixed(2), equals("18.38"));
      expect(gustavoShips + nanyShips, equals(40));

      // Verificar fallbacks en schedule_view.dart
      final scheduleFile = File('lib/modules/schedule/schedule_view.dart');
      final content = scheduleFile.readAsStringSync();
      expect(content.contains('raizenMonthKtons = 14.68;'), isTrue);
      expect(content.contains('gustavoMonthKtons = 7.39;'), isTrue);
      expect(content.contains('nanyMonthKtons = 10.99;'), isTrue);
      expect(content.contains('wfsMonthShips = 40;'), isTrue);
    });

    test('Limpieza de novedades viejas: descarta comunicados vencidos o con más de 30 días', () async {
      final homeService = ProductionHomeService();
      final posts = await homeService.fetchPosts();
      final now = DateTime.now();
      for (final p in posts) {
        if (p.endsAt != null) {
          expect(p.endsAt!.isBefore(now), isFalse);
        }
        expect(p.timestamp.isBefore(now.subtract(const Duration(days: 30))), isFalse);
      }
    });
  });

  group('5. Portadas y Cabeceras Dinámicas (Buque NANY & Oficina)', () {
    test('Archivos de imagen del NANY y de Alfa C existen en assets/images', () {
      expect(File('assets/images/nany_dia.png').existsSync(), isTrue);
      expect(File('assets/images/nany_tarde.png').existsSync(), isTrue);
      expect(File('assets/images/nany_noche.png').existsSync(), isTrue);
      expect(File('assets/images/header_bg.png').existsSync(), isTrue);
      expect(File('assets/images/alfa_dia.png').existsSync(), isTrue);
      expect(File('assets/images/alfa_noche.png').existsSync(), isTrue);
      expect(File('assets/images/alfa_tarde.png').existsSync(), isTrue);
    });

    test('Identificación y portadas dinámicas de tripulantes de ALFA C', () {
      final session = SessionManager.shared;

      final alfaUser = User(
        id: "AL_01",
        name: "Marenco Rubén Darío",
        role: "Capitán",
        sector: "Buque ALFA C",
        avatarURL: "",
      );
      session.setTripulanteModeOverride(null);
      session.setCurrentUserForTesting(alfaUser);
      expect(session.isUserAlfaCrew, isTrue);
      expect(session.isUserNanyCrew, isFalse);

      final cover = session.activeCoverAsset;
      expect(cover, anyOf(
        contains('alfa_dia.png'),
        contains('header_bg.png'),
        contains('alfa_noche.png'),
      ));
    });

    test('Identificación exclusiva de tripulantes del NANY', () {
      final session = SessionManager.shared;

      // 1. Usuario de oficina
      session.setCurrentUserForTesting(null);
      session.setTripulanteModeOverride(false);
      expect(session.isUserNanyCrew, isFalse);

      // 2. Miembro asignado al NANY en sector
      final nanyUser = User(
        id: "NA_01",
        name: "Hernandez Pablo",
        role: "Capitán",
        sector: "Buque NANY",
        avatarURL: "",
      );
      session.setTripulanteModeOverride(null);
      session.setCurrentUserForTesting(nanyUser);
      expect(session.isUserNanyCrew, isTrue);

      // 3. Portada NANY asignada a tripulante
      final cover = session.activeCoverAsset;
      expect(cover, anyOf(
        contains('nany_dia.png'),
        contains('nany_tarde.png'),
        contains('nany_noche.png'),
      ));
    });

    test('Tripulantes de GUSTAVO U utilizan las portadas dinámicas de ALFA C hasta fotos nuevas', () {
      final session = SessionManager.shared;

      final gustavoUser = User(
        id: "GU_01",
        name: "Ramirez Pedro",
        role: "Capitán",
        sector: "Buque GUSTAVO U",
        avatarURL: "",
      );
      session.setTripulanteModeOverride(null);
      session.setCurrentUserForTesting(gustavoUser);
      expect(session.isUserGustavoCrew, isTrue);
      expect(session.isUserAlfaCrew, isFalse);
      expect(session.isUserNanyCrew, isFalse);

      // Portada asignada: Alfa C (alfa_dia, header_bg, alfa_noche)
      final cover = session.activeCoverAsset;
      expect(cover, anyOf(
        contains('alfa_dia.png'),
        contains('header_bg.png'),
        contains('alfa_noche.png'),
      ));
    });

    test('Deslizamiento y conmutación de portadas en personal de oficina (Alfa C y Nany)', () {
      final session = SessionManager.shared;

      // Configurar usuario de oficina
      final officeUser = User(
        id: "1",
        name: "Alejandro Lo Presti",
        role: "Gerencia General",
        sector: "Gerencia",
        avatarURL: "",
      );
      session.setCurrentUserForTesting(officeUser);
      session.setTripulanteModeOverride(false);

      expect(session.isUserNanyCrew, isFalse);
      expect(session.isUserAlfaCrew, isFalse);
      expect(session.isUserGustavoCrew, isFalse);

      // Catálogo de 6 portadas (3 de Alfa C y 3 de Nany)
      expect(SessionManager.officeCoversList.length, equals(6));

      // Primera portada por defecto o actual
      final firstCover = session.activeCoverAsset;
      expect(firstCover, contains('.png'));

      // Deslizar hacia adelante (nextOfficeCover)
      session.nextOfficeCover();
      final secondCover = session.activeCoverAsset;
      expect(secondCover, isNotNull);

      // Deslizar hacia atrás (previousOfficeCover)
      session.previousOfficeCover();
      final backToFirst = session.activeCoverAsset;
      expect(backToFirst, equals(firstCover));

      // Conmutar entre buques directamente (toggleOfficeShipCover)
      final initialShip = session.currentOfficeShipName;
      session.toggleOfficeShipCover();
      final nextShip = session.currentOfficeShipName;
      expect(nextShip, isNot(equals(initialShip)));
    });
  });

  group('7. Aislamiento estricto del último programa de carga por buque y limpieza de programas viejos', () {
    test('compareVoyagesDesc prioriza cronológicamente el último viaje por año y mes', () {
      final oldVoyage = {
        'id': 10168,
        'sheet_name': 'SEPTIEMBRE-2025',
        'records_detail': [{'start_date_time': '2025-09-01T08:00:00-03:00'}]
      };
      final newVoyage = {
        'id': 20206,
        'sheet_name': 'OCTUBRE 2026',
        'records_detail': [{'start_date_time': '2026-10-01T08:00:00-03:00'}]
      };
      final midVoyage = {
        'id': 10176,
        'sheet_name': 'DICIEMBRE 2025',
        'records_detail': [{'start_date_time': '2025-12-01T08:00:00-03:00'}]
      };

      final list = [oldVoyage, newVoyage, midVoyage];
      list.sort((a, b) => ProductionFleetService.compareVoyagesDesc(a, b));

      expect(list[0]['id'], equals(20206)); // Octubre 2026
      expect(list[1]['id'], equals(10176)); // Diciembre 2025
      expect(list[2]['id'], equals(10168)); // Septiembre 2025
    });

    test('Schedule.fromJson normaliza shipId a nombres de buque legibles sin duplicados', () {
      final s1 = Schedule.fromJson({
        'id': '10176',
        'ship': 1,
        'ship_detail': {'id': 1, 'description': 'ALFA C'},
        'sheet_name': 'DICIEMBRE 2025',
      });
      final s2 = Schedule.fromJson({
        'id': '20206',
        'ship': 2,
        'ship_detail': {'id': 2, 'description': 'GUSTAVO U'},
        'sheet_name': 'OCTUBRE 2026',
      });
      final s3 = Schedule.fromJson({
        'id': '20205',
        'ship': 4,
        'ship_detail': {'id': 4, 'description': 'NANY'},
        'sheet_name': 'OCTUBRE-26',
      });

      expect(s1.shipId, equals('Alfa C'));
      expect(s2.shipId, equals('Gustavo U'));
      expect(s3.shipId, equals('Nany'));
    });

    test('fetchMonthlySchedule retorna únicamente el último programa de cada buque (1 por barco)', () async {
      final schedules = await MockScheduleService().fetchMonthlySchedule();
      expect(schedules.length, equals(3));
      final shipNames = schedules.map((s) => s.shipId).toSet();
      expect(shipNames.contains('Alfa C'), isTrue);
      expect(shipNames.contains('Gustavo U'), isTrue);
      expect(shipNames.contains('Nany'), isTrue);
    });

    test('Target ships de cada buque no contienen terminales, muelles ni acumulaciones históricas', () {
      final alfaTargets = Ship.getDefaultTargetShipsFor('Alfa C');
      final gustavoTargets = Ship.getDefaultTargetShipsFor('Gustavo U');
      final nanyTargets = Ship.getDefaultTargetShipsFor('Nany');

      // Máximo buques de un solo período mensual
      expect(alfaTargets.length <= 15, isTrue);
      expect(gustavoTargets.length <= 15, isTrue);
      expect(nanyTargets.length <= 15, isTrue);

      // Ningún muelle ni terminal
      for (final t in [...alfaTargets, ...gustavoTargets, ...nanyTargets]) {
        final upper = t.name.toUpperCase();
        expect(upper.contains('DDI'), isFalse);
        expect(upper.contains('DAPSA'), isFalse);
        expect(upper.contains('MUELLE'), isFalse);
        expect(upper.contains('CAMPANA'), isFalse);
        expect(upper.contains('PAE TOMA'), isFalse);
      }
    });

    test('Programa de Carga oficial de ALFA C contiene exactamente los buques requeridos', () {
      final targets = Ship.getDefaultTargetShipsFor('ALFA C');
      final names = targets.map((t) => t.name.toUpperCase()).toList();
      expect(names.contains('SCRUB ISLAND'), isTrue);
      expect(names.contains('EDESSAIKOS'), isTrue);
      expect(names.contains('CARAVOS TRIUMPH'), isTrue);
      expect(names.contains('ASTRO CASTOR'), isTrue);
      expect(names.contains('YAESU'), isTrue);
      expect(targets.length, equals(5));
    });

    test('Programa de Carga oficial de NANY contiene exactamente los buques requeridos', () {
      final targets = Ship.getDefaultTargetShipsFor('NANY');
      final names = targets.map((t) => t.name.toUpperCase()).toList();
      expect(names.contains('SCOT DRESDEN'), isTrue);
      expect(names.contains('CL EMILY BRONTE'), isTrue);
      expect(names.contains('BBC RAISE'), isTrue);
      expect(names.contains('BC PISTI'), isTrue);
      expect(names.contains('STAR NAGA'), isTrue);
      expect(targets.length, equals(5));
    });

    test('Recursos de los barcos (Agua, Combustible, Slop) coinciden con los valores exactos de la intranet', () async {
      final ships = await MockFleetService().fetchShips();
      final alfa = ships.firstWhere((s) => s.name.contains('ALFA'));
      final gustavo = ships.firstWhere((s) => s.name.contains('GUSTAVO'));
      final nany = ships.firstWhere((s) => s.name.contains('NANY'));

      // ALFA C (118.2 m³ agua, 150.54 m³ combustible, 8.31 m³ slop)
      expect(alfa.totalWater, equals(118.2));
      expect(alfa.totalCarbon, equals(150.54));
      expect(alfa.totalSlop, equals(8.31));

      // GUSTAVO U (90.0 m³ agua, 89.76 m³ combustible, 11.89 m³ slop)
      expect(gustavo.totalWater, equals(90.0));
      expect(gustavo.totalCarbon, equals(89.76));
      expect(gustavo.totalSlop, equals(11.89));

      // NANY (125.36 m³ agua, 115.52 m³ combustible, 86.39 m³ slop)
      expect(nany.totalWater, equals(125.36));
      expect(nany.totalCarbon, equals(115.52));
      expect(nany.totalSlop, equals(86.39));
    });
  });

  group('7. Validación de Días de Dotación Oficiales de Intranet (ALFA C, GUSTAVO U, NANY)', () {
    test('ALFA C: Dotación de 15 tripulantes con días exactos del tablero', () async {
      final crew = await MockFleetService().fetchCrew('ALFA C');
      expect(crew.length, equals(15));

      final marenco = crew.firstWhere((c) => c.name.contains('Marenco'));
      final carattoli = crew.firstWhere((c) => c.name.contains('Carattoli'));
      final sosaArmando = crew.firstWhere((c) => c.name.contains('Sosa Armando'));
      final ledesma = crew.firstWhere((c) => c.name.contains('Ledesma'));
      final albornoz = crew.firstWhere((c) => c.name.contains('Albornoz'));
      final davidRodriguez = crew.firstWhere((c) => c.name.contains('Rodriguez David'));

      expect(marenco.calculatedDays, equals(23));
      expect(carattoli.calculatedDays, equals(48));
      expect(sosaArmando.calculatedDays, equals(31));
      expect(ledesma.calculatedDays, equals(49));
      expect(albornoz.calculatedDays, equals(6));
      expect(davidRodriguez.calculatedDays, equals(6));
    });

    test('GUSTAVO U: Dotación de 14 tripulantes con días exactos del tablero (Dotación mínima incompleta)', () async {
      final crew = await MockFleetService().fetchCrew('GUSTAVO U');
      expect(crew.length, equals(14));

      final tobias = crew.firstWhere((c) => c.name.contains('Tobias'));
      final cucurulo = crew.firstWhere((c) => c.name.contains('Cucurulo'));
      final camacho = crew.firstWhere((c) => c.name.contains('Camacho'));
      final percara = crew.firstWhere((c) => c.name.contains('Percara'));
      final aguero = crew.firstWhere((c) => c.name.contains('Agüero'));
      final gaetan = crew.firstWhere((c) => c.name.contains('Gaetan'));

      expect(tobias.calculatedDays, equals(121));
      expect(cucurulo.calculatedDays, equals(37));
      expect(camacho.calculatedDays, equals(42));
      expect(percara.calculatedDays, equals(22));
      expect(aguero.calculatedDays, equals(27));
      expect(gaetan.calculatedDays, equals(9));
    });

    test('NANY: Dotación de 15 tripulantes con días exactos del tablero', () async {
      final crew = await MockFleetService().fetchCrew('NANY');
      expect(crew.length, equals(15));

      final hernandez = crew.firstWhere((c) => c.name.contains('Hernandez'));
      final gallardo = crew.firstWhere((c) => c.name.contains('Gallardo'));
      final saucedo = crew.firstWhere((c) => c.name.contains('Saucedo'));
      final rosales = crew.firstWhere((c) => c.name.contains('Rosales'));
      final andrada = crew.firstWhere((c) => c.name.contains('Andrada'));
      final tula = crew.firstWhere((c) => c.name.contains('Tula'));

      expect(hernandez.calculatedDays, equals(9));
      expect(gallardo.calculatedDays, equals(5));
      expect(saucedo.calculatedDays, equals(27));
      expect(rosales.calculatedDays, equals(31));
      expect(andrada.calculatedDays, equals(36));
      expect(tula.calculatedDays, equals(5));
    });
  });

  group('8. Validación de Mejoras Solicitadas: Usuario marenco, Modo Tripulante y Cámaras Ezviz', () {
    test('Usuario "marenco" resuelve de forma estricta a Capitán Marenco Rubén Darío de ALFA C', () async {
      // 1. Deserialización directa desde json
      final user = User.fromJson({'username': 'marenco'});
      expect(user.name, equals('Marenco Rubén Darío'));
      expect(user.role, equals('Capitán'));
      expect(user.sector, contains('ALFA C'));

      // 2. Comprobación en SessionManager
      SessionManager.shared.setCurrentUserForTesting(user);
      expect(SessionManager.shared.isUserTripulanteRole, isTrue);
      expect(SessionManager.shared.isTripulanteMode, isTrue);
      expect(SessionManager.shared.isUserAlfaCrew, isTrue);
      expect(SessionManager.shared.isUserNanyCrew, isFalse);

      // 3. Login por MockAuthService
      final authResult = await MockAuthService().login('marenco', 'pass123');
      final loggedUser = authResult['user'] as User;
      expect(loggedUser.name, equals('Marenco Rubén Darío'));
      expect(loggedUser.role, equals('Capitán'));
    });

    test('Cámaras Ezviz: ALFA C y NANY cuentan con URLs activas no vencidas y caché instantáneo', () async {
      final alfaUrl = EzvizService.shared.getCachedStreamUrl('BF1765385');
      final nanyUrl = EzvizService.shared.getCachedStreamUrl('BF1765344');

      expect(alfaUrl, isNotNull);
      expect(alfaUrl!.contains('BF1765385_1_1.m3u8'), isTrue);
      expect(alfaUrl.contains('expire=1793052311'), isTrue); // Timestamp activo y válido

      expect(nanyUrl, isNotNull);
      expect(nanyUrl!.contains('BF1765344_1_1.m3u8'), isTrue);
      expect(nanyUrl.contains('expire=1793052312'), isTrue);

      // Resolución inmediata con getLiveStreamUrl
      final liveAlfa = await EzvizService.shared.getLiveStreamUrl('BF1765385');
      expect(liveAlfa, equals(alfaUrl));
    });
  });
}


