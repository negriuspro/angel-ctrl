@echo off
title Administrador Servidor Ubuntu
color 0A

set SERVER=192.168.100.6
set USER=angel

:menu
cls
echo ============================================
echo      ADMINISTRADOR SERVIDOR UBUNTU
echo ============================================
echo.
echo Servidor: %USER%@%SERVER%
echo.
echo 1. Conectar por SSH
echo 2. Ver IPs del servidor
echo 3. Ver recursos (RAM/CPU/Disco)
echo 4. Ver contenedores Docker
echo 5. Ver estadisticas Docker
echo 6. Ver puertos abiertos
echo 7. Reiniciar Daniel
echo 8. Actualizar todos los proyectos
echo 9. Ver estado completo
echo 0. Salir
echo.
set /p op=Selecciona una opcion:

if "%op%"=="1" goto ssh
if "%op%"=="2" goto ips
if "%op%"=="3" goto recursos
if "%op%"=="4" goto dockerps
if "%op%"=="5" goto stats
if "%op%"=="6" goto puertos
if "%op%"=="7" goto daniel
if "%op%"=="8" goto update
if "%op%"=="9" goto full
if "%op%"=="0" exit

goto menu

:ssh
ssh %USER%@%SERVER%
goto menu

:ips
cls
ssh %USER%@%SERVER% "echo HOSTNAME; hostname; echo; echo IPs; hostname -I; echo; echo TAILSCALE; tailscale ip -4"
pause
goto menu

:recursos
cls
ssh %USER%@%SERVER% "free -h && echo && df -h"
pause
goto menu

:dockerps
cls
ssh %USER%@%SERVER% "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
pause
goto menu

:stats
cls
ssh %USER%@%SERVER% "docker stats --no-stream"
pause
goto menu

:puertos
cls
ssh %USER%@%SERVER% "sudo ss -tulpn | grep LISTEN"
pause
goto menu

:daniel
cls
ssh %USER%@%SERVER% "cd ~/projects/jarvis && docker compose restart"
pause
goto menu

:update
cls
ssh %USER%@%SERVER% "~/projects/update-all.sh"
pause
goto menu

:full
cls
ssh %USER%@%SERVER% "echo ===== HOST ===== && hostname && echo && echo ===== IP ===== && hostname -I && echo && echo ===== TAILSCALE ===== && tailscale ip -4 && echo && echo ===== MEMORIA ===== && free -h && echo && echo ===== DISCO ===== && df -h && echo && echo ===== DOCKER ===== && docker ps --format 'table {{.Names}}\t{{.Status}}'"
pause
goto menu
