param(
    [ValidateSet('Interactive', 'EnsureWinget', 'EnsurePython', 'PrintEnvironmentJson', 'PrintSystemJson', 'PrintDiskJson', 'Library')]
    [string]$Mode = 'Interactive',
    [switch]$RunFromBootstrap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ProgramCatalog = @(
    [pscustomobject]@{ Key='1';  DisplayName='7-Zip';                   WingetId='7zip.7zip';                        ChocoId='7zip';                   Match=@('7-Zip','7zip') }
    [pscustomobject]@{ Key='2';  DisplayName='Audacity';                WingetId='Audacity.Audacity';                ChocoId='audacity';               Match=@('Audacity') }
    [pscustomobject]@{ Key='3';  DisplayName='BCUninstaller';           WingetId='Klocman.BulkCrapUninstaller';      ChocoId='bulk-crap-uninstaller';  Match=@('Bulk Crap Uninstaller','BCUninstaller') }
    [pscustomobject]@{ Key='4';  DisplayName='CPU-Z';                   WingetId='CPUID.CPU-Z';                      ChocoId='cpu-z';                  Match=@('CPU-Z','CPUID') }
    [pscustomobject]@{ Key='5';  DisplayName='CrystalDiskInfo';         WingetId='CrystalDewWorld.CrystalDiskInfo';  ChocoId='crystaldiskinfo';        Match=@('CrystalDiskInfo') }
    [pscustomobject]@{ Key='6';  DisplayName='CrystalDiskMark';         WingetId='CrystalDewWorld.CrystalDiskMark';  ChocoId='crystaldiskmark';        Match=@('CrystalDiskMark') }
    [pscustomobject]@{ Key='7';  DisplayName='Discord';                 WingetId='Discord.Discord';                  ChocoId='discord';                Match=@('Discord') }
    [pscustomobject]@{ Key='8';  DisplayName='Eclipse Temurin JDK 17';  WingetId='EclipseAdoptium.Temurin.17.JDK';   ChocoId='temurin17';              Match=@('Eclipse Temurin','Temurin','AdoptOpenJDK') }
    [pscustomobject]@{ Key='9';  DisplayName='Epic Games Launcher';     WingetId='EpicGames.EpicGamesLauncher';      ChocoId='epicgameslauncher';      Match=@('Epic Games','Epic Launcher') }
    [pscustomobject]@{ Key='10'; DisplayName='GameSave Manager';        WingetId=$null;                              ChocoId=$null;                    Match=@('GameSave Manager'); DirectUrl='https://www.gamesave-manager.com/download.php'; FileName='GSM_Setup.exe'; Arguments='/S' }
    [pscustomobject]@{ Key='11'; DisplayName='Git';                     WingetId='Git.Git';                          ChocoId='git';                    Match=@('Git') }
    [pscustomobject]@{ Key='12'; DisplayName='Hydra Launcher';          WingetId=$null;                              ChocoId=$null;                    Match=@('Hydra','Hydra Launcher'); DirectUrl='https://github.com/hydralauncher/hydra/releases/latest'; FileName='hydra-setup.exe'; Arguments='/S'; GitHubRepo='hydralauncher/hydra'; AssetPattern='*.exe' }
    [pscustomobject]@{ Key='13'; DisplayName='ImageGlass';              WingetId='DuongDieuPhap.ImageGlass';         ChocoId='imageglass';             Match=@('ImageGlass') }
    [pscustomobject]@{ Key='14'; DisplayName='League of Legends';       WingetId=$null;                              ChocoId=$null;                    Match=@('League of Legends','Riot Games'); DirectUrl='https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe'; FileName='Install_LoL.exe'; Arguments='' }
    [pscustomobject]@{ Key='15'; DisplayName='Mozilla Firefox';         WingetId='Mozilla.Firefox';                  ChocoId='firefox';                Match=@('Mozilla Firefox','Firefox') }
    [pscustomobject]@{ Key='16'; DisplayName='mpv (media player)';      WingetId='mpv.net';                          ChocoId='mpv';                    Match=@('mpv','mpv.net') }
    [pscustomobject]@{ Key='17'; DisplayName='Notepad++';               WingetId='Notepad++.Notepad++';              ChocoId='notepadplusplus';        Match=@('Notepad++') }
    [pscustomobject]@{ Key='18'; DisplayName='OBS Studio';              WingetId='OBSProject.OBSStudio';             ChocoId='obs-studio';             Match=@('OBS Studio') }
    [pscustomobject]@{ Key='19'; DisplayName='Obsidian';                WingetId='Obsidian.Obsidian';                ChocoId='obsidian';               Match=@('Obsidian') }
    [pscustomobject]@{ Key='20'; DisplayName='OP.GG';                   WingetId=$null;                              ChocoId=$null;                    Match=@('OP.GG'); DirectUrl='https://op.gg/desktop/download'; FileName='OPGG-Setup.exe'; Arguments='/S' }
    [pscustomobject]@{ Key='21'; DisplayName='Prism Launcher';          WingetId='PrismLauncher.PrismLauncher';      ChocoId='prismlauncher';          Match=@('Prism Launcher','PrismLauncher') }
    [pscustomobject]@{ Key='22'; DisplayName='qBittorrent';             WingetId='qBittorrent.qBittorrent';          ChocoId='qbittorrent';            Match=@('qBittorrent') }
    [pscustomobject]@{ Key='23'; DisplayName='Roblox';                  WingetId='Roblox.Roblox';                    ChocoId=$null;                    Match=@('Roblox') }
    [pscustomobject]@{ Key='24'; DisplayName='RustDesk';                WingetId='RustDesk.RustDesk';                ChocoId='rustdesk';               Match=@('RustDesk') }
    [pscustomobject]@{ Key='25'; DisplayName='ShareX';                  WingetId='ShareX.ShareX';                    ChocoId='sharex';                 Match=@('ShareX') }
    [pscustomobject]@{ Key='26'; DisplayName='Spotify';                 WingetId='Spotify.Spotify';                  ChocoId='spotify';                Match=@('Spotify') }
    [pscustomobject]@{ Key='27'; DisplayName='Steam';                   WingetId='Valve.Steam';                      ChocoId='steam';                  Match=@('Steam') }
    [pscustomobject]@{ Key='28'; DisplayName='Telegram Desktop';        WingetId='Telegram.TelegramDesktop';         ChocoId='telegram';               Match=@('Telegram') }
)

$script:PreferredInstaller = 'winget'  # Options: winget, choco, direct

$script:GameDependencyCatalog = @(
    [pscustomobject]@{
        Key         = '1'
        DisplayName = 'VisualCppRedist AIO (abbodi1406 - TODOS os VC++)'
        Id          = 'vcredist_aio'
        Url         = 'https://github.com/abbodi1406/vcredist/releases/download/v0.103.0/VisualCppRedist_AIO_x86_x64.exe'
        FileName    = 'VisualCppRedist_AIO_x86_x64.exe'
        Arguments   = '/ai /gm2'
        Type        = 'download'
        GitHubRepo  = 'abbodi1406/vcredist'
        AssetName   = 'VisualCppRedist_AIO_x86_x64.exe'
    },
    [pscustomobject]@{
        Key         = '2'
        DisplayName = 'DirectX End-User Runtime (Legacy Components)'
        Id          = 'directx_legacy'
        Url         = 'https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe'
        FileName    = 'dxwebsetup.exe'
        Arguments   = '/Q'
        Type        = 'download'
    },
    [pscustomobject]@{
        Key         = '3'
        DisplayName = 'Microsoft .NET Framework 3.5'
        Id          = 'dotnet_35'
        Type        = 'dism'
        Feature     = 'NetFx3'
    },
    [pscustomobject]@{
        Key         = '4'
        DisplayName = 'Microsoft .NET Desktop Runtime 6'
        Id          = 'dotnet_desktop_6'
        WingetId    = 'Microsoft.DotNet.DesktopRuntime.6'
        Type        = 'winget'
    },
    [pscustomobject]@{
        Key         = '5'
        DisplayName = 'Microsoft .NET Desktop Runtime 8'
        Id          = 'dotnet_desktop_8'
        WingetId    = 'Microsoft.DotNet.DesktopRuntime.8'
        Type        = 'winget'
    },
    [pscustomobject]@{
        Key         = '6'
        DisplayName = 'Microsoft .NET Desktop Runtime 10'
        Id          = 'dotnet_desktop_10'
        WingetId    = 'Microsoft.DotNet.DesktopRuntime.10'
        Type        = 'winget'
    },
    [pscustomobject]@{
        Key         = '7'
        DisplayName = 'XNA Framework Redistributable 4.0'
        Id          = 'xna_40'
        Url         = 'https://download.microsoft.com/download/A/C/2/AC2C903B-E6E8-42C2-9FD7-BEBAC362A930/xnafx40_redist.msi'
        FileName    = 'xnafx40_redist.msi'
        Arguments   = '/quiet /norestart'
        Type        = 'download'
    },
    [pscustomobject]@{
        Key         = '8'
        DisplayName = 'OpenAL Installer'
        Id          = 'openal'
        Url         = 'https://www.openal.org/downloads/oalinst.zip'
        FileName    = 'oalinst.zip'
        InnerExe    = 'oalinst.exe'
        Arguments   = '/SILENT'
        Type        = 'download_zip'
    },
    [pscustomobject]@{
        Key         = '9'
        DisplayName = 'NVIDIA PhysX System Software'
        Id          = 'physx'
        WingetId    = 'Nvidia.PhysX'
        Type        = 'winget'
    }
)

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-WarnText {
    param([string]$Message)
    Write-Host "[AVISO] $Message" -ForegroundColor Yellow
}

function Write-ErrorText {
    param([string]$Message)
    Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Pause-Console {
    [void](Read-Host 'Pressione Enter para continuar')
}

function Pause-BeforeTermination {
    param([string]$Reason)

    if ($RunFromBootstrap -or $Mode -ne 'Interactive') {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
        Write-Host ''
        Write-WarnText $Reason
    }

    Write-Host ''
    [void](Read-Host 'Pressione Enter para fechar')
}

function Read-TrimmedInput {
    param([Parameter(Mandatory = $true)][string]$Prompt)

    $value = Read-Host $Prompt
    if ($null -eq $value) {
        return ''
    }

    return $value.Trim()
}

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-CommandPath {
    param([Parameter(Mandatory = $true)][string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }

    return $command.Source
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Format-Bytes {
    param([UInt64]$Bytes)

    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return ('{0:N2} KB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -lt 1TB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    return ('{0:N2} TB' -f ($Bytes / 1TB))
}

function Get-InstalledSoftwareEntries {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $entries = foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.PSObject.Properties.Name -contains 'DisplayName') -and
                (-not [string]::IsNullOrWhiteSpace([string]$_.DisplayName))
            }
    }

    return @($entries)
}

function Get-CimSafe {
    param([Parameter(Mandatory = $true)][string]$ClassName)

    try {
        return @(Get-CimInstance -ClassName $ClassName -ErrorAction Stop)
    }
    catch {
        return @()
    }
}

function Test-ProgramInstalled {
    param([Parameter(Mandatory = $true)][pscustomobject]$Program)

    foreach ($entry in Get-InstalledSoftwareEntries) {
        $displayName = [string]$entry.DisplayName
        foreach ($pattern in $Program.Match) {
            if ($displayName -like "*$pattern*") {
                return $true
            }
        }
    }

    return $false
}

function Get-ProgramStatus {
    $items = foreach ($program in $script:ProgramCatalog) {
        [pscustomobject]@{
            Key         = $program.Key
            DisplayName = $program.DisplayName
            WingetId    = $program.WingetId
            Installed   = Test-ProgramInstalled -Program $program
        }
    }

    return @($items)
}

function Get-EnvironmentStatus {
    [pscustomobject]@{
        ComputerName   = $env:COMPUTERNAME
        IsAdministrator = Test-IsAdministrator
        PowerShell     = [pscustomobject]@{
            Available = $true
            Version   = $PSVersionTable.PSVersion.ToString()
            Path      = $PSHOME
        }
        Winget         = [pscustomobject]@{
            Available = Test-CommandAvailable -Name 'winget'
            Path      = Get-CommandPath -Name 'winget'
        }
        Python         = [pscustomobject]@{
            Available = Test-CommandAvailable -Name 'python'
            Path      = Get-CommandPath -Name 'python'
        }
        Programs       = Get-ProgramStatus
        GameDependencies = Get-GameDependencyStatus
    }
}

function Get-SystemSummary {
    $cpu = Get-CimSafe -ClassName 'Win32_Processor' |
        Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed

    $gpu = Get-CimSafe -ClassName 'Win32_VideoController' |
        Select-Object Name, DriverVersion, VideoProcessor, AdapterRAM

    $memoryModules = Get-CimSafe -ClassName 'Win32_PhysicalMemory' |
        Select-Object Manufacturer, Capacity, Speed, BankLabel, PartNumber

    $computerSystem = Get-CimSafe -ClassName 'Win32_ComputerSystem' | Select-Object -First 1
    $os = Get-CimSafe -ClassName 'Win32_OperatingSystem' | Select-Object -First 1
    $totalPhysicalMemory = if ($computerSystem -and $computerSystem.PSObject.Properties.Name -contains 'TotalPhysicalMemory' -and $computerSystem.TotalPhysicalMemory) {
        [uint64]$computerSystem.TotalPhysicalMemory
    }
    else {
        [uint64]0
    }

    [pscustomobject]@{
        Cpu    = @($cpu)
        Gpu    = @($gpu)
        Memory = [pscustomobject]@{
            TotalPhysicalMemory = $totalPhysicalMemory
            Modules             = @($memoryModules)
        }
        System = [pscustomobject]@{
            ComputerName    = if ($computerSystem) { $computerSystem.Name } else { $env:COMPUTERNAME }
            Manufacturer    = if ($computerSystem) { $computerSystem.Manufacturer } else { 'Nao informado' }
            Model           = if ($computerSystem) { $computerSystem.Model } else { 'Nao informado' }
            OperatingSystem = if ($os) { $os.Caption } else { 'Windows' }
            Version         = if ($os) { $os.Version } else { 'Nao informado' }
            BuildNumber     = if ($os) { $os.BuildNumber } else { 'Nao informado' }
            Architecture    = if ($os) { $os.OSArchitecture } else { 'Nao informado' }
            LastBoot        = if ($os) { $os.LastBootUpTime } else { 'Nao informado' }
            UserName        = if ($computerSystem) { $computerSystem.UserName } else { $env:USERNAME }
        }
    }
}

function Convert-StatusText {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Array]) {
        $items = @()
        foreach ($item in $Value) {
            if ($null -ne $item) {
                $text = [string]$item
                if (-not [string]::IsNullOrWhiteSpace($text)) {
                    $items += $text.Trim()
                }
            }
        }

        if ($items.Count -eq 0) {
            return $null
        }

        return ($items -join ', ')
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text.Trim()
}

function Get-FirstText {
    param([object[]]$Values)

    foreach ($value in $Values) {
        $text = Convert-StatusText -Value $value
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            return $text
        }
    }

    return $null
}

