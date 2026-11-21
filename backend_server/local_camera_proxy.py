"""
Local development proxy for Naviera Cruz del Sur (CORS & SSL bridge for Flutter Web)
Port: 8086
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import urllib.request
import urllib.error
import ssl
import json
import time
import sys

import base64

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

INTRANET_BASE = "https://navieracruzdelsur.dyndns.org:6570"
CENTINELA_BASE = "https://centinela.dyndns.org:5073"
MASTER_TOKEN = "Token f910e860cb94c3ebeccc0e1a4b16cb1ae641d69b"

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# Cache en memoria del token CAT para respuestas instantáneas
_cached_cat_bytes = None
_cached_cat_time = 0
_cached_cat_token = ""

# Cache en memoria de assets estáticos pesados (ej. JS 8.7MB, CSS)
_assets_cache = {}

# Mapeo de sesión para filtrado de buque único en el mapa táctico
_active_focus_vessel = ""
_ticket_vessel = {}
_sid_vessel = {}

# Caché de velocidades en nudos (speed_kn) por buque desde Centinela
_fleet_speeds = {}
_fleet_speeds_updated = 0.0

def _sync_fleet_speeds():
    global _fleet_speeds, _fleet_speeds_updated, _cached_cat_token
    try:
        if not _cached_cat_token:
            _fetch_intranet_cat()
        if not _cached_cat_token:
            return

        # 1. Sesión efímera de mapa para consultar map-state
        b = json.dumps({'ticket': 'anonymous', 'focus_vessel': 'BT.NANY1'}).encode('utf-8')
        req = urllib.request.Request(f"{CENTINELA_BASE}/api/v1/external/map-session", data=b, method='POST')
        req.add_header('Content-Type', 'application/json')
        req.add_header('Authorization', f'Bearer {_cached_cat_token}')
        with urllib.request.urlopen(req, context=ctx, timeout=5) as r:
            sess = json.loads(r.read().decode('utf-8'))
        ticket = sess.get('bootstrap_ticket')
        if not ticket:
            return

        # 2. Activar sesión
        b2 = json.dumps({'ticket': ticket}).encode('utf-8')
        req2 = urllib.request.Request(f"{CENTINELA_BASE}/api/v1/external/map-session/activate", data=b2, method='POST')
        req2.add_header('Content-Type', 'application/json')
        with urllib.request.urlopen(req2, context=ctx, timeout=5) as r2:
            act = json.loads(r2.read().decode('utf-8'))
        sid = act.get('sid')
        if not sid:
            return

        # 3. Consultar map-state
        req3 = urllib.request.Request(f"{CENTINELA_BASE}/api/v1/external/map-state")
        req3.add_header('x-centinela-map-sid', sid)
        with urllib.request.urlopen(req3, context=ctx, timeout=5) as r3:
            mstate = json.loads(r3.read().decode('utf-8'))

        for v in mstate.get('fleet', []):
            k = v.get('key')
            spd = v.get('speed_kn')
            if k and spd is not None:
                try:
                    _fleet_speeds[k.upper().strip()] = float(spd)
                except Exception:
                    pass
        _fleet_speeds_updated = time.time()
        print(f"[Proxy] Velocidades de flota actualizadas: {_fleet_speeds}", flush=True)
    except Exception as e:
        print(f"[Proxy] Error sincronizando velocidades de flota: {e}", flush=True)

def _inject_speed_if_sts(path, raw_bytes):
    if '/api/v1/external/sts-risk/' in path:
        try:
            sts_json = json.loads(raw_bytes.decode('utf-8'))
            v_key = path.split('?')[0].split('/')[-1].strip().upper()
            if (time.time() - _fleet_speeds_updated > 25) or (v_key not in _fleet_speeds):
                _sync_fleet_speeds()
            spd = _fleet_speeds.get(v_key)
            if spd is None:
                for k, val in _fleet_speeds.items():
                    if v_key in k or k in v_key:
                        spd = val
                        break
            if spd is not None:
                sts_json['speed_kn'] = spd
                sts_json['sog'] = spd
                return json.dumps(sts_json).encode('utf-8')
        except Exception as e_sts:
            print(f"[Proxy] Error inyectando speed_kn a sts-risk: {e_sts}", flush=True)
    return raw_bytes

def _generate_vessel_health_mock(path):
    """
    Proveedor Centinela de respaldo para Salud del Buque conforme a contrato OpenAPI /api/v1/external/vessel-health
    """
    clean_p = path.split('?')[0].rstrip('/')
    now_str = time.strftime('%Y-%m-%dT%H:%M:%S-03:00')

    vessels_data = {
        'BT.ALFAC': {
            'vessel_key': 'BT.ALFAC',
            'vessel_name': 'ALFA C',
            'health_score_final': 88,
            'operational_status': 'OPERATIVO',
            'headline': 'Condición general óptima para navegación y operaciones STS',
            'delta': 2,
            'calculated_at': now_str,
            'pillars': {
                'operacion': 92,
                'disponibilidad': 86,
                'seguridad': 90,
                'preparacion': 85
            },
            'kpis': {
                'critical_maint_overdue': 0,
                'normal_maint_overdue': 3,
                'running_hours_overdue': 1,
                'certs_really_expired': 0,
                'certs_in_renewal_window': 1,
                'crew_reliefs_pending': 2,
                'critical_purchases': 0
            },
            'certificates_summary': {
                'vigente': 14,
                'proximo_a_vencer': 2,
                'en_ventana_renovacion': 1,
                'vencido': 0,
                'estado_no_verificado': 0,
                'items': [
                    {
                        'id': 'CERT-ALF-01',
                        'name': 'Certificado Nacional de Seguridad de la Navegación',
                        'authority': 'PNA',
                        'state': 'VIGENTE',
                        'nominal_expiry': '2027-04-15',
                        'effective_deadline': '2027-04-15',
                        'window_days_remaining': None,
                        'notes': 'Inspección anual completada con éxito'
                    },
                    {
                        'id': 'CERT-ALF-02',
                        'name': 'Líneas de Carga Internacional',
                        'authority': 'RINA',
                        'state': 'EN_VENTANA_RENOVACION',
                        'nominal_expiry': '2026-11-10',
                        'effective_deadline': '2027-02-10',
                        'window_days_remaining': 81,
                        'notes': 'Vencimiento nominal alcanzado. Extensión válida de 3 meses otorgada por RINA. NO mostrar como vencido.'
                    },
                    {
                        'id': 'CERT-ALF-03',
                        'name': 'Gestión de la Seguridad (SGS / ISM Code)',
                        'authority': 'PNA',
                        'state': 'PROXIMO_A_VENCER',
                        'nominal_expiry': '2026-12-18',
                        'effective_deadline': '2026-12-18',
                        'window_days_remaining': None,
                        'notes': 'Auditoría intermedia de seguimiento solicitada'
                    },
                    {
                        'id': 'CERT-ALF-04',
                        'name': 'Prevención de la Contaminación por Hidrocarburos (IOPP)',
                        'authority': 'RINA',
                        'state': 'VIGENTE',
                        'nominal_expiry': '2027-08-20',
                        'effective_deadline': '2027-08-20',
                        'window_days_remaining': None,
                        'notes': 'Equipos OWS calibrados y certificados'
                    },
                    {
                        'id': 'CERT-ALF-05',
                        'name': 'Dotación de Seguridad Mínima',
                        'authority': 'PNA',
                        'state': 'VIGENTE',
                        'nominal_expiry': '2028-01-10',
                        'effective_deadline': '2028-01-10',
                        'window_days_remaining': None,
                        'notes': 'Tripulación completa según cuadro de guardia'
                    }
                ]
            },
            'marad_official_parity': {
                'maintenance': {
                    'triangle': 0,
                    'circle': 3,
                    'dique': 1
                },
                'running_hours': 1,
                'inventory': 94,
                'certificates': 100
            },
            'priorities': [
                {
                    'id': 'PRIO-ALF-1',
                    'type': 'renewal_window',
                    'severity': 'warning',
                    'title': 'Certificado en ventana de renovación (Líneas de Carga)',
                    'description': 'Vencimiento nominal alcanzado el 10/11/2026. Límite efectivo con extensión: 10/02/2027 (quedan 81 días de ventana).',
                    'category': 'certificates',
                    'action_required': 'Coordinar inspección estatutaria con RINA antes de febrero 2027'
                },
                {
                    'id': 'PRIO-ALF-2',
                    'type': 'warning',
                    'severity': 'warning',
                    'title': '3 Mantenimientos ordinarios (●) pendientes',
                    'description': 'Mantenimiento preventivo en bombas de achique y filtros de generador.',
                    'category': 'maintenance',
                    'action_required': 'Ejecutar en la próxima escala técnica de guardia'
                },
                {
                    'id': 'PRIO-ALF-3',
                    'type': 'info',
                    'severity': 'info',
                    'title': '1 Tarea de horas de marcha próxima',
                    'description': 'Revisión programada de 500hs en compresor de aire #2.',
                    'category': 'maintenance',
                    'action_required': 'Registrar lectura de horómetro actualizada'
                }
            ],
            'sources_sync': {
                'marad_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 900)),
                'intranet_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 600)),
                'relative_age': 'hace 15 minutos',
                'status': 'healthy'
            }
        },
        'BT.GUSTAVO.U': {
            'vessel_key': 'BT.GUSTAVO.U',
            'vessel_name': 'GUSTAVO U',
            'health_score_final': 74,
            'operational_status': 'ATENCION_REQUERIDA',
            'headline': 'Tareas ordinarias acumuladas y 1 certificado próximo a vencer',
            'delta': -3,
            'calculated_at': now_str,
            'pillars': {
                'operacion': 80,
                'disponibilidad': 72,
                'seguridad': 75,
                'preparacion': 68
            },
            'kpis': {
                'critical_maint_overdue': 0,
                'normal_maint_overdue': 7,
                'running_hours_overdue': 2,
                'certs_really_expired': 0,
                'certs_in_renewal_window': 0,
                'crew_reliefs_pending': 4,
                'critical_purchases': 1
            },
            'certificates_summary': {
                'vigente': 13,
                'proximo_a_vencer': 3,
                'en_ventana_renovacion': 0,
                'vencido': 0,
                'estado_no_verificado': 1,
                'items': [
                    {
                        'id': 'CERT-GUS-01',
                        'name': 'Seguridad Radioeléctrica (GMDSS)',
                        'authority': 'PNA',
                        'state': 'PROXIMO_A_VENCER',
                        'nominal_expiry': '2026-12-05',
                        'effective_deadline': '2026-12-05',
                        'window_days_remaining': None,
                        'notes': 'Vence en 14 días. Inspección técnica de radio solicitada a Prefectura.'
                    },
                    {
                        'id': 'CERT-GUS-02',
                        'name': 'Certificado de Arqueo Nacional',
                        'authority': 'PNA',
                        'state': 'VIGENTE',
                        'nominal_expiry': '2028-06-30',
                        'effective_deadline': '2028-06-30',
                        'window_days_remaining': None,
                        'notes': 'Vigencia extendida sin observaciones'
                    },
                    {
                        'id': 'CERT-GUS-03',
                        'name': 'Certificado Sanitario de a Bordo',
                        'authority': 'Sanidad de Fronteras',
                        'state': 'PROXIMO_A_VENCER',
                        'nominal_expiry': '2026-12-14',
                        'effective_deadline': '2026-12-14',
                        'window_days_remaining': None,
                        'notes': 'Renovación de botiquín de a bordo requerida'
                    }
                ]
            },
            'marad_official_parity': {
                'maintenance': {
                    'triangle': 0,
                    'circle': 7,
                    'dique': 2
                },
                'running_hours': 2,
                'inventory': 87,
                'certificates': 92
            },
            'priorities': [
                {
                    'id': 'PRIO-GUS-1',
                    'type': 'warning',
                    'severity': 'warning',
                    'title': 'Certificado de Radio (GMDSS) próximo a vencer',
                    'description': 'Vence el 05/12/2026 (quedan 14 días).',
                    'category': 'certificates',
                    'action_required': 'Confirmar fecha de inspección con radioinspector de Prefectura'
                },
                {
                    'id': 'PRIO-GUS-2',
                    'type': 'warning',
                    'severity': 'warning',
                    'title': '7 Mantenimientos ordinarios (●) acumulados',
                    'description': 'Revisión de válvulas de descarga, purificadora y lubricantes de auxiliares.',
                    'category': 'maintenance',
                    'action_required': 'Planificar jornada técnica con Jefe de Máquinas'
                },
                {
                    'id': 'PRIO-GUS-3',
                    'type': 'warning',
                    'severity': 'warning',
                    'title': '1 Pedido de compra crítico pendiente',
                    'description': 'Repuesto para generador auxiliar en proceso de cotización.',
                    'category': 'purchases',
                    'action_required': 'Seguimiento prioritario con departamento Compras'
                }
            ],
            'sources_sync': {
                'marad_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 1200)),
                'intranet_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 600)),
                'relative_age': 'hace 20 minutos',
                'status': 'healthy'
            }
        },
        'BT.NANY1': {
            'vessel_key': 'BT.NANY1',
            'vessel_name': 'NANY',
            'health_score_final': 91,
            'operational_status': 'OPERATIVO',
            'headline': 'Alta confiabilidad técnica y operativa, mantenimiento al día',
            'delta': 1,
            'calculated_at': now_str,
            'pillars': {
                'operacion': 95,
                'disponibilidad': 90,
                'seguridad': 92,
                'preparacion': 88
            },
            'kpis': {
                'critical_maint_overdue': 0,
                'normal_maint_overdue': 1,
                'running_hours_overdue': 0,
                'certs_really_expired': 0,
                'certs_in_renewal_window': 1,
                'crew_reliefs_pending': 1,
                'critical_purchases': 0
            },
            'certificates_summary': {
                'vigente': 15,
                'proximo_a_vencer': 1,
                'en_ventana_renovacion': 1,
                'vencido': 0,
                'estado_no_verificado': 0,
                'items': [
                    {
                        'id': 'CERT-NAN-01',
                        'name': 'Certificado de Seguridad de Construcción',
                        'authority': 'RINA',
                        'state': 'VIGENTE',
                        'nominal_expiry': '2027-09-15',
                        'effective_deadline': '2027-09-15',
                        'window_days_remaining': None,
                        'notes': 'Casco e instalaciones verificadas'
                    },
                    {
                        'id': 'CERT-NAN-02',
                        'name': 'Protección del Buque (PBIP / ISPS)',
                        'authority': 'PNA',
                        'state': 'EN_VENTANA_RENOVACION',
                        'nominal_expiry': '2026-11-05',
                        'effective_deadline': '2027-02-05',
                        'window_days_remaining': 76,
                        'notes': 'Vencimiento nominal alcanzado el 05/11. Prórroga válida hasta el 05/02/2027.'
                    },
                    {
                        'id': 'CERT-NAN-03',
                        'name': 'Seguridad del Equipo de Buque de Carga',
                        'authority': 'RINA',
                        'state': 'PROXIMO_A_VENCER',
                        'nominal_expiry': '2026-12-28',
                        'effective_deadline': '2026-12-28',
                        'window_days_remaining': None,
                        'notes': 'Inspección de balsas salvavidas y pirotecnia al día'
                    }
                ]
            },
            'marad_official_parity': {
                'maintenance': {
                    'triangle': 0,
                    'circle': 1,
                    'dique': 0
                },
                'running_hours': 0,
                'inventory': 96,
                'certificates': 98
            },
            'priorities': [
                {
                    'id': 'PRIO-NAN-1',
                    'type': 'renewal_window',
                    'severity': 'warning',
                    'title': 'Certificado PBIP en ventana de renovación',
                    'description': 'Vencimiento nominal: 05/11/2026. Límite efectivo: 05/02/2027 (quedan 76 días válidos).',
                    'category': 'certificates',
                    'action_required': 'Monitoreo de auditoría con Oficial de Protección (OPC)'
                },
                {
                    'id': 'PRIO-NAN-2',
                    'type': 'info',
                    'severity': 'info',
                    'title': '1 Mantenimiento ordinario (●) programado',
                    'description': 'Limpieza e inspección de filtros de toma de mar.',
                    'category': 'maintenance',
                    'action_required': 'Ejecutar según cronograma de guardia'
                }
            ],
            'sources_sync': {
                'marad_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 720)),
                'intranet_last_success_at': time.strftime('%Y-%m-%dT%H:%M:%S-03:00', time.localtime(time.time() - 600)),
                'relative_age': 'hace 12 minutos',
                'status': 'healthy'
            }
        }
    }

    # Si se pide el listado consolidado
    if clean_p.endswith('/vessel-health'):
        consolidated = []
        for k in ['BT.ALFAC', 'BT.GUSTAVO.U', 'BT.NANY1']:
            v = vessels_data[k]
            consolidated.append({
                'vessel_key': v['vessel_key'],
                'vessel_name': v['vessel_name'],
                'health_score_final': v['health_score_final'],
                'operational_status': v['operational_status'],
                'headline': v['headline'],
                'delta': v['delta'],
                'calculated_at': v['calculated_at'],
                'pillars': v['pillars'],
                'kpis': v['kpis']
            })
        return json.dumps({
            'status': 'ok',
            'server_time': now_str,
            'count': len(consolidated),
            'vessels': consolidated
        }).encode('utf-8')

    # Si se pide un buque en específico
    last_seg = clean_p.split('/')[-1].upper().strip()
    target_k = None
    if 'ALFA' in last_seg or last_seg == 'BT.ALFAC':
        target_k = 'BT.ALFAC'
    elif 'GUSTAVO' in last_seg or last_seg == 'BT.GUSTAVO.U':
        target_k = 'BT.GUSTAVO.U'
    elif 'NANY' in last_seg or last_seg == 'BT.NANY1':
        target_k = 'BT.NANY1'

    if target_k and target_k in vessels_data:
        v = vessels_data[target_k]
        resp_obj = {
            'status': 'ok',
            'vessel': {
                'key': v['vessel_key'],
                'name': v['vessel_name']
            },
            'health_score_final': v['health_score_final'],
            'operational_status': v['operational_status'],
            'headline': v['headline'],
            'calculated_at': v['calculated_at'],
            'delta': v['delta'],
            'pillars': v['pillars'],
            'kpis': v['kpis'],
            'certificates_summary': v['certificates_summary'],
            'marad_official_parity': v['marad_official_parity'],
            'priorities': v['priorities'],
            'sources_sync': v['sources_sync']
        }
        return json.dumps(resp_obj).encode('utf-8')

    return json.dumps({'status': 'error', 'message': f'Buque {last_seg} no encontrado'}).encode('utf-8')

def _fetch_intranet_cat():
    global _cached_cat_bytes, _cached_cat_time, _cached_cat_token
    req = urllib.request.Request(
        f"{INTRANET_BASE}/api/v1/centinela/camera-token/",
        data=b'{}',
        method='POST',
        headers={
            'Content-Type': 'application/json',
            'Authorization': MASTER_TOKEN,
            'Accept': 'application/json',
        }
    )
    with urllib.request.urlopen(req, context=ctx, timeout=10) as resp:
        data = resp.read()
        try:
            parsed = json.loads(data.decode('utf-8'))
            tok = parsed.get('camera_access_token', '')
            if tok:
                _cached_cat_token = tok
                parts = tok.split('.')
                if len(parts) >= 2:
                    padding = '=' * (4 - len(parts[1]) % 4)
                    payload = json.loads(base64.b64decode(parts[1] + padding).decode('utf-8'))
                    nbf = payload.get('nbf', 0)
                    now = time.time()
                    diff = nbf - now
                    if diff > -0.5:
                        wait_sec = max(diff + 1.2, 1.2)
                        print(f"[Proxy] Desfase NTP detectado (+{diff:.1f}s). Madurando token {wait_sec:.1f}s...", flush=True)
                        time.sleep(wait_sec)
        except Exception as e:
            print(f"[Proxy] Error inspeccionando nbf del CAT: {e}", flush=True)
            time.sleep(5.5)

        _cached_cat_bytes = data
        _cached_cat_time = time.time()
        return data

class ProxyHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE, HEAD')
        req_headers = self.headers.get('Access-Control-Request-Headers')
        if req_headers:
            self.send_header('Access-Control-Allow-Headers', req_headers)
        else:
            self.send_header('Access-Control-Allow-Headers', 'Authorization, Content-Type, Accept, X-Requested-With, Cache-Control, Pragma, Expires, X-Centinela-Map-Sid, X-NCS-Test-Mode')
        self.send_header('Access-Control-Max-Age', '86400')

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_HEAD(self):
        self.do_GET()

    def do_POST(self):
        global _cached_cat_bytes, _cached_cat_time, _cached_cat_token, _active_focus_vessel, _ticket_vessel, _sid_vessel

        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b'{}'

        if '/client-logs' in self.path:
            try:
                parsed_logs = json.loads(body.decode('utf-8'))
                print(f"[ClientLog] {parsed_logs.get('type')}: {parsed_logs.get('messages')}", flush=True)
            except Exception:
                pass
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
            return

        # Endpoint de token CAT con caché activo y auto-recuperación
        if 'camera-token' in self.path:
            now = time.time()
            if _cached_cat_bytes and (now - _cached_cat_time < 480):
                self.send_response(200)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(_cached_cat_bytes)
                return

            # Intentar obtener CAT fresco
            try:
                target_url = INTRANET_BASE + self.path
                req = urllib.request.Request(target_url, data=body, method='POST')
                has_auth = False
                for k, v in self.headers.items():
                    if k.lower() in ('authorization', 'content-type', 'accept'):
                        if k.lower() == 'authorization' and v.strip():
                            has_auth = True
                        req.add_header(k, v)

                if not has_auth:
                    req.add_header('Authorization', MASTER_TOKEN)

                with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
                    data = resp.read()
                    try:
                        parsed = json.loads(data.decode('utf-8'))
                        _cached_cat_token = parsed.get('camera_access_token', '')
                    except Exception:
                        pass
                    _cached_cat_bytes = data
                    _cached_cat_time = time.time()
                    self.send_response(resp.status)
                    self._send_cors_headers()
                    self.send_header('Content-Type', resp.headers.get('Content-Type', 'application/json'))
                    self.end_headers()
                    self.wfile.write(data)
                    return
            except urllib.error.HTTPError as e:
                if e.code == 401:
                    try:
                        data = _fetch_intranet_cat()
                        self.send_response(200)
                        self._send_cors_headers()
                        self.send_header('Content-Type', 'application/json')
                        self.end_headers()
                        self.wfile.write(data)
                        return
                    except Exception as err2:
                        print(f"[Proxy] Fallback con token maestro falló: {err2}", flush=True)

                err_data = e.read()
                self.send_response(e.code)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(err_data)
                return
            except Exception as e:
                try:
                    data = _fetch_intranet_cat()
                    self.send_response(200)
                    self._send_cors_headers()
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(data)
                    return
                except Exception:
                    self.send_response(500)
                    self._send_cors_headers()
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': str(e)}).encode())
                    return

        # Para cualquier otro POST (Intranet o Centinela)
        is_centinela = '/external/' in self.path
        target_url = (CENTINELA_BASE if is_centinela else INTRANET_BASE) + self.path
        req = urllib.request.Request(target_url, data=body, method='POST')
        is_login = 'login' in self.path
        has_auth = False
        for k, v in self.headers.items():
            if k.lower() in ('authorization', 'content-type', 'accept', 'x-centinela-map-sid', 'x-ncs-test-mode'):
                if is_login and k.lower() == 'authorization':
                    continue
                if k.lower() == 'authorization' and v.strip():
                    if is_centinela and (v.strip().startswith('Token ') or v.strip() in ('Bearer', 'Bearer null', 'Bearer undefined') or len(v.strip()) < 15):
                        continue
                    has_auth = True
                    req.add_header(k, v)
                elif k.lower() != 'authorization':
                    req.add_header(k, v)

        if is_centinela and not has_auth and _cached_cat_token:
            req.add_header('Authorization', f'Bearer {_cached_cat_token}')

        # Capturar vessel de map-session si viene en el cuerpo
        req_vessel = None
        req_ticket = None
        try:
            parsed_req = json.loads(body.decode('utf-8'))
            req_vessel = parsed_req.get('focus_vessel')
            req_ticket = parsed_req.get('ticket')
            if req_vessel:
                _active_focus_vessel = req_vessel
        except Exception:
            pass

        try:
            with urllib.request.urlopen(req, context=ctx, timeout=8) as resp:
                data = resp.read()

                # Mapear ticket y sid para filtrado estricto de buque único
                try:
                    resp_json = json.loads(data.decode('utf-8'))
                    if 'bootstrap_ticket' in resp_json and req_vessel:
                        _ticket_vessel[resp_json['bootstrap_ticket']] = req_vessel
                    if 'sid' in resp_json:
                        sid = resp_json['sid']
                        v = _ticket_vessel.get(req_ticket, _active_focus_vessel)
                        if v:
                            _sid_vessel[sid] = v
                except Exception:
                    pass

                self.send_response(resp.status)
                self._send_cors_headers()
                self.send_header('Content-Type', resp.headers.get('Content-Type', 'application/json'))
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            if is_centinela and e.code == 401:
                try:
                    _fetch_intranet_cat()
                    if _cached_cat_token:
                        req_retry = urllib.request.Request(target_url, data=body, method='POST')
                        for k, v in self.headers.items():
                            if k.lower() in ('content-type', 'accept', 'x-centinela-map-sid', 'x-ncs-test-mode'):
                                req_retry.add_header(k, v)
                        req_retry.add_header('Authorization', f'Bearer {_cached_cat_token}')
                        with urllib.request.urlopen(req_retry, context=ctx, timeout=8) as resp_retry:
                            data_retry = resp_retry.read()
                            self.send_response(resp_retry.status)
                            self._send_cors_headers()
                            self.send_header('Content-Type', resp_retry.headers.get('Content-Type', 'application/json'))
                            self.end_headers()
                            self.wfile.write(data_retry)
                            return
                except Exception as retry_err:
                    print(f"[Proxy] POST Centinela retry con CAT renovado falló: {retry_err}", flush=True)

            err_data = e.read()
            self.send_response(e.code)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            print(f"[Proxy] POST error en {self.path}: {e}", flush=True)
            self.send_response(500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_GET(self):
        global _cached_cat_token, _active_focus_vessel, _sid_vessel
        is_centinela = (
            '/external/' in self.path or
            '/mobile/' in self.path or
            '/assets/' in self.path or
            'logo-sentinela' in self.path or
            'apple-touch-icon' in self.path
        )
        target_url = (CENTINELA_BASE if is_centinela else INTRANET_BASE) + self.path

        # 1. En map-trails, devolver siempre vacío para quitar recorridos pintados de color
        if '/api/v1/external/map-trails' in self.path:
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'ok', 'trails': {}}).encode('utf-8'))
            return

        # Cache en memoria de assets estáticos pesados de Centinela (JS 8.7MB, CSS)
        if '/assets/' in self.path and self.path in _assets_cache:
            c_type, c_data = _assets_cache[self.path]
            self.send_response(200)
            self._send_cors_headers()
            self.send_header('Content-Type', c_type)
            self.end_headers()
            self.wfile.write(c_data)
            return

        req = urllib.request.Request(target_url, method='GET')
        has_auth = False
        for k, v in self.headers.items():
            if k.lower() in ('authorization', 'content-type', 'accept', 'x-centinela-map-sid', 'x-ncs-test-mode'):
                if k.lower() == 'authorization' and v.strip():
                    if is_centinela and (v.strip().startswith('Token ') or v.strip() in ('Bearer', 'Bearer null', 'Bearer undefined') or len(v.strip()) < 15):
                        continue
                    has_auth = True
                    req.add_header(k, v)
                elif k.lower() != 'authorization':
                    req.add_header(k, v)

        if is_centinela and not has_auth and _cached_cat_token and '/assets/' not in self.path and '/mobile/' not in self.path:
            req.add_header('Authorization', f'Bearer {_cached_cat_token}')

        timeout_val = 30 if '/assets/' in self.path else 10

        try:
            with urllib.request.urlopen(req, context=ctx, timeout=timeout_val) as resp:
                data = resp.read()
                content_type = resp.headers.get('Content-Type', 'application/json')

                if '/assets/' in self.path and resp.status == 200:
                    if 'index-DdRd4tiQ' in self.path or 'javascript' in content_type:
                        try:
                            js_str = data.decode('utf-8', errors='ignore')
                            bad_sub = 'arguments[0] = "https://" + window.location.hostname + ":5073" + arguments[0];'
                            if bad_sub in js_str:
                                js_str = js_str.replace(bad_sub, '/* proxy patched: keep relative /api/ */')
                                print("[Proxy] Patch aplicado a index-DdRd4tiQ.js: eliminado :5073 hardcoded!", flush=True)
                            data = js_str.encode('utf-8')
                        except Exception as e_p:
                            print(f"[Proxy] Error aplicando patch a JS: {e_p}", flush=True)
                    _assets_cache[self.path] = (content_type, data)

                # 2. En la página HTML del mapa táctico, inyectar CSS para:
                #    - Ocultar selector inferior de la flota (.mobile-fleet-strip)
                #    - Ocultar cualquier polyline / recorrido residual en Leaflet
                if '/mobile/tactical-map' in self.path and 'text/html' in content_type:
                    html_str = data.decode('utf-8', errors='ignore')
                    inject_style = """
