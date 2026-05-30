# Compara la IP actual de WSL2 con la guardada y actualiza si ha cambiado.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ipFile = Join-Path $scriptDir "last_wsl_ip.txt"
$fixScript = Join-Path $scriptDir "fix-network.ps1"

# Obtener la IP actual de WSL2
try {
    $wslIpList = wsl -d Ubuntu hostname -I
    if ($null -eq $wslIpList -or $wslIpList.Trim() -eq "") {
        exit 0 # WSL no está encendido, no hacemos nada
    }
    $currentIp = $wslIpList.Split(" ")[0].Trim()
} catch {
    exit 1
}

# Validar si es una IP válida
if ($currentIp -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
    exit 1
}

# Leer la IP anterior si existe
$lastIp = ""
if (Test-Path $ipFile) {
    $lastIp = (Get-Content $ipFile).Trim()
}

# Si la IP ha cambiado o no existía registro, ejecutar fix-network
if ($currentIp -ne $lastIp) {
    Write-Host "La IP de WSL2 cambio de '$lastIp' a '$currentIp'. Ejecutando fix-network..."
    & $fixScript
    
    # Guardar nueva IP en el archivo de registro
    $currentIp | Out-File -FilePath $ipFile -Force -Encoding ascii
} else {
    Write-Host "La IP de WSL2 ($currentIp) no ha cambiado. Todo al dia."
}
