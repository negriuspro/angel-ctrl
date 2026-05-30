# Configura portproxy y firewall en Windows para redirigir tráfico a WSL2
$ports = @(3000, 3001, 3002)

# Obtener la IP de WSL2 (distribución Ubuntu)
try {
    $wslIpList = wsl -d Ubuntu hostname -I
    if ($null -eq $wslIpList -or $wslIpList.Trim() -eq "") {
        Write-Error "No se pudo obtener la IP de WSL2. Asegúrate de que la distro Ubuntu está corriendo."
        exit 1
    }
    $wslIp = $wslIpList.Split(" ")[0].Trim()
} catch {
    Write-Error "Error al ejecutar comando wsl: $_"
    exit 1
}

Write-Host "IP de WSL2 detectada: $wslIp"

# Limpiar reglas antiguas de portproxy para estos puertos
foreach ($port in $ports) {
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 | Out-Null
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=127.0.0.1 | Out-Null
}

# Configurar nuevas reglas de portproxy redirigiendo a la IP de WSL2
foreach ($port in $ports) {
    Write-Host "Configurando portproxy para puerto $port -> $wslIp`:$port"
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp | Out-Null
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=127.0.0.1 connectport=$port connectaddress=$wslIp | Out-Null
}

# Configurar Reglas de Firewall
$firewallRuleName = "Antigravity Control Center Ports"
# Borrar regla antigua si existe
Remove-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue

# Agregar nueva regla para permitir puertos de entrada
New-NetFirewallRule -DisplayName $firewallRuleName `
                    -Direction Inbound `
                    -Action Allow `
                    -Protocol TCP `
                    -LocalPort $ports `
                    -Program System `
                    -Enabled True `
                    -Description "Permitir acceso a los puertos de Antigravity desde la LAN y Tailscale" | Out-Null

Write-Host "¡Configuración de red completada con éxito!"
