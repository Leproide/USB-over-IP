# ─────────── PARAMETRI ───────────
# Metti qui il VID:PID del device che vuoi
$targetVidPid = "0781:5583"
$shareLog     = "C:\usbipd_share.txt"
$errorLog     = "C:\usbipd_error.txt"

# ─────────── FUNZIONI DI LOG ───────────
function Log-Share {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $shareLog -Value "$timestamp - $Message"
}

function Log-Error {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $errorLog -Value "$timestamp - $Message"
}

# ─────────── LISTA DISPOSITIVI ───────────
$usbList = usbipd list

# Cerco la riga col VID:PID
$matchLine = $usbList | Where-Object { $_ -match $targetVidPid }

if (-not $matchLine) {
    Write-Error "Nessun dispositivo con VID:PID $targetVidPid trovato. Controlla e riprova."
    Log-Error "impossibile condividere il dispositivo $targetVidPid"
    exit 1
}

# Estraggo il BUSID (splitto su 2+ spazi)
$fields = $matchLine -split '\s{2,}'
$busId  = $fields[0].Trim()
Write-Host "Trovato dispositivo: BUSID = $busId"

# ─────────── BIND CON GESTIONE ERRORE ───────────
$bindOutput = & usbipd bind -b $busId 2>&1

if ($bindOutput -match "already shared") {
    Write-Host "Il dispositivo $targetVidPid è già condiviso sul bus $busId."
    Log-Error "impossibile condividere il dispositivo $targetVidPid"
    exit 0
}
elseif ($LASTEXITCODE -ne 0) {
    Write-Error "Bind fallito: $bindOutput"
    Log-Error "impossibile condividere il dispositivo $targetVidPid"
    exit $LASTEXITCODE
}
else {
    Write-Host "Fatto. Il dispositivo $targetVidPid è ora shared sul bus $busId."
    Log-Share "dispositivo usb $targetVidPid condiviso su rete"
}
