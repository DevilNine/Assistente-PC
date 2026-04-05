<#
.SYNOPSIS
    DEVIL9 PC ASSISTANT - Post-Format Automation Tool v4
.DESCRIPTION
    Complete post-format assistant for Windows 10/11.
.VERSION
    4.0.0
.AUTHOR
    Devil9
#>
[CmdletBinding()]
param(
    [switch]$InstallDefaults,
    [switch]$InstallDeps,
    [switch]$InstallFonts,
    [switch]$Tweaks,
    [switch]$Interactive,
    [switch]$NoLogo,
    [switch]$Benchmark,
    [string]$ConfigPath,
    [string]$LogOverride,
    [string]$OnlyInstall
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$script:VERSION    = "4.0.0"
$script:ConfigFile = "$env:APPDATA\Devil9Assistant\config.json"
$script:LogFile    = "$env:APPDATA\Devil9Assistant\devil9_$(Get-Date -Format 'yyyyMMdd').log"

if ($ConfigPath) { $script:ConfigFile = $ConfigPath }
if ($LogOverride) { $script:LogFile = $LogOverride }

# ============================================================
# 1. LOGGING & UTILS
# ============================================================
function Log {
    param([string]$Msg, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts [$Level] $Msg"
    try {
        $logDir = Split-Path $script:LogFile
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        $entry | Add-Content -Path $script:LogFile -ErrorAction SilentlyContinue
    } catch {}
}

function Write-OK   { param([string]$m); Write-Host " [+] $m" -ForegroundColor Green;  Log $m "OK" }
function Write-Info { param([string]$m); Write-Host " [i] $m" -ForegroundColor Cyan;   Log $m "INFO" }
function Write-Err  { param([string]$m); Write-Host " [x] $m" -ForegroundColor Red;    Log $m "ERROR" }
function Write-Warn { param([string]$m); Write-Host " [!] $m" -ForegroundColor Yellow; Log $m "WARN" }

function Write-Step {
    param([string]$m)
    Write-Host ""
    $pad = [Math]::Max(1, 60 - $m.Length)
    Write-Host (" === " + $m + " " + ("=" * $pad)) -ForegroundColor Magenta
    Log "STEP: $m" "STEP"
}

function Wait-Enter {
    Write-Host ""
    Write-Host " Press ENTER to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Draw-Box {
    param([string]$Title)
    $w = 56
    Write-Host ("-" * $w) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host ("-" * $w) -ForegroundColor Cyan
}

# ============================================================
# 2. CONFIG SYSTEM
# ============================================================
$script:Config = @{}

function New-DefaultConfig {
    @{
        version                 = $script:VERSION
        use_winget              = $true
        use_choco               = $true
        use_scoop               = $false
        silent_mode             = $true
        install_timeout_seconds = 300
        max_retries             = 3
        retry_delay_seconds     = 5
        verify_after_install    = $true
        install_parallel        = $true
        create_restore_point    = $true
        proxy_url               = ""
        dns_override            = ""
        skipped_programs        = @()
    }
}

function Load-Config {
    try {
        if (Test-Path $script:ConfigFile) {
            $raw = Get-Content $script:ConfigFile -Raw -ErrorAction Stop
            $loaded = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            $def = New-DefaultConfig
            foreach ($key in $def.Keys) {
                if (-not $loaded.ContainsKey($key)) { $loaded[$key] = $def[$key] }
            }
            if (-not $loaded.ContainsKey("skipped_programs")) { $loaded["skipped_programs"] = @() }
            $script:Config = $loaded
            Write-Info "Config loaded"
            Log "Config loaded" "CONFIG"
            return
        }
    } catch {
        Write-Warn "Config load failed, using defaults"
        Log "Config load failed: $_" "WARN"
    }
    $script:Config = New-DefaultConfig
    Save-Config
}

function Save-Config {
    try {
        $cfgDir = Split-Path $script:ConfigFile
        if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null }
        $script:Config | ConvertTo-Json -Depth 10 | Set-Content $script:ConfigFile -Force -ErrorAction Stop
    } catch { Log "Config save failed: $_" "ERROR" }
}

function Get-Cfg {
    param([string]$Key, $Default = $null)
    $keys = $Key -split '\.'
    $v = $script:Config
    foreach ($k in $keys) {
        if ($v -is [hashtable] -and $v.ContainsKey($k)) { $v = $v[$k] }
        else { return $Default }
    }
    if ($null -ne $v) { return $v }
    return $Default
}

function Set-Cfg {
    param([string]$Key, $Value)
    $keys = $Key -split '\.'
    $t = $script:Config
    $i = 0
    while ($i -lt ($keys.Count - 1)) {
        if (-not $t.ContainsKey($keys[$i])) { $t[$keys[$i]] = @{} }
        $t = $t[$keys[$i]]
        $i++
    }
    $t[$keys[-1]] = $Value
    Save-Config
}

# ============================================================
# 3. ADMIN CHECK
# ============================================================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warn "Elevating to Administrator..."
    $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -ArgumentList $a -Verb RunAs -Wait
    exit
}

# ============================================================
# 4. PRE-FLIGHT
# ============================================================
function Test-Internet {
    foreach ($h in @("8.8.8.8", "1.1.1.1")) {
        try { if (Test-Connection -ComputerName $h -Count 2 -Quiet -EA SilentlyContinue) { return $true } } catch {}
    }
    try {
        $web = [System.Net.WebRequest]::Create("https://www.google.com")
        $web.Timeout = 5000
        $resp = $web.GetResponse()
        $resp.Close()
        return $true
    } catch {}
    return $false
}

function Test-Winget { try { $null = Get-Command winget -EA Stop; return $true } catch { return $false } }
function Test-Choco  { try { $null = Get-Command choco  -EA Stop; return $true } catch { return $false } }
function Test-Scoop  { try { $null = Get-Command scoop  -EA Stop; return $true } catch { return $false } }

