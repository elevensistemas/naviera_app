@echo off
title Naviera Cruz del Sur - Launcher
set "SCRIPT_DIR=%~dp0"
set "TARGET_DIR=%SCRIPT_DIR:~0,-1%"

echo ========================================================
echo   NAV I E R A   C R U Z   D E L   S U R   -  LAUNCHER
echo ========================================================
echo.
echo  Ruta de trabajo: "%TARGET_DIR%"
echo.

echo [1/2] Configurando unidad virtual N:...
subst N: /d >nul 2>&1
subst N: "%TARGET_DIR%" >nul 2>&1

if exist "N:\" (
    echo [+] Unidad N: mapeada con exito.
    set "APP_DIR=N:\naviera_cruz_app"
    set "WEBAPP_DIR=N:\ncs-webapp"
    set "FLUTTER_CMD=N:\flutter\bin\flutter.bat"
) else (
    echo [!] No se pudo usar N:, iniciando con la ruta original...
    set "APP_DIR=%TARGET_DIR%\naviera_cruz_app"
    set "WEBAPP_DIR=%TARGET_DIR%\ncs-webapp"
    set "FLUTTER_CMD=%TARGET_DIR%\flutter\bin\flutter.bat"
)

echo.
echo [2/2] Iniciando aplicaciones automaticamente (Opcion 3)...
echo   - Ejecutando React WebApp en ventana independiente (Puerto 2223)...
start "NCS WebApp (React)" cmd /c "cd /d "%WEBAPP_DIR%" && npm run dev"

echo   - Abriendo navegador Chrome sin restricciones CORS en http://localhost:8085 ...
start chrome.exe --disable-web-security --user-data-dir="C:\tmp\chrome_dev_cors" "http://localhost:8085"

echo   - Ejecutando Flutter App en esta ventana (Puerto 8085)...
cd /d "%APP_DIR%"
call "%FLUTTER_CMD%" run -d web-server --web-port=8085 --web-hostname=127.0.0.1

echo.
echo Proceso finalizado.
pause
