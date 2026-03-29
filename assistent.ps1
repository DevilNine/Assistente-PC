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

# Habilitar ExecutionPolicy Unrestricted para todos os escopos
Set-ExecutionPolicy Unrestricted -Scope Process -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction SilentlyContinue

# Desabilitar UAC temporariamente para instalações silenciosas
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Force -EA SilentlyContinue

# Instalação single via job (parallel install)
if ($args[0] -eq "-InstallSingle") {
    $progName = $args[1]
    $wingetId = $args[2]
    $chocoId = $args[3]
    $directUrl = $args[4]
    
    $prog = [PSCustomObject]@{
        DisplayName = $progName
        WingetId = $wingetId
        ChocoId = $chocoId
        DirectUrl = $directUrl
    }
    
    # Same as Install-Target but simplified
    if ($chocoId -and (Get-Command choco -EA SilentlyContinue)) {
        choco install $chocoId -y --force --ignore-checksums 2>$null
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) { 
            Write-Output "OK: $progName via Chocolatey"
            exit 
        }
    }
    if ($wingetId -and (Get-Command winget -EA SilentlyContinue)) {
        Start-Process "winget" -ArgumentList "install --id $wingetId -e --accept-source-agreements --accept-package-agreements --silent --accept-source-manifests" -WindowStyle Hidden -Wait
        if ($LASTEXITCODE -eq 0) { 
            Write-Output "OK: $progName via Winget"
            exit 
        }
    }
    if ($directUrl) {
        $tempFile = "$env:TEMP\$progName.exe"
        Start-BitsTransfer -Source $directUrl -Destination $tempFile -Priority High
        Start-Process $tempFile -ArgumentList "/S /NCRC" -Wait
        Write-Output "OK: $progName via Download"
        Remove-Item $tempFile -Force -EA SilentlyContinue
        exit
    }
    Write-Output "ERRO: $progName"
    exit
}


# 2. LOGGING E INTERFACE
function Write-Log { param([string]$m) Write-Host " [i] $m" -ForegroundColor Cyan }
function Write-Suc { param([string]$m) Write-Host " [+] $m" -ForegroundColor Green }
function Write-Err { param([string]$m) Write-Host " [x] $m" -ForegroundColor Red }
function Write-Warn { param([string]$m) Write-Host " [!] $m" -ForegroundColor Yellow }

function Pause-Output {
    Write-Host ""
    Read-Host "Pressione ENTER para continuar..."
}

# 3. VERIFICAÇÃO DE INSTALADOS
$script:InstalledCache = $null

function Get-InstalledSoftware {
    if ($script:InstalledCache) { return $script:InstalledCache }
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $script:InstalledCache = @()
    foreach($p in $paths) {
        $script:InstalledCache += Get-ItemProperty -Path $p -EA SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName
    }
    return $script:InstalledCache
}

function Test-Installed {
    param($prog)
    $installed = Get-InstalledSoftware
    foreach($m in $prog.Match) {
        if (($installed.DisplayName) -like "*$m*") { return $true }
    }
    return $false
}

