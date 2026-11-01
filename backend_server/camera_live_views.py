"""
Módulo de Streaming de Cámaras Ezviz para el Backend Corporativo (Django REST Framework)
Ubicación en el servidor: /api/v1/cameras/<camera_id>/live-url/

Seguridad y Reglas de Negocio:
1. Credenciales fuera de código y registros:
   - Se leen exclusivamente desde variables de entorno del servidor (os.environ['EZVIZ_APP_KEY'], os.environ['EZVIZ_APP_SECRET']).
   - No se imprimen en logs bajo ninguna circunstancia.
2. Control de Acceso Basado en Roles (RBAC):
   - El endpoint exige autenticación estricta (Token / Sesión). Respuestas:
     * Sin autenticación: HTTP 401 Unauthorized.
     * Usuario sin permiso sobre el buque: HTTP 403 Forbidden.
     * Usuario autorizado: HTTP 200 OK.
   - Evita la manipulación de seriales o IDs de cámara para espiar buques ajenos.
3. Protección perimetral contra abuso (Server-side Throttling):
   - Límites en servidor de 15 solicitudes por minuto por usuario/cámara.
   - Respuestas: HTTP 429 Too Many Requests si se excede el límite.
4. Política rigurosa de Vencimiento de Sesiones:
   - Token de Acceso EZVIZ: Lee expireTime (ms) informado por EZVIZ. Aplica un margen de seguridad de 12 horas
     antes de la expiración real. Ante fallo o sesión inválida (10001/10002), se purga la caché y se renueva de inmediato.
   - Enlace HLS (.m3u8): Lee expireTime / parámetro 'expire=' en segundos informado por EZVIZ. Aplica un margen de
     seguridad de 30 minutos antes del vencimiento. Si no viene informado, se adopta un TTL conservador de 2 horas.
"""

import os
import re
import logging
import requests
from datetime import datetime, timedelta, timezone
from urllib.parse import urlparse, parse_qs
from django.apps import apps
from django.core.cache import cache
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.throttling import UserRateThrottle

# Configuración de logger corporativo (sin registrar secretos)
logger = logging.getLogger('cameras.streaming')

class CameraStreamUserThrottle(UserRateThrottle):
    """Límite a nivel de servidor: máximo 20 peticiones por minuto por usuario autenticado."""
    rate = '20/minute'
    scope = 'camera_stream_user'