function Get-ObjectPropertyValue {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-CollectionCount {
    param($Value)

    if ($null -eq $Value) {
        return 0
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return 0
        }

        return 1
    }

    if ($Value -is [System.Collections.ICollection]) {
        return $Value.Count
    }

    return @($Value).Count
}

function Get-ObjectEntries {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return @(
            $Value.GetEnumerator() |
                Where-Object {
                    $null -ne $_.Value -and
                    (-not ($_.Value -is [string] -and [string]::IsNullOrWhiteSpace($_.Value)))
                } |
                Sort-Object Name
        )
    }

    $entries = foreach ($property in $Value.PSObject.Properties) {
        if ($null -ne $property.Value -and (-not ($property.Value -is [string] -and [string]::IsNullOrWhiteSpace($property.Value)))) {
            [pscustomobject]@{
                Name  = $property.Name
                Value = $property.Value
            }
        }
    }

    return @($entries)
}

function Normalize-Token {
    param($Value)

    $text = Convert-StatusText -Value $Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return ''
    }

    return ($text.ToUpperInvariant() -replace '[^A-Z0-9]', '')
}

function New-DiskProbe {
    param(
        $DiskNumber,
        $Serial,
        $Pnp,
        $Name,
        $Size,
        $DevicePath
    )

    return [ordered]@{
        DiskNumber     = $DiskNumber
        Serial         = $Serial
        Pnp            = $Pnp
        Name           = $Name
        Size           = $Size
        DevicePath     = $DevicePath
        SerialNorm     = Normalize-Token $Serial
        PnpNorm        = Normalize-Token $Pnp
        NameNorm       = Normalize-Token $Name
        SizeValue      = $Size
        DevicePathNorm = Normalize-Token $DevicePath
    }
}

function New-DiskDiagnosticRecord {
    param([Parameter(Mandatory = $true)][string]$Key)

    return [ordered]@{
        Key                       = $Key
        Sources                   = @()
        DiskNumber                = $null
        DevicePath                = $null
        FriendlyName              = $null
        Model                     = $null
        SerialNumber              = $null
        PNPDeviceID               = $null
        InterfaceType             = $null
        BusType                   = $null
        MediaType                 = $null
        Size                      = $null
        FirmwareRevision          = $null
        PartitionStyle            = $null
        HealthStatus              = $null
        OperationalStatus         = $null
        PhysicalHealthStatus      = $null
        PhysicalOperationalStatus = $null
        PhysicalCanPool           = $null
        PnpStatus                 = $null
        PnpPresent                = $null
        PnpProblemCode            = $null
        IsOffline                 = $null
        IsReadOnly                = $null
        IsBoot                    = $null
        IsSystem                  = $null
        ProvisioningType          = $null
        Win32Status               = $null
        TemperatureC              = $null
        Reliability               = [ordered]@{}
        Volumes                   = @()
        Findings                  = @()
        SeverityRank              = 0
    }
}

function Add-DiskSource {
    param(
        [System.Collections.IDictionary]$Record,
        [Parameter(Mandatory = $true)][string]$Source
    )

    if ($Record['Sources'] -notcontains $Source) {
        $Record['Sources'] += $Source
    }
}