# 4. INSTALADOR BASE (otimizado com BitsTransfer e instalação paralela)
function Install-Target {
    param($prog)
    if (Test-Installed -prog $prog) {
        Write-Suc "$($prog.DisplayName) ja esta instalado!"
        return
    }

    $success = $false
    
    # Tenta Chocolatey PRIMERO (mais confiável)
    if ($prog.ChocoId -and (Get-Command choco -EA SilentlyContinue)) {
        Write-Log "Tentando via Chocolatey: $($prog.DisplayName)"
        choco install $prog.ChocoId -y --force --ignore-checksums 2>$null
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) { 
            $success = $true 
            Write-Suc "Instalado via Chocolatey!"
            return
        }
    }
    
    # Tenta Winget com instalação oculta
    if (-not $success -and $prog.WingetId -and (Get-Command winget -EA SilentlyContinue)) {
        Write-Log "Tentando via Winget: $($prog.DisplayName)"
        $wingetArgs = "--id $($prog.WingetId) -e --accept-source-agreements --accept-package-agreements --silent --accept-source-manifests"
        Start-Process -FilePath "winget" -ArgumentList "install $wingetArgs" -WindowStyle Hidden -Wait -EA SilentlyContinue
        if ($LASTEXITCODE -eq 0) { 
            $success = $true 
            Write-Suc "Instalado via Winget!"
            return
        }
    }

    # Download direto via BitsTransfer como último recurso
    if (-not $success -and $prog.DirectUrl) {
        Write-Log "Tentando download direto: $($prog.DisplayName)"
        $tempInstaller = "$env:TEMP\$($prog.DisplayName)_setup.exe"
        try {
            Start-BitsTransfer -Source $prog.DirectUrl -Destination $tempInstaller -Priority High -TransferType Download
            Start-Process -FilePath $tempInstaller -ArgumentList "/S /NCRC" -Wait -EA SilentlyContinue
            $success = $true
            Write-Suc "Instalado via Download Direto!"
            Remove-Item $tempInstaller -Force -EA SilentlyContinue
        } catch {
            Write-Err "Download direto falhou: $($prog.DisplayName)"
        }
    }

    if (-not $success) {
        Write-Err "Nao foi possivel instalar $($prog.DisplayName)"
    }
}

# 5. CATÁLOGO DE APLICATIVOS (OS 28 PROGRAMAS)
$ProgramCatalog = @(
    [pscustomobject]@{ DisplayName='7-Zip'; WingetId='7zip.7zip'; ChocoId='7zip'; Match=@('7-Zip') }
    [pscustomobject]@{ DisplayName='Audacity'; WingetId='Audacity.Audacity'; ChocoId='audacity'; Match=@('Audacity') }
    [pscustomobject]@{ DisplayName='BCUninstaller'; WingetId='Klocman.BulkCrapUninstaller'; ChocoId='bcuninstaller'; Match=@('Bulk Crap Uninstaller') }
    [pscustomobject]@{ DisplayName='CPU-Z'; WingetId='CPUID.CPU-Z'; ChocoId='cpu-z'; Match=@('CPU-Z') }
    [pscustomobject]@{ DisplayName='CrystalDiskInfo'; WingetId='CrystalDewWorld.CrystalDiskInfo'; ChocoId='crystaldiskinfo'; Match=@('CrystalDiskInfo') }
    [pscustomobject]@{ DisplayName='CrystalDiskMark'; WingetId='CrystalDewWorld.CrystalDiskMark'; ChocoId='crystaldiskmark'; Match=@('CrystalDiskMark') }
    [pscustomobject]@{ DisplayName='Discord'; WingetId='Discord.Discord'; ChocoId='discord'; Match=@('Discord') }
    [pscustomobject]@{ DisplayName='Eclipse Temurin JDK17'; WingetId='EclipseFoundation.Temurin.17.JDK'; ChocoId='temurin17jre'; Match=@('Eclipse Temurin') }
    [pscustomobject]@{ DisplayName='Epic Games'; WingetId='EpicGames.EpicGamesLauncher'; ChocoId='epicgameslauncher'; DirectUrl='https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/Installers.win32.epicgames-launcher-installer.exe'; Match=@('Epic Games') }
    [pscustomobject]@{ DisplayName='GameSave Manager'; WingetId='InsaneMatters.GameSaveManager'; ChocoId='gamesavemanager'; DirectUrl='https://www.gamesavemanager.com/Download'; Match=@('GameSave Manager') }
    [pscustomobject]@{ DisplayName='Git'; WingetId='Git.Git'; ChocoId='git'; Match=@('Git') }
    [pscustomobject]@{ DisplayName='Hydra Launcher'; WingetId='Polaar.Hydra'; ChocoId='hydra'; DirectUrl='https://github.com/HydraLauncher/Hydra/releases/latest/download/Hydra-Setup.exe'; Match=@('Hydra') }
    [pscustomobject]@{ DisplayName='ImageGlass'; WingetId='ImageGlass.ImageGlass'; ChocoId='imageglass'; Match=@('ImageGlass') }
    [pscustomobject]@{ DisplayName='League of Legends'; WingetId='RiotGames.LeagueOfLegends.EUW'; ChocoId=''; Match=@('League of Legends') }
    [pscustomobject]@{ DisplayName='Firefox'; WingetId='Mozilla.Firefox'; ChocoId='firefox'; Match=@('Firefox') }
    [pscustomobject]@{ DisplayName='MPV Player'; WingetId='mpv.mpv'; ChocoId='mpv'; Match=@('mpv') }
    [pscustomobject]@{ DisplayName='Notepad++'; WingetId='Notepad++.Notepad++'; ChocoId='notepadplusplus'; Match=@('Notepad++') }
    [pscustomobject]@{ DisplayName='OBS Studio'; WingetId='OBSProject.OBSStudio'; ChocoId='obs-studio'; Match=@('OBS Studio') }
    [pscustomobject]@{ DisplayName='Obsidian'; WingetId='Obsidian.Obsidian'; ChocoId='obsidian'; Match=@('Obsidian') }
    [pscustomobject]@{ DisplayName='OP.GG'; WingetId='OPGG.OPGG'; ChocoId='opgg'; Match=@('OP.GG') }
    [pscustomobject]@{ DisplayName='Prism Launcher'; WingetId='PrismLauncher.PrismLauncher'; ChocoId='prismlauncher'; Match=@('Prism') }
    [pscustomobject]@{ DisplayName='qBittorrent'; WingetId='qBittorrent.qBittorrent'; ChocoId='qbittorrent'; Match=@('qBittorrent') }
    [pscustomobject]@{ DisplayName='Roblox'; WingetId='Roblox.Roblox'; ChocoId='roblox'; Match=@('Roblox') }
    [pscustomobject]@{ DisplayName='RustDesk'; WingetId='RustDesk.RustDesk'; ChocoId='rustdesk'; Match=@('RustDesk') }
    [pscustomobject]@{ DisplayName='ShareX'; WingetId='ShareX.ShareX'; ChocoId='sharex'; Match=@('ShareX') }
    [pscustomobject]@{ DisplayName='Spotify'; WingetId='Spotify.Spotify'; ChocoId='spotify'; Match=@('Spotify') }
    [pscustomobject]@{ DisplayName='Steam'; WingetId='Valve.Steam'; ChocoId='steam'; Match=@('Steam') }
    [pscustomobject]@{ DisplayName='Telegram'; WingetId='Telegram.TelegramDesktop'; ChocoId='telegram'; Match=@('Telegram') }
)

