# Parion - Google Sign-In Debug Helper
# Bu script, cihaz bağlandığında SHA parmak izlerini gösterir ve Google Sign-In
# hata loglarını filtreler.

param(
    [switch]$ShaOnly,    # Sadece SHA'ları göster
    [switch]$WatchLogs   # Sadece logcat izle
)

$ErrorActionPreference = "Continue"
$KEYTOOL = "C:\Users\HUSEYIN\AppData\Local\Programs\Eclipse Adoptium\jdk-25.0.2.10-hotspot\bin\keytool.exe"

# adb yolunu bul
function Find-Adb {
    $candidates = @(
        "C:\Program Files (x86)\Minimal ADB and Fastboot\adb.exe",
        "C:\Program Files\Minimal ADB and Fastboot\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\platform-tools\adb.exe",
        "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    $fromPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
    if ($fromPath) { return $fromPath }
    return $null
}
$ADB = Find-Adb

function Show-Banner {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Parion - Google Sign-In Debug Helper" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-Fingerprints {
    Write-Host "[DEBUG KEystore]  $($env:USERPROFILE)\.android\debug.keystore" -ForegroundColor Yellow
    & $KEYTOOL -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -alias androiddebugkey 2>&1 |
        Select-String -Pattern "SHA1|SHA256" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    Write-Host ""
    Write-Host "[UPLOAD KEYSTORE] E:\KODLAMA\Parion\android\upload-keystore.jks" -ForegroundColor Yellow
    & $KEYTOOL -list -v -keystore "E:\KODLAMA\Parion\android\upload-keystore.jks" -storepass app12345 -alias upload 2>&1 |
        Select-String -Pattern "SHA1|SHA256" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    Write-Host ""
    Write-Host "[PLAY STORE SHA]  Google Play Console > Setup > App signing bolumunden alin" -ForegroundColor Yellow
    Write-Host "  (Bu SHA google-services.json'da YOK; Firebase Console'a manuel eklenmeli)" -ForegroundColor Gray
}

function Watch-SignInLogs {
    Write-Host "[*] Google Sign-In / Firebase Auth loglari izleniyor (Ctrl+C ile dur)" -ForegroundColor Green
    Write-Host "[*] Logcat komutlari: 'adb logcat' veya 'flutter logs'" -ForegroundColor Green
    Write-Host ""
    if (-not $ADB) {
        Write-Host "[!] adb bulunamadi." -ForegroundColor Red
        return
    }
    & $ADB logcat -c
    & $ADB logcat | Select-String "GoogleSignIn|FirebaseAuth|GSIH|GoogleApi|Auth"
}

function Run-App {
    if (-not $ADB) {
        Write-Host "[!] adb bulunamadi." -ForegroundColor Red
        return
    }
    Write-Host "[*] Cihazlar:" -ForegroundColor Green
    $devices = & $ADB devices 2>&1
    Write-Host $devices
    Write-Host ""

    $deviceLines = $devices | Select-String "device$"
    if ($deviceLines.Count -eq 0) {
        Write-Host "[!] Cihaz bulunamadi. USB hata ayiklamayi acin." -ForegroundColor Red
        return
    }

    Write-Host "[*] flutter run --debug baslatiliyor..." -ForegroundColor Green
    Set-Location "E:\KODLAMA\Parion"
    & C:\flutter\bin\flutter.bat run --debug
}

# Main
Show-Banner

if ($ShaOnly) {
    Get-Fingerprints
    return
}

if ($WatchLogs) {
    Watch-SignInLogs
    return
}

# Default: SHA goster + cihaz kontrol + run secenegi
Get-Fingerprints
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "Ne yapmak istiyorsun? [1] Uygulamayi calistir (debug)  [2] Logcat izle  [Q] Cikis"
switch ($choice.ToUpper()) {
    "1" { Run-App }
    "2" { Watch-SignInLogs }
    "Q" { return }
    default { Write-Host "Gecersiz secim" -ForegroundColor Red }
}