function Set-DiskRecordIfEmpty {
    param(
        [System.Collections.IDictionary]$Record,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [string] -and [string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    if ($null -eq $Record[$Name] -or ($Record[$Name] -is [string] -and [string]::IsNullOrWhiteSpace([string]$Record[$Name]))) {
        $Record[$Name] = $Value
    }
}

function Get-DiskMatchScore {
    param(
        [System.Collections.IDictionary]$Record,
        [System.Collections.IDictionary]$Probe
    )

    $score = 0

    if ($null -ne $Probe['DiskNumber'] -and $null -ne $Record['DiskNumber']) {
        if ([int]$Probe['DiskNumber'] -eq [int]$Record['DiskNumber']) {
            $score += 100
        }
    }

    $recordDevicePath = Normalize-Token $Record['DevicePath']
    if ($Probe['DevicePathNorm'] -and $recordDevicePath -and $recordDevicePath -eq $Probe['DevicePathNorm']) {
        $score += 95
    }

    $recordPnp = Normalize-Token $Record['PNPDeviceID']
    if ($Probe['PnpNorm'] -and $recordPnp) {
        if ($recordPnp -eq $Probe['PnpNorm']) {
            $score += 90
        }
        elseif ($recordPnp.Contains($Probe['PnpNorm']) -or $Probe['PnpNorm'].Contains($recordPnp)) {
            $score += 70
        }
    }

    $recordSerial = Normalize-Token $Record['SerialNumber']
    if ($Probe['SerialNorm'] -and $recordSerial) {
        if ($recordSerial -eq $Probe['SerialNorm']) {
            $score += 85
        }
        elseif ($recordSerial.Length -ge 6 -and ($recordSerial.Contains($Probe['SerialNorm']) -or $Probe['SerialNorm'].Contains($recordSerial))) {
            $score += 65
        }
    }

    $recordName = Normalize-Token (Get-FirstText @($Record['Model'], $Record['FriendlyName']))
    if ($Probe['NameNorm'] -and $recordName) {
        if ($recordName -eq $Probe['NameNorm']) {
            $score += 45
        }
        elseif ($recordName.Contains($Probe['NameNorm']) -or $Probe['NameNorm'].Contains($recordName)) {
            $score += 30
        }
    }

    if ($null -ne $Probe['SizeValue'] -and $null -ne $Record['Size']) {
        $probeSize = [double]$Probe['SizeValue']
        $recordSize = [double]$Record['Size']
        if ($probeSize -gt 0 -and $recordSize -gt 0) {
            $delta = [math]::Abs($probeSize - $recordSize)
            $maximum = [math]::Max($probeSize, $recordSize)
            if ($maximum -gt 0 -and ($delta / $maximum) -le 0.01) {
                $score += 25
            }
        }
    }

    return $score
}

function Resolve-DiskDiagnosticRecord {
    param(
        [hashtable]$Inventory,
        [System.Collections.IDictionary]$Probe,
        [int]$MinimumScore = 50
    )

    $bestRecord = $null
    $bestScore = $MinimumScore

    foreach ($record in $Inventory.Values) {
        $score = Get-DiskMatchScore -Record $record -Probe $Probe
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestRecord = $record
        }
    }

    return $bestRecord
}

function Ensure-DiskDiagnosticRecord {
    param(
        [hashtable]$Inventory,
        [System.Collections.IDictionary]$Probe,
        [Parameter(Mandatory = $true)][string]$FallbackPrefix
    )

    $record = Resolve-DiskDiagnosticRecord -Inventory $Inventory -Probe $Probe -MinimumScore 40
    if ($null -ne $record) {
        return $record
    }

    if ($null -ne $Probe['DiskNumber']) {
        $key = 'disk-{0}' -f $Probe['DiskNumber']
    }
    elseif ($Probe['SerialNorm']) {
        $key = 'serial-{0}' -f $Probe['SerialNorm']
    }
    elseif ($Probe['PnpNorm']) {
        $prefixLength = [math]::Min($Probe['PnpNorm'].Length, 24)
        $key = 'pnp-{0}' -f $Probe['PnpNorm'].Substring(0, $prefixLength)
    }
    elseif ($Probe['NameNorm']) {
        $prefixLength = [math]::Min($Probe['NameNorm'].Length, 24)
        $key = 'name-{0}' -f $Probe['NameNorm'].Substring(0, $prefixLength)
    }
    else {
        $key = '{0}-{1}' -f $FallbackPrefix, $Inventory.Count
    }

    if (-not $Inventory.Contains($key)) {
        $Inventory[$key] = New-DiskDiagnosticRecord -Key $key
    }

    return $Inventory[$key]
}

function Get-DiskVolumesInfo {
    param([int]$DiskNumber)

    $volumes = @()
    if (-not (Test-CommandAvailable -Name 'Get-Partition')) {
        return $volumes
    }

    try {
        $partitions = @(Get-Partition -DiskNumber $DiskNumber -ErrorAction Stop | Sort-Object PartitionNumber)
    }
    catch {
        return $volumes
    }

    foreach ($partition in $partitions) {
        $partitionNumber = Get-ObjectPropertyValue -InputObject $partition -Name 'PartitionNumber'
        $partitionSize = Get-ObjectPropertyValue -InputObject $partition -Name 'Size'
        $partitionType = Get-FirstText @(
            (Get-ObjectPropertyValue -InputObject $partition -Name 'Type'),
            (Get-ObjectPropertyValue -InputObject $partition -Name 'GptType'),
            (Get-ObjectPropertyValue -InputObject $partition -Name 'MbrType')
        )

        try {
            $volumeObjects = @($partition | Get-Volume -ErrorAction Stop)
        }
        catch {
            $volumeObjects = @()
        }

        if ($volumeObjects.Count -eq 0) {
            $volumes += [ordered]@{
                PartitionNumber = $partitionNumber
                DriveLetter     = $null
                FileSystemLabel = $null
                FileSystem      = $null
                HealthStatus    = $null
                Size            = $partitionSize
                SizeRemaining   = $null
                PartitionType   = $partitionType
            }
            continue
        }

        foreach ($volume in $volumeObjects) {
            $volumes += [ordered]@{
                PartitionNumber = $partitionNumber
                DriveLetter     = Get-ObjectPropertyValue -InputObject $volume -Name 'DriveLetter'
                FileSystemLabel = Get-ObjectPropertyValue -InputObject $volume -Name 'FileSystemLabel'
                FileSystem      = Get-ObjectPropertyValue -InputObject $volume -Name 'FileSystem'
                HealthStatus    = Get-ObjectPropertyValue -InputObject $volume -Name 'HealthStatus'
                Size            = Get-ObjectPropertyValue -InputObject $volume -Name 'Size'
                SizeRemaining   = Get-ObjectPropertyValue -InputObject $volume -Name 'SizeRemaining'
                PartitionType   = $partitionType
            }
        }
    }

    return $volumes
}

function Get-ReliabilitySnapshot {
    param($Counter)

    $snapshot = [ordered]@{}
    if ($null -eq $Counter) {
        return $snapshot
    }

    $candidateProperties = @(
        'Temperature',
        'PowerOnHours',
        'ReadErrorsTotal',
        'WriteErrorsTotal',
        'ReadErrorsUncorrected',
        'WriteErrorsUncorrected',
        'Wear',
        'LoadUnloadCycleCount',
        'StartStopCycleCount',
        'ReallocatedSectors',
        'MediaErrors'
    )

    foreach ($propertyName in $candidateProperties) {
        $value = Get-ObjectPropertyValue -InputObject $Counter -Name $propertyName
        if ($null -ne $value -and ([string]$value).Trim() -ne '') {
            $snapshot[$propertyName] = $value
        }
    }

    return $snapshot
}

function Add-DiskFinding {
    param(
        [System.Collections.IDictionary]$Record,
        [Parameter(Mandatory = $true)][string]$Severity,
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$Recommendation
    )

    foreach ($finding in $Record['Findings']) {
        if ($finding['Code'] -eq $Code) {
            return
        }
    }

    $rank = 0
    switch ($Severity.ToUpperInvariant()) {
        'CRITICO' { $rank = 3 }
        'ALERTA' { $rank = 2 }
        'ATENCAO' { $rank = 1 }
        default { $rank = 0 }
    }

    if ($rank -gt $Record['SeverityRank']) {
        $Record['SeverityRank'] = $rank
    }

    $Record['Findings'] += [ordered]@{
        Severity       = $Severity.ToUpperInvariant()
        Rank           = $rank
        Code           = $Code
        Message        = $Message
        Recommendation = $Recommendation
    }
}

function Analyze-DiskDiagnosticRecord {
    param([System.Collections.IDictionary]$Record)

    $displayName = Get-FirstText @($Record['FriendlyName'], $Record['Model'], $Record['DevicePath'], 'Disco sem nome')
    $sizeValue = if ($null -ne $Record['Size']) { [int64]$Record['Size'] } else { [int64]0 }

    if ($sizeValue -eq 0) {
        Add-DiskFinding -Record $Record -Severity 'INFO' -Code 'NO_MEDIA' -Message ('{0} foi detectado sem midia utilizavel.' -f $displayName) -Recommendation 'Se isso for leitor de cartao vazio ou slot sem disco, pode ignorar.'
        return
    }

    $pnpStatus = Convert-StatusText $Record['PnpStatus']
    if ($pnpStatus -and $pnpStatus -ne 'OK') {
        Add-DiskFinding -Record $Record -Severity 'CRITICO' -Code 'PNP_STATUS' -Message ('O dispositivo esta com status PnP "{0}".' -f $pnpStatus) -Recommendation 'Teste outro cabo/porta, outra case USB, atualize drivers de armazenamento/chipset e confira se a unidade funciona em outra maquina.'
    }

    if (($Record['Sources'] -contains 'Win32_DiskDrive' -or $Record['Sources'] -contains 'Get-PnpDevice') -and $Record['Sources'] -notcontains 'Get-Disk') {
        Add-DiskFinding -Record $Record -Severity 'CRITICO' -Code 'DETECTED_NOT_ENUMERATED' -Message 'O hardware foi detectado, mas o Windows nao conseguiu enumerar a unidade em Get-Disk.' -Recommendation 'Isso combina com disco detectado, mas que nao inicializa no Gerenciamento de Disco. Se houver dados importantes, nao force inicializacao: teste conexao direta SATA/NVMe, outra porta USB/enclosure, outra controladora e outra maquina.'
    }

    $healthText = Get-FirstText @($Record['HealthStatus'], $Record['PhysicalHealthStatus'])
    if ($healthText -match 'Warning') {
        Add-DiskFinding -Record $Record -Severity 'ALERTA' -Code 'HEALTH_WARNING' -Message 'O Windows marcou a saude do disco como Warning.' -Recommendation 'Faca backup, acompanhe a unidade e planeje substituicao se o alerta persistir.'
    }
    elseif ($healthText -match 'Unhealthy|Failed') {
        Add-DiskFinding -Record $Record -Severity 'CRITICO' -Code 'HEALTH_FAILED' -Message 'O Windows marcou a saude do disco como Unhealthy/Failed.' -Recommendation 'Pare de confiar nessa unidade para dados importantes, faca backup ou clonagem imediata e substitua o disco.'
    }

    if ($Record['IsOffline'] -eq $true -or (Convert-StatusText $Record['OperationalStatus']) -match 'Offline') {
        Add-DiskFinding -Record $Record -Severity 'ALERTA' -Code 'OFFLINE' -Message 'O disco esta offline no Windows.' -Recommendation 'Se voce confirmou que e o disco certo e nao ha risco para os dados, tente coloca-lo online com Set-Disk -Number <N> -IsOffline $false ou pelo Gerenciamento de Disco.'
    }

    if ($Record['IsReadOnly'] -eq $true) {
        Add-DiskFinding -Record $Record -Severity 'ATENCAO' -Code 'READ_ONLY' -Message 'O disco esta marcado como somente leitura.' -Recommendation 'Se isso nao for intencional, remova o estado com Set-Disk -Number <N> -IsReadOnly $false ou via diskpart.'
    }

    if ($null -ne $Record['TemperatureC']) {
        $temperature = [double]$Record['TemperatureC']
        if ($temperature -ge 55) {
            Add-DiskFinding -Record $Record -Severity 'CRITICO' -Code 'HIGH_TEMP' -Message ('Temperatura elevada detectada: {0:N0} C.' -f $temperature) -Recommendation 'Melhore fluxo de ar, limpe poeira, verifique dissipador/enclosure e reduza carga pesada ate normalizar.'
        }
        elseif ($temperature -ge 48) {
            Add-DiskFinding -Record $Record -Severity 'ALERTA' -Code 'WARM_TEMP' -Message ('Temperatura acima do ideal: {0:N0} C.' -f $temperature) -Recommendation 'Monitore a unidade e melhore a refrigeracao se ela trabalha frequentemente acima de 48 C.'
        }
    }

    foreach ($counterName in @('ReallocatedSectors', 'MediaErrors', 'ReadErrorsTotal', 'WriteErrorsTotal', 'ReadErrorsUncorrected', 'WriteErrorsUncorrected')) {
        if ($Record['Reliability'].Contains($counterName)) {
            $counterValue = [double]$Record['Reliability'][$counterName]
            if ($counterValue -gt 0) {
                $severity = if ($counterValue -ge 10) { 'CRITICO' } else { 'ALERTA' }
                Add-DiskFinding -Record $Record -Severity $severity -Code ('COUNTER_{0}' -f $counterName.ToUpperInvariant()) -Message ('O contador {0} esta acima de zero: {1}.' -f $counterName, $counterValue) -Recommendation 'Isso indica erro real de comunicacao ou midia. Faca backup, teste cabos/porta/controladora e acompanhe se a contagem cresce.'
            }
        }
    }

    $partitionStyle = Convert-StatusText $Record['PartitionStyle']
    if ($partitionStyle -and ($partitionStyle -eq 'RAW' -or $partitionStyle -eq 'Unknown')) {
        $severity = if ($Record['SeverityRank'] -ge 2) { 'CRITICO' } else { 'ALERTA' }
        Add-DiskFinding -Record $Record -Severity $severity -Code 'RAW_OR_UNKNOWN' -Message ('O disco esta sem tabela de particao utilizavel ({0}).' -f $partitionStyle) -Recommendation 'Se o disco for novo e voce nao precisa preservar dados, inicialize em GPT. Se ha dados importantes ou o Gerenciamento de Disco falha, nao force escrita: teste outra conexao/controladora e considere recuperacao de dados.'
    }

    if ($Record['Volumes'].Count -eq 0 -and $sizeValue -gt 0 -and $partitionStyle -and $partitionStyle -ne 'RAW' -and $partitionStyle -ne 'Unknown') {
        Add-DiskFinding -Record $Record -Severity 'ATENCAO' -Code 'NO_VOLUMES' -Message 'O disco nao apresentou volumes montados.' -Recommendation 'Verifique particoes, letras de unidade, integridade do sistema de arquivos e se o volume esta oculto ou sem letra.'
    }

    foreach ($volume in $Record['Volumes']) {
        $volumeSize = $volume['Size']
        $remaining = $volume['SizeRemaining']
        if ($null -ne $volumeSize -and $null -ne $remaining -and [double]$volumeSize -gt 0) {
            $freePercent = ([double]$remaining / [double]$volumeSize) * 100
            if ($freePercent -lt 5) {
                Add-DiskFinding -Record $Record -Severity 'ALERTA' -Code ('LOW_FREE_{0}' -f $volume['PartitionNumber']) -Message ('Um volume deste disco esta com espaco livre criticamente baixo ({0:N1}%%).' -f $freePercent) -Recommendation 'Libere espaco para evitar queda de desempenho e falhas em jogos, atualizacoes, cache e arquivos temporarios.'
            }
            elseif ($freePercent -lt 10) {
                Add-DiskFinding -Record $Record -Severity 'ATENCAO' -Code ('LOW_FREE_WARN_{0}' -f $volume['PartitionNumber']) -Message ('Um volume deste disco esta com pouco espaco livre ({0:N1}%%).' -f $freePercent) -Recommendation 'Planeje limpeza de espaco ou expansao de capacidade para evitar gargalos.'
            }
        }

        $volumeHealth = Convert-StatusText $volume['HealthStatus']
        if ($volumeHealth -and $volumeHealth -ne 'Healthy') {
            Add-DiskFinding -Record $Record -Severity 'ALERTA' -Code ('VOL_HEALTH_{0}' -f $volume['PartitionNumber']) -Message ('Um volume foi marcado com saude "{0}".' -f $volumeHealth) -Recommendation 'Verifique integridade do sistema de arquivos, logs NTFS/ReFS e execute checagens adequadas se o volume estiver acessivel.'
        }
    }
}

function Get-DiskDiagnosticsReport {
    $notes = @()
    $inventory = @{}

    $win32Disks = @(Get-CimSafe -ClassName 'Win32_DiskDrive')
    if ($win32Disks.Count -eq 0) {
        $notes += 'Win32_DiskDrive nao retornou unidades ou foi bloqueado neste contexto.'
    }

    foreach ($disk in $win32Disks) {
        $probe = New-DiskProbe -DiskNumber (Get-ObjectPropertyValue -InputObject $disk -Name 'Index') -Serial (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber') -Pnp (Get-ObjectPropertyValue -InputObject $disk -Name 'PNPDeviceID') -Name (Get-FirstText @((Get-ObjectPropertyValue -InputObject $disk -Name 'Model'), (Get-ObjectPropertyValue -InputObject $disk -Name 'Caption'))) -Size (Get-ObjectPropertyValue -InputObject $disk -Name 'Size') -DevicePath (Get-ObjectPropertyValue -InputObject $disk -Name 'DeviceID')
        $record = Ensure-DiskDiagnosticRecord -Inventory $inventory -Probe $probe -FallbackPrefix 'win32'
        Add-DiskSource -Record $record -Source 'Win32_DiskDrive'
        Set-DiskRecordIfEmpty -Record $record -Name 'DiskNumber' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Index')
        Set-DiskRecordIfEmpty -Record $record -Name 'DevicePath' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'DeviceID')
        Set-DiskRecordIfEmpty -Record $record -Name 'Model' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Model')
        Set-DiskRecordIfEmpty -Record $record -Name 'SerialNumber' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber')
        Set-DiskRecordIfEmpty -Record $record -Name 'PNPDeviceID' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'PNPDeviceID')
        Set-DiskRecordIfEmpty -Record $record -Name 'InterfaceType' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'InterfaceType')
        Set-DiskRecordIfEmpty -Record $record -Name 'FirmwareRevision' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'FirmwareRevision')
        Set-DiskRecordIfEmpty -Record $record -Name 'Size' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Size')
        Set-DiskRecordIfEmpty -Record $record -Name 'Win32Status' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Status')
    }

    if (Test-CommandAvailable -Name 'Get-Disk') {
        try {
            $storageDisks = @(Get-Disk -ErrorAction Stop)
        }
        catch {
            $storageDisks = @()
            $notes += ('Get-Disk falhou: {0}' -f $_.Exception.Message)
        }

        foreach ($disk in $storageDisks) {
            $probe = New-DiskProbe -DiskNumber (Get-ObjectPropertyValue -InputObject $disk -Name 'Number') -Serial (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber') -Pnp $null -Name (Get-ObjectPropertyValue -InputObject $disk -Name 'FriendlyName') -Size (Get-ObjectPropertyValue -InputObject $disk -Name 'Size') -DevicePath (Get-ObjectPropertyValue -InputObject $disk -Name 'Path')
            $record = Ensure-DiskDiagnosticRecord -Inventory $inventory -Probe $probe -FallbackPrefix 'disk'
            Add-DiskSource -Record $record -Source 'Get-Disk'
            $diskNumber = Get-ObjectPropertyValue -InputObject $disk -Name 'Number'
            Set-DiskRecordIfEmpty -Record $record -Name 'DiskNumber' -Value $diskNumber
            Set-DiskRecordIfEmpty -Record $record -Name 'DevicePath' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Path')
            Set-DiskRecordIfEmpty -Record $record -Name 'FriendlyName' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'FriendlyName')
            Set-DiskRecordIfEmpty -Record $record -Name 'SerialNumber' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber')
            Set-DiskRecordIfEmpty -Record $record -Name 'BusType' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'BusType')
            Set-DiskRecordIfEmpty -Record $record -Name 'PartitionStyle' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'PartitionStyle')
            Set-DiskRecordIfEmpty -Record $record -Name 'HealthStatus' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'HealthStatus')
            Set-DiskRecordIfEmpty -Record $record -Name 'OperationalStatus' -Value (Convert-StatusText (Get-ObjectPropertyValue -InputObject $disk -Name 'OperationalStatus'))
            Set-DiskRecordIfEmpty -Record $record -Name 'ProvisioningType' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'ProvisioningType')
            Set-DiskRecordIfEmpty -Record $record -Name 'IsOffline' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'IsOffline')
            Set-DiskRecordIfEmpty -Record $record -Name 'IsReadOnly' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'IsReadOnly')
            Set-DiskRecordIfEmpty -Record $record -Name 'IsBoot' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'IsBoot')
            Set-DiskRecordIfEmpty -Record $record -Name 'IsSystem' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'IsSystem')
            Set-DiskRecordIfEmpty -Record $record -Name 'Size' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Size')
            if ($null -ne $diskNumber) {
                $record['Volumes'] = @(Get-DiskVolumesInfo -DiskNumber ([int]$diskNumber))
            }
        }
    }
    else {
        $notes += 'Get-Disk nao esta disponivel neste Windows/PowerShell.'
    }

    if (Test-CommandAvailable -Name 'Get-PhysicalDisk') {
        try {
            $physicalDisks = @(Get-PhysicalDisk -ErrorAction Stop)
        }
        catch {
            $physicalDisks = @()
            $notes += ('Get-PhysicalDisk falhou: {0}' -f $_.Exception.Message)
        }

        foreach ($disk in $physicalDisks) {
            $probe = New-DiskProbe -DiskNumber $null -Serial (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber') -Pnp $null -Name (Get-ObjectPropertyValue -InputObject $disk -Name 'FriendlyName') -Size (Get-ObjectPropertyValue -InputObject $disk -Name 'Size') -DevicePath $null
            $record = Ensure-DiskDiagnosticRecord -Inventory $inventory -Probe $probe -FallbackPrefix 'physical'
            Add-DiskSource -Record $record -Source 'Get-PhysicalDisk'
            Set-DiskRecordIfEmpty -Record $record -Name 'FriendlyName' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'FriendlyName')
            Set-DiskRecordIfEmpty -Record $record -Name 'SerialNumber' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'SerialNumber')
            Set-DiskRecordIfEmpty -Record $record -Name 'BusType' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'BusType')
            Set-DiskRecordIfEmpty -Record $record -Name 'MediaType' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'MediaType')
            Set-DiskRecordIfEmpty -Record $record -Name 'Size' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'Size')
            Set-DiskRecordIfEmpty -Record $record -Name 'PhysicalHealthStatus' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'HealthStatus')
            Set-DiskRecordIfEmpty -Record $record -Name 'PhysicalOperationalStatus' -Value (Convert-StatusText (Get-ObjectPropertyValue -InputObject $disk -Name 'OperationalStatus'))
            Set-DiskRecordIfEmpty -Record $record -Name 'PhysicalCanPool' -Value (Get-ObjectPropertyValue -InputObject $disk -Name 'CanPool')

            if (Test-CommandAvailable -Name 'Get-StorageReliabilityCounter') {
                try {
                    $counter = $disk | Get-StorageReliabilityCounter -ErrorAction Stop
                    $record['Reliability'] = Get-ReliabilitySnapshot -Counter $counter
                    if ($record['Reliability'].Contains('Temperature')) {
                        $record['TemperatureC'] = [double]$record['Reliability']['Temperature']
                    }
                }
                catch {
                }
            }
        }
    }
    else {
        $notes += 'Get-PhysicalDisk nao esta disponivel neste Windows/PowerShell.'
    }

    if (Test-CommandAvailable -Name 'Get-PnpDevice') {
        try {
            $pnpDisks = @(Get-PnpDevice -Class DiskDrive -PresentOnly -ErrorAction Stop)
        }
        catch {
            $pnpDisks = @()
            $notes += ('Get-PnpDevice falhou: {0}' -f $_.Exception.Message)
        }

        foreach ($device in $pnpDisks) {
            $probe = New-DiskProbe -DiskNumber $null -Serial $null -Pnp (Get-ObjectPropertyValue -InputObject $device -Name 'InstanceId') -Name (Get-ObjectPropertyValue -InputObject $device -Name 'FriendlyName') -Size $null -DevicePath (Get-ObjectPropertyValue -InputObject $device -Name 'InstanceId')
            $record = Ensure-DiskDiagnosticRecord -Inventory $inventory -Probe $probe -FallbackPrefix 'pnp'
            Add-DiskSource -Record $record -Source 'Get-PnpDevice'
            Set-DiskRecordIfEmpty -Record $record -Name 'FriendlyName' -Value (Get-ObjectPropertyValue -InputObject $device -Name 'FriendlyName')
            Set-DiskRecordIfEmpty -Record $record -Name 'PNPDeviceID' -Value (Get-ObjectPropertyValue -InputObject $device -Name 'InstanceId')
            Set-DiskRecordIfEmpty -Record $record -Name 'PnpStatus' -Value (Get-ObjectPropertyValue -InputObject $device -Name 'Status')
            Set-DiskRecordIfEmpty -Record $record -Name 'PnpPresent' -Value (Get-ObjectPropertyValue -InputObject $device -Name 'Present')
            Set-DiskRecordIfEmpty -Record $record -Name 'PnpProblemCode' -Value (Get-ObjectPropertyValue -InputObject $device -Name 'ProblemCode')
        }
    }
    else {
        $notes += 'Get-PnpDevice nao esta disponivel neste Windows/PowerShell.'
    }

    $records = @($inventory.Values)
    foreach ($record in $records) {
        Analyze-DiskDiagnosticRecord -Record $record
    }

    $sortedRecords = @(
        $records | Sort-Object @{
            Expression = {
                if ($null -ne $_['DiskNumber']) { [int]$_['DiskNumber'] } else { 9999 }
            }
        }, @{
            Expression = {
                Get-FirstText @($_['FriendlyName'], $_['Model'], $_['DevicePath'], $_['Key'])
            }
        }
    )

    return [pscustomobject]@{
        GeneratedAt     = Get-Date
        IsAdministrator = Test-IsAdministrator
        Notes           = @($notes)
        Disks           = @($sortedRecords | ForEach-Object { [pscustomobject]$_ })
    }
}

