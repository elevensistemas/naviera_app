r"""
Suite oficial de pruebas unitarias para Django REST Framework.
Ubicación en el servidor: intranet/api/tests/test_camera_live_views.py (o intranet/tests/test_camera_live_views.py)
Ejecutar con:
venv\Scripts\python.exe manage.py test intranet.api.tests.test_camera_live_views --settings=intranet_django2.settings.naviera

Prueba la vista real CameraLiveStreamView con la base de datos de pruebas de Django,
usuarios con distintos roles/permisos y respuestas simuladas (mock) de EZVIZ.
"""

import json
from unittest.mock import patch, MagicMock
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient

User = get_user_model()

class CameraLiveStreamAPITests(APITestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

        # 1. Crear usuarios de prueba en la base de datos real de Django
        self.admin_user = User.objects.create_superuser(
            username='admin_test',
            email='admin@navieracruzdelsur.com',
            password='TestPassword123!'
        )
        self.authorized_user = User.objects.create_user(
            username='marenco_capitan',
            email='marenco@navieracruzdelsur.com',
            password='TestPassword123!'
        )
        self.unauthorized_user = User.objects.create_user(
            username='marinero_ajeno',
            email='marinero@navieracruzdelsur.com',
            password='TestPassword123!'
        )

        # 2. Cargar modelos reales de intranet (intranet.models.Ship y intranet.models.Camera)
        try:
            from intranet.models import Ship, Camera
        except ImportError:
            from django.apps import apps
            Ship = apps.get_model('intranet', 'Ship')
            Camera = apps.get_model('intranet', 'Camera')

        self.ship_alfa, _ = Ship.objects.get_or_create(code='alfa', defaults={'description': 'ALFA C', 'active': True})
        self.ship_gustavo, _ = Ship.objects.get_or_create(code='gustavo', defaults={'description': 'GUSTAVO U', 'active': True})

        self.cam_alfa, _ = Camera.objects.get_or_create(
            serial_number='BF1765385',
            defaults={
                'name': 'BT.Alfa C',
                'is_active': True,
                'ship': self.ship_alfa
            }
        )
        self.cam_inactiva, _ = Camera.objects.get_or_create(
            serial_number='BF9999999',
            defaults={
                'name': 'Cámara Deshabilitada Test',
                'is_active': False,
                'ship': self.ship_alfa
            }
        )

        # Asociar permiso de buque al usuario autorizado si existen relaciones explícitas
        if hasattr(self.authorized_user, 'assigned_ships'):
            self.authorized_user.assigned_ships.add(self.ship_alfa)
        elif hasattr(self.ship_alfa, 'authorized_users'):
            self.ship_alfa.authorized_users.add(self.authorized_user)

    def tearDown(self):
        cache.clear()

    def test_endpoint_unauthenticated_returns_401(self):
        """Caso 1: Petición sin cabecera de autenticación debe responder 401 Unauthorized."""
        url = f'/api/v1/cameras/{self.cam_alfa.id}/live-url/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_without_ship_permission_returns_403(self):
        """Caso 2: Usuario autenticado pero sin permiso sobre ese buque debe responder 403 Forbidden."""
        self.client.force_authenticate(user=self.unauthorized_user)
        url = f'/api/v1/cameras/{self.cam_alfa.id}/live-url/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('no tiene permisos', response.data.get('detail', ''))

    def test_inactive_camera_returns_400(self):
        """Caso 3: Cámara deshabilitada administrativamente (is_active=False) debe responder 400 Bad Request."""
        self.client.force_authenticate(user=self.admin_user)
        url = f'/api/v1/cameras/{self.cam_inactiva.id}/live-url/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('deshabilitada administrativamente', response.data.get('detail', ''))

    @patch('requests.post')
    def test_authorized_user_receives_hls_stream_and_safe_ttl(self, mock_post):
        """Caso 4: Usuario autorizado recibe enlace HLS con TTL seguro calculado y sin credenciales expuestas."""
        self.client.force_authenticate(user=self.authorized_user)

        # Simular respuestas oficiales de EZVIZ
        token_response = MagicMock()
        token_response.json.return_value = {
            'code': '200',
            'data': {'accessToken': 'at.test_mock_token_123', 'expireTime': 1793794715000}
        }
        live_response = MagicMock()
        live_response.json.return_value = {
            'code': '200',
            'data': {
                'url': 'https://vtmsaopaulo.ezvizlife.com:4443/v3/openlive/BF1765385_1_1.m3u8?expire=1793189895&t=mock',
                'expireTime': 1793189895
            }
        }
        mock_post.side_effect = [token_response, live_response]

        with patch.dict('os.environ', {'EZVIZ_APP_KEY': 'mock_key', 'EZVIZ_APP_SECRET': 'mock_secret'}):
            url = f'/api/v1/cameras/{self.cam_alfa.id}/live-url/'
            response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get('status'), 'online')
        self.assertTrue(response.data.get('url', '').startswith('https://vtmsaopaulo.ezvizlife.com'))
        self.assertIn('expires_at', response.data)
        # Verificar que NO se filtre ninguna credencial en la respuesta
        self.assertNotIn('appKey', json.dumps(response.data))
        self.assertNotIn('appSecret', json.dumps(response.data))

    @patch('requests.post')
    def test_camera_physically_offline_telemetry_20007(self, mock_post):
        """Caso 5: EZVIZ confirma telemetría de desconexión física (20007) -> status='offline'."""
        self.client.force_authenticate(user=self.admin_user)

        token_response = MagicMock()
        token_response.json.return_value = {
            'code': '200',
            'data': {'accessToken': 'at.test_mock_token_123', 'expireTime': 1793794715000}
        }
        offline_response = MagicMock()
        offline_response.json.return_value = {
            'code': '20007',
            'msg': 'The device is offline.'
        }
        mock_post.side_effect = [token_response, offline_response]

        with patch.dict('os.environ', {'EZVIZ_APP_KEY': 'mock_key', 'EZVIZ_APP_SECRET': 'mock_secret'}):
            url = f'/api/v1/cameras/{self.cam_alfa.id}/live-url/'
            response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get('status'), 'offline')
        self.assertEqual(response.data.get('code'), '20007')

    @patch('requests.post')
    def test_invalid_token_auto_recovery_and_retry(self, mock_post):
        """Caso 6: Token expirado/rechazado en EZVIZ (10002) provoca purga y reintento exitoso."""
        self.client.force_authenticate(user=self.admin_user)

        token_res_1 = MagicMock()
        token_res_1.json.return_value = {'code': '200', 'data': {'accessToken': 'stale_token'}}
        live_res_1 = MagicMock()
        live_res_1.json.return_value = {'code': '10002', 'msg': 'AccessToken is expired.'}
        token_res_2 = MagicMock()
        token_res_2.json.return_value = {'code': '200', 'data': {'accessToken': 'fresh_token'}}
        live_res_2 = MagicMock()
        live_res_2.json.return_value = {
            'code': '200',
            'data': {'url': 'https://vtmsaopaulo.ezvizlife.com/live.m3u8?expire=1793189895'}
        }
        mock_post.side_effect = [token_res_1, live_res_1, token_res_2, live_res_2]

        with patch.dict('os.environ', {'EZVIZ_APP_KEY': 'mock_key', 'EZVIZ_APP_SECRET': 'mock_secret'}):
            url = f'/api/v1/cameras/{self.cam_alfa.id}/live-url/'
            response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get('status'), 'online')