# 6. DEPENDÊNCIAS DE JOGOS
$DepsCatalog = @(
    [pscustomobject]@{ DisplayName='VCRedist AIO'; WingetId=''; ChocoId='vcredist-all'; Match=@('Visual C++','vcredist') }
    [pscustomobject]@{ DisplayName='DirectX End-User'; WingetId='Microsoft.DirectX'; ChocoId='directx'; Match=@('DirectX') }
    [pscustomobject]@{ DisplayName='.NET Desktop Runtime 8'; WingetId='Microsoft.DotNet.DesktopRuntime.8'; ChocoId='dotnet-desktopruntime'; Match=@('.NET') }
    [pscustomobject]@{ DisplayName='XNA Framework 4.0'; WingetId=''; ChocoId='xna4'; Match=@('XNA') }
    [pscustomobject]@{ DisplayName='OpenAL'; WingetId=''; ChocoId='openal'; Match=@('OpenAL') }
    [pscustomobject]@{ DisplayName='PhysX'; WingetId=''; ChocoId='physx'; Match=@('PhysX') }
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
    Write-Host "=== INSTALADOR DE SOFTWARES ===" -ForegroundColor Cyan
    Write-Host "Lista baseada no WinUtil / Winget / Choco`n"
    
    $i = 1
    foreach ($p in $ProgramCatalog) {
        $st = if (Test-Installed -prog $p) { "[OK]" } else { "    " }
        $color = if ($st -eq "[OK]") { "DarkGray" } else { "White" }
        Write-Host (" [{0:d2}] {1}  {2}" -f $i, $st, $p.DisplayName) -ForegroundColor $color
        $i++
    }
    
    Write-Host "`nDigite os números (ex: 1,4,15-20) ou ENTER p/ voltar:" -ForegroundColor Yellow
    $inp = Read-Host ">"
    $sel = Parse-Selection -inStr $inp -max $ProgramCatalog.Count
    
    if ($sel.Count -gt 0) {
        Write-Host "`nIniciando instalacao PARALELA de $($sel.Count) itens..." -ForegroundColor Cyan

        # Instalar todos em paralelo usando Jobs
        $jobs = @()
        foreach ($s in $sel) {
            $prog = $ProgramCatalog[$s-1]
            $job = Start-Job -ScriptBlock {
                param($p, $scriptPath)
                & $scriptPath -InstallSingle $p.DisplayName $p.WingetId $p.ChocoId $p.DirectUrl
            } -ArgumentList $prog, $PSCommandPath
            $jobs += $job
        }

        # Aguardar todos os jobs terminarem
        Write-Log "Aguardando instalacoes..."
        $jobs | Wait-Job | Out-Null
        
        foreach ($job in $jobs) {
            $result = Receive-Job -Job $job
            if ($result -match "OK") { Write-Suc $result }
            elseif ($result -match "ERRO") { Write-Err $result }
        }
        
        Remove-Job -Job $jobs -Force -EA SilentlyContinue
        Write-Suc "Todas as instalacoes concluidas!"
        Pause-Output
    }
}