function Get-DiskSeverityLabel {
    param([int]$Rank)

    switch ($Rank) {
        3 { return 'CRITICO' }
        2 { return 'ALERTA' }
        1 { return 'ATENCAO' }
        default { return 'OK' }
    }
}

function Get-DiskSeverityColor {
    param([int]$Rank)

    switch ($Rank) {
        3 { return 'Red' }
        2 { return 'Yellow' }
        1 { return 'DarkYellow' }
        default { return 'Green' }
    }
}

function Show-DiskDiagnostics {
    Clear-Host
    Write-Host '=====================================' -ForegroundColor DarkCyan
    Write-Host ' Diagnostico de Discos e SSDs' -ForegroundColor DarkCyan
    Write-Host '=====================================' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host 'Coletando informacoes do armazenamento...'
    Write-Host ''

    $report = Get-DiskDiagnosticsReport
    if ($report.Disks.Count -eq 0) {
        Write-WarnText 'Nenhuma unidade foi retornada pelas fontes disponiveis.'
        foreach ($note in $report.Notes) {
            Write-WarnText $note
        }
        Pause-Console
        return
    }

    Write-Host ("Administrador: {0}" -f $(if ($report.IsAdministrator) { 'SIM' } else { 'NAO' })) -ForegroundColor Gray
    if ($report.Notes.Count -gt 0) {
        Write-Host 'Observacoes da coleta:' -ForegroundColor Yellow
        foreach ($note in $report.Notes) {
            Write-Host ("- {0}" -f $note)
        }
        Write-Host ''
    }

    foreach ($disk in $report.Disks) {
        $displayName = Get-FirstText @($disk.FriendlyName, $disk.Model, $disk.DevicePath, 'Disco sem nome')
        $severity = Get-DiskSeverityLabel -Rank $disk.SeverityRank
        $color = Get-DiskSeverityColor -Rank $disk.SeverityRank
        $diskNumberLabel = if ($null -ne $disk.DiskNumber) { $disk.DiskNumber } else { 'n/d' }
        $sizeBytes = if ($null -ne $disk.Size) { [uint64][int64]$disk.Size } else { [uint64]0 }
        $temperatureLabel = if ($null -ne $disk.TemperatureC) { ('{0:N0} C' -f [double]$disk.TemperatureC) } else { 'n/d' }
        $healthLabel = Get-FirstText @($disk.HealthStatus, $disk.PhysicalHealthStatus, $disk.Win32Status, 'n/d')
        $operationalLabel = Get-FirstText @($disk.OperationalStatus, $disk.PhysicalOperationalStatus, 'n/d')
        $offlineLabel = if ($null -eq $disk.IsOffline) { 'n/d' } elseif ($disk.IsOffline -eq $true) { 'SIM' } else { 'NAO' }
        $readOnlyLabel = if ($null -eq $disk.IsReadOnly) { 'n/d' } elseif ($disk.IsReadOnly -eq $true) { 'SIM' } else { 'NAO' }
        $sourcesLabel = if ((Get-CollectionCount -Value $disk.Sources) -gt 0) { (@($disk.Sources) -join ', ') } else { 'n/d' }

        Write-Host ('------------------------------------------------------------') -ForegroundColor DarkGray
        Write-Host ("Disco {0} | {1} | {2}" -f $diskNumberLabel, $displayName, $severity) -ForegroundColor $color
        Write-Host ("Tamanho: {0}" -f (Format-Bytes -Bytes $sizeBytes))
        Write-Host ("Modelo / Nome amigavel: {0} / {1}" -f (Get-FirstText @($disk.Model, 'n/d')), (Get-FirstText @($disk.FriendlyName, 'n/d')))
        Write-Host ("Serial / Firmware: {0} / {1}" -f (Get-FirstText @($disk.SerialNumber, 'n/d')), (Get-FirstText @($disk.FirmwareRevision, 'n/d')))
        Write-Host ("Barramento/Interface: {0} / {1}" -f (Get-FirstText @($disk.BusType, 'n/d')), (Get-FirstText @($disk.InterfaceType, 'n/d')))
        Write-Host ("Tipo de midia: {0}" -f (Get-FirstText @($disk.MediaType, 'n/d')))
        Write-Host ("Temperatura: {0}" -f $temperatureLabel)
        Write-Host ("Saude: {0}" -f $healthLabel)
        Write-Host ("Estado operacional: {0}" -f $operationalLabel)
        Write-Host ("Particionamento: {0}" -f (Get-FirstText @($disk.PartitionStyle, 'n/d')))
        Write-Host ("Offline / Somente leitura: {0} / {1}" -f $offlineLabel, $readOnlyLabel)
        Write-Host ("PnP: {0}" -f (Get-FirstText @($disk.PNPDeviceID, 'n/d')))
        Write-Host ("Fontes: {0}" -f $sourcesLabel)

        if ((Get-CollectionCount -Value $disk.Volumes) -gt 0) {
            Write-Host 'Volumes:' -ForegroundColor Yellow
            foreach ($volume in @($disk.Volumes)) {
                $drive = if ($volume['DriveLetter']) { ('{0}:' -f $volume['DriveLetter']) } else { 'sem letra' }
                $label = Get-FirstText @($volume['FileSystemLabel'], 'sem rotulo')
                $fs = Get-FirstText @($volume['FileSystem'], 'n/d')
                $remaining = if ($null -ne $volume['SizeRemaining']) { Format-Bytes -Bytes ([uint64][int64]$volume['SizeRemaining']) } else { 'n/d' }
                $total = if ($null -ne $volume['Size']) { Format-Bytes -Bytes ([uint64][int64]$volume['Size']) } else { 'n/d' }
                $usage = 'n/d'
                if ($null -ne $volume['Size'] -and $null -ne $volume['SizeRemaining'] -and [double]$volume['Size'] -gt 0) {
                    $usedPercent = 100 - (([double]$volume['SizeRemaining'] / [double]$volume['Size']) * 100)
                    $usage = ('{0:N1}%% usado' -f $usedPercent)
                }

                Write-Host ("- {0} | {1} | {2} | livre {3} de {4} | {5}" -f $drive, $label, $fs, $remaining, $total, $usage)
            }
        }
        else {
            Write-Host 'Volumes: nenhum volume montado ou a consulta nao retornou volumes.'
        }

        $reliabilityEntries = @(Get-ObjectEntries -Value $disk.Reliability)
        if ($reliabilityEntries.Count -gt 0) {
            Write-Host 'Confiabilidade:' -ForegroundColor Yellow
            foreach ($property in $reliabilityEntries) {
                Write-Host ("- {0}: {1}" -f $property.Name, $property.Value)
            }
        }

        if ((Get-CollectionCount -Value $disk.Findings) -gt 0) {
            Write-Host 'Analise e sugestoes:' -ForegroundColor Yellow
            foreach ($finding in @($disk.Findings)) {
                $findingColor = Get-DiskSeverityColor -Rank $finding['Rank']
                Write-Host ("- [{0}] {1}" -f $finding['Severity'], $finding['Message']) -ForegroundColor $findingColor
                Write-Host ("  Solucao provavel: {0}" -f $finding['Recommendation'])
            }
        }
        else {
            Write-Host 'Analise e sugestoes: nenhum problema relevante detectado.' -ForegroundColor Green
        }

        Write-Host ''
    }

    Pause-Console
}

