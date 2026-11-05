# Parion - Play Store SHA Bulma
# Uygulamayi Google Play Store'dan indirip yuklediyseniz, imzalama SHA'sini
# dogrudan cihazdan okuyabiliriz.

param(
    [string]$PackageName = "com.bulut.wallet"
)

$ErrorActionPreference = "Continue"

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
    # PATH'te ara
    $fromPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
    if ($fromPath) { return $fromPath }
    return $null
}
$ADB = Find-Adb
if (-not $ADB) {
    Write-Host "[!] adb bulunamadi. PATH'e ekleyin veya tam yol verin:" -ForegroundColor Red
    Write-Host "    Ornek: \$env:Path += ';C:\Program Files (x86)\Minimal ADB and Fastboot'" -ForegroundColor Gray
    exit 1
}
Write-Host "[*] adb: $ADB" -ForegroundColor DarkGray
Write-Host ""

function Show-Banner {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Play Store SHA-1 / SHA-256 Bulma" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SHAFromDevice {
    Write-Host "[*] Cihazdaki uygulama imzasi okunuyor (paket: $PackageName)..." -ForegroundColor Green
    Write-Host ""

    $deviceCount = (& $ADB devices | Select-String "device$" | Measure-Object).Count
    if ($deviceCount -eq 0) {
        Write-Host "[!] Cihaz bagli degil. USB Debug AÇIK olmali." -ForegroundColor Red
        return $null
    }

    # APK path'ini al (dumpsys yerine daha güvenilir)
    $pmOutput = & $ADB shell "pm path $PackageName" 2>&1
    $apkPath = $pmOutput | Select-String "package:" | ForEach-Object {
        $_.Line -replace "package:", "" -replace "`r", ""
    } | Select-Object -First 1

    if (-not $apkPath) {
        Write-Host "[!] Uygulama cihazda bulunamadi." -ForegroundColor Red
        Write-Host "    pm path ciktisi: $pmOutput" -ForegroundColor Gray
        Write-Host "    Kontrol edin:" -ForegroundColor Yellow
        Write-Host "      - Uygulama yuklu mu? (Play Store veya debug)" -ForegroundColor Gray
        Write-Host "      - Paket adi dogru mu? (su an: $PackageName)" -ForegroundColor Gray
        Write-Host "      - Cihaz USB Debug modunda mi?" -ForegroundColor Gray
        return $null
    }

    Write-Host "[*] APK cihazda bulundu: $apkPath" -ForegroundColor Green

    # APK'yı dışarı çek
    $localApk = "$env:TEMP\parion_$(Get-Date -Format 'yyyyMMdd_HHmmss').apk"
    Write-Host "[*] APK disari cekiliyor: $localApk" -ForegroundColor Green
    & $ADB pull $apkPath $localApk 2>&1 | Out-Null

    if (-not (Test-Path $localApk) -or (Get-Item $localApk).Length -eq 0) {
        Write-Host "[!] APK cekilemedi." -ForegroundColor Red
        Write-Host "    APK yolu: $apkPath" -ForegroundColor Gray
        Write-Host "    Hedef:    $localApk" -ForegroundColor Gray
        return $null
    }

    $apkSize = "{0:N2} MB" -f ((Get-Item $localApk).Length / 1MB)
    Write-Host "[*] APK boyutu: $apkSize" -ForegroundColor Green
    Write-Host ""

    # apksigner yolunu bul
    $apksigner = Get-ChildItem -Path "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($apksigner) {
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  APK IMZA BILGILERI" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        & $apksigner.FullName verify --print-certs $localApk 2>&1 | ForEach-Object {
            $line = $_.ToString().Trim()
            if ($line -match "SHA-256 digest|SHA-1 digest|Subject DN|Issuer DN|Verified") {
                Write-Host "  $line" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "[*] apksigner bulunamadi, keytool + APK unzip deneniyor..." -ForegroundColor Yellow
        $KEYTOOL = "C:\Users\HUSEYIN\AppData\Local\Programs\Eclipse Adoptium\jdk-25.0.2.10-hotspot\bin\keytool.exe"

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($localApk)
        $cert = $zip.Entries | Where-Object { $_.FullName -match "META-INF/.*\.(RSA|DSA|EC)$" } | Select-Object -First 1
        if ($cert) {
            $certPath = "$env:TEMP\cert_$(Get-Date -Format 'HHmmss').rsa"
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($cert, $certPath, $true)
            $zip.Dispose()
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host "  APK IMZA BILGILERI" -ForegroundColor Cyan
            Write-Host "============================================================" -ForegroundColor Cyan
            & $KEYTOOL -printcert -file $certPath 2>&1 | Select-String -Pattern "SHA1|SHA256|Owner|Issuer" | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Yellow
            }
            Remove-Item $certPath -Force
        } else {
            $zip.Dispose()
            Write-Host "[!] APK icinde sertifika bulunamadi (v2/v3 imza olabilir)" -ForegroundColor Red
            Write-Host "    Bu durumda Yontem 2 (Play Console) veya Yontem 3 kullanin" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "[*] APK: $localApk" -ForegroundColor Green

    # Kullanıcının yüklediği vs Play Store uyarısı
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "  ONEMLI: Bu SHA hangisinin?" -ForegroundColor Magenta
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "  Cihazdaki uygulama su kaynaklardan biriyle yuklenmis olabilir:" -ForegroundColor White
    Write-Host "    - Play Store (SHA = Google'in ozel anahtari)" -ForegroundColor Gray
    Write-Host "    - Kendi gelistirme build'iniz (SHA = upload veya debug)" -ForegroundColor Gray
    Write-Host "  Google Sign-In icin Play Store SHA gerekli." -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Magenta

    return $localApk
}

    # PackageInfo'dan signatures al
    $rawDump = & $ADB shell "dumpsys package $PackageName" 2>&1
    $signatures = $rawDump | Select-String -Pattern "Signers?\[|signatures\["

    if (-not $signatures) {
        Write-Host "[!] Uygulama cihazda bulunamadi veya imza okunamadi." -ForegroundColor Red
        Write-Host "    Kontrol edin:" -ForegroundColor Yellow
        Write-Host "      - Uygulama Play Store'dan indirilip yuklendi mi?" -ForegroundColor Gray
        Write-Host "      - Paket adi dogru mu? (su an: $PackageName)" -ForegroundColor Gray
        Write-Host "      - Cihaz USB Debug modunda mi?" -ForegroundColor Gray
        return $null
    }

    Write-Host "[*] Cihaz uzerindeki imzalar (ilk 5 satır):" -ForegroundColor Yellow
    $signatures | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host ""

    # APK'yı dışarı çek (Play Store imzalı)
    $apkPath = & $ADB shell "pm path $PackageName" 2>&1 | Select-String "package:" | ForEach-Object {
        $_ -replace "package:", ""
    } | Select-Object -First 1

    if ($apkPath) {
        Write-Host "[*] APK cihazda bulundu: $apkPath" -ForegroundColor Green
        $localApk = "$env:TEMP\playstore_signed.apk"
        Write-Host "[*] APK disari cekiliyor..." -ForegroundColor Green
        & $ADB pull $apkPath $localApk 2>&1 | Out-Null

        if (Test-Path $localApk) {
            Write-Host "[*] APK SHA'ları hesaplaniyor..." -ForegroundColor Green
            $KEYTOOL = "C:\Users\HUSEYIN\AppData\Local\Programs\Eclipse Adoptium\jdk-25.0.2.10-hotspot\bin\keytool.exe"

            # apksigner yolunu bul
            $apksigner = Get-ChildItem -Path "$env:LOCALAPPDATA\Android\Sdk\build-tools" -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($apksigner) {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Cyan
                Write-Host "  PLAY STORE APK IMZA BILGILERI" -ForegroundColor Cyan
                Write-Host "============================================================" -ForegroundColor Cyan
                & $apksigner.FullName verify --print-certs $localApk 2>&1 | ForEach-Object {
                    if ($_ -match "SHA-256 digest|SHA-1 digest|Subject|Issuer") {
                        Write-Host "  $_" -ForegroundColor Yellow
                    } else {
                        Write-Host "  $_" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "[!] apksigner bulunamadi, keytool deneniyor..." -ForegroundColor Yellow
                # zip align ile META-INF/CERT.RSA çıkar, keytool ile oku
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::OpenRead($localApk)
                $cert = $zip.Entries | Where-Object { $_.FullName -match "META-INF/.*\.(RSA|DSA|EC)" } | Select-Object -First 1
                if ($cert) {
                    $certPath = "$env:TEMP\cert.rsa"
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($cert, $certPath, $true)
                    $zip.Dispose()
                    & $KEYTOOL -printcert -file $certPath 2>&1 | Select-String -Pattern "SHA1|SHA256|Owner|Issuer" | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor Yellow
                    }
                    Remove-Item $certPath -Force
                } else {
                    $zip.Dispose()
                    Write-Host "[!] Sertifika cikarilamadi" -ForegroundColor Red
                }
            }

            Write-Host ""
            Write-Host "[*] APK: $localApk (sha icin kullanabilirsiniz)" -ForegroundColor Green
        }
    }
    return $localApk
}

function Get-SHAFromPlayConsoleGuide {
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  PLAY CONSOLE'DA SHA BULMA (yeni arayuz)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. https://play.google.com/console adresine gidin" -ForegroundColor White
    Write-Host "2. Parion uygulamasini secin" -ForegroundColor White
    Write-Host ""
    Write-Host "   Sol menude sirasiyla deneyin:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   OPSIYON A:  Test and release  >  App integrity" -ForegroundColor Green
    Write-Host "   OPSIYON B:  Release          >  Setup  >  App integrity" -ForegroundColor Green
    Write-Host "   OPSIYON C:  Grow             >  App integrity" -ForegroundColor Green
    Write-Host ""
    Write-Host "   (Eski adi: 'App signing' / 'Uygulama imzalama')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 'App signing key certificate' bolumunu acin" -ForegroundColor White
    Write-Host "4. 'SHA-1 certificate fingerprint' ve 'SHA-256 certificate fingerprint'" -ForegroundColor White
    Write-Host "   degerlerini kopyalayip bana gonderin." -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
}

# Main
Show-Banner

Write-Host "Hangi yolu denemek istersiniz?" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] Cihazdaki Play Store uygulamasindan SHA oku (otomatik)" -ForegroundColor Green
Write-Host "  [2] Play Console adim adim rehber" -ForegroundColor Green
Write-Host "  [Q] Cikis" -ForegroundColor Gray
Write-Host ""
$choice = Read-Host "Seciminiz"

switch ($choice.ToUpper()) {
    "1" {
        Get-SHAFromDevice
    }
    "2" {
        Get-SHAFromPlayConsoleGuide
    }
    "Q" { return }
    default { Write-Host "Gecersiz secim" -ForegroundColor Red }
}
