<#
.SYNOPSIS
    Bootstrapper do Assistente PC (Chris Titus Style)
.DESCRIPTION
    Este script baixa os arquivos necessários diretamente do repositório GitHub e os executa.
    Uso: irm https://raw.githubusercontent.com/SEU-USUARIO/Assistente-PC/main/run.ps1 | iex
#>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Elevacao Automatica de Privilegios
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevando privilegios para Administrador..." -ForegroundColor Yellow
    $args = "-NoProfile -ExecutionPolicy Bypass -Command `"& {irm 'https://raw.githubusercontent.com/DevilNine/Assistente-PC/refs/heads/main/run.ps1' | iex}`""
    Start-Process powershell -ArgumentList $args -Verb RunAs -Wait
    exit
}

Write-Host "Iniciando Assistente do PC..." -ForegroundColor Cyan

# 2. Diretorio Temporario de Trabalho
$tempDir = Join-Path $env:TEMP "AssistentePC"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# 3. URLs do Repositorio (SUBSTITUA "SEU-USUARIO/Assistente-PC" PELO SEU REPOSITORIO)
$repoBaseUrl = "https://raw.githubusercontent.com/DevilNine/Assistente-PC/refs/heads/main/run.ps1"

# 4. Download Otimizado e Direto
Write-Host "Baixando nucleo do assistente..."
try {
    Invoke-WebRequest -Uri "$repoBaseUrl/Assistente-PC.ps1" -OutFile "$tempDir\Assistente-PC.ps1" -UseBasicParsing
    Invoke-WebRequest -Uri "$repoBaseUrl/Assistente-GUI.ps1" -OutFile "$tempDir\Assistente-GUI.ps1" -UseBasicParsing
} catch {
    Write-Host "Falha ao baixar arquivos do GitHub. Verifique o link no codigo ou sua internet." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit
}

# 5. Executar Interface Gráfica
Write-Host "Abrindo Interface Grafica..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-STA -NoProfile -ExecutionPolicy Bypass -File `"$tempDir\Assistente-GUI.ps1`"" -NoNewWindow -Wait

# 6. Limpeza
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