function Bootstrap-Winget {
    if (Test-Winget) { Write-OK "WinGet available"; return $true }

    Write-Warn "Bootstrapping WinGet..."

    # Method 1: MS Store via winget (works if winget already exists from a previous run)
    try {
        winget install --id Microsoft.DesktopAppInstaller -e --source msstore --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
        # Refresh PATH for current session
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        # Also reload from registry directly
        $regPath = [Environment]::GetEnvironmentVariable("Path","Machine")
        if ($regPath) { $env:Path = $regPath + ";" + $env:Path }
        if (Test-Winget) { Write-OK "WinGet installed"; return $true }
    } catch {}

    # Method 2: Direct .msixbundle download
    try {
        $msixFile = "$env:TEMP\WinGet.msixbundle"
        Invoke-Download "https://aka.ms/getwinget" $msixFile 2 | Out-Null
        Add-AppxPackage -Path $msixFile -EA SilentlyContinue
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        $regPath = [Environment]::GetEnvironmentVariable("Path","Machine")
        if ($regPath) { $env:Path = $regPath + ";" + $env:Path }
        if (Test-Winget) { Write-OK "WinGet installed via direct download"; return $true }
    } catch {}

    # Method 3: Install App Installer from the Microsoft Store XML catalog
    try {
        $msixFile2 = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        Invoke-Download "https://cdn.winget.microsoft.com/cache/main.msix" $msixFile2 2 | Out-Null
        if (Test-Path $msixFile2 -and (Get-Item $msixFile2).Length -gt 10240) {
            Add-AppxPackage -Path $msixFile2 -EA SilentlyContinue
        }
    } catch {}

    # Method 4: Install via Chocolatey as last resort
    if (Test-Choco) {
        try {
            choco install winget-cli-universal -y --force --ignore-checksums 2>&1 | Out-Null
            $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
            if (Test-Winget) { Write-OK "WinGet installed via Chocolatey"; return $true }
        } catch {}
    }

    Write-Err "WinGet bootstrap failed - will use Chocolatey as fallback"
    return $false
}

function Bootstrap-Choco {
    if (Test-Choco) { Write-OK "Chocolatey available"; return $true }
    if (-not (Get-Cfg "use_choco")) { return $false }
    Write-Warn "Bootstrapping Chocolatey..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-Expression (Invoke-WebRequest "https://community.chocolatey.org/install.ps1" -UseBasicParsing -TimeoutSec 30).Content | Out-Null
        $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
        if (Test-Choco) { Write-OK "Chocolatey installed"; return $true }
    } catch { Write-Warn "Choco bootstrap failed" }
    return $false
}

function Bootstrap-Scoop {
    if (Test-Scoop) { return $true }
    if (-not (Get-Cfg "use_scoop")) { return $false }
    try {
        Invoke-Expression "& { $(Invoke-RestMethod https://get.scoop.sh -TimeoutSec 30) } -RunAsAdmin" | Out-Null
        if (Test-Scoop) { Write-OK "Scoop installed"; return $true }
    } catch {}
    return $false
}

function PreFlight {
    Write-Step "PRE-FLIGHT CHECKS"
    if (Test-Internet) { Write-OK "Internet OK" }
    else { Write-Err "NO internet detected" }

    $dns = Get-Cfg "dns_override"
    if ($dns -and $dns -ne "") {
        try {
            Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Set-DnsClientServerAddress -ServerAddresses $dns -EA SilentlyContinue
            Write-OK "DNS set to $dns"
        } catch {}
    }

    Bootstrap-Winget | Out-Null
    Bootstrap-Choco | Out-Null
    Bootstrap-Scoop | Out-Null

    $os = Get-CimInstance Win32_OperatingSystem
    Write-Info "OS: $($os.Caption) (Build $($os.BuildNumber))"

    if (Get-Cfg "create_restore_point") {
        Write-Info "Creating System Restore Point..."
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive" -EA SilentlyContinue
            Checkpoint-Computer -Description "Devil9Assistant $(Get-Date -Format yyyyMMdd)" -RestorePointType MODIFY_SETTINGS -EA Stop
            Write-OK "Restore point created"
        } catch { Write-Warn "Restore point failed (non-critical)" }
    }
}

# ============================================================
# 5. DOWNLOAD ENGINE
# ============================================================
function Invoke-Download {
    param([string]$Url, [string]$OutFile, [int]$MaxRetries = 3)
    $retries = [Math]::Max(1, $MaxRetries)
    $baseDelay = [int](Get-Cfg "retry_delay_seconds" 3)

    $attempt = 1
    while ($attempt -le $retries) {
        if ($attempt -gt 1) {
            $delay = [Math]::Pow(2, $attempt - 1) * $baseDelay
            Write-Warn "  Retry $attempt/$retries (waiting ${delay}s)..."
            Start-Sleep -Seconds ([int]$delay)
        }

        # Method 1: .NET WebClient (fastest, no BITS overhead)
        try {
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Devil9Assistant/$script:VERSION")
            $wc.DownloadFile($Url, $OutFile)
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 10240) {
                $wc.Dispose()
                Log "Download OK WebClient attempt $attempt" "DL"
                return $true
            }
            $wc.Dispose()
        } catch {
            Log "WebClient attempt $attempt failed: $_" "DL-RETRY"
        }

        # Method 2: IWR as fallback
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } -UseBasicParsing -TimeoutSec 120 -EA Stop
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 10240) {
                Log "Download OK IWR attempt $attempt" "DL"
                return $true
            }
        } catch {
            Log "IWR attempt $attempt failed: $_" "DL-RETRY"
        }

        # Method 3: BITS as last resort (slow but reliable for large files)
        try {
            Start-BitsTransfer -Source $Url -Destination $OutFile -Priority High -TransferType Download -EA Stop
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 10240) {
                Log "Download OK BITS attempt $attempt" "DL"
                return $true
            }
        } catch {
            Log "BITS attempt $attempt failed: $_" "DL-RETRY"
        }

        $attempt++
    }
    Write-Err "  Download FAILED after $retries attempts"
    Log "Download FAILED: $Url" "DL-FAIL"
    return $false
}

# ============================================================
# 6. GITHUB RESOLVER
# ============================================================
function Resolve-GithubLatest {
    param([string]$Repo, [string]$Pattern = "\.exe$|\.msi$")
    try {
        $resp = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 10 -EA Stop
        if ($resp.assets) {
            $asset = $resp.assets | Where-Object { $_.name -match $Pattern -and $_.name -notmatch "arm|arm64|^src" } | Select-Object -First 1
            if ($asset) { return $asset.browser_download_url }
        }
    } catch {}
    try {
        $rels = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases" -TimeoutSec 10 -EA Stop
        foreach ($rel in $rels) {
            if ($rel.assets) {
                $asset = $rel.assets | Where-Object { $_.name -match $Pattern -and $_.name -notmatch "arm|arm64|^src" } | Select-Object -First 1
                if ($asset) { return $asset.browser_download_url }
            }
        }
    } catch {}
    return $null
}

