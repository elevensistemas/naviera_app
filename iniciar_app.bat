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

echo [1/3] Verificando y liberando puerto 8085 si esta en uso...
powershell -Command "try { $p = (Get-NetTCPConnection -LocalPort 8085 -State Listen -ErrorAction SilentlyContinue).OwningProcess; if ($p) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1

echo [2/3] Configurando unidad virtual N:...
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
echo [3/3] Iniciando servicios...
echo   - Ejecutando React WebApp en ventana independiente (Puerto 2223)...
start "NCS WebApp (React)" cmd /c "cd /d "%WEBAPP_DIR%" && npm run dev"

echo   - Programando apertura automatica del navegador en cuanto Flutter este listo...
start "NCS - Esperando Servidor" /min cmd /c "for /l %%i in (1,1,60) do ( curl.exe -s http://127.0.0.1:8085/ >nul && ( start chrome.exe --disable-web-security --ignore-certificate-errors --user-data-dir=\"C:\tmp\chrome_dev_cors\" \"http://127.0.0.1:8085\" & exit ) || ( timeout /t 2 /nobreak >nul ) )"

echo.
echo ========================================================
echo   Compilando e iniciando Flutter Web App...
echo   Por favor espere unos 15 a 20 segundos.
echo   El navegador se abrira automaticamente con la App lista.
echo ========================================================
echo.

cd /d "%APP_DIR%"
call "%FLUTTER_CMD%" run -d web-server --web-port=8085 --web-hostname=0.0.0.0

echo.
echo Proceso finalizado.
pause