function Test-VcRuntimeInstalled {
    param([Parameter(Mandatory = $true)][ValidateSet('x64', 'x86')][string]$Architecture)

    $registryPath = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$Architecture"
    $runtime = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
    if ($null -eq $runtime) {
        return $false
    }

    return ($runtime.Installed -eq 1)
}

function Test-DirectXLegacyInstalled {
    $requiredFiles = @(
        'd3dx9_43.dll',
        'd3dx10_43.dll',
        'd3dx11_43.dll',
        'd3dcompiler_43.dll',
        'xinput1_3.dll',
        'XAudio2_7.dll'
    )

    $paths = @('C:\Windows\System32')
    if ([Environment]::Is64BitOperatingSystem) {
        $paths += 'C:\Windows\SysWOW64'
    }

    foreach ($path in $paths) {
        foreach ($file in $requiredFiles) {
            if (-not (Test-Path -LiteralPath (Join-Path $path $file))) {
                return $false
            }
        }
    }

    return $true
}

function Test-DotNetDesktopRuntimeInstalled {
    param([Parameter(Mandatory = $true)][string]$MajorVersion)

    if (-not (Test-CommandAvailable -Name 'dotnet')) {
        return $false
    }

    try {
        $runtimes = & dotnet --list-runtimes 2>$null
        return [bool]($runtimes | Where-Object { $_ -match ('^Microsoft\.WindowsDesktop\.App {0}\.' -f [regex]::Escape($MajorVersion)) })
    }
    catch {
        return $false
    }
}

function Test-DotNet35Installed {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -ErrorAction Stop
        return ($feature.State -eq 'Enabled')
    }
    catch {
        $key = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5' -ErrorAction SilentlyContinue
        return ($null -ne $key -and $key.Install -eq 1)
    }
}

function Test-XnaInstalled {
    foreach ($entry in Get-InstalledSoftwareEntries) {
        if ([string]$entry.DisplayName -match 'XNA Framework.*4\.0') {
            return $true
        }
    }
    return $false
}

function Test-OpenAlInstalled {
    return (Test-Path -LiteralPath 'C:\Windows\System32\OpenAL32.dll')
}

function Test-VcRedistAioInstalled {
    return (Test-VcRuntimeInstalled -Architecture 'x64') -and (Test-VcRuntimeInstalled -Architecture 'x86')
}

function Test-GameDependencyInstalled {
    param([Parameter(Mandatory = $true)][pscustomobject]$Dependency)

    switch ($Dependency.Id) {
        'vcredist_aio'     { return Test-VcRedistAioInstalled }
        'directx_legacy'   { return Test-DirectXLegacyInstalled }
        'dotnet_35'        { return Test-DotNet35Installed }
        'dotnet_desktop_6' { return Test-DotNetDesktopRuntimeInstalled -MajorVersion '6' }
        'dotnet_desktop_8' { return Test-DotNetDesktopRuntimeInstalled -MajorVersion '8' }
        'dotnet_desktop_10'{ return Test-DotNetDesktopRuntimeInstalled -MajorVersion '10' }
        'xna_40'           { return Test-XnaInstalled }
        'openal'           { return Test-OpenAlInstalled }
        'physx' {
            foreach ($entry in Get-InstalledSoftwareEntries) {
                if ([string]$entry.DisplayName -match 'NVIDIA PhysX') { return $true }
            }
            return $false
        }
        default { return $false }
    }
}

function Get-GameDependencyStatus {
    $items = foreach ($dependency in $script:GameDependencyCatalog) {
        [pscustomobject]@{
            Key         = $dependency.Key
            DisplayName = $dependency.DisplayName
            Id          = $dependency.Id
            Installed   = Test-GameDependencyInstalled -Dependency $dependency
        }
    }

    return @($items)
}