# ============================================================
# 7. CATALOGS
# ============================================================
function Get-SoftwareCatalog {
    return @(
        @{ name='Firefox';          winget='Mozilla.Firefox';             choco='firefox';             direct='';                                                    match=@('Firefox') }
        @{ name='Discord';          winget='Discord.Discord';             choco='discord';             direct='';                                                    match=@('Discord') }
        @{ name='Telegram';         winget='Telegram.TelegramDesktop';    choco='telegram';            direct='';                                                    match=@('Telegram Desktop') }
        @{ name='Spotify';          winget='Spotify.Spotify';             choco='spotify';             direct='https://download.scdn.co/SpotifySetup.exe';          match=@('Spotify') }
        @{ name='VLC';              winget='VideoLAN.VLC';                choco='vlc';                 direct='';                                                    match=@('VLC') }
        @{ name='MPV';              winget='mpv.mpv';                     choco='mpv';                 direct='{GH:shinchiro/mpv-winbuild-cmake}';                  match=@('mpv') }
        @{ name='Audacity';         winget='Audacity.Audacity';           choco='audacity';            direct='{GH:audacity/audacity}';                              match=@('Audacity') }
        @{ name='OBS Studio';       winget='OBSProject.OBSStudio';        choco='obs-studio';          direct='{GH:obsproject/obs-studio}';                          match=@('OBS Studio') }
        @{ name='Notepad++';        winget='Notepad++.Notepad++';         choco='notepadplusplus';     direct='';                                                    match=@('Notepad++') }
        @{ name='ShareX';           winget='ShareX.ShareX';               choco='sharex';              direct='{GH:ShareX/ShareX}';                                  match=@('ShareX') }
        @{ name='Obsidian';         winget='Obsidian.Obsidian';           choco='obsidian';            direct='';                                                    match=@('Obsidian') }
        @{ name='PowerToys';        winget='Microsoft.PowerToys';         choco='powertoys';           direct='{GH:microsoft/PowerToys}';                            match=@('PowerToys') }
        @{ name='7-Zip';            winget='7zip.7zip';                   choco='7zip';                direct='';                                                    match=@('7-Zip') }
        @{ name='WinRAR';           winget='RARLab.WinRAR';               choco='winrar';              direct='';                                                    match=@('WinRAR') }
        @{ name='ImageGlass';       winget='ImageGlass.ImageGlass';       choco='imageglass';          direct='{GH:d2phap/ImageGlass}';                              match=@('ImageGlass') }
        @{ name='Steam';            winget='Valve.Steam';                 choco='steam-client';        direct='https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe'; match=@('Steam') }
        @{ name='Epic Games';       winget='EpicGames.EpicGamesLauncher'; choco='epicgameslauncher';   direct='https://launcher-distill-static.ol.epicgames.com/Installer/Windows/EpicInstaller.exe'; match=@('Epic Games') }
        @{ name='Roblox';           winget='Roblox.Roblox';               choco='roblox';              direct='';                                                    match=@('Roblox') }
        @{ name='GOG Galaxy';       winget='GOG.Galaxy';                  choco='goggalaxy';           direct='';                                                    match=@('GOG Galaxy') }
        @{ name='PrismLauncher';    winget='PrismLauncher.PrismLauncher'; choco='prismlauncher';       direct='{GH:PrismLauncher/PrismLauncher}';                    match=@('PrismLauncher') }
        @{ name='LoL';              winget='RiotGames.LeagueOfLegends';   choco='leagueoflegends';     direct='https://lol.secure.dyn.riotcdn.net/channels/public/installs/leagueoflegends.exe'; match=@('League of Legends') }
        @{ name='GameSave Manager'; winget='InsaneMatters.GameSaveManager'; choco='gamesavemanager';   direct='';                                                    match=@('GameSave Manager') }
        @{ name='Git';              winget='Git.Git';                     choco='git';                 direct='';                                                    match=@('Git') }
        @{ name='Node.js LTS';      winget='OpenJS.NodeJS.LTS';           choco='nodejs-lts';          direct='';                                                    match=@('Node.js LTS') }
        @{ name='VSCode';           winget='Microsoft.VisualStudioCode';  choco='vscode';              direct='';                                                    match=@('Visual Studio Code') }
        @{ name='RustDesk';         winget='RustDesk.RustDesk';           choco='rustdesk';            direct='{GH:rustdesk/rustdesk}';                             match=@('RustDesk') }
        @{ name='CPU-Z';            winget='CPUID.CPU-Z';                 choco='cpu-z';               direct='';                                                    match=@('CPU-Z') }
        @{ name='CrystalDiskInfo';  winget='CrystalDewWorld.CrystalDiskInfo'; choco='crystaldiskinfo'; direct='';                                                    match=@('CrystalDiskInfo') }
        @{ name='CrystalDiskMark';  winget='CrystalDewWorld.CrystalDiskMark'; choco='crystaldiskmark'; direct='';                                                    match=@('CrystalDiskMark') }
        @{ name='BCUninstaller';    winget='Klocman.BulkCrapUninstaller'; choco='bulk-crap-uninstaller'; direct='{GH:Klocman/Bulk-Crap-Uninstaller}';              match=@('Bulk Crap Uninstaller') }
    )
}

function Get-DepsCatalog {
    return @(
        @{ name='VCRedist AIO';   winget='';                            choco='vcredist140';             direct='{GH:abbodi1406/vcredist}';              match=@('Visual C++','vcredist') }
        @{ name='DirectX Runtime';winget='Microsoft.DirectX';           choco='directx';                 direct='https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe'; match=@('DirectX') }
        @{ name='.NET 8 Desktop'; winget='Microsoft.DotNet.DesktopRuntime.8'; choco='dotnet-8.0-desktopruntime'; direct='';                  match=@('.NET Desktop Runtime 8') }
        @{ name='OpenAL';         winget='';                             choco='openal';                 direct='https://www.openal.org/downloads/oalinst.zip'; match=@('OpenAL') }
    )
}

function Get-FontsCatalog {
    return @(
        @{ name='Cascadia Code';     winget='Microsoft.CascadiaCode';             match=@('Cascadia Code') }
        @{ name='Fira Code';         winget='TheFiraCode.FiraCode';               match=@('Fira Code') }
        @{ name='Nerd Fonts';        winget='JanDeDobbeleer.NerdFontsSymbolsOnly'; match=@('Nerd Font') }
        @{ name='Inter';             winget='Inter.Inter';                        match=@('Inter') }
        @{ name='Roboto';            winget='Google.Roboto';                      match=@('Roboto') }
        @{ name='Segoe UI Variable'; winget='Microsoft.SegoeUIVariable';          match=@('Segoe UI Variable') }
    )
}

# ============================================================
# 8. INSTALLED CHECK
# ============================================================
$script:InstalledCache = $null
$script:CacheTime      = $null

