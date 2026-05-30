# Acceso Remoto - Antigravity

Tres servicios corriendo en Docker:
| Servicio | Puerto |
|---|---|
| InterfazDocker (panel principal) | 3000 |
| AntigravityMobile | 3001 |
| Jarvis (asistente IA) | 3002 |

---

## 📍 Misma red (LAN)

Usa la IP local del PC. Abre en el navegador:

```
http://192.168.X.X:3000   → interfazdocker
http://192.168.X.X:3002   → Jarvis
```

Para obtener tu IP: `ipconfig` en cmd, busca "Dirección IPv4".

**Recurso: 0% extra** — ya está funcionando.

---

## 🌐 Red diferente (WAN) — Opciones

### Opción A: Tailscale (RECOMENDADA) — ~50MB RAM

VPN mesh privada. Gratis hasta 100 dispositivos.

**Instalar:**
1. En el PC: https://tailscale.com/download/windows
2. En tu teléfono: Play Store → Tailscale
3. Loguéate con la misma cuenta en ambos
4. El PC aparece con IP `100.x.x.x`

**Acceder desde cualquier red:**
```
http://100.x.x.x:3000   → desde cualquier dispositivo
```

**En la tablet (Android 4.4):** no puede instalar Tailscale. Soluciones:
- Conecta la tablet al hotspot del teléfono (que sí tiene Tailscale)
- O usa la Opción B para la tablet

---

### Opción B: localtunnel (para la tablet) — ~30MB RAM

No necesita instalar nada en la tablet. Las URLs cambian cada vez que reinicias.

**Ejecutar:**
```
.\run-tunnel.ps1
```
Te genera URLs como:
```
https://xxx.loca.lt:3000
https://yyy.loca.lt:3002
```

---

## 🚀 Configuración persistente (auto-inicio)

Para que los servicios arranquen solos al encender el PC:

1. **Docker** ya debe estar configurado para auto-inicio
2. **Tailscale** se instala como servicio Windows (auto-start)
3. **localtunnel** para la tablet → programa `.\run-tunnel.ps1` en el inicio de Windows:

```
Win + R → shell:startup
Crear acceso directo a: powershell.exe -File "C:\Users\je416\Desktop\interfazdocker\run-tunnel.ps1"
```
