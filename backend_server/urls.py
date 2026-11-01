r"""
Configuración de URLs para el endpoint de cámaras en Django REST Framework.
Incorporar estas 2 rutas en el archivo:
C:\Users\ARBUENCS-SRV02\OneDrive - Naviera Cruz del Sur\Escritorio\python\intranet_django3\intranet\api\urls.py
"""

from django.urls import path
from .camera_live_views import CameraLiveStreamView

# Agregar a la lista 'urlpatterns' existente en intranet/api/urls.py:
urlpatterns_cameras = [
    # Endpoint principal por ID de cámara (ej: 10012 para ALFA C)
    path('cameras/<int:camera_id>/live-url/', CameraLiveStreamView.as_view(), name='camera-live-url-by-id'),
    
    # Endpoint alternativo por serial de cámara (ej: BF1765385)
    path('cameras/<str:camera_id>/live-url/', CameraLiveStreamView.as_view(), name='camera-live-url-by-serial'),
]

