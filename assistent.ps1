#========================================================================
# Assistente do PC - Standalone Terminal Edition
# Version: 2.0 (Pure PowerShell CLI)
#========================================================================
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# 1. ELEVAÇÃO DE ADMIN
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Requires Administrator Privileges. Elevating..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Enable ExecutionPolicy Unrestricted for all scopes
Set-ExecutionPolicy Unrestricted -Scope Process -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction SilentlyContinue

# Disable UAC temporarily for silent installations
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Force -EA SilentlyContinue


# 2. LOGGING AND INTERFACE
function Write-Log { param([string]$m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Suc { param([string]$m) Write-Host " [+] $m" -ForegroundColor Green }
function Write-Err { param([string]$m) Write-Host " [x] $m" -ForegroundColor Red }
function Write-Warn { param([string]$m) Write-Host " [!] $m" -ForegroundColor Yellow }

function Pause-Output {
    Write-Host ""
    Read-Host "Press ENTER to continue..."
}

# 3. CHECK INSTALLED SOFTWARE (ROBUST VERSION)
$script:InstalledCache = $null
$script:CacheTime = $null

function Get-InstalledSoftware {
    $now = Get-Date
    if ($script:InstalledCache -and $script:CacheTime -and (($now - $script:CacheTime).TotalSeconds -lt 300)) {
        return $script:InstalledCache
    }
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $script:InstalledCache = @()
    foreach($p in $paths) {
        $script:InstalledCache += Get-ItemProperty -Path $p -EA SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName, InstallLocation, Publisher
    }
    $script:CacheTime = Get-Date
    return $script:InstalledCache
}

function Test-Installed {
    param($prog)
    $script:InstalledCache = $null
    $installed = Get-InstalledSoftware
    foreach($m in $prog.Match) {
        $matches = $installed | Where-Object { $_.DisplayName -like "*$m*" }
        if ($matches) { return $true }
    }
    $programName = $prog.DisplayName.ToLower()
    $commonPaths = @(
        "C:\Program Files\$($prog.DisplayName)",
        "C:\Program Files (x86)\$($prog.DisplayName)",
        "$env:LOCALAPPDATA\Programs\$($prog.DisplayName)",
        "$env:APPDATA\$($prog.DisplayName)"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) { return $true }
    }
    return $false
}

function Confirm-Installation {
    param($prog)
    Start-Sleep -Seconds 2
    $script:InstalledCache = $null
    return Test-Installed -prog $prog
}

# 4. BASE INSTALLER (ROBUST VERSION)
function Install-Target {
    param($prog)
    if (Test-Installed -prog $prog) {
        Write-Suc "$($prog.DisplayName) is already installed!"
        return
    }

    $success = $false
    $progName = $prog.DisplayName -replace '[^\w]', '_'
    $tempInstaller = "$env:TEMP\${progName}_setup.exe"
    $installMethod = ""
    
    # Try Chocolatey first (most reliable)
    if ($prog.ChocoId -and (Get-Command choco -EA SilentlyContinue)) {
        Write-Log "Trying Chocolatey: $($prog.DisplayName)"
        $chocoResult = & choco install $prog.ChocoId -y --force --ignore-checksums 2>&1
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010 -or $chocoResult -match "installed|success") { 
            if (Confirm-Installation -prog $prog) {
                $success = $true
                $installMethod = "Chocolatey"
                Write-Suc "Installed via Chocolatey!"
                return
            }
        }
    }
    
    # Try Winget with silent install
    if (-not $success -and $prog.WingetId -and (Get-Command winget -EA SilentlyContinue)) {
        Write-Log "Trying Winget: $($prog.DisplayName)"
        $wingetArgs = "--id $($prog.WingetId) -e --accept-source-agreements --accept-package-agreements --silent --accept-source-manifests"
        $wingetResult = & winget install $wingetArgs 2>&1
        if ($LASTEXITCODE -eq 0 -or $wingetResult -match "Successfully installed|installed") {
            if (Confirm-Installation -prog $prog) {
                $success = $true
                $installMethod = "Winget"
                Write-Suc "Installed via Winget!"
                return
            }
        }
    }

    # Direct download as last resort
    if (-not $success -and $prog.DirectUrl) {
        Write-Log "Trying direct download: $($prog.DisplayName)"
        $downloadSuccess = $false
        
        # Try BitsTransfer first
        try {
            Start-BitsTransfer -Source $prog.DirectUrl -Destination $tempInstaller -Priority High -TransferType Download -ErrorAction Stop
            if ((Test-Path $tempInstaller) -and (Get-Item $tempInstaller).Length -gt 0) {
                $downloadSuccess = $true
            }
        } catch {
            Write-Log "BitsTransfer failed, trying alternative..."
        }
        
        # Fallback to Invoke-WebRequest
        if (-not $downloadSuccess) {
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($prog.DirectUrl, $tempInstaller)
                if ((Test-Path $tempInstaller) -and (Get-Item $tempInstaller).Length -gt 0) {
                    $downloadSuccess = $true
                }
            } catch {
                Write-Log "WebClient failed"
            }
        }
        
        # Fallback to Invoke-WebRequest with headers
        if (-not $downloadSuccess) {
            try {
                $headers = @{
                    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                Invoke-WebRequest -Uri $prog.DirectUrl -OutFile $tempInstaller -Headers $headers -UseBasicParsing -TimeoutSec 60 -EA SilentlyContinue
                if ((Test-Path $tempInstaller) -and (Get-Item $tempInstaller).Length -gt 0) {
                    $downloadSuccess = $true
                }
            } catch {
                Write-Log "Invoke-WebRequest failed"
            }
        }
        
        if ($downloadSuccess) {
            $fileExt = [System.IO.Path]::GetExtension($prog.DirectUrl).ToLower()
            Write-Log "Installing from $fileExt file..."
            
            try {
                if ($fileExt -eq '.msi') {
                    Start-Process msiexec.exe -ArgumentList "/i `"$tempInstaller`" /qn /norestart" -Wait -NoNewWindow
                } elseif ($fileExt -eq '.zip') {
                    $extractPath = "$env:TEMP\${progName}_unzip"
                    Expand-Archive -Path $tempInstaller -DestinationPath $extractPath -Force
                    $exeFiles = Get-ChildItem $extractPath -Filter "*.exe" -Recurse -EA SilentlyContinue | Select-Object -First 1
                    if ($exeFiles) {
                        Start-Process $exeFiles.FullName -ArgumentList "/S" -Wait -NoNewWindow
                    }
                } else {
                    $argList = @("/S", "/NCRC", "/silent", "/norestart", "/quiet", "/Q")
                    $proc = Start-Process -FilePath $tempInstaller -ArgumentList $argList -Wait -PassThru -NoNewWindow
                }
                
                # Wait for installation to complete
                Start-Sleep -Seconds 5
                
                if (Confirm-Installation -prog $prog) {
                    $success = $true
                    Write-Suc "Installed via Direct Download!"
                }
            } catch {
                Write-Err "Installation process failed: $_"
            }
            
            # Cleanup
            Remove-Item $tempInstaller -Force -EA SilentlyContinue
            return
        }
    }

    # Final verification
    if (Test-Installed -prog $prog) {
        $success = $true
        Write-Suc "Installed successfully (verified)!"
        return
    }

    if (-not $success) {
        Write-Err "Failed to install $($prog.DisplayName) after all methods"
            }
        }
    }

    if (-not $success) {
        Write-Err "Failed to install $($prog.DisplayName)"
    }
}

# 5. CATÁLOGO DE APLICATIVOS (OS 28 PROGRAMAS)
$ProgramCatalog = @(
    [pscustomobject]@{ DisplayName='7-Zip'; WingetId='7zip.7zip'; ChocoId='7zip'; Match=@('7-Zip') }
    [pscustomobject]@{ DisplayName='Audacity'; WingetId='Audacity.Audacity'; ChocoId='audacity'; Match=@('Audacity') }
    [pscustomobject]@{ DisplayName='BCUninstaller'; WingetId='Klocman.BulkCrapUninstaller'; ChocoId='bulk-crap-uninstaller'; DirectUrl='https://github.com/Klocman/Bulk-Crap-Uninstaller/releases/download/v5.8/BulkCSSetup.exe'; Match=@('Bulk Crap Uninstaller') }
    [pscustomobject]@{ DisplayName='CPU-Z'; WingetId='CPUID.CPU-Z'; ChocoId='cpu-z'; Match=@('CPU-Z') }
    [pscustomobject]@{ DisplayName='CrystalDiskInfo'; WingetId='CrystalDewWorld.CrystalDiskInfo'; ChocoId='crystaldiskinfo'; Match=@('CrystalDiskInfo') }
    [pscustomobject]@{ DisplayName='CrystalDiskMark'; WingetId='CrystalDewWorld.CrystalDiskMark'; ChocoId='crystaldiskmark'; Match=@('CrystalDiskMark') }
    [pscustomobject]@{ DisplayName='Discord'; WingetId='Discord.Discord'; ChocoId='discord'; Match=@('Discord') }
    [pscustomobject]@{ DisplayName='Eclipse Temurin JDK17'; WingetId='EclipseFoundation.Temurin.17.JDK'; ChocoId='temurin17jre'; Match=@('Eclipse Temurin') }
    [pscustomobject]@{ DisplayName='Epic Games'; WingetId='EpicGames.EpicGamesLauncher'; ChocoId='epicgameslauncher'; DirectUrl='https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/Installers.win32.epicgames-launcher-installer.exe'; Match=@('Epic Games') }
    [pscustomobject]@{ DisplayName='GameSave Manager'; WingetId='InsaneMatters.GameSaveManager'; ChocoId='gamesavemanager'; DirectUrl='https://www.gamesavemanager.com/Download'; Match=@('GameSave Manager') }
    [pscustomobject]@{ DisplayName='Git'; WingetId='Git.Git'; ChocoId='git'; Match=@('Git') }
    [pscustomobject]@{ DisplayName='Hydra Launcher'; WingetId='Polaar.Hydra'; ChocoId=''; DirectUrl='https://github.com/HydraLauncher/Hydra/releases/download/2.0.6/Hydra-Setup.exe'; Match=@('Hydra') }
    [pscustomobject]@{ DisplayName='ImageGlass'; WingetId='ImageGlass.ImageGlass'; ChocoId='imageglass'; Match=@('ImageGlass') }
    [pscustomobject]@{ DisplayName='League of Legends'; WingetId='RiotGames.LeagueOfLegends'; ChocoId='leagueoflegends'; DirectUrl='https://signup.leagueoflegends.com/platform-shared/v1/install/na/prod/InstallLeague.exe'; Match=@('League of Legends') }
    [pscustomobject]@{ DisplayName='Firefox'; WingetId='Mozilla.Firefox'; ChocoId='firefox'; Match=@('Firefox') }
    [pscustomobject]@{ DisplayName='MPV Player'; WingetId='mpv.mpv'; ChocoId='mpv'; Match=@('mpv') }
    [pscustomobject]@{ DisplayName='Notepad++'; WingetId='Notepad++.Notepad++'; ChocoId='notepadplusplus'; Match=@('Notepad++') }
    [pscustomobject]@{ DisplayName='OBS Studio'; WingetId='OBSProject.OBSStudio'; ChocoId='obs-studio'; Match=@('OBS Studio') }
    [pscustomobject]@{ DisplayName='Obsidian'; WingetId='Obsidian.Obsidian'; ChocoId='obsidian'; Match=@('Obsidian') }
    [pscustomobject]@{ DisplayName='OP.GG'; WingetId='OPGG.OPGG'; ChocoId=''; DirectUrl='https://op.gg-desktop.gg/tests/OP.GG-Setup.exe'; Match=@('OP.GG') }
    [pscustomobject]@{ DisplayName='Prism Launcher'; WingetId='PrismLauncher.PrismLauncher'; ChocoId='prismlauncher'; Match=@('Prism') }
    [pscustomobject]@{ DisplayName='qBittorrent'; WingetId='qBittorrent.qBittorrent'; ChocoId='qbittorrent'; Match=@('qBittorrent') }
    [pscustomobject]@{ DisplayName='Roblox'; WingetId='Roblox.Roblox'; ChocoId='roblox'; Match=@('Roblox') }
    [pscustomobject]@{ DisplayName='RustDesk'; WingetId='RustDesk.RustDesk'; ChocoId='rustdesk'; Match=@('RustDesk') }
    [pscustomobject]@{ DisplayName='ShareX'; WingetId='ShareX.ShareX'; ChocoId='sharex'; Match=@('ShareX') }
    [pscustomobject]@{ DisplayName='Spotify'; WingetId='Spotify.Spotify'; ChocoId='spotify'; Match=@('Spotify') }
    [pscustomobject]@{ DisplayName='Steam'; WingetId='Valve.Steam'; ChocoId='steam'; Match=@('Steam') }
    [pscustomobject]@{ DisplayName='Telegram'; WingetId='Telegram.TelegramDesktop'; ChocoId='telegram'; Match=@('Telegram') }
)

# 6. GAME DEPENDENCIES
$DepsCatalog = @(
    [pscustomobject]@{ DisplayName='VCRedist AIO'; WingetId=''; ChocoId='vcredist-all'; DirectUrl='https://github.com/abbodi1406/vcredist/raw/master/VisualCppRedist_AIO_x86_x64_71.exe'; Match=@('Visual C++','vcredist') }
    [pscustomobject]@{ DisplayName='DirectX End-User'; WingetId='Microsoft.DirectX'; ChocoId='directx'; DirectUrl='https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe'; Match=@('DirectX') }
    [pscustomobject]@{ DisplayName='.NET Desktop Runtime 8'; WingetId='Microsoft.DotNet.DesktopRuntime.8'; ChocoId='dotnet-desktopruntime'; DirectUrl='https://download.visualstudio.microsoft.com/download/pr/70e302c8-3019-40b0-8b16-7d4e5c3b0c6c/e4c12f84e68b4c4a9f5c8e0c5e7b8c3/dotnet-desktop-runtime-8.0.11-win-x64.exe'; Match=@('.NET') }
    [pscustomobject]@{ DisplayName='XNA Framework 4.0'; WingetId='Microsoft.XNARedist'; ChocoId='xna4'; DirectUrl='https://download.microsoft.com/download/5/6/3/5638ba26-1741-491b-8c6e-2fd5c0e2251a/xnafx40_redist.msi'; Match=@('XNA') }
    [pscustomobject]@{ DisplayName='OpenAL'; WingetId=''; ChocoId='openal'; DirectUrl='https://www.openal.org/downloads/oalinst.zip'; Match=@('OpenAL') }
    [pscustomobject]@{ DisplayName='PhysX'; WingetId='NVIDIA.NVIDIAPhysX'; ChocoId='nvidia-physx'; DirectUrl='https://us.download.nvidia.com/GFE/GFEClient/3D/PhysX-9.21.0718-Std-Setup.exe'; Match=@('PhysX') }
)

# 7. PARSER MULTI-SELEÇÃO
function Parse-Selection {
    param([string]$inStr, [int]$max)
    $res = @()
    if ([string]::IsNullOrWhiteSpace($inStr)) { return $res }
    $parts = $inStr -split ','
    foreach ($p in $parts) {
        $p = $p.Trim()
        if ($p -match '^(\d+)-(\d+)$') {
            $s = [int]$matches[1]; $e = [int]$matches[2]
            if ($s -le $e) { for($i=$s; $i -le $e; $i++){ if($i -ge 1 -and $i -le $max){ $res+=$i } } }
            else { for($i=$s; $i -ge $e; $i--){ if($i -ge 1 -and $i -le $max){ $res+=$i } } }
        } elseif ($p -match '^\d+$') {
            $n = [int]$p
            if ($n -ge 1 -and $n -le $max) { $res+=$n }
        }
    }
    return $res | Select-Object -Unique | Sort-Object
}

# 8. MENUS COMANDOS

function Menu-Installs {
    Clear-Host
    Write-Host "=== SOFTWARE INSTALLER ===" -ForegroundColor Cyan
    Write-Host "Based on WinUtil / Winget / Choco`n"
    
    $i = 1
    foreach ($p in $ProgramCatalog) {
        $st = if (Test-Installed -prog $p) { "[OK]" } else { "    " }
        $color = if ($st -eq "[OK]") { "DarkGray" } else { "White" }
        Write-Host (" [{0:d2}] {1}  {2}" -f $i, $st, $p.DisplayName) -ForegroundColor $color
        $i++
    }
    
    Write-Host "`n [A] Install ALL" -ForegroundColor Green
    Write-Host "Enter numbers (ex: 1,4,15-20) or ENTER to go back:" -ForegroundColor Yellow
    $inp = Read-Host ">"
    
    if ($inp -eq "A" -or $inp -eq "a") {
        Write-Host "`nInstalling ALL software..." -ForegroundColor Cyan
        foreach ($p in $ProgramCatalog) { Install-Target -prog $p }
        Pause-Output
        return
    }
    
    $sel = Parse-Selection -inStr $inp -max $ProgramCatalog.Count
    
    if ($sel.Count -gt 0) {
        Write-Host "`nStarting installation of $($sel.Count) items..." -ForegroundColor Cyan
        foreach ($s in $sel) { Install-Target -prog $ProgramCatalog[$s-1] }
        Pause-Output
    }
}

function Menu-Deps {
    Clear-Host
    Write-Host "=== GAME DEPENDENCIES ===" -ForegroundColor Cyan
    $i = 1
    foreach ($d in $DepsCatalog) {
        $st = if (Test-Installed -prog $d) { "[OK]" } else { "    " }
        $color = if ($st -eq "[OK]") { "DarkGray" } else { "White" }
        Write-Host (" [{0}] {1}  {2}" -f $i, $st, $d.DisplayName) -ForegroundColor $color
        $i++
    }
    Write-Host "`n [A] Install ALL Dependencies" -ForegroundColor Green
    Write-Host "Enter numbers (ex: 1,2,4-6) or ENTER to go back:" -ForegroundColor Yellow
    $inp = Read-Host ">"
    
    if ($inp -eq "A" -or $inp -eq "a") {
        Write-Host "`nInstalling ALL dependencies..." -ForegroundColor Cyan
        foreach ($d in $DepsCatalog) { Install-Target -prog $d }
        Pause-Output
        return
    }
    
    $sel = Parse-Selection -inStr $inp -max $DepsCatalog.Count
    
    if ($sel.Count -gt 0) {
        Write-Host "`nStarting installation..." -ForegroundColor Cyan
        foreach ($s in $sel) { Install-Target -prog $DepsCatalog[$s-1] }
        Pause-Output
    }
}

function Menu-Tweaks {
    Clear-Host
    Write-Host "=== CLEANUP & SYSTEM ===" -ForegroundColor Cyan
    Write-Host " [1] Clean Temp Files (%TEMP% and C:\Windows\Temp)"
    Write-Host " [2] Empty Recycle Bin"
    Write-Host " [3] Run Disk Cleanup (cleanmgr)"
    Write-Host "`n [4] Flush DNS Cache"
    Write-Host " [5] Reset Winsock and IP (Requires Restart)"
    Write-Host "`n [6] Back"
    
    $ch = Read-Host "`nSelect"
    switch($ch){
        '1' { 
            Write-Log "Cleaning user temp..."
            Get-ChildItem $env:TEMP -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
            Write-Log "Cleaning windows temp..."
            Get-ChildItem "C:\Windows\Temp" -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
            Write-Suc "Temp folders cleaned."
            Pause-Output
        }
        '2' {
            Clear-RecycleBin -Force -EA SilentlyContinue
            Write-Suc "Recycle Bin emptied."
            Pause-Output
        }
        '3' {
            Start-Process cleanmgr
        }
        '4' {
            ipconfig /flushdns | Out-Null
            Write-Suc "DNS Flushed."
            Pause-Output
        }
        '5' {
            netsh winsock reset | Out-Null
            netsh int ip reset | Out-Null
            netsh winhttp reset proxy | Out-Null
            Write-Suc "IP/Winsock reset. Restart your computer."
            Pause-Output
        }
    }
}

function Menu-Packs {
    Clear-Host
    Write-Host "=== PREMIUM TOOLS & SCRIPTS ===" -ForegroundColor Magenta
    Write-Host " [1] Install Spicetify (Spotify Ad-free Mod)"
    Write-Host " [2] Install AME Wizard (ReviOS)"
    Write-Host " [3] WinAct Activator"
    Write-Host " [4] Install Spotify (Official Installer)"
    Write-Host " [5] Back"
    $ch = Read-Host "`nSelect"
    switch($ch) {
        '1' {
            Write-Log "Installing Spicetify..."
            $tempScript = "$env:TEMP\spicetify_install.ps1"
            Start-BitsTransfer -Source "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" -Destination $tempScript
            Invoke-Expression $tempScript
            Remove-Item $tempScript -Force -EA SilentlyContinue
            Pause-Output
        }
        '2' {
            Write-Log "Downloading AME Wizard..."
            $ameUrl = "https://github.com/adrifcastr/AME-Wizard/releases/latest/download/AME.exe"
            $amePath = "$env:TEMP\AME.exe"
            try {
                Start-BitsTransfer -Source $ameUrl -Destination $amePath
                Start-Process -FilePath $amePath
            } catch {
                Write-Err "Failed to download AME Wizard"
            }
            Pause-Output
        }
        '3' {
            Write-Log "Downloading and running WinAct..."
            $tempScript = "$env:TEMP\winact.ps1"
            try {
                Start-BitsTransfer -Source "https://massgrave.dev/get" -Destination $tempScript
                Invoke-Expression (Get-Content $tempScript -Raw)
                Remove-Item $tempScript -Force -EA SilentlyContinue
            } catch {
                Write-Err "Failed to run WinAct"
            }
            Pause-Output
        }
        '4' {
            Write-Log "Downloading official Spotify installer..."
            $spotifyExe = "$env:TEMP\SpotifySetup.exe"
            Start-BitsTransfer -Source "https://download.scdn.co/SpotifySetup.exe" -Destination $spotifyExe
            Write-Log "Running installer..."
            Start-Process -FilePath $spotifyExe -Wait
            Write-Suc "Spotify installation completed."
            Pause-Output
        }
    }
}

function Menu-Tools {
    Clear-Host
    Write-Host "=== QUICK SHORTCUTS ===" -ForegroundColor Cyan
    Write-Host " [1] Device Manager (devmgmt)"
    Write-Host " [2] Services (services.msc)"
    Write-Host " [3] Task Manager"
    Write-Host " [4] Registry Editor (regedit)"
    Write-Host " [5] Control Panel"
    Write-Host " [6] Restart Windows Explorer"
    Write-Host " [7] System Information"
    Write-Host " [8] Back"
    
    $ch = Read-Host "`nSelect"
    switch($ch) {
        '1' { Start-Process devmgmt.msc }
        '2' { Start-Process services.msc }
        '3' { Start-Process taskmgr }
        '4' { Start-Process regedit }
        '5' { Start-Process control }
        '6' { Stop-Process -Name explorer -Force; Write-Suc "Explorer Restarted." ; Pause-Output }
        '7' {
            Clear-Host
            $sys = Get-CimInstance Win32_ComputerSystem
            $cpu = Get-CimInstance Win32_Processor | Select -First 1
            $gpu = Get-CimInstance Win32_VideoController | Select -First 1
            $os = Get-CimInstance Win32_OperatingSystem
            Write-Host "--- SYSTEM INFO ---" -ForegroundColor Cyan
            Write-Host "PC Name: $($sys.Name)"
            Write-Host "CPU: $($cpu.Name)"
            Write-Host "GPU: $($gpu.Name)"
            Write-Host "RAM: $([math]::Round($os.TotalVisibleMemorySize/1GB, 1)) GB"
            Write-Host "OS: $($os.Caption) ($($os.OSArchitecture))"
            Pause-Output
        }
    }
}

# 9. MAIN LOOP
while ($true) {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "      DEVIL9 - PC ASSISTANT CLI          " -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Software (28 Apps)" -ForegroundColor White
    Write-Host " [2] Dependencies (Games/Dev)" -ForegroundColor White
    Write-Host " [3] Cleanup & Network" -ForegroundColor White
    Write-Host " [4] Premium Modules / ReviOS" -ForegroundColor White
    Write-Host " [5] Windows Utilities" -ForegroundColor White
    Write-Host " [6] Exit" -ForegroundColor Red
    Write-Host ""
    
    $ch = Read-Host "Select an option"
    
    switch($ch) {
        '1' { Menu-Installs }
        '2' { Menu-Deps }
        '3' { Menu-Tweaks }
        '4' { Menu-Packs }
        '5' { Menu-Tools }
        '6' { Write-Host "Exiting..."; exit }
    }
}
