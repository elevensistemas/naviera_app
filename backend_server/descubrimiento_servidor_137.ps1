# ==============================================================================
# AUDITORÍA Y DESCUBRIMIENTO DE SOLO LECTURA EN SERVIDOR 192.168.2.137
# Objetivo: Identificar la instalación real de Django/Daphne en el puerto 6570
#           sin inventar rutas, modelos ni nombres de servicios.
# Ejecutar en PowerShell (como Administrador si es posible) dentro de la .137
# ==============================================================================

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "DESCUBRIMIENTO DEL ENTORNO DJANGO / DAPHNE EN 192.168.2.137:6570" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Identificar el proceso activo escuchando en el puerto 6570 (Daphne HTTPS)
# ------------------------------------------------------------------------------
Write-Host "`n[1] INSPECCIONANDO PUERTO 6570..." -ForegroundColor Yellow
$conn = Get-NetTCPConnection -LocalPort 6570 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $conn) {
    Write-Host "ALERTA: No se detectó ninguna conexión en estado Listen en el puerto 6570." -ForegroundColor Red
    Write-Host "Verifique si el servicio Daphne está temporalmente detenido o en otro puerto." -ForegroundColor Red
} else {
    $pidNum = $conn.OwningProcess
    Write-Host "Puerto 6570 activo. PID de proceso: $pidNum" -ForegroundColor Green
    
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pidNum" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "  Nombre de proceso: $($proc.Name)" -ForegroundColor White
        Write-Host "  Ejecutable:        $($proc.ExecutablePath)" -ForegroundColor White
        Write-Host "  Línea de comando:  $($proc.CommandLine)" -ForegroundColor White
    }
}

# ------------------------------------------------------------------------------
# 2. Localizar la carpeta raíz del proyecto Django
# ------------------------------------------------------------------------------
Write-Host "`n[2] BUSCANDO CARPETA RAÍZ DEL PROYECTO DJANGO..." -ForegroundColor Yellow

$projectDir = $null

# Intentar extraer ruta desde la línea de comando del proceso
if ($proc -and $proc.CommandLine) {
    $tokens = $proc.CommandLine -split '\s+'
    foreach ($token in $tokens) {
        $clean = $token.Trim('"', "'")
        if ($clean -match '^[a-zA-Z]:\\.*' -and (Test-Path $clean)) {
            if (Test-Path (Join-Path $clean "manage.py")) {
                $projectDir = $clean
                break
            } elseif (Test-Path (Join-Path (Split-Path $clean -Parent) "manage.py")) {
                $projectDir = Split-Path $clean -Parent
                break
            }
        }
    }
}

# Si no se dedujo de la línea de comando, buscar manage.py en C:\ y D:\
if (-not $projectDir) {
    Write-Host "Buscando manage.py en unidades de disco locales (C:, D:)..." -ForegroundColor Gray
    $candidates = @("C:\inetpub", "C:\xampp", "C:\apps", "C:\backend", "C:\django", "C:\srv", "D:\apps", "D:\backend", "C:\")
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $found = Get-ChildItem -Path $c -Filter "manage.py" -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $projectDir = $found.DirectoryName
                break
            }
        }
    }
}

if ($projectDir) {
    Write-Host "Carpeta del proyecto Django identificada: $projectDir" -ForegroundColor Green
} else {
    Write-Host "No se pudo determinar automáticamente la carpeta del proyecto. Localice manualmente la carpeta donde reside 'manage.py'." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 3. Identificar el método de supervisión / reinicio de Daphne
# ------------------------------------------------------------------------------
Write-Host "`n[3] IDENTIFICANDO MÉTODO DE SUPERVISIÓN DE DAPHNE..." -ForegroundColor Yellow

# A) ¿Servicio de Windows oficial?
$winServices = Get-Service -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -match "daphne|django|asgi|ncs|backend" -or $_.DisplayName -match "daphne|django|asgi|ncs|backend"
}
if ($winServices) {
    Write-Host "Servicios de Windows coincidentes detectados:" -ForegroundColor Green
    foreach ($s in $winServices) {
        Write-Host "  - Servicio: $($s.Name) | Nombre para mostrar: '$($s.DisplayName)' | Estado: $($s.Status)" -ForegroundColor White
    }
} else {
    Write-Host "No se encontraron servicios de Windows estándar con 'daphne/django/ncs'." -ForegroundColor Gray
}