function Menu-Deps {
    Clear-Host
    Write-Host "=== DEPENDENCIAS DE JOGOS ===" -ForegroundColor Cyan
    $i = 1
    foreach ($d in $DepsCatalog) {
        $st = if (Test-Installed -prog $d) { "[OK]" } else { "    " }
        $color = if ($st -eq "[OK]") { "DarkGray" } else { "White" }
        Write-Host (" [{0}] {1}  {2}" -f $i, $st, $d.DisplayName) -ForegroundColor $color
        $i++
    }
    Write-Host "`nDigite os números (ex: 1,2,4-6) ou ENTER p/ voltar:" -ForegroundColor Yellow
    $inp = Read-Host ">"
    $sel = Parse-Selection -inStr $inp -max $DepsCatalog.Count
    
    if ($sel.Count -gt 0) {
        Write-Host "`nIniciando instalacao..." -ForegroundColor Cyan
        foreach ($s in $sel) { Install-Target -prog $DepsCatalog[$s-1] }
        Pause-Output
    }
}

function Menu-Tweaks {
    Clear-Host
    Write-Host "=== LIMPEZA E SISTEMA ===" -ForegroundColor Cyan
    Write-Host " [1] Limpar Arquivos Temporários (%TEMP% e C:\Windows\Temp)"
    Write-Host " [2] Esvaziar Lixeira"
    Write-Host " [3] Executar Limpeza de Disco (cleanmgr)"
    Write-Host "`n [4] Flush DNS Cache"
    Write-Host " [5] Reset Winsock e IP (Requer Reiniciar)"
    Write-Host "`n [6] Voltar"
    
    $ch = Read-Host "`nSelecione"
    switch($ch){
        '1' { 
            Write-Log "Limpando user temp..."
            Get-ChildItem $env:TEMP -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
            Write-Log "Limpando windows temp..."
            Get-ChildItem "C:\Windows\Temp" -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
            Write-Suc "Pastas Temporárias Limpas."
            Pause-Output
        }
        '2' {
            Clear-RecycleBin -Force -EA SilentlyContinue
            Write-Suc "Lixeira Esvaziada."
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
            Write-Suc "Rede IP/Winsock resetada. Reinicie o computador."
            Pause-Output
        }
    }
}