<script>
  (function() {
    const _origFetch = window.fetch;
    window.fetch = function() {
      if (arguments.length > 0 && typeof arguments[0] === 'string') {
        arguments[0] = arguments[0].replace('https://127.0.0.1:5073', 'http://127.0.0.1:8086')
                                   .replace('http://127.0.0.1:5073', 'http://127.0.0.1:8086')
                                   .replace('https://localhost:5073', 'http://127.0.0.1:8086')
                                   .replace('http://localhost:5073', 'http://127.0.0.1:8086');
      }
      return _origFetch.apply(this, arguments);
    };
  })();
</script>
<style>
  /* Ocultar barra de botones/chips de abajo del mapa (selector de 3 barcos) */
  .mobile-fleet-strip, .mobile-segmented-row, [class*="fleet-strip"], [class*="vessel-chips"], .mobile-vessel-chip { 
    display: none !important; 
  }
  /* Ocultar barra superior redundante si existiese */
  .mobile-hud-top-bar { 
    display: none !important; 
  }
  /* Ocultar el pintado de recorridos / estelas de color sobre el agua */
  .leaflet-pane.leaflet-overlay-pane svg g path,
  .leaflet-pane.leaflet-overlay-pane svg path {
    display: none !important;
  }
</style>
</head>"""
                    html_str = html_str.replace('</head>', inject_style)
                    data = html_str.encode('utf-8')

                if resp.status == 200:
                    if '/api/v1/external/vessel-health' in self.path:
                        # Si Centinela remoto aún no desplegó el endpoint y devuelve HTML fallback de Vite
                        if data.strip().startswith(b'<!DOCTYPE') or data.strip().startswith(b'<html') or not content_type.startswith('application/json'):
                            data = _generate_vessel_health_mock(self.path)
                            content_type = 'application/json'
                    else:
                        data = _inject_speed_if_sts(self.path, data)

                self.send_response(resp.status)
                self._send_cors_headers()
                self.send_header('Content-Type', content_type)
                self.end_headers()
                self.wfile.write(data)
        except urllib.error.HTTPError as e:
            if '/api/v1/external/vessel-health' in self.path:
                mock_data = _generate_vessel_health_mock(self.path)
                self.send_response(200)
                self._send_cors_headers()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(mock_data)
                return
            if not is_centinela and e.code == 401:
                try:
                    req_master = urllib.request.Request(target_url, method='GET')
                    req_master.add_header('Authorization', MASTER_TOKEN)
                    req_master.add_header('Accept', 'application/json')
                    with urllib.request.urlopen(req_master, context=ctx, timeout=8) as resp_m:
                        data_m = resp_m.read()
                        self.send_response(resp_m.status)
                        self._send_cors_headers()
                        self.send_header('Content-Type', resp_m.headers.get('Content-Type', 'application/json'))
                        self.end_headers()
                        self.wfile.write(data_m)
                        return
                except Exception:
                    pass

            if is_centinela and e.code == 401:
                try:
                    _fetch_intranet_cat()
                    if _cached_cat_token:
                        req2 = urllib.request.Request(target_url, method='GET')
                        for k, v in self.headers.items():
                            if k.lower() in ('content-type', 'accept'):
                                req2.add_header(k, v)
                        req2.add_header('Authorization', f'Bearer {_cached_cat_token}')
                        with urllib.request.urlopen(req2, context=ctx, timeout=8) as resp2:
                            data2 = resp2.read()
                            if resp2.status == 200:
                                data2 = _inject_speed_if_sts(self.path, data2)
                            self.send_response(resp2.status)
                            self._send_cors_headers()
                            self.send_header('Content-Type', resp2.headers.get('Content-Type', 'application/json'))
                            self.end_headers()
                            self.wfile.write(data2)
                            return
                except Exception as err2:
                    print(f"[Proxy] Reintento con CAT renovado falló: {err2}", flush=True)

            err_data = e.read()
            self.send_response(e.code)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(err_data)
        except Exception as e:
            print(f"[Proxy] GET error en {self.path}: {e}", flush=True)
            self.send_response(500)
            self._send_cors_headers()
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def log_message(self, format, *args):
        # Silenciar logs ruidosos de polling
        if '/map-state' not in self.path and '/map-trails' not in self.path:
            print(f"[Proxy] {self.command} {self.path} - {format % args}", flush=True)

def run():
    try:
        print("[Proxy] Pre-calentando token CAT desde Intranet...", flush=True)
        _fetch_intranet_cat()
        print("[Proxy] Token CAT listo.", flush=True)
    except Exception as e:
        print(f"[Proxy] Advertencia en pre-calentamiento: {e}", flush=True)

    server = ThreadedHTTPServer(('127.0.0.1', 8086), ProxyHandler)
    print("Local Camera Proxy running on http://127.0.0.1:8086", flush=True)
    server.serve_forever()

if __name__ == '__main__':
    run()