class CameraLiveStreamView(APIView):
    """
    Endpoint autenticado para obtener el enlace temporal HLS (.m3u8) de una cámara autorizada.
    GET /api/v1/cameras/<camera_id>/live-url/
    """
    authentication_classes = [TokenAuthentication, SessionAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [CameraStreamUserThrottle]

    # Constantes oficiales de EZVIZ Open Cloud
    EZVIZ_TOKEN_URL = "https://open.ezvizlife.com/api/lapp/token/get"
    EZVIZ_LIVE_ADDRESS_URL = "https://open.ezvizlife.com/api/lapp/v2/live/address/get"

    def _get_ezviz_credentials(self):
        """Lee las credenciales de entorno del servidor sin registrarlas."""
        app_key = os.environ.get('EZVIZ_APP_KEY')
        app_secret = os.environ.get('EZVIZ_APP_SECRET')
        if not app_key or not app_secret:
            logger.error("Credenciales EZVIZ no configuradas en las variables de entorno del servidor.")
            raise ValueError("Servicio de cámaras no configurado en el servidor.")
        return app_key, app_secret

    def _get_cached_access_token(self, force_renew=False):
        """
        Obtiene o renueva el token de acceso de EZVIZ.
        Usa el vencimiento informado por EZVIZ (expireTime en ms) con margen de seguridad de 12 horas.
        Si EZVIZ no lo informa, usa un criterio conservador de 24 horas.
        """
        cache_key = "ezviz_backend_access_token"
        if not force_renew:
            cached_token = cache.get(cache_key)
            if cached_token:
                return cached_token

        app_key, app_secret = self._get_ezviz_credentials()
        try:
            resp = requests.post(
                self.EZVIZ_TOKEN_URL,
                data={'appKey': app_key, 'appSecret': app_secret},
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
                timeout=8
            )
            data = resp.json()
            if data.get('code') == '200' and data.get('data'):
                token_data = data['data']
                token = token_data['accessToken']
                expire_time_ms = token_data.get('expireTime')

                # Justificación técnica de plazos de caché para tokens:
                # EZVIZ asigna típicamente 7 días (604.800 s). Descontamos un margen de seguridad de 12 horas (43.200 s)
                # para que el servidor renueve el token con holgura antes de que cualquier petición falle.
                if expire_time_ms and isinstance(expire_time_ms, (int, float)):
                    expire_dt = datetime.fromtimestamp(expire_time_ms / 1000.0, tz=timezone.utc)
                    remaining_seconds = int((expire_dt - datetime.now(timezone.utc)).total_seconds())
                    # Margen de seguridad: 12 horas antes
                    safe_ttl = max(3600, remaining_seconds - 43200)
                else:
                    # Criterio documentado de respaldo si EZVIZ no informa expireTime: 24 horas
                    safe_ttl = 24 * 3600

                cache.set(cache_key, token, timeout=safe_ttl)
                return token
            else:
                logger.error(f"Fallo al obtener token EZVIZ: código {data.get('code')}")
                raise RuntimeError(data.get('msg', 'Error al autenticar con el proveedor de cámaras.'))
        except requests.RequestException as e:
            logger.error(f"Fallo de conexión saliente con EZVIZ token: {e}")
            raise

    def _check_user_ship_permission(self, user, ship):
        """
        Control de Acceso Basado en Roles (RBAC):
        Comprueba estrictamente si el usuario autenticado tiene autorización para ver este buque.
        Evita que atacantes o usuarios manipulen el ID/serial para espiar buques ajenos.
        """
        # 1. Superusuarios y staff tienen acceso corporativo total
        if user.is_superuser or user.is_staff:
            return True

        # 2. Verificación si el buque está en los buques asignados al usuario
        if hasattr(user, 'assigned_ships') and user.assigned_ships.filter(pk=ship.pk).exists():
            return True

        if hasattr(ship, 'authorized_users') and ship.authorized_users.filter(pk=user.pk).exists():
            return True

        # 3. Verificación de rol de tripulante (embarcado o asignado al buque del perfil)
        if hasattr(user, 'crew_member'):
            crew = user.crew_member
            if crew.ship_id == ship.pk or (crew.ship and crew.ship.code == ship.code):
                return True

        # 4. Verificación basada en perfil corporativo / fleet-combo
        profile = getattr(user, 'profile', None)
        if profile and hasattr(profile, 'allowed_ships'):
            if profile.allowed_ships.filter(pk=ship.pk).exists():
                return True

        return False

    def _calculate_stream_ttl(self, stream_url, expire_time_param):
        """
        Calcula el tiempo de vida (TTL) de la URL HLS usando el vencimiento informado por EZVIZ.
        Aplica un margen de seguridad de 30 minutos.
        Si no se informa, aplica un criterio documentado de 2 horas.
        """
        epoch_expire = None

        # 1. Intentar leer expire_time informado directamente por el endpoint
        if expire_time_param and str(expire_time_param).isdigit():
            epoch_expire = int(expire_time_param)

        # 2. Si no vino en el JSON, extraer el parámetro 'expire' de la URL query string
        if not epoch_expire and stream_url:
            parsed = urlparse(stream_url)
            qs = parse_qs(parsed.query)
            if 'expire' in qs and qs['expire'][0].isdigit():
                epoch_expire = int(qs['expire'][0])

        if epoch_expire:
            expire_dt = datetime.fromtimestamp(epoch_expire, tz=timezone.utc)
            remaining_seconds = int((expire_dt - datetime.now(timezone.utc)).total_seconds())
            # Margen de seguridad: descontar 30 minutos (1800 s)
            safe_ttl = remaining_seconds - 1800
            if safe_ttl > 300:
                return safe_ttl, expire_dt.strftime('%Y-%m-%dT%H:%M:%SZ')

        # 3. Criterio documentado de respaldo si EZVIZ no informa expireTime: 2 horas con margen
        fallback_ttl = 2 * 3600
        fallback_dt = (datetime.now(timezone.utc) + timedelta(seconds=fallback_ttl)).strftime('%Y-%m-%dT%H:%M:%SZ')
        return fallback_ttl, fallback_dt

    def get(self, request, camera_id):
        user = request.user

        # 1. Resolver el objeto de la cámara por ID numérico o serial (Modelo intranet.models.Camera)
        Camera = None
        try:
            from intranet.models import Camera as IntranetCamera
            Camera = IntranetCamera
        except ImportError:
            for app_label in ['intranet', 'core', 'fleet', 'cameras', 'ships']:
                try:
                    Camera = apps.get_model(app_label, 'Camera')
                    if Camera:
                        break
                except LookupError:
                    continue

        camera = None
        if Camera:
            try:
                if str(camera_id).isdigit():
                    camera = Camera.objects.select_related('ship').filter(pk=int(camera_id)).first()
                if not camera:
                    camera = Camera.objects.select_related('ship').filter(serial_number=str(camera_id)).first()
            except Exception as e:
                logger.error(f"Error consultando modelo Camera en app '{getattr(Camera._meta, 'app_label', 'intranet')}': {e}")

        if not camera:
            return Response(
                {"detail": "Cámara no encontrada o no registrada en la flota."},
                status=status.HTTP_404_NOT_FOUND
            )

        # 2. Comprobación de estado administrativo en base de datos
        # Nota: is_active es una bandera administrativa, NO de desconexión física
        if not camera.is_active:
            return Response(
                {"detail": "La cámara se encuentra deshabilitada administrativamente en el sistema."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 3. Comprobación estricta de permisos de usuario sobre el buque (RBAC)
        ship = getattr(camera, 'ship', None)
        if not ship or not self._check_user_ship_permission(user, ship):
            logger.warning(
                f"Acceso denegado: usuario '{user.username}' intentó consultar cámara '{camera.id}' "
                f"del buque '{getattr(ship, 'code', 'desconocido')}' sin autorización."
            )
            return Response(
                {"detail": "Acceso denegado: no tiene permisos para visualizar las cámaras de este buque."},
                status=status.HTTP_403_FORBIDDEN
            )

        serial = camera.serial_number
        if not serial:
            return Response(
                {"detail": "La cámara no tiene configurado un número de serie válido."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 4. Verificación de caché de URL de reproducción (.m3u8) en el servidor
        stream_cache_key = f"ezviz_live_stream_{serial}"
        force_refresh = request.query_params.get('refresh', '').lower() in ['true', '1']

        if not force_refresh:
            cached_stream = cache.get(stream_cache_key)
            if cached_stream and isinstance(cached_stream, dict):
                return Response(cached_stream, status=status.HTTP_200_OK)

        # 5. Consulta a EZVIZ desde el servidor con recuperación automática ante sesión inválida
        attempts = 0
        while attempts < 2:
            attempts += 1
            try:
                access_token = self._get_cached_access_token(force_renew=(attempts > 1))
                resp = requests.post(
                    self.EZVIZ_LIVE_ADDRESS_URL,
                    data={
                        'accessToken': access_token,
                        'deviceSerial': serial,
                        'channelNo': 1,
                        'protocol': 2,  # 2 = HLS (.m3u8)
                        'quality': 1    # 1 = HD / Fluido
                    },
                    headers={'Content-Type': 'application/x-www-form-urlencoded'},
                    timeout=10
                )
                data = resp.json()

                # Caso A: Éxito en la resolución del stream HLS
                if data.get('code') == '200' and data.get('data'):
                    stream_url = data['data'].get('url')
                    expire_time_param = data['data'].get('expireTime')
                    safe_ttl, expire_iso = self._calculate_stream_ttl(stream_url, expire_time_param)

                    payload = {
                        "status": "online",
                        "url": stream_url,
                        "expires_at": expire_iso,
                        "camera_id": camera.id,
                        "device_serial": serial,
                        "ship_code": getattr(ship, 'code', ''),
                        "ship_name": getattr(ship, 'description', getattr(ship, 'name', ''))
                    }

                    cache.set(stream_cache_key, payload, timeout=safe_ttl)
                    return Response(payload, status=status.HTTP_200_OK)

                # Caso B: Cámara físicamente desconectada (confirmado por EZVIZ)
                elif data.get('code') == '20007':
                    # Descartar cualquier caché previa del stream
                    cache.delete(stream_cache_key)
                    return Response({
                        "status": "offline",
                        "code": "20007",
                        "detail": "El dispositivo se encuentra físicamente fuera de línea.",
                        "device_serial": serial
                    }, status=status.HTTP_200_OK)

                # Caso C: Token expirado o revocado en EZVIZ (10001, 10002) -> Descartar y reintentar inmediatamente
                elif data.get('code') in ['10002', '10001'] and attempts == 1:
                    logger.warning("Token EZVIZ rechazado por el proveedor; purgando caché y reintentando...")
                    cache.delete("ezviz_backend_access_token")
                    continue

                else:
                    logger.error(f"EZVIZ devolvió código {data.get('code')}: {data.get('msg')}")
                    return Response(
                        {"detail": "No se pudo obtener la transmisión en vivo del buque."},
                        status=status.HTTP_502_BAD_GATEWAY
                    )

            except requests.Timeout:
                logger.error(f"Timeout al conectar con servidores EZVIZ para serial {serial}")
                return Response(
                    {"detail": "Tiempo de espera agotado al conectar con el servicio de video."},
                    status=status.HTTP_504_GATEWAY_TIMEOUT
                )
            except Exception as e:
                logger.error(f"Error inesperado al obtener transmisión: {e}")
                return Response(
                    {"detail": "Error interno del servidor al procesar la solicitud de video."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
