@echo off
set "SCRIPT_DIR=%~dp0"
set "TARGET_DIR=%SCRIPT_DIR:~0,-1%"

echo ========================================================
echo   Iniciando Naviera Cruz del Sur - App Flutter Web
echo ========================================================

echo.
echo [1/3] Limpiando mapeos anteriores en la unidad N:...
subst N: /d >nul 2>&1

echo.
echo [2/3] Creando unidad virtual N: para evitar espacios en la ruta...
subst N: "%TARGET_DIR%"

if %errorlevel% neq 0 (
    echo [!] Error al mapear la unidad N:.
    echo     Se intentara iniciar directamente con la ruta de origen...
    echo.
    cd /d "%TARGET_DIR%\naviera_cruz_app"
    call ..\flutter\bin\flutter.bat run -d chrome --web-browser-flag="--disable-web-security"
) else (
    echo [+] Unidad N: mapeada con exito.
    echo.
    echo [3/3] Iniciando Flutter en Chrome con CORS desactivado...
    cd /d N:\naviera_cruz_app
    call N:\flutter\bin\flutter.bat run -d chrome --web-browser-flag="--disable-web-security"
)

echo.
echo Proceso finalizado. Cerrando...
pause