# B) ¿Proceso NSSM (Non-Sucking Service Manager)?
$nssmProcs = Get-CimInstance Win32_Process -Filter "Name LIKE '%nssm%'" -ErrorAction SilentlyContinue
if ($nssmProcs) {
    Write-Host "Supervisión por NSSM detectada:" -ForegroundColor Green
    foreach ($n in $nssmProcs) {
        Write-Host "  - NSSM PID: $($n.ProcessId) | Comando: $($n.CommandLine)" -ForegroundColor White
    }
}

# C) ¿Tarea programada de Windows?
$schedTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { 
    $_.TaskName -match "daphne|django|asgi|ncs|backend" 
}
if ($schedTasks) {
    Write-Host "Tareas programadas coincidentes detectadas:" -ForegroundColor Green
    foreach ($t in $schedTasks) {
        Write-Host "  - Tarea: $($t.TaskName) | Estado: $($t.State)" -ForegroundColor White
    }
}

# ------------------------------------------------------------------------------
# 4. Identificar modelos de buques y cámaras existentes
# ------------------------------------------------------------------------------
Write-Host "`n[4] LOCALIZANDO DEFINICIÓN DE MODELOS (Camera, Ship)..." -ForegroundColor Yellow
if ($projectDir -and (Test-Path $projectDir)) {
    $modelMatches = Select-String -Path "$projectDir\*\models.py", "$projectDir\*\models\*.py" -Pattern "class\s+(Camera|Ship|Buque|Barco)" -ErrorAction SilentlyContinue
    if ($modelMatches) {
        foreach ($m in $modelMatches) {
            Write-Host "  Coincidencia en: $($m.Path): Línea $($m.LineNumber): $($m.Line.Trim())" -ForegroundColor White
        }
    } else {
        Write-Host "No se encontraron clases 'Camera' o 'Ship' directas con glob simple. Buscar en aplicaciones registradas en settings.py." -ForegroundColor Gray
    }
} else {
    Write-Host "Paso omitido por no disponer de la ruta de proyecto confirmada." -ForegroundColor Gray
}

# ------------------------------------------------------------------------------
# 5. Identificar archivo de rutas de la API (urls.py)
# ------------------------------------------------------------------------------
Write-Host "`n[5] LOCALIZANDO REGISTRO DE RUTAS /api/v1/..." -ForegroundColor Yellow
if ($projectDir -and (Test-Path $projectDir)) {
    $urlMatches = Select-String -Path "$projectDir\*\urls.py" -Pattern "cameras|api/v1" -ErrorAction SilentlyContinue
    if ($urlMatches) {
        foreach ($u in $urlMatches) {
            Write-Host "  Coincidencia en: $($u.Path): Línea $($u.LineNumber): $($u.Line.Trim())" -ForegroundColor White
        }
    } else {
        Write-Host "No se encontraron rutas con 'cameras' o 'api/v1'. Inspeccionar el urls.py principal del proyecto." -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# 6. Identificar mecanismo de configuración (.env o variables de entorno)
# ------------------------------------------------------------------------------
Write-Host "`n[6] INSPECCIONANDO CONFIGURACIÓN DE ENTORNO (.env)..." -ForegroundColor Yellow
if ($projectDir -and (Test-Path $projectDir)) {
    $envFiles = Get-ChildItem -Path $projectDir -Filter ".env*" -File -ErrorAction SilentlyContinue
    if ($envFiles) {
        Write-Host "Archivos .env detectados en la raíz del proyecto:" -ForegroundColor Green
        foreach ($ef in $envFiles) {
            Write-Host "  - $($ef.FullName)" -ForegroundColor White
        }
    } else {
        Write-Host "No se encontraron archivos .env en la raíz del proyecto. Verificar si las credenciales se definen como variables del sistema Windows." -ForegroundColor Gray
    }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "FIN DEL DESCUBRIMIENTO. Utilice esta información para adaptar los pasos." -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
