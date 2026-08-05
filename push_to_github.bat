@echo off
echo ==============================================
echo Configurando e iniciando subida a GitHub...
echo ==============================================

:: Inicializar git si no esta inicializado
if not exist .git (
    echo [1/5] Inicializando repositorio Git local...
    git init
) else (
    echo [1/5] Repositorio Git ya inicializado localmente.
)

:: Configurar el repositorio remoto
echo [2/5] Configurando repositorio remoto...
git remote remove origin >nul 2>&1
git remote add origin https://ghp_gMwRfTWDA7V4wKCheHQCzj7WXU6Krg42nS8k@github.com/elevensistemas/naviera_app.git

:: Agregar los archivos
echo [3/5] Agregando archivos al area de preparacion (staging)...
echo (Esto puede tardar unos momentos...)
git add .

:: Confirmar cambios
echo [4/5] Creando el commit inicial...
git config user.name >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] Identidad de Git no detectada. Configurando identidad local para este repositorio...
    git config user.email "contacto@elevensistemas.com"
    git config user.name "Eleven Sistemas"
)
git commit -m "Primer commit: Estructura del proyecto"

:: Renombrar rama a main y empujar
echo [5/5] Subiendo a GitHub en la rama main...
git branch -M main

:: Desactivar helper de credenciales (evita que falle el login visual y usa el token directo)
git config credential.helper ""

:: Intentar empujar
git push -u origin main

if %ERRORLEVEL% equ 0 (
    echo ==============================================
    echo ¡PROYECTO SUBIDO CON EXITO A GITHUB!
    echo ==============================================
) else (
    echo ==============================================
    echo Hubo un error al subir el proyecto.
    echo Asegurate de tener permisos en el repositorio y haber iniciado sesion en Git/GitHub.
    echo ==============================================
)

pause