function Menu-Packs {
    Clear-Host
    Write-Host "=== PACÕES E SCRIPTS PREMIUM ===" -ForegroundColor Magenta
    Write-Host " [1] Instalar Spicetify (Spotify Mod sem Ads)"
    Write-Host " [2] Instalar AME Wizard (ReviOS)"
    Write-Host " [3] Ativador WinAct"
    Write-Host " [4] Instalar Spotify (Instalador Oficial - Não MS Store)"
    Write-Host " [5] Voltar"
    $ch = Read-Host "`nSelecione"
    switch($ch) {
        '1' {
            Write-Log "Instalando Spicetify..."
            $tempScript = "$env:TEMP\spicetify_install.ps1"
            Start-BitsTransfer -Source "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" -Destination $tempScript
            Invoke-Expression $tempScript
            Remove-Item $tempScript -Force -EA SilentlyContinue
            Pause-Output
        }
        '2' {
            Write-Log "Baixando AME Wizard..."
            $ameUrl = "https://github.com/adrifcastr/AME-Wizard/releases/latest/download/AME.exe"
            $amePath = "$env:TEMP\AME.exe"
            try {
                Start-BitsTransfer -Source $ameUrl -Destination $amePath
                Start-Process -FilePath $amePath
            } catch {
                Write-Err "Falha ao baixar AME Wizard"
            }
            Pause-Output
        }
        '3' {
            Write-Log "Baixando e executando WinAct..."
            $tempScript = "$env:TEMP\winact.ps1"
            try {
                Start-BitsTransfer -Source "https://massgrave.dev/get" -Destination $tempScript
                Invoke-Expression (Get-Content $tempScript -Raw)
                Remove-Item $tempScript -Force -EA SilentlyContinue
            } catch {
                Write-Err "Falha ao executar WinAct"
            }
            Pause-Output
        }
        '4' {
            Write-Log "Baixando o instalador oficial do Spotify..."
            $spotifyExe = "$env:TEMP\SpotifySetup.exe"
            Start-BitsTransfer -Source "https://download.scdn.co/SpotifySetup.exe" -Destination $spotifyExe
            Write-Log "Rodando o instalador..."
            Start-Process -FilePath $spotifyExe -Wait
            Write-Suc "Instalação do Spotify concluída."
            Pause-Output
        }
    }
}

function Menu-Tools {
    Clear-Host
    Write-Host "=== ATALHOS RÁPIDOS ===" -ForegroundColor Cyan
    Write-Host " [1] Gerenciador de Dispositivos (devmgmt)"
    Write-Host " [2] Serviços (services.msc)"
    Write-Host " [3] Gerenciador de Tarefas"
    Write-Host " [4] Editor de Registro (regedit)"
    Write-Host " [5] Painel de Controle"
    Write-Host " [6] Reiniciar Windows Explorer"
    Write-Host " [7] Informações do Sistema"
    Write-Host " [8] Voltar"
    
    $ch = Read-Host "`nSelecione"
    switch($ch) {
        '1' { Start-Process devmgmt.msc }
        '2' { Start-Process services.msc }
        '3' { Start-Process taskmgr }
        '4' { Start-Process regedit }
        '5' { Start-Process control }
        '6' { Stop-Process -Name explorer -Force; Write-Suc "Explorer Reiniciado." ; Pause-Output }
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

# 9. LOOP PRINCIPAL
while ($true) {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "      DEVIL9 - PC ASSISTANT CLI          " -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Softwares (28 Apps)" -ForegroundColor White
    Write-Host " [2] Dependencias (Jogos/Dev)" -ForegroundColor White
    Write-Host " [3] Limpeza e Rede" -ForegroundColor White
    Write-Host " [4] Modulos Premium / ReviOS" -ForegroundColor White
    Write-Host " [5] Utilitarios do Windows" -ForegroundColor White
    Write-Host " [6] Sair" -ForegroundColor Red
    Write-Host ""
    
    $ch = Read-Host "Selecione uma opcao"
    
    switch($ch) {
        '1' { Menu-Installs }
        '2' { Menu-Deps }
        '3' { Menu-Tweaks }
        '4' { Menu-Packs }
        '5' { Menu-Tools }
        '6' { Write-Host "Saindo..."; exit }
    }
}
