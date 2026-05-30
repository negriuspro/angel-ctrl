@echo off
:: Comprobar privilegios de Administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run
) else (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:run
cd /d "%~dp0"
echo Ejecutando fix-network.ps1...
powershell -ExecutionPolicy Bypass -File "scripts\fix-network.ps1"
pause
