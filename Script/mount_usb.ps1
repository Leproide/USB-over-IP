# ───────── PARAMETRI ─────────
$remoteIp     = "192.168.1.100"
$targetVidPid = "0781:5583"
$errorLog     = "C:\usbmount_error.txt"
$mountLog     = "C:\usbmount_mount.txt"

# ───────── FUNZIONI DI LOG ─────────
function Log-Error {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $errorLog -Value "$timestamp - $Message"
}

function Log-Mount {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $mountLog -Value "$timestamp - $Message"
}

# ───────── LISTA REMOTA ─────────
Write-Host "Chiedo la lista dei device esportabili da $remoteIp..."
$rawOutput = & usbip list -r $remoteIp 2>&1
$usbList   = $rawOutput -split "`r?`n"

if ($rawOutput -match "no suitable device found") {
    Log-Error "Impossibile trovare device esportabili su $remoteIp"
    exit 1
}

# ───────── PARSING BUSID ─────────
$line = $usbList | Where-Object { $_ -match "\($targetVidPid\)" }
if (-not $line) {
    Log-Error "Impossibile trovare device $targetVidPid su $remoteIp"
    exit 1
}

$busId = ($line.Trim() -split '\s+')[0]
Write-Host "Trovato remote BUSID: $busId"

# ───────── ATTACH ─────────
Write-Host "Attacco il device remoto..."
$attachOutput = & usbip attach -r $remoteIp -b $busId 2>&1

if ($attachOutput -match "already attached" -or $attachOutput -match "Device busy") {
    Write-Host "Device già montato sul BUSID $busId."
}
elseif ($LASTEXITCODE -ne 0) {
    Log-Error "Attach fallito su $remoteIp bus $busId - $attachOutput"
    exit $LASTEXITCODE
}
else {
    Write-Host "Fatto. Device $targetVidPid montato da $remoteIp sul BUSID $busId."
    Log-Mount "device usb $targetVidPid montato con successo"
}
