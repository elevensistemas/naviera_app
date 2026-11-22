
/// Modelo de respuesta para el módulo de Compras / Pedidos de la Intranet
class ComprasResponse {
  final Map<String, dynamic> filters;
  final ComprasSummary summary;
  final int count;
  final List<PedidoCompra> results;

  ComprasResponse({
    required this.filters,
    required this.summary,
    required this.count,
    required this.results,
  });

  factory ComprasResponse.fromJson(Map<String, dynamic> json) {
    return ComprasResponse(
      filters: json['filters'] is Map<String, dynamic> ? json['filters'] : {},
      summary: json['summary'] is Map<String, dynamic>
          ? ComprasSummary.fromJson(json['summary'])
          : ComprasSummary.empty(),
      count: json['count'] is int ? json['count'] : (int.tryParse('${json['count']}') ?? 0),
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => PedidoCompra.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ComprasSummary {
  final int totalPedidos;
  final int totalArticulos;
  final double totalUnidadesSolicitadas;
  final ComprasCategoryStats criticos;
  final ComprasCategoryStats noCriticos;
  final List<ComprasShipStats> porBarco;
  final List<ComprasTypeStats> porTipoPedido;

  ComprasSummary({
    required this.totalPedidos,
    required this.totalArticulos,
    required this.totalUnidadesSolicitadas,
    required this.criticos,
    required this.noCriticos,
    required this.porBarco,
    required this.porTipoPedido,
  });

  factory ComprasSummary.empty() => ComprasSummary(
        totalPedidos: 0,
        totalArticulos: 0,
        totalUnidadesSolicitadas: 0,
        criticos: ComprasCategoryStats.empty(),
        noCriticos: ComprasCategoryStats.empty(),
        porBarco: [],
        porTipoPedido: [],
      );

  factory ComprasSummary.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

    return ComprasSummary(
      totalPedidos: _i(json['total_pedidos']),
      totalArticulos: _i(json['total_articulos']),
      totalUnidadesSolicitadas: _d(json['total_unidades_solicitadas']),
      criticos: json['criticos'] is Map<String, dynamic>
          ? ComprasCategoryStats.fromJson(json['criticos'])
          : ComprasCategoryStats.empty(),
      noCriticos: json['no_criticos'] is Map<String, dynamic>
          ? ComprasCategoryStats.fromJson(json['no_criticos'])
          : ComprasCategoryStats.empty(),
      porBarco: (json['por_barco'] as List<dynamic>?)
              ?.map((b) => ComprasShipStats.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      porTipoPedido: (json['por_tipo_pedido'] as List<dynamic>?)
              ?.map((t) => ComprasTypeStats.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ComprasCategoryStats {
  final int total;
  final int cumplidos;
  final int vencidos;
  final int enPlan;

  ComprasCategoryStats({
    required this.total,
    required this.cumplidos,
    required this.vencidos,
    required this.enPlan,
  });

  factory ComprasCategoryStats.empty() => ComprasCategoryStats(
        total: 0,
        cumplidos: 0,
        vencidos: 0,
        enPlan: 0,
      );

  factory ComprasCategoryStats.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    return ComprasCategoryStats(
      total: _i(json['total']),
      cumplidos: _i(json['cumplidos']),
      vencidos: _i(json['vencidos']),
      enPlan: _i(json['en_plan']),
    );
  }
}

class ComprasShipStats {
  final String barco;
  final int shipRemoteId;
  final int shipIntranetId;
  final int totalPedidos;
  final int cumplidos;
  final int vencidos;
  final int enPlan;
  final int criticos;
  final int totalArticulos;
  final double totalUnidadesSolicitadas;

  ComprasShipStats({
    required this.barco,
    required this.shipRemoteId,
    required this.shipIntranetId,
    required this.totalPedidos,
    required this.cumplidos,
    required this.vencidos,
    required this.enPlan,
    required this.criticos,
    required this.totalArticulos,
    required this.totalUnidadesSolicitadas,
  });

  factory ComprasShipStats.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

    return ComprasShipStats(
      barco: json['barco']?.toString() ?? '',
      shipRemoteId: _i(json['ship_remote_id']),
      shipIntranetId: _i(json['ship_intranet_id']),
      totalPedidos: _i(json['total_pedidos']),
      cumplidos: _i(json['cumplidos']),
      vencidos: _i(json['vencidos']),
      enPlan: _i(json['en_plan']),
      criticos: _i(json['criticos']),
      totalArticulos: _i(json['total_articulos']),
      totalUnidadesSolicitadas: _d(json['total_unidades_solicitadas']),
    );
  }
}

class ComprasTypeStats {
  final String tipoPedido;
  final int totalPedidos;
  final int totalArticulos;
  final double totalUnidadesSolicitadas;

  ComprasTypeStats({
    required this.tipoPedido,
    required this.totalPedidos,
    required this.totalArticulos,
    required this.totalUnidadesSolicitadas,
  });

  factory ComprasTypeStats.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

    return ComprasTypeStats(
      tipoPedido: json['tipo_pedido']?.toString() ?? '',
      totalPedidos: _i(json['total_pedidos']),
      totalArticulos: _i(json['total_articulos']),
      totalUnidadesSolicitadas: _d(json['total_unidades_solicitadas']),
    );
  }
}

class PedidoCompra {
  final int id;
  final String numero;
  final String fechaPedido;
  final String? fechaVencimiento;
  final int diasPlazo;
  final int diasTranscurridos;
  final String estado; // En plan, Vencido, Cumplido
  final String vigencia; // Vigente, Vencido
  final bool cumplido;
  final bool esCritico;
  final String barco; // Alfa C, Gustavo U, Nany
  final String barcoNombreCompleto;
  final String departamento; // Cubierta, Máquinas
  final String tipoPedido; // Repuestos, Consumible, Servicios
  final String categoria;
  final String urgencia; // Normal, Urgente, Crítico
  final String estadoDocumento;
  final String? usuarioCreador;
  final String? observaciones;
  final int cantidadArticulos;
  final double totalUnidadesSolicitadas;
  final List<ArticuloPedido> articulos;

  PedidoCompra({
    required this.id,
    required this.numero,
    required this.fechaPedido,
    this.fechaVencimiento,
    required this.diasPlazo,
    required this.diasTranscurridos,
    required this.estado,
    required this.vigencia,
    required this.cumplido,
    required this.esCritico,
    required this.barco,
    required this.barcoNombreCompleto,
    required this.departamento,
    required this.tipoPedido,
    required this.categoria,
    required this.urgencia,
    required this.estadoDocumento,
    this.usuarioCreador,
    this.observaciones,
    required this.cantidadArticulos,
    required this.totalUnidadesSolicitadas,
    required this.articulos,
  });

  factory PedidoCompra.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    bool _b(dynamic v) => v == true || v == 1 || '$v'.toLowerCase() == 'true';

    return PedidoCompra(
      id: _i(json['id']),
      numero: json['numero']?.toString() ?? '',
      fechaPedido: json['fecha_pedido']?.toString() ?? '',
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      diasPlazo: _i(json['dias_plazo']),
      diasTranscurridos: _i(json['dias_transcurridos']),
      estado: json['estado']?.toString() ?? 'En plan',
      vigencia: json['vigencia']?.toString() ?? 'Vigente',
      cumplido: _b(json['cumplido']),
      esCritico: _b(json['es_critico']),
      barco: json['barco']?.toString() ?? '',
      barcoNombreCompleto: json['barco_nombre_completo']?.toString() ?? '',
      departamento: json['departamento']?.toString() ?? '',
      tipoPedido: json['tipo_pedido']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      urgencia: json['urgencia']?.toString() ?? 'Normal',
      estadoDocumento: json['estado_documento']?.toString() ?? '',
      usuarioCreador: json['usuario_creador']?.toString(),
      observaciones: json['observaciones']?.toString(),
      cantidadArticulos: _i(json['cantidad_articulos']),
      totalUnidadesSolicitadas: _d(json['total_unidades_solicitadas']),
      articulos: (json['articulos'] as List<dynamic>?)
              ?.map((a) => ArticuloPedido.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Un pedido es Crítico en el sistema de Compras de la Intranet
  /// si contiene al menos un artículo clasificado como dispositivo crítico (o esCritico si no hay artículos).
  bool get esPedidoCritico => articulos.isNotEmpty
      ? articulos.any((a) => a.esDispositivoCritico)
      : esCritico;

  /// Está cumplido si tiene el flag cumplido o su estado es 'Cumplido'
  bool get estaCumplido => cumplido || estado.toLowerCase() == 'cumplido';

  /// Está vencido si no está cumplido y su vigencia/estado es vencido, o si sus días transcurridos superan el plazo
  bool get estaVencido {
    if (estaCumplido) return false;
    if (vigencia.toLowerCase() == 'vencido' || estado.toLowerCase() == 'vencido') return true;
    final plazo = diasPlazo > 0 ? diasPlazo : 45;
    return diasTranscurridos > plazo;
  }

  /// En plan si no está cumplido ni vencido
  bool get estaEnPlan => !estaCumplido && !estaVencido;
}

class ArticuloPedido {
  final int lineaId;
  final int productoId;
  final String codigoReferencia;
  final String nombre;
  final String descripcion;
  final double cantidadSolicitada;
  final String unidad;
  final bool completado;
  final bool esDispositivoCritico;

  ArticuloPedido({
    required this.lineaId,
    required this.productoId,
    required this.codigoReferencia,
    required this.nombre,
    required this.descripcion,
    required this.cantidadSolicitada,
    required this.unidad,
    required this.completado,
    required this.esDispositivoCritico,
  });

  factory ArticuloPedido.fromJson(Map<String, dynamic> json) {
    int _i(dynamic v) => (v is int) ? v : (int.tryParse('$v') ?? 0);
    double _d(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    bool _b(dynamic v) => v == true || v == 1 || '$v'.toLowerCase() == 'true';

    return ArticuloPedido(
      lineaId: _i(json['linea_id']),
      productoId: _i(json['producto_id']),
      codigoReferencia: json['codigo_referencia']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      cantidadSolicitada: _d(json['cantidad_solicitada']),
      unidad: json['unidad']?.toString() ?? 'u',
      completado: _b(json['completado']),
      esDispositivoCritico: _b(json['es_dispositivo_critico']),
    );
  }
}
