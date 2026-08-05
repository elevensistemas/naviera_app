@echo off
echo ==============================================
echo Probando el token contra la API de GitHub...
echo ==============================================

:: Ejecutar curl para probar el token
curl -i -H "Authorization: token ghp_gMwRfTWDA7V4wKCheHQCzj7WXU6Krg42nS8k" https://api.github.com/user

echo.
echo ==============================================
echo Fin de la prueba.
echo ==============================================
pause
