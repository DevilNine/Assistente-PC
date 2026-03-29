# Assistente-GUI.ps1
# Interface Nativa WPF (Padrao CTT / Chris Titus Tech)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Carrega o Engine principal em Modo Library
$enginePath = Join-Path $PSScriptRoot "Assistente-PC.ps1"
if (Test-Path $enginePath) {
    . $enginePath -Mode 'Library'
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Assistente Premium do PC - CTT Style" Height="850" Width="1100"
        WindowStartupLocation="CenterScreen" Background="#1e1e1e" Foreground="#ffffff"
        FontFamily="Segoe UI">
    <Window.Resources>
    
        <!-- Estilo de Abas Superiores (Top Nav) -->
        <Style x:Key="TopNavBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#a0a0a0"/>
            <Setter Property="FontSize" Value="20"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="20,15"/>
            <Setter Property="BorderThickness" Value="0,0,0,3"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderThickness="{TemplateBinding BorderThickness}" BorderBrush="{TemplateBinding BorderBrush}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#ffffff"/>
                                <Setter TargetName="border" Property="Background" Value="#2d2d2d"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Checkbox Flat Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="5"/>
        </Style>

        <!-- GroupBox Minimalista -->
        <Style TargetType="GroupBox">
            <Setter Property="BorderBrush" Value="#404040"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Margin" Value="10"/>
            <Setter Property="Padding" Value="15"/>
            <Setter Property="Foreground" Value="#00bfff"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="16"/>
        </Style>

        <!-- Botao Principal de Acao -->
        <Style x:Key="MainActionBtn" TargetType="Button">
            <Setter Property="Background" Value="#007acc"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="30,12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#0098ff"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/> <!-- Top Nav -->
            <RowDefinition Height="*"/> <!-- Main Content -->
            <RowDefinition Height="80"/> <!-- Action Area -->
            <RowDefinition Height="200"/> <!-- Integrated Terminal -->
        </Grid.RowDefinitions>

        <!-- Top Navigation Bar -->
        <Border Grid.Row="0" Background="#262626" BorderBrush="#333333" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button x:Name="TabInstall" Content="Instalacao" Style="{StaticResource TopNavBtn}"/>
                <Button x:Name="TabTweaks" Content="Otimizacoes" Style="{StaticResource TopNavBtn}"/>
                <Button x:Name="TabConfig" Content="Sistema/Config" Style="{StaticResource TopNavBtn}"/>
                <Button x:Name="TabUpdates" Content="Utilitarios" Style="{StaticResource TopNavBtn}"/>
            </StackPanel>
        </Border>

        <!-- Conteudo Dinamico (Centro) -->
        <Border Grid.Row="1" Background="#1e1e1e">
            <Grid Margin="20">
                
                <!-- Painel: Instalacao (Apps) -->
                <Grid x:Name="PanelInstall" Visibility="Visible">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <TextBlock Text="Selecione os aplicativos para instalar em massa:" Foreground="#888888" Margin="10,0,0,10"/>
                            <GroupBox Header="Softwares Essenciais (Winget/Choco/Downloads)">
                                <WrapPanel x:Name="ProgramsWrapPanel" ItemWidth="230"/>
                            </GroupBox>
                            
                            <GroupBox Header="Dependencias para Jogos (DirectX, VC++, .NET, XNA)">
                                <WrapPanel x:Name="DepsWrapPanel" ItemWidth="400"/>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>

                <!-- Painel: Otimizacoes (Tweaks) -->
                <Grid x:Name="PanelTweaks" Visibility="Collapsed">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <GroupBox Header="Limpeza Profunda">
                                <StackPanel>
                                    <CheckBox x:Name="ChkCleanTemp" Content="Apagar Arquivos Temporarios e Lixo do Sistema" IsChecked="True"/>
                                    <CheckBox x:Name="ChkCleanNetwork" Content="Redefinir e Reparar Conexoes de Rede" />
                                </StackPanel>
                            </GroupBox>
                            
                            <GroupBox Header="Recursos Premium">
                                <StackPanel>
                                    <CheckBox x:Name="ChkSpotify" Content="Spotify Sem Anuncios (Instalar Spotify + Spicetify)" />
                                    <CheckBox x:Name="ChkSteam" Content="Steam LuaTools (Gemas e Opcoes da Steam Extras)" />
                                    <CheckBox x:Name="ChkWinAct" Content="Executar Ativador Nativo (WinAct - Windows/Office)" />
                                </StackPanel>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>

                <!-- Painel: Sistema / Config -->
                <Grid x:Name="PanelConfig" Visibility="Collapsed">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <GroupBox Header="Informacoes de Hardware">
                                <StackPanel x:Name="SystemInfoPanel">
                                    <TextBlock Text="Coletando dados do sistema..." Foreground="#a0a0a0"/>
                                </StackPanel>
                            </GroupBox>
                            
                            <GroupBox Header="ReviOS &amp; Otimizacoes Extremas">
                                <StackPanel>
                                    <CheckBox x:Name="ChkReviOS" Content="Baixar ReviOS Playbook e AME Wizard (Preparar Arquivos)" />
                                    <TextBlock Text="Nota: Executar o ReviOS altera profundamente o Windows. Use com cautela." Foreground="#ffcc00" FontSize="12" Margin="25,5,0,10"/>
                                </StackPanel>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>

                <!-- Painel: Utilitarios -->
                <Grid x:Name="PanelUpdates" Visibility="Collapsed">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <GroupBox Header="Ferramentas Manuais do Windows">
                                <StackPanel>
                                    <Button x:Name="BtnCleanMgr" Content="Abrir Ferramenta de Limpeza de Disco Nativa" Width="300" HorizontalAlignment="Left" Padding="10" Margin="0,5" Background="#333333" Foreground="White" BorderThickness="0"/>
                                    <Button x:Name="BtnLaunchAme" Content="Abrir AME Wizard Manualmente" Width="300" HorizontalAlignment="Left" Padding="10" Margin="0,5" Background="#333333" Foreground="White" BorderThickness="0"/>
                                </StackPanel>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
                
            </Grid>
        </Border>

        <!-- Area de Acao Principal (Botao Run) -->
        <Border Grid.Row="2" Background="#262626" BorderThickness="0,1,0,1" BorderBrush="#333333">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Button x:Name="BtnRunSelected" Content="EXECUTAR ITENS SELECIONADOS" Style="{StaticResource MainActionBtn}"/>
            </StackPanel>
        </Border>

        <!-- Terminal Integrado (Log) -->
        <Border Grid.Row="3" Background="#0c0c0c" Padding="10">
            <TextBox x:Name="TxtLog" IsReadOnly="True" Background="Transparent" Foreground="#00ff00" FontFamily="Consolas" FontSize="13" BorderThickness="0" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
        </Border>

    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Elementos e Estilos
$tabs = @("Install", "Tweaks", "Config", "Updates")

function Set-PanelVisibility([string]$targetTab) {
    foreach ($t in $tabs) {
        $panel = $window.FindName("Panel$t")
        $btn = $window.FindName("Tab$t")
        if ($t -eq $targetTab) {
            $panel.Visibility = 'Visible'
            $btn.BorderBrush = "#00bfff"
            $btn.Foreground = "#ffffff"
        } else {
            $panel.Visibility = 'Collapsed'
            $btn.BorderBrush = "Transparent"
            $btn.Foreground = "#a0a0a0"
        }
    }
}

# Funcao para gravar logs diretamente no Terminal Embutido
function Write-GuiLog([string]$msg) {
    $window.Dispatcher.Invoke({
        $log = $window.FindName("TxtLog")
        $time = (Get-Date).ToString("HH:mm:ss")
        $log.AppendText("[$time] $msg`n")
        $log.ScrollToEnd()
    })
}

# Define cliques nas abas
foreach ($t in $tabs) {
    $window.FindName("Tab$t").add_Click($ExecutionContext.InvokeCommand.NewScriptBlock("Set-PanelVisibility '$t'"))
}
Set-PanelVisibility "Install"

# Funcao assincrona segura para nao travar a UI
function Invoke-AsyncExec([scriptblock]$action) {
    $window.FindName("BtnRunSelected").IsEnabled = $false
    
    [System.Threading.Tasks.Task]::Run({
        try {
            & $action
        } catch {
            Write-GuiLog "ERRO: $($_.Exception.Message)"
        }
        $window.Dispatcher.Invoke({
            $window.FindName("BtnRunSelected").IsEnabled = $true
        })
    })
}

# --- Inicializacao de Dados ---

Write-GuiLog "Inicializando Interface CTT e Carregando Modulos do Sistema..."

try {
    # 1. Sistema Info
    $sys = Get-SystemSummary
    $envStats = Get-EnvironmentStatus
    $text = "COMPUTADOR: $($sys.System.ComputerName)`n"
    $text += "SO: $($sys.System.OperatingSystem)`n"
    $text += "CPU: $(($sys.Cpu | Select-Object -First 1).Name)`n"
    $text += "GPU: $(($sys.Gpu | Select-Object -First 1).Name)`n"
    $text += "RAM: $(Format-Bytes $sys.Memory.TotalPhysicalMemory)`n`n"
    $text += "Winget: $(if($envStats.Winget.Available){'[OK] Pronto'}else{'[X] Falha'})`n"
    $text += "Choco: $(if(Test-CommandAvailable 'choco'){'[OK] Pronto'}else{'[X] Falha'})`n"
    $text += "Privilegios Admin: $(if($envStats.IsAdministrator){'SIM'}else{'NAO'})"

    $panel = $window.FindName("SystemInfoPanel")
    $panel.Children.Clear()
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Foreground = "#e2e8f0"
    $tb.FontSize = 15
    $tb.Text = $text
    $panel.Children.Add($tb)

    # 2. Catalogo de Programas
    $statusArray = Get-ProgramStatus
    $wp = $window.FindName("ProgramsWrapPanel")
    $wp.Children.Clear()

    foreach ($p in $statusArray) {
        $cb = New-Object System.Windows.Controls.CheckBox
        if ($p.Installed) {
            $cb.Content = "$($p.DisplayName) [INSTALADO]"
            $cb.Foreground = "#888888" # Cinza para simbolizar que ja tem
            $cb.IsChecked = $false
        } else {
            $cb.Content = $p.DisplayName
        }
        $cb.Tag = $p.Key
        $wp.Children.Add($cb)
    }

    # 3. Catalogo de Dependencias
    $statusArrayDeps = Get-GameDependencyStatus
    $wpDeps = $window.FindName("DepsWrapPanel")
    $wpDeps.Children.Clear()

    foreach ($p in $statusArrayDeps) {
        $cb = New-Object System.Windows.Controls.CheckBox
        if ($p.Installed) {
            $cb.Content = "$($p.DisplayName) [PRESENTE]"
            $cb.Foreground = "#888888"
            $cb.IsChecked = $false
        } else {
            $cb.Content = $p.DisplayName
        }
        $cb.Tag = $p.Key
        $wpDeps.Children.Add($cb)
    }

    Write-GuiLog "Todos os catalogos foram carregados com sucesso."
} catch { 
    Write-GuiLog "Erro ao inicializar conteudos: $($_.Exception.Message)" 
}

# --- Utilitarios Manuais Binds ---
$window.FindName("BtnCleanMgr").add_Click({ Start-Process cleanmgr })
$window.FindName("BtnLaunchAme").add_Click({ Invoke-AmeWizardLaunch })

# --- Logica de Execucao em Lote (Botao Mestre) ---

$window.FindName("BtnRunSelected").add_Click({
    Write-GuiLog "=== INICIANDO EXECUCAO EM LOTE ==="

    # Coletar Programas Marcados
    $appsToInstall = @()
    foreach ($cb in $window.FindName("ProgramsWrapPanel").Children) {
        if ($cb.IsChecked -eq $true) {
            $key = $cb.Tag
            $prog = $script:ProgramCatalog | Where-Object Key -eq $key
            if ($prog) { $appsToInstall += $prog }
        }
    }

    # Coletar Deps Marcadas
    $depsToInstall = @()
    foreach ($cb in $window.FindName("DepsWrapPanel").Children) {
        if ($cb.IsChecked -eq $true) {
            $key = $cb.Tag
            $dep = $script:GameDependencyCatalog | Where-Object Key -eq $key
            if ($dep) { $depsToInstall += $dep }
        }
    }
    
    # Coletar CheckBoxes de Sistema/Tweaks
    $runClean       = $window.FindName("ChkCleanTemp").IsChecked
    $runNetwork     = $window.FindName("ChkCleanNetwork").IsChecked
    $runSpotify     = $window.FindName("ChkSpotify").IsChecked
    $runSteam       = $window.FindName("ChkSteam").IsChecked
    $runWinAct      = $window.FindName("ChkWinAct").IsChecked
    $runReviOS      = $window.FindName("ChkReviOS").IsChecked

    # Dispatcher assincrono
    Invoke-AsyncExec {
        # 1. Instalar Apps
        foreach ($prog in $appsToInstall) {
            Write-GuiLog "-> Instalando Software: $($prog.DisplayName)"
            Install-ProgramMultiMethod -Program $prog
            Write-GuiLog "[OK] $($prog.DisplayName)"
        }

        # 2. Instalar Deps
        foreach ($dep in $depsToInstall) {
            Write-GuiLog "-> Instalando Dependencia: $($dep.DisplayName)"
            Install-GameDependency -Dependency $dep
            Write-GuiLog "[OK] $($dep.DisplayName)"
        }

        # 3. Limpeza
        if ($runClean -eq $true) {
            Write-GuiLog "-> Executando Limpeza Profunda de Temporarios..."
            Invoke-RoutineCleanup
            Write-GuiLog "[OK] Limpeza concluida."
        }

        if ($runNetwork -eq $true) {
            Write-GuiLog "-> Executando Redefinicao de Rede (Flush DNS, Winsock)..."
            Invoke-NetworkRepair
            Write-GuiLog "[OK] Rede reparada."
        }

        # 4. Premium
        if ($runSpotify -eq $true) {
            Write-GuiLog "-> Injetando Spotify Premium (Spicetify)..."
            Invoke-SpotifyPremium
            Write-GuiLog "[OK] Spicetify concluido."
        }
        if ($runSteam -eq $true) {
            Write-GuiLog "-> Instalando Steam LuaTools Plugin..."
            Invoke-SteamPlugin
            Write-GuiLog "[OK] Plugin Steam ativo."
        }
        if ($runWinAct -eq $true) {
            Write-GuiLog "-> Lanzando motor WinAct (Verifique a nova aba que abrira)..."
            Invoke-WinAct
            Write-GuiLog "[OK] Script WinAct submetido."
        }

        # 5. Config/Sistema
        if ($runReviOS -eq $true) {
            Write-GuiLog "-> Baixando pacotes base ReviOS + AME Wizard..."
            Invoke-ReviOSDownload
            Invoke-AmeWizardDownload
            Write-GuiLog "[OK] Binarios ReviOS estao prontos. Utilize a aba Utilitarios para aplicar."
        }

        Write-GuiLog "=== EXECUCAO EM LOTE FINALIZADA COM SUCESSO! ==="
    }
})

$window.ShowDialog() | Out-Null