function Invoke-DownloadedInstaller {
    param([Parameter(Mandatory = $true)][pscustomobject]$Dependency)

    $downloadDirectory = Join-Path $env:TEMP 'AssistentePC\downloads'
    $installerPath = Join-Path $downloadDirectory $Dependency.FileName
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

    try {
        Write-Info ("Baixando {0}..." -f $Dependency.DisplayName)
        Invoke-WebRequest -Uri $Dependency.Url -OutFile $installerPath -UseBasicParsing
        Write-Info ("Instalando {0}..." -f $Dependency.DisplayName)

        if ($installerPath -match '\.msi$') {
            $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList ('/i', "`"$installerPath`"", $Dependency.Arguments) -Wait -PassThru
        }
        else {
            $process = Start-Process -FilePath $installerPath -ArgumentList $Dependency.Arguments -Wait -PassThru
        }

        if ($process.ExitCode -in @(0, 1638, 3010)) {
            if ($process.ExitCode -eq 3010) {
                Write-WarnText 'Instalacao concluida, mas um reinicio pode ser necessario.'
            }
            return $true
        }

        Write-WarnText ("Instalador retornou codigo {0}." -f $process.ExitCode)
        return $false
    }
    catch {
        Write-ErrorText ("Falha na instalacao de {0}: {1}" -f $Dependency.DisplayName, $_.Exception.Message)
        return $false
    }
    finally {
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-DownloadedZipInstaller {
    param([Parameter(Mandatory = $true)][pscustomobject]$Dependency)

    $downloadDirectory = Join-Path $env:TEMP 'AssistentePC\downloads'
    $zipPath = Join-Path $downloadDirectory $Dependency.FileName
    $extractDir = Join-Path $downloadDirectory ($Dependency.Id + '_extracted')
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

    try {
        Write-Info ("Baixando {0}..." -f $Dependency.DisplayName)
        Invoke-WebRequest -Uri $Dependency.Url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
        $innerExePath = Join-Path $extractDir $Dependency.InnerExe
        if (-not (Test-Path -LiteralPath $innerExePath)) {
            $found = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter $Dependency.InnerExe | Select-Object -First 1
            if ($null -eq $found) {
                Write-ErrorText "Arquivo interno nao encontrado no ZIP."
                return $false
            }
            $innerExePath = $found.FullName
        }
        Write-Info ("Instalando {0}..." -f $Dependency.DisplayName)
        $process = Start-Process -FilePath $innerExePath -ArgumentList $Dependency.Arguments -Wait -PassThru
        return ($process.ExitCode -eq 0)
    }
    catch {
        Write-ErrorText ("Falha: {0}" -f $_.Exception.Message)
        return $false
    }
    finally {
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-GameDependency {
    param([Parameter(Mandatory = $true)][pscustomobject]$Dependency)

    if (Test-GameDependencyInstalled -Dependency $Dependency) {
        Write-WarnText ("{0} ja esta presente. Nao vou reinstalar." -f $Dependency.DisplayName)
        return
    }

    switch ($Dependency.Type) {
        'download' {
            $result = Invoke-DownloadedInstaller -Dependency $Dependency
            if ($result -and (Test-GameDependencyInstalled -Dependency $Dependency)) {
                Write-Success ("{0} instalado com sucesso." -f $Dependency.DisplayName)
            }
            elseif ($result) {
                Write-WarnText ("A instalacao foi executada, mas nao consegui confirmar {0} ainda." -f $Dependency.DisplayName)
            }
        }
        'download_zip' {
            $result = Invoke-DownloadedZipInstaller -Dependency $Dependency
            if ($result) {
                Write-Success ("{0} instalado com sucesso." -f $Dependency.DisplayName)
            }
        }
        'dism' {
            if (-not (Test-IsAdministrator)) {
                Write-WarnText 'Esta dependencia requer execucao como administrador (DISM).'
                return
            }
            Write-Info ("Habilitando {0} via DISM..." -f $Dependency.DisplayName)
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName $Dependency.Feature -All -NoRestart -ErrorAction Stop | Out-Null
                Write-Success ("{0} habilitado com sucesso." -f $Dependency.DisplayName)
            }
            catch {
                Write-ErrorText ("Falha ao habilitar {0}: {1}" -f $Dependency.DisplayName, $_.Exception.Message)
            }
        }
        'winget' {
            if (-not (Test-CommandAvailable -Name 'winget')) {
                Write-WarnText 'Winget nao encontrado para instalar esta dependencia.'
                if (-not (Install-WingetFromOfficialSource)) {
                    return
                }
            }

            Write-Info ("Instalando {0} via winget..." -f $Dependency.DisplayName)
            & winget install --id $Dependency.WingetId -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Success ("{0} instalado com sucesso." -f $Dependency.DisplayName)
            }
            else {
                Write-WarnText ("Winget retornou codigo {0} ao instalar {1}." -f $LASTEXITCODE, $Dependency.DisplayName)
            }
        }
    }
}

function Show-GameDependenciesMenu {
    do {
        Clear-Host
        Write-Host '========================================' -ForegroundColor DarkCyan
        Write-Host ' Dependencias Completas para Jogos' -ForegroundColor DarkCyan
        Write-Host '========================================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host 'Pack completo: VC++ AIO (2005-2026), DirectX, .NET, XNA, OpenAL, PhysX.'
        Write-Host 'Dica: execute como administrador para melhorar a compatibilidade.'
        Write-Host ''

        $status = Get-GameDependencyStatus
        foreach ($dependency in $status) {
            $state = if ($dependency.Installed) { 'INSTALADO' } else { 'NAO INSTALADO' }
            $color = if ($dependency.Installed) { 'Green' } else { 'Yellow' }
            Write-Host ("{0,2}. {1} [{2}]" -f $dependency.Key, $dependency.DisplayName, $state) -ForegroundColor $color
        }

        $totalDeps = $script:GameDependencyCatalog.Count
        Write-Host ''
        Write-Host ('{0}. Instalar pacote gamer essencial (VC++ AIO + DirectX + .NET)' -f ($totalDeps + 1))
        Write-Host ('{0}. Instalar TUDO que estiver faltando' -f ($totalDeps + 2))
        Write-Host ('{0}. Voltar' -f ($totalDeps + 3))
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        $choiceInt = 0
        if ([int]::TryParse($choice, [ref]$choiceInt)) {
            if ($choiceInt -ge 1 -and $choiceInt -le $totalDeps) {
                Install-GameDependency -Dependency $script:GameDependencyCatalog[$choiceInt - 1]
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalDeps + 1)) {
                $essentialIds = @('vcredist_aio', 'directx_legacy', 'dotnet_35', 'dotnet_desktop_8', 'dotnet_desktop_10')
                foreach ($dependency in $script:GameDependencyCatalog) {
                    if ($dependency.Id -in $essentialIds -and -not (Test-GameDependencyInstalled -Dependency $dependency)) {
                        Install-GameDependency -Dependency $dependency
                    }
                }
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalDeps + 2)) {
                foreach ($dependency in $script:GameDependencyCatalog) {
                    if (-not (Test-GameDependencyInstalled -Dependency $dependency)) {
                        Install-GameDependency -Dependency $dependency
                    }
                }
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalDeps + 3)) {
                return
            }
            else {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
        else {
            Write-WarnText 'Opcao invalida.'
            Start-Sleep -Seconds 1
        }
    } while ($true)
}

function Get-PythonSummaryText {
    $pythonPath = Get-CommandPath -Name 'python'
    $helperPath = Join-Path $PSScriptRoot 'helpers\resumo_hardware.py'

    if ([string]::IsNullOrWhiteSpace($pythonPath) -or -not (Test-Path -LiteralPath $helperPath)) {
        return $null
    }

    $tempDirectory = Join-Path $env:TEMP 'AssistentePC'
    $tempFile = Join-Path $tempDirectory 'hardware_summary.json'

    try {
        New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null
        Get-SystemSummary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $tempFile -Encoding UTF8
        $output = & $pythonPath $helperPath $tempFile 2>$null
        if ($LASTEXITCODE -eq 0 -and $output) {
            return ($output -join [Environment]::NewLine)
        }
    }
    catch {
        return $null
    }
    finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }

    return $null
}

function Show-SystemOverview {
    Clear-Host
    Write-Host '==========================================' -ForegroundColor DarkCyan
    Write-Host ' Assistente do PC - Diagnostico do Sistema' -ForegroundColor DarkCyan
    Write-Host '==========================================' -ForegroundColor DarkCyan
    Write-Host ''

    $pythonSummary = Get-PythonSummaryText
    if (-not [string]::IsNullOrWhiteSpace($pythonSummary)) {
        Write-Host $pythonSummary -ForegroundColor White
        Write-Host ''
    }

    $summary = Get-SystemSummary

    Write-Host 'CPU' -ForegroundColor Yellow
    foreach ($item in $summary.Cpu) {
        Write-Host ("- {0}" -f $item.Name)
        Write-Host ("  Fabricante: {0}" -f $item.Manufacturer)
        Write-Host ("  Nucleos/Threads: {0}/{1}" -f $item.NumberOfCores, $item.NumberOfLogicalProcessors)
        Write-Host ("  Clock maximo: {0} MHz" -f $item.MaxClockSpeed)
    }

    Write-Host ''
    Write-Host 'GPU' -ForegroundColor Yellow
    foreach ($item in $summary.Gpu) {
        $gpuRam = if ($item.AdapterRAM) { Format-Bytes -Bytes ([uint64]$item.AdapterRAM) } else { 'Nao informado' }
        Write-Host ("- {0}" -f $item.Name)
        Write-Host ("  Processador de video: {0}" -f $item.VideoProcessor)
        Write-Host ("  VRAM estimada: {0}" -f $gpuRam)
        Write-Host ("  Driver: {0}" -f $item.DriverVersion)
    }

    Write-Host ''
    Write-Host 'RAM' -ForegroundColor Yellow
    Write-Host ("- Total: {0}" -f (Format-Bytes -Bytes $summary.Memory.TotalPhysicalMemory))
    foreach ($module in $summary.Memory.Modules) {
        Write-Host ("  Modulo: {0} | {1} | {2} | {3} MHz" -f $module.BankLabel, (Format-Bytes -Bytes ([uint64]$module.Capacity)), $module.Manufacturer, $module.Speed)
    }

    Write-Host ''
    Write-Host 'Sistema' -ForegroundColor Yellow
    Write-Host ("- Computador: {0}" -f $summary.System.ComputerName)
    Write-Host ("- Fabricante/Modelo: {0} / {1}" -f $summary.System.Manufacturer, $summary.System.Model)
    Write-Host ("- Windows: {0}" -f $summary.System.OperatingSystem)
    Write-Host ("- Versao/Build: {0} / {1}" -f $summary.System.Version, $summary.System.BuildNumber)
    Write-Host ("- Arquitetura: {0}" -f $summary.System.Architecture)
    Write-Host ("- Ultimo boot: {0}" -f $summary.System.LastBoot)
    Write-Host ''

    Pause-Console
}

function Get-DirectorySize {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [uint64]0
    }

    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum

    if ($null -eq $sum) {
        return [uint64]0
    }

    return [uint64]$sum
}

function Clear-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RequireAdministrator
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Path       = $Path
            Success    = $false
            FreedBytes = [uint64]0
            Message    = 'Caminho inexistente.'
        }
    }

    if ($RequireAdministrator -and -not (Test-IsAdministrator)) {
        return [pscustomobject]@{
            Path       = $Path
            Success    = $false
            FreedBytes = [uint64]0
            Message    = 'Execute como administrador para limpar este caminho.'
        }
    }

    $before = Get-DirectorySize -Path $Path

    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue) {
        try {
            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
        }
    }

    $after = Get-DirectorySize -Path $Path
    $freed = if ($before -gt $after) { $before - $after } else { [uint64]0 }

    return [pscustomobject]@{
        Path       = $Path
        Success    = $true
        FreedBytes = $freed
        Message    = 'Limpeza concluida.'
    }
}

function Show-CleanupResult {
    param([Parameter(Mandatory = $true)]$Result)

    if ($Result.Success) {
        Write-Success ("{0} | espaco liberado: {1}" -f $Result.Path, (Format-Bytes -Bytes $Result.FreedBytes))
    }
    else {
        Write-WarnText ("{0} | {1}" -f $Result.Path, $Result.Message)
    }
}

function Invoke-RecycleBinCleanup {
    if (-not (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue)) {
        Write-WarnText 'O cmdlet Clear-RecycleBin nao esta disponivel neste sistema.'
        return
    }

    try {
        Clear-RecycleBin -Force -ErrorAction Stop | Out-Null
        Write-Success 'Lixeira esvaziada.'
    }
    catch {
        Write-WarnText ("Nao foi possivel limpar a Lixeira: {0}" -f $_.Exception.Message)
    }
}

function Confirm-Action {
    param([Parameter(Mandatory = $true)][string]$Prompt)

    $answer = Read-TrimmedInput -Prompt "$Prompt [S/N]"
    return $answer -match '^(s|sim|y|yes)$'
}

function Show-TemporaryCleanupMenu {
    do {
        Clear-Host
        Write-Host '===============================' -ForegroundColor DarkCyan
        Write-Host ' Limpeza de Arquivos Temporarios' -ForegroundColor DarkCyan
        Write-Host '===============================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host '1. Limpar TEMP do usuario'
        Write-Host '2. Limpar C:\Windows\Temp (admin)'
        Write-Host '3. Esvaziar Lixeira'
        Write-Host '4. Executar limpeza segura completa'
        Write-Host '5. Voltar'
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        switch ($choice) {
            '1' {
                if (Confirm-Action -Prompt 'Deseja limpar a pasta TEMP do usuario agora?') {
                    Show-CleanupResult -Result (Clear-DirectoryContents -Path $env:TEMP)
                    Pause-Console
                }
            }
            '2' {
                if (Confirm-Action -Prompt 'Deseja limpar C:\Windows\Temp agora?') {
                    Show-CleanupResult -Result (Clear-DirectoryContents -Path 'C:\Windows\Temp' -RequireAdministrator)
                    Pause-Console
                }
            }
            '3' {
                if (Confirm-Action -Prompt 'Deseja esvaziar a Lixeira agora?') {
                    Invoke-RecycleBinCleanup
                    Pause-Console
                }
            }
            '4' {
                if (Confirm-Action -Prompt 'Deseja executar a limpeza segura completa agora?') {
                    Show-CleanupResult -Result (Clear-DirectoryContents -Path $env:TEMP)
                    Show-CleanupResult -Result (Clear-DirectoryContents -Path 'C:\Windows\Temp' -RequireAdministrator)
                    Invoke-RecycleBinCleanup
                    Pause-Console
                }
            }
            '5' { return }
            default {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Invoke-CmdCommand {
    param(
        [Parameter(Mandatory = $true)][string]$CommandLine,
        [switch]$RequireAdministrator,
        [switch]$RestartRecommended
    )

    if ($RequireAdministrator -and -not (Test-IsAdministrator)) {
        Write-WarnText 'Esta acao exige PowerShell/Prompt como administrador.'
        return
    }

    Write-Info ("Executando: {0}" -f $CommandLine)
    & cmd.exe /c $CommandLine
    if ($LASTEXITCODE -eq 0) {
        Write-Success 'Comando concluido.'
        if ($RestartRecommended) {
            Write-WarnText 'Reiniciar o Windows e recomendado para aplicar tudo.'
        }
    }
    else {
        Write-ErrorText ("O comando terminou com codigo {0}." -f $LASTEXITCODE)
    }
}

function Show-NetworkCleanupMenu {
    do {
        Clear-Host
        Write-Host '=============================' -ForegroundColor DarkCyan
        Write-Host ' Limpeza e Reparo de Internet' -ForegroundColor DarkCyan
        Write-Host '=============================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host '1. Limpar cache DNS'
        Write-Host '2. Resetar Winsock (admin)'
        Write-Host '3. Resetar pilha IP (admin)'
        Write-Host '4. Resetar proxy WinHTTP (admin)'
        Write-Host '5. Renovar IP (release/renew)'
        Write-Host '6. Executar pacote completo'
        Write-Host '7. Voltar'
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        switch ($choice) {
            '1' {
                Invoke-CmdCommand -CommandLine 'ipconfig /flushdns'
                Pause-Console
            }
            '2' {
                if (Confirm-Action -Prompt 'Deseja resetar o Winsock agora?') {
                    Invoke-CmdCommand -CommandLine 'netsh winsock reset' -RequireAdministrator -RestartRecommended
                    Pause-Console
                }
            }
            '3' {
                if (Confirm-Action -Prompt 'Deseja resetar a pilha IP agora?') {
                    Invoke-CmdCommand -CommandLine 'netsh int ip reset' -RequireAdministrator -RestartRecommended
                    Pause-Console
                }
            }
            '4' {
                if (Confirm-Action -Prompt 'Deseja resetar o proxy WinHTTP agora?') {
                    Invoke-CmdCommand -CommandLine 'netsh winhttp reset proxy' -RequireAdministrator
                    Pause-Console
                }
            }
            '5' {
                if (Confirm-Action -Prompt 'Isso pode derrubar sua conexao por alguns instantes. Continuar?') {
                    Invoke-CmdCommand -CommandLine 'ipconfig /release && ipconfig /renew'
                    Pause-Console
                }
            }
            '6' {
                if (Confirm-Action -Prompt 'Deseja executar o pacote completo de reparo de rede agora?') {
                    Invoke-CmdCommand -CommandLine 'ipconfig /flushdns'
                    Invoke-CmdCommand -CommandLine 'netsh winsock reset' -RequireAdministrator -RestartRecommended
                    Invoke-CmdCommand -CommandLine 'netsh int ip reset' -RequireAdministrator -RestartRecommended
                    Invoke-CmdCommand -CommandLine 'netsh winhttp reset proxy' -RequireAdministrator
                    Pause-Console
                }
            }
            '7' { return }
            default {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Install-WingetFromOfficialSource {
    if (Test-CommandAvailable -Name 'winget') {
        Write-Success 'Winget ja esta disponivel.'
        return $true
    }

    try {
        Write-Info 'Tentando registrar o App Installer ja presente no sistema...'
        Add-AppxPackage -RegisterByFamilyName -MainPackage 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe' -ErrorAction Stop
    }
    catch {
        Write-WarnText 'Registro local nao funcionou. Vou tentar o download oficial.'
    }

    if (Test-CommandAvailable -Name 'winget') {
        Write-Success 'Winget habilitado com sucesso.'
        return $true
    }

    $tempDirectory = Join-Path $env:TEMP 'AssistentePC'
    $bundlePath = Join-Path $tempDirectory 'Microsoft.DesktopAppInstaller.msixbundle'
    New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null

    try {
        Write-Info 'Baixando o App Installer oficial da Microsoft...'
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $bundlePath -UseBasicParsing
        Add-AppxPackage -Path $bundlePath -ErrorAction Stop
    }
    catch {
        Write-ErrorText ("Falha ao instalar o winget: {0}" -f $_.Exception.Message)
        return $false
    }
    finally {
        Remove-Item -LiteralPath $bundlePath -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 2

    if (Test-CommandAvailable -Name 'winget') {
        Write-Success 'Winget instalado com sucesso.'
        return $true
    }

    Write-WarnText 'O winget ainda nao esta disponivel. Talvez seja preciso reiniciar a sessao ou instalar o App Installer manualmente.'
    return $false
}

function Ensure-PythonFromWinget {
    if (Test-CommandAvailable -Name 'python') {
        Write-Success 'Python ja esta instalado.'
        return $true
    }

    if (-not (Test-CommandAvailable -Name 'winget')) {
        Write-WarnText 'Nao consigo instalar Python automaticamente sem winget.'
        return $false
    }

    Write-Info 'Instalando Python via winget...'
    & winget install --id Python.Python.3.13 -e --accept-source-agreements --accept-package-agreements

    if (Test-CommandAvailable -Name 'python') {
        Write-Success 'Python instalado com sucesso.'
        return $true
    }

    Write-WarnText 'Python nao apareceu no PATH ainda. Tente abrir uma nova janela do terminal.'
    return $false
}

function Ensure-ChocolateyInstalled {
    if (Test-CommandAvailable -Name 'choco') {
        return $true
    }

    if (-not (Test-IsAdministrator)) {
        Write-WarnText 'Chocolatey precisa de admin para instalar. Execute como administrador.'
        return $false
    }

    Write-Info 'Instalando Chocolatey...'
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
        if (Test-CommandAvailable -Name 'choco') {
            Write-Success 'Chocolatey instalado com sucesso.'
            return $true
        }
    }
    catch {
        Write-ErrorText ("Falha ao instalar Chocolatey: {0}" -f $_.Exception.Message)
    }

    return $false
}

function Install-ProgramViaChocolatey {
    param([Parameter(Mandatory = $true)][string]$ChocoId,
          [Parameter(Mandatory = $true)][string]$DisplayName)

    if (-not (Ensure-ChocolateyInstalled)) { return $false }

    Write-Info ("Instalando {0} via Chocolatey..." -f $DisplayName)
    & choco install $ChocoId -y --no-progress 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Install-ProgramViaDirect {
    param([Parameter(Mandatory = $true)][pscustomobject]$Program)

    $url = $Program.DirectUrl
    $fileName = $Program.FileName
    if ([string]::IsNullOrWhiteSpace($url) -or [string]::IsNullOrWhiteSpace($fileName)) {
        Write-WarnText ("Download direto nao disponivel para {0}." -f $Program.DisplayName)
        return $false
    }

    $downloadDir = Join-Path $env:TEMP 'AssistentePC\downloads'
    $filePath = Join-Path $downloadDir $fileName
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null

    try {
        Write-Info ("Baixando {0}..." -f $Program.DisplayName)
        Invoke-WebRequest -Uri $url -OutFile $filePath -UseBasicParsing
        Write-Info ("Executando instalador de {0}..." -f $Program.DisplayName)
        $args = if ($Program.PSObject.Properties['Arguments'] -and $Program.Arguments) { $Program.Arguments } else { '' }
        $process = Start-Process -FilePath $filePath -ArgumentList $args -Wait -PassThru
        return ($process.ExitCode -in @(0, 3010))
    }
    catch {
        Write-ErrorText ("Falha: {0}" -f $_.Exception.Message)
        return $false
    }
    finally {
        Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue
    }
}

function Install-ProgramMultiMethod {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Program,
        [string]$Method = $script:PreferredInstaller
    )

    if (Test-ProgramInstalled -Program $Program) {
        Write-WarnText ("{0} ja esta instalado." -f $Program.DisplayName)
        return
    }

    $success = $false

    # Try preferred method first
    switch ($Method) {
        'winget' {
            if ($Program.WingetId) {
                if (-not (Test-CommandAvailable -Name 'winget')) {
                    Write-WarnText 'Winget ausente, tentando instalar...'
                    Install-WingetFromOfficialSource | Out-Null
                }
                if (Test-CommandAvailable -Name 'winget') {
                    Write-Info ("Instalando {0} via winget..." -f $Program.DisplayName)
                    & winget install --id $Program.WingetId -e --accept-source-agreements --accept-package-agreements
                    $success = ($LASTEXITCODE -eq 0)
                }
            }
        }
        'choco' {
            if ($Program.ChocoId) {
                $success = Install-ProgramViaChocolatey -ChocoId $Program.ChocoId -DisplayName $Program.DisplayName
            }
        }
        'direct' {
            if ($Program.PSObject.Properties['DirectUrl'] -and $Program.DirectUrl) {
                $success = Install-ProgramViaDirect -Program $Program
            }
        }
    }

    # Fallback chain: winget -> choco -> direct
    if (-not $success -and $Method -ne 'winget' -and $Program.WingetId -and (Test-CommandAvailable -Name 'winget')) {
        Write-WarnText 'Tentando fallback via winget...'
        & winget install --id $Program.WingetId -e --accept-source-agreements --accept-package-agreements
        $success = ($LASTEXITCODE -eq 0)
    }

    if (-not $success -and $Method -ne 'choco' -and $Program.ChocoId) {
        Write-WarnText 'Tentando fallback via Chocolatey...'
        $success = Install-ProgramViaChocolatey -ChocoId $Program.ChocoId -DisplayName $Program.DisplayName
    }

    if (-not $success -and $Method -ne 'direct' -and $Program.PSObject.Properties['DirectUrl'] -and $Program.DirectUrl) {
        Write-WarnText 'Tentando fallback via download direto...'
        $success = Install-ProgramViaDirect -Program $Program
    }

    if ($success) {
        Write-Success ("{0} instalado com sucesso." -f $Program.DisplayName)
    }
    else {
        Write-ErrorText ("Nao foi possivel instalar {0} por nenhum metodo." -f $Program.DisplayName)
    }
}

function Show-ProgramInstallerMenu {
    do {
        Clear-Host
        Write-Host '=============================================' -ForegroundColor DarkCyan
        Write-Host ' Instalador de Programas (Multi-Metodo)' -ForegroundColor DarkCyan
        Write-Host '=============================================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host ("Metodo preferido: {0} | Alternativas: winget, choco, direct" -f $script:PreferredInstaller) -ForegroundColor Gray
        Write-Host ''

        $status = Get-ProgramStatus
        $pageSize = 14
        $totalPrograms = $status.Count

        foreach ($program in $status) {
            $state = if ($program.Installed) { 'OK' } else { '--' }
            $color = if ($program.Installed) { 'Green' } else { 'Yellow' }
            Write-Host ("{0,2}. {1} [{2}]" -f $program.Key, $program.DisplayName, $state) -ForegroundColor $color
        }

        Write-Host ''
        Write-Host ('{0}. Instalar TODOS os programas ausentes' -f ($totalPrograms + 1))
        Write-Host ('{0}. Alternar metodo preferido (winget/choco/direct)' -f ($totalPrograms + 2))
        Write-Host ('{0}. Tentar instalar/habilitar o winget' -f ($totalPrograms + 3))
        Write-Host ('{0}. Instalar Chocolatey' -f ($totalPrograms + 4))
        Write-Host ('{0}. Voltar' -f ($totalPrograms + 5))
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        $choiceInt = 0
        if ([int]::TryParse($choice, [ref]$choiceInt)) {
            if ($choiceInt -ge 1 -and $choiceInt -le $totalPrograms) {
                Install-ProgramMultiMethod -Program $script:ProgramCatalog[$choiceInt - 1]
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalPrograms + 1)) {
                foreach ($program in $script:ProgramCatalog) {
                    if (-not (Test-ProgramInstalled -Program $program)) {
                        Install-ProgramMultiMethod -Program $program
                    }
                }
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalPrograms + 2)) {
                switch ($script:PreferredInstaller) {
                    'winget' { $script:PreferredInstaller = 'choco' }
                    'choco'  { $script:PreferredInstaller = 'direct' }
                    default  { $script:PreferredInstaller = 'winget' }
                }
                Write-Success ("Metodo preferido alterado para: {0}" -f $script:PreferredInstaller)
                Start-Sleep -Seconds 1
            }
            elseif ($choiceInt -eq ($totalPrograms + 3)) {
                Install-WingetFromOfficialSource | Out-Null
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalPrograms + 4)) {
                Ensure-ChocolateyInstalled | Out-Null
                Pause-Console
            }
            elseif ($choiceInt -eq ($totalPrograms + 5)) {
                return
            }
            else {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
        else {
            Write-WarnText 'Opcao invalida.'
            Start-Sleep -Seconds 1
        }
    } while ($true)
}

function Show-EnvironmentScreen {
    Clear-Host
    $status = Get-EnvironmentStatus

    Write-Host '========================' -ForegroundColor DarkCyan
    Write-Host ' Estado do Ambiente' -ForegroundColor DarkCyan
    Write-Host '========================' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host ("Computador: {0}" -f $status.ComputerName)
    Write-Host ("PowerShell: {0}" -f $status.PowerShell.Version)
    Write-Host ("Administrador: {0}" -f ($(if ($status.IsAdministrator) { 'SIM' } else { 'NAO' })))
    Write-Host ("Winget: {0}" -f ($(if ($status.Winget.Available) { 'DISPONIVEL' } else { 'AUSENTE' })))
    if ($status.Winget.Path) {
        Write-Host ("  Caminho: {0}" -f $status.Winget.Path)
    }
    Write-Host ("Python: {0}" -f ($(if ($status.Python.Available) { 'DISPONIVEL' } else { 'AUSENTE' })))
    if ($status.Python.Path) {
        Write-Host ("  Caminho: {0}" -f $status.Python.Path)
    }
    Write-Host ''
    Write-Host 'Programas monitorados:' -ForegroundColor Yellow
    foreach ($program in $status.Programs) {
        Write-Host ("- {0}: {1}" -f $program.DisplayName, $(if ($program.Installed) { 'instalado' } else { 'ausente' }))
    }
    Write-Host ''
    Write-Host 'Dependencias gamer:' -ForegroundColor Yellow
    foreach ($dependency in $status.GameDependencies) {
        Write-Host ("- {0}: {1}" -f $dependency.DisplayName, $(if ($dependency.Installed) { 'instalado' } else { 'ausente' }))
    }
    Write-Host ''

    Pause-Console
}

function Show-PremiumMenu {
    do {
        Clear-Host
        Write-Host '=========================================' -ForegroundColor DarkCyan
        Write-Host ' Assistente do PC - Area Premium' -ForegroundColor DarkCyan
        Write-Host '=========================================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host ' 1. Spotify Premium (Spicetify CLI)'
        Write-Host '    - Instala Spotify oficial'
        Write-Host '    - Aplica Spicetify para remover anuncios em modo silencioso'
        Write-Host ' 2. Steam Plugin (LuaTools)'
        Write-Host '    - Aplica modificadores na Steam'
        Write-Host ' 3. WinAct (Ativador do Windows)'
        Write-Host '    - Executa o ativador get.activated.win'
        Write-Host ' 4. Voltar'
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        switch ($choice) {
            '1' { Invoke-SpotifyPremium }
            '2' { Invoke-SteamPlugin }
            '3' { Invoke-WinAct }
            '4' { return }
            default {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Invoke-SpotifyPremium {
    Clear-Host
    Write-Host '=========================================' -ForegroundColor DarkCyan
    Write-Host ' Instalando Spotify + Spicetify' -ForegroundColor DarkCyan
    Write-Host '=========================================' -ForegroundColor DarkCyan
    
    # 1. Check/Install Spotify
    $spotifyMatch = $script:ProgramCatalog | Where-Object { $_.Key -eq 'spotify' -or $_.DisplayName -match 'Spotify' } | Select-Object -First 1
    if (-not $spotifyMatch) {
        Write-ErrorText 'Configuracao do Spotify ausente no catalogo.'
        Pause-Console
        return
    }

    if (Test-ProgramInstalled -Program $spotifyMatch) {
        Write-Success 'Spotify ja esta instalado.'
    } else {
        Write-Info 'Spotify nao encontrado. Tentando instalar...'
        Install-ProgramMultiMethod -Program $spotifyMatch
        Start-Sleep -Seconds 3
        if (-not (Test-ProgramInstalled -Program $spotifyMatch)) {
            Write-WarnText 'Falha ao confirmar a instalacao do Spotify. Continuando mesmo assim...'
        }
    }

    # 2. Run Spicetify
    Write-Info 'Aplicando Spicetify em modo silencioso...'
    try {
        # Execution policy bypass and run silently
        Invoke-Expression "& { $(Invoke-RestMethod -UseBasicParsing -Uri 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1') } -Quiet"
        Write-Success 'Spicetify executado. (Verifique erros no output acima, se houver)'
    } catch {
        Write-ErrorText "Falha ao executar Spicetify: $($_.Exception.Message)"
    }
    Pause-Console
}

function Invoke-SteamPlugin {
    Clear-Host
    Write-Host '=========================================' -ForegroundColor DarkCyan
    Write-Host ' Instalando Steam Plugin (LuaTools)' -ForegroundColor DarkCyan
    Write-Host '=========================================' -ForegroundColor DarkCyan
    
    Write-Info 'Executando script...'
    try {
        Invoke-RestMethod "https://luatools.vercel.app/install-plugin.ps1" | Invoke-Expression
        Write-Success 'Script finalizado.'
    } catch {
        Write-ErrorText "Falha: $($_.Exception.Message)"
    }
    Pause-Console
}

function Invoke-WinAct {
    Clear-Host
    Write-Host '=========================================' -ForegroundColor DarkCyan
    Write-Host ' Executando WinAct' -ForegroundColor DarkCyan
    Write-Host '=========================================' -ForegroundColor DarkCyan

    Write-Info 'Executando script...'
    try {
        Invoke-RestMethod "https://get.activated.win" | Invoke-Expression
        Write-Success 'Script finalizado.'
    } catch {
        Write-ErrorText "Falha: $($_.Exception.Message)"
    }
    Pause-Console
}

function Show-ReviOSMenu {
    $reviosDir = Join-Path $env:USERPROFILE 'Desktop\ReviOS'

    do {
        Clear-Host
        Write-Host '============================================' -ForegroundColor DarkCyan
        Write-Host ' Otimizacao do Windows (ReviOS + AME Wizard)' -ForegroundColor DarkCyan
        Write-Host '============================================' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host 'Aplique o playbook ReviOS para otimizar o Windows 11.'
        Write-Host 'O AME Wizard e necessario para aplicar o playbook (.apbx).'
        Write-Host ''

        $playbookPath = Join-Path $reviosDir 'Revision-Playbook.apbx'
        $amePath = Join-Path $reviosDir 'AME-Beta-v0.8.4.exe'
        $playbookExists = Test-Path -LiteralPath $playbookPath
        $ameExists = Test-Path -LiteralPath $amePath

        $pbStatus = if ($playbookExists) { 'BAIXADO' } else { 'NAO BAIXADO' }
        $ameStatus = if ($ameExists) { 'BAIXADO' } else { 'NAO BAIXADO' }
        $pbColor = if ($playbookExists) { 'Green' } else { 'Yellow' }
        $ameColor = if ($ameExists) { 'Green' } else { 'Yellow' }

        Write-Host ("Playbook ReviOS 25.10: [{0}]" -f $pbStatus) -ForegroundColor $pbColor
        Write-Host ("AME Wizard v0.8.4:     [{0}]" -f $ameStatus) -ForegroundColor $ameColor
        Write-Host ("Pasta: {0}" -f $reviosDir) -ForegroundColor Gray
        Write-Host ''
        Write-Host '1. Baixar Playbook ReviOS 25.10'
        Write-Host '2. Baixar AME Wizard v0.8.4'
        Write-Host '3. Baixar AMBOS'
        Write-Host '4. Abrir AME Wizard'
        Write-Host '5. Abrir pasta ReviOS'
        Write-Host '6. Voltar'
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        switch ($choice) {
            '1' {
                Invoke-ReviOSPlaybookDownload -DestinationDir $reviosDir
                Pause-Console
            }
            '2' {
                Invoke-AMEWizardDownload -DestinationDir $reviosDir
                Pause-Console
            }
            '3' {
                Invoke-ReviOSPlaybookDownload -DestinationDir $reviosDir
                Invoke-AMEWizardDownload -DestinationDir $reviosDir
                Pause-Console
            }
            '4' {
                if ($ameExists) {
                    Write-Info 'Abrindo AME Wizard...'
                    Start-Process -FilePath $amePath
                    Write-Success 'AME Wizard iniciado. Arraste o arquivo .apbx para dentro dele.'
                }
                else {
                    Write-WarnText 'AME Wizard nao encontrado. Baixe primeiro (opcao 2).'
                }
                Pause-Console
            }
            '5' {
                New-Item -ItemType Directory -Path $reviosDir -Force | Out-Null
                Start-Process explorer.exe -ArgumentList $reviosDir
            }
            '6' { return }
            default {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

function Invoke-ReviOSPlaybookDownload {
    param([Parameter(Mandatory = $true)][string]$DestinationDir)

    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    $playbookUrl = 'https://modsfire.com/46j4c4507kXt18F'
    $expectedHash = 'E05C26414BB655AD54B826F81D703B63D03D50E9822F63394DE43E3F5CF6807B'
    $destFile = Join-Path $DestinationDir 'Revision-Playbook.apbx'

    Write-Info 'Baixando ReviOS Playbook 25.10...'
    Write-Info 'Link: O download sera feito pelo modsfire. Se nao funcionar automaticamente,'
    Write-Info ("acesse manualmente: {0}" -f $playbookUrl)

    try {
        $apiUrl = 'https://api.github.com/repos/meetrevision/playbook/releases/tags/25.10'
        $releaseInfo = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
        $asset = $releaseInfo.assets | Where-Object { $_.name -match '\.apbx$' } | Select-Object -First 1
        if ($null -ne $asset) {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $destFile -UseBasicParsing
        }
        else {
            Write-WarnText 'Nao encontrei o .apbx na release do GitHub. Tentando link alternativo...'
            Invoke-WebRequest -Uri $playbookUrl -OutFile $destFile -UseBasicParsing
        }

        if (Test-Path -LiteralPath $destFile) {
            $hash = (Get-FileHash -LiteralPath $destFile -Algorithm SHA256).Hash
            if ($hash -eq $expectedHash) {
                Write-Success 'Playbook baixado e verificado (SHA256 OK).'
            }
            else {
                Write-WarnText ("SHA256 diferente do esperado. Obtido: {0}" -f $hash)
                Write-WarnText 'O arquivo pode ser de uma versao diferente ou o link foi alterado. Verifique manualmente.'
            }
        }
    }
    catch {
        Write-ErrorText ("Falha ao baixar o playbook: {0}" -f $_.Exception.Message)
        Write-WarnText ("Acesse manualmente: {0}" -f $playbookUrl)
        Write-WarnText 'Ou acesse: https://github.com/meetrevision/playbook/releases/tag/25.10'
    }
}

function Invoke-AMEWizardDownload {
    param([Parameter(Mandatory = $true)][string]$DestinationDir)

    New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    $ameUrl = 'https://github.com/Ameliorated-LLC/trusted-uninstaller-cli/releases/download/0.8.4/AME-Beta-v0.8.4.exe'
    $expectedHash = 'A637F32B64E1493B315DB9139065105656C84518DCA20CE3B18C89750EE40C82'
    $destFile = Join-Path $DestinationDir 'AME-Beta-v0.8.4.exe'

    Write-Info 'Baixando AME Wizard v0.8.4...'
    try {
        Invoke-WebRequest -Uri $ameUrl -OutFile $destFile -UseBasicParsing

        if (Test-Path -LiteralPath $destFile) {
            $hash = (Get-FileHash -LiteralPath $destFile -Algorithm SHA256).Hash
            if ($hash -eq $expectedHash) {
                Write-Success 'AME Wizard baixado e verificado (SHA256 OK).'
            }
            else {
                Write-WarnText ("SHA256 diferente: {0}" -f $hash)
            }
        }
    }
    catch {
        Write-ErrorText ("Falha ao baixar o AME Wizard: {0}" -f $_.Exception.Message)
    }
}

function Open-WebDashboard {
    $webServerPath = Join-Path $PSScriptRoot 'WebServer.ps1'
    $dashboardPath = Join-Path $PSScriptRoot 'dashboard\index.html'

    if (-not (Test-Path -LiteralPath $dashboardPath)) {
        Write-WarnText 'Dashboard nao encontrado. Verifique se a pasta dashboard/ existe.'
        Pause-Console
        return
    }

    if (Test-Path -LiteralPath $webServerPath) {
        Write-Info 'Iniciando servidor web do dashboard...'
        Start-Process -FilePath 'powershell.exe' -ArgumentList ('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $webServerPath)
        Start-Sleep -Seconds 2
        Start-Process 'http://localhost:8765'
        Write-Success 'Dashboard aberto no navegador.'
    }
    else {
        Write-Info 'Abrindo dashboard diretamente no navegador...'
        Start-Process $dashboardPath
    }
    Pause-Console
}

function Start-InteractiveMode {
    do {
        Clear-Host
        Write-Host '=========================================' -ForegroundColor DarkCyan
        Write-Host ' Assistente do PC - Menu Principal' -ForegroundColor DarkCyan
        Write-Host '=========================================' -ForegroundColor DarkCyan
        Write-Host ''

        $envStatus = Get-EnvironmentStatus
        $adminLabel = if ($envStatus.IsAdministrator) { 'SIM' } else { 'NAO' }
        $wingetLabel = if ($envStatus.Winget.Available) { 'OK' } else { 'AUSENTE' }
        $chocoLabel = if (Test-CommandAvailable -Name 'choco') { 'OK' } else { 'AUSENTE' }
        $pythonLabel = if ($envStatus.Python.Available) { 'OK' } else { 'AUSENTE' }
        Write-Host ("Admin: {0} | Winget: {1} | Choco: {2} | Python: {3}" -f $adminLabel, $wingetLabel, $chocoLabel, $pythonLabel) -ForegroundColor Gray
        if ($RunFromBootstrap) {
            Write-Host 'Inicializado pelo bootstrap CMD.' -ForegroundColor Gray
        }
        Write-Host ''
        Write-Host ' 1. Ver configuracoes do sistema (CPU, GPU, RAM)'
        Write-Host ' 2. Limpeza de arquivos temporarios'
        Write-Host ' 3. Limpeza e reparo de internet/rede'
        Write-Host ' 4. Instalar programas (multi-metodo)'
        Write-Host ' 5. Instalar dependencias completas para jogos'
        Write-Host ' 6. Diagnosticar discos rigidos e SSDs'
        Write-Host ' 7. Verificar ambiente e dependencias'
        Write-Host ' 8. Otimizacao do Windows (ReviOS + AME Wizard)'
        Write-Host ' 9. Recursos Premium (Spotify, Steam, WinAct)'
        Write-Host '10. Abrir Dashboard Web'
        Write-Host '11. Sair'
        Write-Host ''

        $choice = Read-TrimmedInput -Prompt 'Escolha uma opcao'
        switch ($choice) {
            '1'  { Show-SystemOverview }
            '2'  { Show-TemporaryCleanupMenu }
            '3'  { Show-NetworkCleanupMenu }
            '4'  { Show-ProgramInstallerMenu }
            '5'  { Show-GameDependenciesMenu }
            '6'  { Show-DiskDiagnostics }
            '7'  { Show-EnvironmentScreen }
            '8'  { Show-ReviOSMenu }
            '9'  { Show-PremiumMenu }
            '10' { Open-WebDashboard }
            '11' { return }
            default {
                Write-WarnText 'Opcao invalida.'
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

try {
    switch ($Mode) {
        'Library' {
            # Apenas carrega as funcoes em memoria e sai sem fechar o processo original
            Write-Verbose "Assistente-PC.ps1 loaded in Library Mode."
            return
        }
        'EnsureWinget' {
            if (Install-WingetFromOfficialSource) { exit 0 } else { exit 1 }
        }
        'EnsurePython' {
            if (Ensure-PythonFromWinget) { exit 0 } else { exit 1 }
        }
        'PrintEnvironmentJson' {
            Get-EnvironmentStatus | ConvertTo-Json -Depth 6
            exit 0
        }
        'PrintSystemJson' {
            Get-SystemSummary | ConvertTo-Json -Depth 6
            exit 0
        }
        'PrintDiskJson' {
            Get-DiskDiagnosticsReport | ConvertTo-Json -Depth 7
            exit 0
        }
        default {
            Start-InteractiveMode
            Pause-BeforeTermination -Reason 'Execucao finalizada. A janela ficara aberta ate voce confirmar.'
            exit 0
        }
    }
}
catch {
    Write-ErrorText ("Falha inesperada: {0}" -f $_.Exception.Message)
    Pause-BeforeTermination -Reason 'O programa encontrou um erro e ficou aberto para voce poder ler a mensagem.'
    exit 1
}