function Refresh-InstalledCache {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $script:InstalledCache = @()
    foreach ($p in $paths) {
        $items = Get-ItemProperty -Path $p -EA SilentlyContinue
        foreach ($item in $items) {
            if ($item.DisplayName) { $script:InstalledCache += $item }
        }
    }
    $script:CacheTime = Get-Date
}

function Is-Installed {
    param($Sw)
    if (-not $script:InstalledCache -or ((Get-Date) - $script:CacheTime).TotalSeconds -gt 300) {
        Refresh-InstalledCache
    }
    foreach ($m in $Sw.match) {
        foreach ($inst in $script:InstalledCache) {
            if ($inst.DisplayName -like "*$m*") { return $true }
        }
    }
    return $false
}

function Confirm-Install {
    param($Sw, [int]$WaitSec = 8)
    Start-Sleep -Seconds $WaitSec
    $script:InstalledCache = $null
    return Is-Installed -Sw $Sw
}

# ============================================================
# 9. INSTALLER
# ============================================================
$script:Results = [System.Collections.Generic.List[pscustomobject]]::new()

function Install-Sw {
    param($Sw, [string]$ForceMethod = "")
    $name = $Sw.name

    if (Is-Installed -Sw $Sw) {
        Write-OK "$name already installed"
        $script:Results.Add([pscustomobject]@{ Name=$name; Status='SKIPPED'; Method='' })
        return
    }

    Write-Info "Installing: $name"
    $ok = $false
    $usedMethod = ""
    $timeout = [int](Get-Cfg "install_timeout_seconds" 300)

    # WinGet
    if (-not $ok -and $Sw.winget -and $Sw.winget -ne "" -and (Get-Cfg "use_winget")) {
        try {
            $job = Start-Job -ScriptBlock {
                param($id)
                winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent 2>&1
            } -ArgumentList $Sw.winget
            Wait-Job $job -Timeout $timeout | Out-Null
            $out = $job | Receive-Job
            Remove-Job $job -Force

            $isSuccess = $false
            if ($out) {
                $outStr = ($out -join " `n").ToLower()
                if ($outStr -match "successfully installed|no applicable update found|already installed|found in one of the sources") {
                    $isSuccess = $true
                }
                if ($outStr -match "not recognized|command not found|term.*not recognized") {
                    $isSuccess = $false
                }
            }
            if ($isSuccess) {
                Start-Sleep -Seconds 3
                $script:InstalledCache = $null
                if (Is-Installed -Sw $Sw) {
                    $ok = $true
                    $usedMethod = "winget"
                }
            }
        } catch { Log "WinGet failed $name : $_" "E" }
    }

    # Chocolatey
    if (-not $ok -and $Sw.choco -and $Sw.choco -ne "" -and (Get-Cfg "use_choco")) {
        try {
            $job = Start-Job -ScriptBlock {
                param($id)
                choco install $id -y --force --ignore-checksums 2>&1
            } -ArgumentList $Sw.choco
            Wait-Job $job -Timeout $timeout | Out-Null
            $out = $job | Receive-Job
            Remove-Job $job -Force

            $isSuccess = $false
            if ($out) {
                $outStr = ($out -join "`n").ToLower()
                if ($outStr -match "installed / installed: 1/1|1 upgraded|success" -and $outStr -notmatch "not recognized") {
                    $isSuccess = $true
                }
            }
            if ($isSuccess) {
                Start-Sleep -Seconds 3
                $script:InstalledCache = $null
                if (Is-Installed -Sw $Sw) {
                    $ok = $true
                    $usedMethod = "choco"
                }
            }
        } catch { Log "Choco failed $name : $_" "E" }
    }

    # Direct download
    if (-not $ok -and $Sw.direct -and $Sw.direct -ne "") {
        $durl = $Sw.direct
        if ($durl -match '\{GH:(.+?)\}') {
            $repo = $matches[1]
            $extp = '\.exe$|\.msi$'
            if ($durl -match '\.zip$') { $extp = '\.zip$' }
            $durl = Resolve-GithubLatest -Repo $repo -Pattern $extp
        }

        if ($durl) {
            $ext = [System.IO.Path]::GetExtension($durl).ToLowerInvariant()
            $safe = $name -replace '[^\w\-.]', '_'
            $inst = "$env:TEMP\devil9_${safe}_setup${ext}"

            if (Invoke-Download $durl $inst (Get-Cfg "max_retries" 3)) {
                try {
                    if ($ext -eq '.msi') {
                        Start-Process msiexec.exe -ArgumentList "/i `"$inst`" /qn /norestart" -Wait -NoNewWindow
                    } elseif ($ext -eq '.zip') {
                        $extTo = "$env:TEMP\devil9_${safe}_ext"
                        Expand-Archive $inst $extTo -Force -EA Stop
                        $exes = Get-ChildItem $extTo -Filter "*.exe" -Recurse -EA SilentlyContinue | Sort-Object Length -Descending
                        if ($exes) { Start-Process -FilePath $exes[0].FullName -ArgumentList "/S" -Wait -NoNewWindow }
                        Remove-Item $inst -Force -EA SilentlyContinue
                    } else {
                        Start-Process -FilePath $inst -ArgumentList @("/S","/silent","/NCRC","/VERYSILENT") -Wait -NoNewWindow -EA Stop
                    }
                    if (Confirm-Install -Sw $Sw 10) { $ok = $true; $usedMethod = "direct" }
                } catch { Log "Direct exec failed $name : $_" "E" }
            }
        } else {
            Write-Warn "  Could not resolve URL for $name"
        }
    }

    if ($ok -or (Is-Installed -Sw $Sw)) {
        Write-OK "$name installed ($usedMethod)"
        $script:Results.Add([pscustomobject]@{ Name=$name; Status='OK'; Method=$usedMethod })
    } else {
        Write-Err "$name FAILED"
        $script:Results.Add([pscustomobject]@{ Name=$name; Status='FAILED'; Method=$usedMethod })
    }
}

# ============================================================
# 10. BATCH INSTALL
# ============================================================
function Install-Batch {
    param([array]$Items, [string]$Label = "Items")
    $catalog = $Items
    $toDo = @()
    $okCount = 0

    Refresh-InstalledCache
    $skipped = Get-Cfg "skipped_programs" @()

    foreach ($sw in $catalog) {
        $isSkip = $false
        foreach ($sk in $skipped) { if ($sk -eq $sw.name) { $isSkip = $true; break } }
        if ($isSkip) { Write-Warn "Skipping $($sw.name)"; $okCount++; continue }
        if (Is-Installed -Sw $sw) {
            Write-OK "$($sw.name) already installed"; $okCount++
        } else {
            $toDo += $sw
        }
    }

    Write-Host ""
    Write-Host " $Label : $($catalog.Count) total | $okCount OK | $($toDo.Count) to install" -ForegroundColor Yellow
    Write-Host ""

    if ($toDo.Count -eq 0) { Write-OK "All $Label already installed!"; return }

    $swatch = [System.Diagnostics.Stopwatch]::StartNew()
    $i = 1
    foreach ($sw in $toDo) {
        Write-Host " [$i/$($toDo.Count)] " -ForegroundColor Gray -NoNewline
        Install-Sw -Sw $sw
        $i++
    }
    $swatch.Stop()

    Write-Host ""
    Write-Host " [$Label] Done in $($swatch.Elapsed.Minutes)m $($swatch.Elapsed.Seconds)s" -ForegroundColor Green

    $fails = @()
    foreach ($r in $script:Results) { if ($r.Status -eq 'FAILED') { $fails += $r } }
    if ($fails.Count -gt 0) {
        Write-Warn " Failed ($($fails.Count)):"
        foreach ($f in $fails) { Write-Err "  - $($f.Name)" }
        Write-Warn " Re-run to retry."
    }
}

# ============================================================
# 11. SELECTION PARSER
# ============================================================
function Parse-Selection {
    param([string]$Inp, [int]$Max)
    $res = New-Object System.Collections.Generic.List[int]
    if ([string]::IsNullOrWhiteSpace($Inp)) { return @() }
    foreach ($part in ($Inp -split ',')) {
        $part = $part.Trim()
        if ($part -match '^(\d+)-(\d+)$') {
            $s = [int]$matches[1]; $e = [int]$matches[2]
            $step = 1; if ($s -gt $e) { $step = -1 }
            $val = $s
            while (($step -gt 0 -and $val -le $e) -or ($step -lt 0 -and $val -ge $e)) {
                if ($val -ge 1 -and $val -le $Max) { $res.Add($val) | Out-Null }
                $val += $step
            }
        } elseif ($part -match '^\d+$') {
            $n = [int]$part
            if ($n -ge 1 -and $n -le $Max) { $res.Add($n) | Out-Null }
        }
    }
    return @($res | Select-Object -Unique | Sort-Object)
}

# ============================================================
# 12. MENU: SOFTWARE
# ============================================================
function Menu-Installs {
    Clear-Host
    Draw-Box "SOFTWARE INSTALLER"
    Write-Host ""
    $catalog = Get-SoftwareCatalog
    $i = 1
    foreach ($p in $catalog) {
        $st = "   "; if (Is-Installed -Sw $p) { $st = "[OK]" }
        $cl = "White"; if ($st -eq "[OK]") { $cl = "DarkGray" }
        Write-Host (" [{0:d2}] {1} {2}" -f $i, $st, $p.name) -ForegroundColor $cl
        $i++
    }
    Write-Host "`n [A] Install ALL  [R] Refresh  [B] Back" -ForegroundColor Green
    $inp = Read-Host " Numbers"
    if ($inp -match '^[Bb]$') { return }
    if ($inp -match '^[Rr]$') { Refresh-InstalledCache; Menu-Installs; return }
    if ($inp -match '^[Aa]$') { Install-Batch $catalog "SOFTWARE"; Wait-Enter; return }
    $sel = Parse-Selection $inp $catalog.Count
    if ($sel.Count -gt 0) {
        $batch = @(); foreach ($s in $sel) { $batch += $catalog[$s - 1] }
        Install-Batch $batch "Selected"
    }
    Wait-Enter
}

# ============================================================
# 13. MENU: DEPS
# ============================================================
function Menu-Deps {
    Clear-Host
    Draw-Box "GAME DEPENDENCIES"
    Write-Host ""
    $deps = Get-DepsCatalog
    $i = 1
    foreach ($d in $deps) {
        $st = "   "; if (Is-Installed -Sw $d) { $st = "[OK]" }
        $cl = "Yellow"; if ($st -eq "[OK]") { $cl = "DarkGray" }
        Write-Host (" [{0}] {1} {2}" -f $i, $st, $d.name) -ForegroundColor $cl
        $i++
    }
    Write-Host "`n [A] Install ALL  [B] Back" -ForegroundColor Green
    $inp = Read-Host " Numbers"
    if ($inp -match '^[Bb]$') { return }
    if ($inp -match '^[Aa]$') { Install-Batch $deps "DEPENDENCIES"; Wait-Enter; return }
    $sel = Parse-Selection $inp $deps.Count
    if ($sel.Count -gt 0) {
        $batch = @(); foreach ($s in $sel) { $batch += $deps[$s - 1] }
        Install-Batch $batch "Selected Deps"
    }
    Wait-Enter
}

# ============================================================
# 14. MENU: FONTS
# ============================================================
function Menu-Fonts {
    Clear-Host
    Draw-Box "FONT INSTALLER"
    Write-Host ""
    $fonts = Get-FontsCatalog
    $i = 1
    foreach ($f in $fonts) { Write-Host (" [{0}] {1}" -f $i, $f.name) -ForegroundColor White; $i++ }
    Write-Host "`n [A] Install ALL  [B] Back" -ForegroundColor Green
    $inp = Read-Host " Numbers"
    if ($inp -match '^[Bb]$') { return }
    $selected = @()
    if ($inp -match '^[Aa]$') { $selected = $fonts }
    else { $sl = Parse-Selection $inp $fonts.Count; foreach ($s in $sl) { $selected += $fonts[$s - 1] } }
    if ($selected.Count -eq 0) { Write-Info "No fonts selected"; Wait-Enter; return }
    Write-Info "Installing $($selected.Count) fonts..."
    foreach ($f in $selected) {
        try {
            winget install --id $f.winget -e --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
            Write-OK "  $($f.name) done"
        } catch { Write-Err "  $($f.name) failed" }
    }
    Wait-Enter
}

# ============================================================
# 15. MENU: SYSTEM
# ============================================================
function Menu-System {
    while ($true) {
        Clear-Host
        Draw-Box "CLEANUP & SYSTEM TWEAKS"
        Write-Host "`n  [1]  Clean Temp Files"
        Write-Host "  [2]  Empty Recycle Bin"
        Write-Host "  [3]  Disk Cleanup"
        Write-Host "  [4]  Flush DNS"
        Write-Host "  [5]  Reset Winsock and IP"
        Write-Host "  [6]  Windows Updates"
        Write-Host "  [7]  Check Missing Drivers"
        Write-Host "  [8]  Disable Telemetry"
        Write-Host "  [9]  Ultimate Performance Plan"
        Write-Host "  [10] Debloat UWP Apps"
        Write-Host "`n  [0]  Back" -ForegroundColor Red
        $ch = Read-Host "  Select"
        switch ($ch) {
            '1' {
                Write-Step "CLEANING TEMP"
                $total = 0
                $items = Get-ChildItem $env:TEMP -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue -PassThru
                if ($items) { $total += ($items | Measure-Object -Property Length -Sum -EA SilentlyContinue).Sum }
                $items2 = Get-ChildItem "C:\Windows\Temp" -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue -PassThru
                if ($items2) { $total += ($items2 | Measure-Object -Property Length -Sum -EA SilentlyContinue).Sum }
                $mb = [math]::Round($total / 1MB, 2)
                Write-OK "Cleaned ${mb} MB"
                Wait-Enter
            }
            '2' { Clear-RecycleBin -Force -EA SilentlyContinue; Write-OK "Recycle Bin emptied"; Wait-Enter }
            '3' { Start-Process cleanmgr; Wait-Enter }
            '4' { ipconfig /flushdns | Out-Null; Write-OK "DNS flushed"; Wait-Enter }
            '5' {
                netsh winsock reset | Out-Null; netsh int ip reset | Out-Null; netsh winhttp reset proxy | Out-Null
                Write-OK "Network reset. Reboot recommended."; Wait-Enter
            }
            '6' { Start-Process "ms-settings:windowsupdate"; Wait-Enter }
            '7' {
                $missing = Get-PnpDevice | Where-Object { $_.Status -eq 'Error' }
                if ($missing) {
                    Write-Warn "Missing drivers:"
                    foreach ($m in $missing) { Write-Err "  $($m.FriendlyName)" }
                } else { Write-OK "No missing drivers" }
                Wait-Enter
            }
            '8' {
                @('DiagTrack','diagnosticshub.standardcollector.service','dmwappushservice') | ForEach-Object {
                    $svc = Get-Service $_ -EA SilentlyContinue
                    if ($svc) { Set-Service $_ -StartupType Disabled -EA SilentlyContinue; Stop-Service $_ -Force -EA SilentlyContinue; Write-OK "  Disabled: $_" }
                }
                Write-OK "Telemetry disabled"; Wait-Enter
            }
            '9' {
                try { powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null; Write-OK "Ultimate Performance enabled" }
                catch { Write-Warn "Failed: $_" }
                Wait-Enter
            }
            '10' {
                $bloat = @("Microsoft.3DBuilder","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.Messaging","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.MixedReality.Portal","Microsoft.Office.OneNote","Microsoft.OneConnect","Microsoft.People","Microsoft.Print3D","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.YourPhone","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.Todos")
                $sc = 0
                foreach ($app in $bloat) { try { Get-AppxPackage $app | Remove-AppxPackage -EA SilentlyContinue } catch { $sc++ } }
                Write-OK "Debloat done ($sc not installed)"; Wait-Enter
            }
            '0' { return }
        }
    }
}

# ============================================================
# 16. MENU: PREMIUM
# ============================================================
function Menu-Premium {
    Clear-Host
    Draw-Box "PREMIUM TOOLS & SCRIPTS"
    Write-Host "`n  [1] Spicetify (Spotify Customization)"
    Write-Host "  [2] AME Wizard"
    Write-Host "  [3] Open-Shell (Classic Start Menu)"
    Write-Host "  [4] Massgrave Activation"
    Write-Host "`n  [0] Back" -ForegroundColor Red
    $ch = Read-Host "  Select"
    switch ($ch) {
        '1' {
            try {
                $sc = Invoke-RestMethod "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" -TimeoutSec 30 -EA Stop
                Invoke-Expression $sc
                Write-OK "Spicetify started"
            } catch { Write-Err "Failed: $_" }
            Wait-Enter
        }
        '2' {
            $amePath = "$env:TEMP\AME_Wizard.exe"
            if (Invoke-Download "https://github.com/Translucency-Software/AME-Wizard/releases/latest/download/AME.exe" $amePath 3) {
                Start-Process $amePath
            }
            Wait-Enter
        }
        '3' {
            try { winget install --id Open-Shell.OpenShellMenu -e --accept-source-agreements --silent 2>&1 | Out-Null } catch {}
            Wait-Enter
        }
        '4' { Start-Process "https://massgrave.dev"; Wait-Enter }
    }
}

# ============================================================
# 17. MENU: TOOLS
# ============================================================
function Menu-Tools {
    Clear-Host
    Draw-Box "QUICK SHORTCUTS"
    Write-Host "`n  [1] Device Manager"
    Write-Host "  [2] Services"
    Write-Host "  [3] Task Manager"
    Write-Host "  [4] Registry Editor"
    Write-Host "  [5] Control Panel"
    Write-Host "  [6] Restart Explorer"
    Write-Host "  [7] System Information"
    Write-Host "  [8] View Log"
    Write-Host "`n  [0] Back" -ForegroundColor Red
    $ch = Read-Host "  Select"
    switch ($ch) {
        '1' { Start-Process devmgmt.msc }
        '2' { Start-Process services.msc }
        '3' { Start-Process taskmgr }
        '4' { Start-Process regedit }
        '5' { Start-Process control }
        '6' { Stop-Process -Name explorer -Force -EA SilentlyContinue; Write-OK "Explorer restarted"; Wait-Enter }
        '7' {
            $si_sys = Get-CimInstance Win32_ComputerSystem
            $si_cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
            $si_gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
            $si_os = Get-CimInstance Win32_OperatingSystem
            Clear-Host
            Write-Host "  SYSTEM INFORMATION" -ForegroundColor Cyan
            Write-Host "  PC: $($si_sys.Name)"
            Write-Host "  CPU: $($si_cpu.Name)"
            Write-Host "  GPU: $($si_gpu.Name)"
            $ramGB = [math]::Round($si_os.TotalVisibleMemorySize / 1MB, 2)
            Write-Host "  RAM: ${ramGB} GB"
            Write-Host "  OS: $($si_os.Caption) ($($si_os.OSArchitecture))"
            Write-Host "  Log: $script:LogFile"
            Wait-Enter
        }
        '8' { Show-Log }
        '0' { return }
    }
}

# ============================================================
# 18. LOG VIEWER
# ============================================================
function Show-Log {
    Clear-Host
    Write-Host "  INSTALLATION LOG" -ForegroundColor Cyan
    Write-Host "  $script:LogFile" -ForegroundColor DarkGray
    if (Test-Path $script:LogFile) {
        $lines = Get-Content $script:LogFile
        $startIdx = 0
        if ($lines.Count -gt 50) { $startIdx = $lines.Count - 50 }
        $idx = 0
        foreach ($line in $lines) {
            if ($idx -ge $startIdx) {
                $c = "White"
                if ($line -match "ERROR|FAIL") { $c = "Red" }
                elseif ($line -match "OK|SUCCESS") { $c = "Green" }
                elseif ($line -match "WARN") { $c = "Yellow" }
                Write-Host "  $line" -ForegroundColor $c
            }
            $idx++
        }
    } else { Write-Warn "No log file found" }
    Wait-Enter
}

# ============================================================
# 19. MENU: CONFIG
# ============================================================
function Menu-Config {
    while ($true) {
        Clear-Host
        Draw-Box "CONFIGURATION"
        Write-Host "`n  [1]  View Configuration"
        Write-Host "  [2]  Toggle WinGet"
        Write-Host "  [3]  Toggle Chocolatey"
        Write-Host "  [4]  Toggle Scoop"
        Write-Host "  [5]  Toggle Silent Mode"
        Write-Host "  [6]  Toggle Restore Point"
        Write-Host "  [7]  Set Max Retries (current: $(Get-Cfg 'max_retries' 3))"
        Write-Host "  [8]  Set Timeout (current: $(Get-Cfg 'install_timeout_seconds' 300)s)"
        Write-Host "  [9]  Skip/Unskip Program"
        Write-Host "  [10] Reset to Defaults"
        Write-Host "`n  [0]  Back" -ForegroundColor Red
        $ch = Read-Host "  Select"
        switch ($ch) {
            '1' {
                Clear-Host; Write-Host "  Configuration" -ForegroundColor Cyan; Write-Host ""
                foreach ($k in $script:Config.Keys) {
                    $v = $script:Config[$k]
                    if ($v -is [hashtable]) { foreach ($sk in $v.Keys) { Write-Host "  $k.$sk = $($v[$sk])" } }
                    else { Write-Host "  $k = $v" }
                }
                Write-Host "`n  File: $script:ConfigFile" -ForegroundColor DarkGray
                Wait-Enter
            }
            '2'  { $v = -not (Get-Cfg "use_winget"); Set-Cfg "use_winget" $v; Write-OK "WinGet: $v"; Wait-Enter }
            '3'  { $v = -not (Get-Cfg "use_choco"); Set-Cfg "use_choco" $v; Write-OK "Choco: $v"; Wait-Enter }
            '4'  { $v = -not (Get-Cfg "use_scoop"); Set-Cfg "use_scoop" $v; Write-OK "Scoop: $v"; Wait-Enter }
            '5'  { $v = -not (Get-Cfg "silent_mode"); Set-Cfg "silent_mode" $v; Write-OK "Silent: $v"; Wait-Enter }
            '6'  { $v = -not (Get-Cfg "create_restore_point"); Set-Cfg "create_restore_point" $v; Write-OK "RestorePoint: $v"; Wait-Enter }
            '7'  { $v = Read-Host "  Max retries (1-10)? "; Set-Cfg "max_retries" ([int]$v); Wait-Enter }
            '8'  { $v = Read-Host "  Timeout (seconds)? "; Set-Cfg "install_timeout_seconds" ([int]$v); Wait-Enter }
            '9'  {
                Clear-Host; Write-Host "  Skip/Unskip programs:" -ForegroundColor Cyan
                $catalog = Get-SoftwareCatalog
                $ci = 1; foreach ($p in $catalog) { Write-Host "  [$ci] $($p.name)"; $ci++ }
                $sinp = Read-Host "  Number (0 to cancel)"
                if ($sinp -eq "0") { continue }
                $sn = [int]$sinp
                if ($sn -ge 1 -and $sn -le $catalog.Count) {
                    $sname = $catalog[$sn - 1].name
                    $oldSkipped = Get-Cfg "skipped_programs" @()
                    $found = $false
                    $newSkipped = @()
                    foreach ($sk in $oldSkipped) {
                        if ($sk -eq $sname) { $found = $true }
                        else { $newSkipped += $sk }
                    }
                    if ($found) { Write-OK "Unskipped: $sname"; Set-Cfg "skipped_programs" @($newSkipped) }
                    else { $newSkipped += $sname; Write-OK "Skipped: $sname"; Set-Cfg "skipped_programs" @($newSkipped) }
                }
                Wait-Enter
            }
            '10' { $c = Read-Host "  Reset config? (yes/no)"; if ($c -match '^y') { $script:Config = New-DefaultConfig; Save-Config; Write-OK "Config reset" }; Wait-Enter }
            '0'  { return }
        }
    }
}

# ============================================================
# 20. AUTO INSTALL ALL
# ============================================================
function AutoInstall-All {
    $sw_all = [System.Diagnostics.Stopwatch]::StartNew()
    PreFlight

    Write-Step "DEPENDENCIES"
    foreach ($d in (Get-DepsCatalog)) { Install-Sw -Sw $d }

    Write-Step "SOFTWARE"
    foreach ($s in (Get-SoftwareCatalog)) { Install-Sw -Sw $s }

    Write-Step "FONTS"
    foreach ($f in (Get-FontsCatalog)) {
        try { winget install --id $f.winget -e --accept-source-agreements --silent 2>&1 | Out-Null; Write-OK "  $($f.name)" }
        catch { Write-Err "  $($f.name) failed" }
    }

    Write-Step "SYSTEM TWEAKS"
    @('DiagTrack','diagnosticshub.standardcollector.service','dmwappushservice') | ForEach-Object {
        try { $svc = Get-Service $_ -EA SilentlyContinue; if ($svc) { Set-Service $_ -StartupType Disabled -EA SilentlyContinue; Stop-Service $_ -Force -EA SilentlyContinue } } catch {}
    }
    Write-OK "Telemetry disabled"

    $sw_all.Stop()
    Write-Step "DONE in $($sw_all.Elapsed.Minutes)m $($sw_all.Elapsed.Seconds)s"

    $okN = 0; $skipN = 0; $failN = 0
    foreach ($r in $script:Results) {
        if ($r.Status -eq 'OK') { $okN++ } elseif ($r.Status -eq 'SKIPPED') { $skipN++ } else { $failN++ }
    }
    Write-Host "  OK: $okN | Skipped: $skipN | Failed: $failN" -ForegroundColor Cyan
    Write-Host "  Log: $script:LogFile" -ForegroundColor DarkGray
    Write-OK "All done!"
    Wait-Enter
}

# ============================================================
# 21. BENCHMARK
# ============================================================
function Run-Benchmark {
    Clear-Host
    Draw-Box "BENCHMARK & STRESS TEST"
    Write-Host ""

    Write-Step "NETWORK TEST"
    foreach ($h in @("google.com", "github.com", "chocolatey.org")) {
        try {
            $pingResults = Test-Connection $h -Count 4 -EA SilentlyContinue
            if ($pingResults) {
                $avg = ($pingResults | Measure-Object -Property Latency -Average).Average
                $c = "Green"; if ($avg -gt 100) { $c = "Yellow" }; if ($avg -gt 300) { $c = "Red" }
                Write-Host "  $h avg: ${avg}ms" -ForegroundColor $c
            } else { Write-Err "  ${h}: UNREACHABLE" }
        } catch { Write-Err "  ${h}: ERROR" }
    }

    Write-Step "DOWNLOAD SPEED"
    $testUrl = "https://speed.cloudflare.com/__down?bytes=10485760"
    $testOut = "$env:TEMP\devil9_speedtest.tmp"
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Start-BitsTransfer -Source $testUrl -Destination $testOut -EA Stop
        $sw.Stop()
        $sz = (Get-Item $testOut).Length
        $mbps = [math]::Round(($sz * 8) / ($sw.Elapsed.TotalSeconds * 1000000), 2)
        $szMB = [math]::Round($sz / 1MB, 2)
        Write-OK "${mbps} Mbps (${szMB}MB in $($sw.Elapsed.TotalSeconds.ToString('F1'))s)"
    } catch { Write-Err "Download test failed" }
    Remove-Item $testOut -EA SilentlyContinue

    Write-Step "PACKAGE MANAGERS"
    if (Test-Winget) { Write-OK "WinGet available" } else { Write-Warn "WinGet not found" }
    if (Test-Choco)  { Write-OK "Chocolatey available" } else { Write-Warn "Chocolatey not found" }
    if (Test-Scoop)  { Write-OK "Scoop available" } else { Write-Warn "Scoop not found" }

    Write-Step "DISK I/O"
    $tf = "$env:TEMP\devil9_iotest.tmp"
    try {
        $buf = New-Object byte[] 1048576
        (New-Object Random).NextBytes($buf)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $stream = New-Object System.IO.FileStream($tf, 'Create')
        $ii = 0; while ($ii -lt 100) { $stream.Write($buf, 0, $buf.Length); $ii++ }
        $stream.Flush(); $stream.Close(); $sw.Stop()
        $ws = [math]::Round(100 / $sw.Elapsed.TotalSeconds, 2)
        Write-OK "Write: ${ws} MB/s"

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        [System.IO.File]::ReadAllBytes($tf) | Out-Null
        $sw.Stop()
        $rs = [math]::Round(100 / $sw.Elapsed.TotalSeconds, 2)
        Write-OK "Read: ${rs} MB/s"
    } catch { Write-Err "Disk test failed" }
    Remove-Item $tf -EA SilentlyContinue

    Write-Step "SYSTEM SPECS"
    $b_cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $b_gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $b_ram = Get-CimInstance Win32_ComputerSystem
    Write-Host "  CPU: $($b_cpu.Name)"
    Write-Host "  GPU: $($b_gpu.Name)"
    $ramTotal = [math]::Round($b_ram.TotalPhysicalMemory / 1GB, 2)
    Write-Host "  RAM: ${ramTotal} GB"
    Write-Host "  Cores: $($b_cpu.NumberOfCores) ($($b_cpu.NumberOfLogicalProcessors) logical)"

    Write-Step "GITHUB API"
    try {
        $gh = Invoke-RestMethod "https://api.github.com/rate_limit" -TimeoutSec 10 -EA Stop
        $core = $gh.resources.core
        $c2 = "Green"; if ($core.remaining -lt 30) { $c2 = "Red" }
        Write-Host "  Remaining: $($core.remaining)/$($core.limit)" -ForegroundColor $c2
    } catch { Write-Err "GitHub API check failed" }

    Write-Host "`n  Benchmark complete!" -ForegroundColor Green
    Wait-Enter
}

# ============================================================
# 22. MAIN
# ============================================================
$script:Results.Clear()
Load-Config
Log "Devil9 PC Assistant v$script:VERSION started" "START"

Write-Host ""
Write-Host "  DEVIL9 PC ASSISTANT v$script:VERSION" -ForegroundColor Cyan
Write-Host "  Quick Checks:" -ForegroundColor DarkGray

if (Test-Internet) { Write-Host "  [OK] Internet" -ForegroundColor Green } else { Write-Host "  [!!] No Internet" -ForegroundColor Red }
if (Test-Winget)    { Write-Host "  [OK] WinGet" -ForegroundColor Green } else { Write-Host "  [!!] No WinGet" -ForegroundColor Yellow }
if (Test-Choco)     { Write-Host "  [OK] Chocolatey" -ForegroundColor Green } else { Write-Host "  [!!] No Chocolatey" -ForegroundColor Yellow }
Write-Host ""

# Non-interactive modes
if ($InstallDefaults -or ($OnlyInstall -and $OnlyInstall -eq "all")) {
    AutoInstall-All
    exit
}
if ($InstallDeps)  { PreFlight; Install-Batch (Get-DepsCatalog) "DEPENDENCIES"; exit }
if ($InstallFonts) { PreFlight; Menu-Fonts; exit }
if ($Tweaks)       { PreFlight; Menu-System; exit }
if ($Benchmark)    { Run-Benchmark; exit }
if ($Interactive)  { PreFlight }

# Main loop
while ($true) {
    Clear-Host
    if (-not $NoLogo) {
        Draw-Box "DEVIL9 PC ASSISTANT v$script:VERSION"
        Write-Host ""
    }
    Write-Host "  [1] Software Installation" -ForegroundColor White
    Write-Host "  [2] Game Dependencies" -ForegroundColor White
    Write-Host "  [3] Fonts" -ForegroundColor White
    Write-Host "  [4] Cleanup & System Tweaks" -ForegroundColor White
    Write-Host "  [5] Premium Tools & Scripts" -ForegroundColor Magenta
    Write-Host "  [6] Quick Shortcuts" -ForegroundColor White
    Write-Host "  [7] Configuration" -ForegroundColor Yellow
    Write-Host "  [8] Benchmark & Stress Test" -ForegroundColor Cyan
    Write-Host "  [9] Install Everything (Auto)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    $ch = Read-Host "  Select"

    switch ($ch) {
        '1' { Menu-Installs }
        '2' { Menu-Deps }
        '3' { Menu-Fonts }
        '4' { Menu-System }
        '5' { Menu-Premium }
        '6' { Menu-Tools }
        '7' { Menu-Config }
        '8' { Run-Benchmark }
        '9' { $cnf = Read-Host "  Install EVERYTHING? (yes/no)"; if ($cnf -match '^y') { AutoInstall-All } }
        '0' { Log "Exiting" "END"; Write-Host "`n Exiting..."; exit }
    }
}