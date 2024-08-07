# Import necessary assemblies for Windows Forms and Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize global variables
$global:checkboxes = @()
$global:totalTasks = 0
$global:completedTasks = 0
$global:tasksPerStep = 1

# Function to create UI elements
function New-UIElement {
    param (
        [string]$type,
        [hashtable]$properties,
        [scriptblock]$onClick = $null
    )
    $element = New-Object ("System.Windows.Forms.$type")
    foreach ($property in $properties.Keys) {
        $element.$property = $properties[$property]
    }
    if ($onClick -ne $null) {
        $element.Add_Click($onClick)
    }
    return $element
}

# Function to log messages with different levels
function Log-Message {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$level] $message"
    Write-Output $logEntry
    $logEntry | Out-File -FilePath $global:logFile -Append
}

# Function to handle errors
function Handle-Error {
    param (
        [string]$operation,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.ErrorRecord]$exception
    )
    Log-Message "Erro durante ${operation}: $($exception.Exception.Message)" "ERROR"
    Log-Message "Stack Trace: $($exception.Exception.StackTrace)" "ERROR"
    Update-Progress -increment 0
}

# Function to start logging
function Start-Logging {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $global:logFile = "C:\Relatorio\J365_WIN_tools_${timestamp}.log"
    New-Item -ItemType Directory -Force -Path "C:\Relatorio" | Out-Null
    New-Item -ItemType File -Force -Path $global:logFile | Out-Null
    Log-Message "Inicio da execucao do script"
}

# Function to stop logging
function Stop-Logging {
    Log-Message "100% Concluido. Reinicie o dispositivo para concluir as configuracoes"
}

# Function to update progress
function Update-Progress {
    param (
        [int]$increment = 1
    )
    $global:completedTasks += $increment
    $percentComplete = [math]::Round(($global:completedTasks / $global:totalTasks) * 100)
    if ($percentComplete -gt 100) {
        $percentComplete = 100
    }
    $progressBar.Value = $percentComplete
    $progressLabel.Text = "Progresso... $percentComplete% Concluido"
    $progressBar.Refresh()
    $progressLabel.Refresh()
}

# Function to create and align category labels and checkboxes
function Add-CategoryAndCheckboxes {
    param (
        [string]$category,
        [array]$items,
        [int]$xPos,
        [int]$yPos
    )
    $groupBox = New-UIElement -type "GroupBox" -properties @{
        Text = $category
        Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        Location = New-Object System.Drawing.Point($xPos, $yPos)
        Size = New-Object System.Drawing.Size(220, 360)
    }
    $panel.Controls.Add($groupBox)

    $yPos = 20
    foreach ($item in $items) {
        $checkbox = New-UIElement -type "CheckBox" -properties @{
            Text = $item
            Location = New-Object System.Drawing.Point(10, $yPos)
            AutoSize = $true
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            BackColor = [System.Drawing.Color]::White
        }
        $groupBox.Controls.Add($checkbox)
        $global:checkboxes += $checkbox
        $global:totalTasks++
        $yPos += 30

        # Add tooltip
        $tooltip = New-Object System.Windows.Forms.ToolTip
        $tooltip.SetToolTip($checkbox, "Instalacao do $item")
    }
}

# Function to ensure a service is running
function Ensure-ServiceRunning {
    param (
        [string]$serviceName,
        [int]$timeout = 60
    )
    try {
        Log-Message "Verificando status do servico: ${serviceName}"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service.Status -ne 'Running') {
            Log-Message "Iniciando servico: ${serviceName}"
            Start-Service -Name $serviceName
            $elapsedTime = 0
            while ((Get-Service -Name $serviceName).Status -ne 'Running' -and $elapsedTime -lt $timeout) {
                Start-Sleep -Seconds 1
                $elapsedTime++
            }
            if ((Get-Service -Name $serviceName).Status -ne 'Running') {
                throw "Timeout ao iniciar o servico ${serviceName}"
            }
            Log-Message "${serviceName} iniciado."
        } else {
            Log-Message "${serviceName} ja esta em execucao."
        }
    } catch {
        Handle-Error -operation "verificar ou iniciar o servico ${serviceName}" -exception $_
    }
    Update-Progress
}

# Function to stop a service if running
function Stop-ServiceIfRunning {
    param (
        [string]$serviceName,
        [int]$timeout = 60
    )
    try {
        Log-Message "Verificando status do servico: ${serviceName}"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service.Status -eq 'Running') {
            Log-Message "Parando servico: ${serviceName}"
            Stop-Service -Name $serviceName -Force
            $elapsedTime = 0
            while ((Get-Service -Name $serviceName).Status -eq 'Running' -and $elapsedTime -lt $timeout) {
                Start-Sleep -Seconds 1
                $elapsedTime++
            }
            if ((Get-Service -Name $serviceName).Status -eq 'Running') {
                throw "Timeout ao parar o servico ${serviceName}"
            }
            Log-Message "${serviceName} parado."
        } else {
            Log-Message "${serviceName} ja esta parado."
        }
    } catch {
        Handle-Error -operation "verificar ou parar o servico ${serviceName}" -exception $_
    }
    Update-Progress
}

# Function to ensure Winget is installed
function Ensure-WingetInstalled {
    try {
        Log-Message "Verificando se Winget esta instalado..."
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Log-Message "Winget nao encontrado, instalando..."
            Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
            Add-AppxPackage -Path "$env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        } else {
            Log-Message "Winget ja esta instalado."
        }
    } catch {
        Handle-Error -operation "verificar ou instalar Winget" -exception $_
    }
    Update-Progress
}

# Function to ensure WingetUI is installed
function Ensure-WingetUIInstalled {
    try {
        Log-Message "Verificando se WingetUI esta instalado..."
        if (-not (Get-Command wingetui -ErrorAction SilentlyContinue)) {
            Log-Message "WingetUI nao encontrado, instalando..."
            winget install SomePythonThings.WingetUIStore
        } else {
            Log-Message "WingetUI ja esta instalado."
        }
    } catch {
        Handle-Error -operation "verificar ou instalar WingetUI" -exception $_
    }
    Update-Progress
}

# Function to install or update applications
function InstallOrUpdate-Application {
    param (
        [string]$appId,
        [string]$packageManager = "winget"
    )
    try {
        Log-Message "Verificando instalacao ou atualizacao do aplicativo: ${appId} com ${packageManager}"
        $installedApp = &$packageManager list | Where-Object { $_ -match $appId }
        if ($installedApp) {
            Log-Message "Aplicativo ${appId} encontrado. Atualizando..."
            Start-Process $packageManager -ArgumentList "upgrade --id $appId --silent --accept-package-agreements --accept-source-agreements --force" -NoNewWindow -Wait
        } else {
            Log-Message "Instalando aplicativo: ${appId}"
            Start-Process $packageManager -ArgumentList "install --id $appId --silent --accept-package-agreements --accept-source-agreements --force" -NoNewWindow -Wait
        }
    } catch {
        Handle-Error -operation "instalar ou atualizar o aplicativo ${appId} com ${packageManager}" -exception $_
    }
    Update-Progress
}

# Function to update all applications
function Update-AllApplications {
    try {
        Log-Message "Atualizando todas as aplicacoes..."
        Ensure-WingetInstalled
        Ensure-WingetUIInstalled
        Start-Process "winget" -ArgumentList "source update" -NoNewWindow -Wait
        Start-Process "winget" -ArgumentList "upgrade --all --silent --accept-package-agreements --accept-source-agreements --force --include-unknown" -NoNewWindow -Wait
    } catch {
        Handle-Error -operation "atualizar todas as aplicacoes" -exception $_
    }

    # Update Pip packages
    try {
        if (Get-Command pip -ErrorAction SilentlyContinue) {
            Log-Message "Atualizando pacotes pip..."
            Start-Process "pip" -ArgumentList "install --upgrade pip" -NoNewWindow -Wait
            Start-Process "pip" -ArgumentList "list --outdated --format=freeze | %{$_.split('==')[0]} | % {pip install --upgrade $_}" -NoNewWindow -Wait
        } else {
            Log-Message "pip não está instalado." "WARNING"
        }
    } catch {
        Handle-Error -operation "atualizar pacotes pip" -exception $_
    }

    # Update npm packages
    try {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            Log-Message "Atualizando pacotes npm..."
            Start-Process "npm" -ArgumentList "install -g npm" -NoNewWindow -Wait
            Start-Process "npm" -ArgumentList "update -g" -NoNewWindow -Wait
        } else {
            Log-Message "npm não está instalado." "WARNING"
        }
    } catch {
        Handle-Error -operation "atualizar pacotes npm" -exception $_
    }
    Update-Progress
}

# Function to update Windows and drivers
function Update-WindowsAndDrivers {
    Log-Message "Atualizando Windows e drivers..."

    # Ensure BITS and Windows Installer services are running
    Ensure-ServiceRunning -serviceName "BITS"
    Ensure-ServiceRunning -serviceName "msiserver"
    Ensure-ServiceRunning -serviceName "wuauserv"

    # Windows Update - including optional updates and fixing common problems
    try {
        Log-Message "Executando atualizacoes do Windows..."
        # Remover atualizacoes do Microsoft Defender da lista
        $updates = Get-WindowsUpdate -MicrosoftUpdate | Where-Object { $_.Title -notmatch "Microsoft Defender" }
        Install-WindowsUpdate -Update $updates -AcceptAll -AutoReboot
    } catch {
        Handle-Error -operation "atualizacao do Windows" -exception $_
    }

    # Fix common Windows Update issues
    $updateFixes = @(
        "net stop wuauserv",
        "net stop cryptSvc",
        "net stop bits",
        "net stop msiserver",
        {
            try {
                Stop-ServiceIfRunning -serviceName "wuauserv"
                $destPath1 = "C:\Windows\SoftwareDistribution"
                if (Test-Path -Path $destPath1) {
                    Remove-Item -Path $destPath1 -Recurse -Force
                }
                Ensure-ServiceRunning -serviceName "wuauserv"
            } catch {
                Handle-Error -operation "mover SoftwareDistribution" -exception $_
            }
        },
        {
            try {
                Stop-ServiceIfRunning -serviceName "cryptSvc"
                $destPath2 = "C:\Windows\System32\catroot2"
                if (Test-Path -Path $destPath2) {
                    Remove-Item -Path $destPath2 -Recurse -Force
                }
                Ensure-ServiceRunning -serviceName "cryptSvc"
            } catch {
                Handle-Error -operation "mover catroot2" -exception $_
            }
        },
        "net start wuauserv",
        "net start cryptSvc",
        "net start bits",
        "net start msiserver"
    )

    foreach ($fix in $updateFixes) {
        try {
            Log-Message "Executando comando: ${fix}"
            if ($fix -is [ScriptBlock]) {
                & $fix
            } else {
                Invoke-Expression $fix
            }
        } catch {
            Handle-Error -operation ("executar comando {0}" -f $fix) -exception $_
        }
    }
    Update-Progress
}

# Function to perform a complete disk cleanup
function Complete-DiskCleanup {
    try {
        Log-Message "Executando limpeza completa de disco..."
        Cleanmgr /sagerun:1
    } catch {
        Handle-Error -operation "limpeza completa de disco" -exception $_
    }
    Update-Progress
}

# Function to clean temporary files and cache
function Clean-TemporaryFiles {
    Log-Message "Limpando arquivos temporarios e cache..."
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp\*",
        "$env:windir\Temp\*",
        "$env:SystemRoot\Prefetch\*",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*",
        "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCookies\*"
    )
    foreach ($path in $tempPaths) {
        try {
            Log-Message "Limpando: ${path}"
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
        } catch {
            Handle-Error -operation ("limpar {0}" -f $path) -exception $_
        }
    }
    Log-Message "Limpeza de arquivos temporarios e cache concluida."
    Update-Progress
}

# Function to activate Hyper-V
function Activate-HyperV {
    try {
        Log-Message "Verificando se o Hyper-V pode ser ativado..."
        $windowsEdition = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        if ($windowsEdition -match "Windows 10 Home") {
            Log-Message "Hyper-V nao e suportado no Windows 10 Home."
        } else {
            Log-Message "Ativando Hyper-V..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
            Log-Message "Hyper-V ativado."
        }
    } catch {
        Handle-Error -operation "ativar Hyper-V" -exception $_
    }
    Update-Progress
}

# Function to install Windows Sandbox
function Install-WindowsSandbox {
    try {
        Log-Message "Instalando Windows Sandbox..."
        Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart
        Log-Message "Windows Sandbox instalado."
    } catch {
        Handle-Error -operation "instalar Windows Sandbox" -exception $_
    }
    Update-Progress
}

# Function to apply high performance power plan settings
function Apply-HighPerformanceSettings {
    try {
        Log-Message "Aplicando configuracoes de alto desempenho..."
        powercfg -duplicatescheme SCHEME_MIN
        powercfg -setactive SCHEME_MIN
        powercfg -change monitor-timeout-ac 0
        powercfg -change monitor-timeout-dc 0
        powercfg -change disk-timeout-ac 0
        powercfg -change disk-timeout-dc 0
        powercfg -change standby-timeout-ac 0
        powercfg -change standby-timeout-dc 0
        powercfg -change hibernate-timeout-ac 0
        powercfg -change hibernate-timeout-dc 0
        Log-Message "Configuracoes de alto desempenho aplicadas. Reinicie o computador para concluir a configuracao."
    } catch {
        Handle-Error -operation "aplicar configuracoes de alto desempenho" -exception $_
    }
    Update-Progress
}

# Function to perform system maintenance
function Perform-WindowsMaintenance {
    Log-Message "Executando manutencao do Windows..."
    $timestamp = Get-Date -Format "dd_MM_yyyy_HH_mm"
    $maintenanceLog = "C:\Relatorio\J365_WIN_Maintenance_${timestamp}.txt"

    if (-not (Test-Path $maintenanceLog) -or ((Get-Date) - (Get-Item $maintenanceLog).LastWriteTime).TotalHours -gt 1) {
        try {
            Start-Process "sfc" -ArgumentList "/scannow" -NoNewWindow -Wait
            Start-Process "DISM" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait
            Start-Process "DISM" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" -NoNewWindow -Wait
            Log-Message "Manutencao do Windows concluida."
            Log-Message "Atualizando politicas de grupo..."
            gpupdate /force | Out-File -FilePath $maintenanceLog -Append
            Log-Message "Limpando DNS..."
            ipconfig /flushdns | Out-File -FilePath $maintenanceLog -Append
        } catch {
            Handle-Error -operation "manutencao do Windows" -exception $_
        }
    } else {
        Log-Message "Manutencao do Windows ja realizada recentemente. Pulando etapa."
    }
    Update-Progress
}

# Function to optimize Windows for performance
function Optimize-Windows {
    Log-Message "Otimizando o Windows para desempenho..."

    # Set visual effects for best performance
    try {
        $visualEffectsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        Set-ItemProperty -Path $visualEffectsKey -Name "VisualFXSetting" -Value 2
    } catch {
        Handle-Error -operation "configurar os efeitos visuais" -exception $_
    }

    Log-Message "Otimização do Windows concluida."
    Update-Progress
}

# Function to force close processes
function Force-CloseProcesses {
    param (
        [string]$processName
    )
    Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force
}

# Function to execute tasks based on selected checkboxes
function Execute-Tasks {
    Start-Logging

    $global:completedTasks = 0
    $tasks = @()
    foreach ($checkbox in $global:checkboxes) {
        if ($checkbox.Checked) {
            $tasks += $checkbox.Text
        }
    }
    $global:totalTasks = $tasks.Count * $global:tasksPerStep

    foreach ($task in $tasks) {
        $progressLabel.Text = "Executando $task..."
        Log-Message "Executando $task..."
        Update-Progress 0

        try {
            switch ($task) {
                "Microsoft 365 Apps" { InstallOrUpdate-Application "Microsoft.Office" }
                "Teams Trabalho" { InstallOrUpdate-Application "Microsoft.Teams" }
                "Teams Pessoal" { InstallOrUpdate-Application "Microsoft.Teams.Free" }
                "PowerShell 7" { InstallOrUpdate-Application "Microsoft.PowerShell" }
                "Microsoft Graph" { InstallOrUpdate-Application "Microsoft.Graph" }
                "OneDrive" { InstallOrUpdate-Application "Microsoft.OneDrive" }
                "DotNet" { InstallOrUpdate-Application "Microsoft.DotNet" }
                "VCRedist 2015+" { InstallOrUpdate-Application "Microsoft.VCRedist.2015+.x64" }
                "Arc" { InstallOrUpdate-Application "TheBrowserCompany.Arc" }
                "Firefox" { InstallOrUpdate-Application "Mozilla.Firefox" }
                "Chrome" { InstallOrUpdate-Application "Google.Chrome" }
                "Opera GX" { InstallOrUpdate-Application "Opera.OperaGX" }
                "Opera One" { InstallOrUpdate-Application "Opera.Opera" }
                "Edge" { InstallOrUpdate-Application "Microsoft.Edge" }
                "Vivaldi" { InstallOrUpdate-Application "VivaldiTechnologies.Vivaldi" }
                "Brave" { InstallOrUpdate-Application "Brave.Brave" }
                "7zip" { InstallOrUpdate-Application "7zip.7zip" }
                "AnyDesk" { InstallOrUpdate-Application "AnyDesk.SoftwareGmbH" }
                "TeamViewer" { InstallOrUpdate-Application "TeamViewer.TeamViewer" }
                "Remote Desktop Manager" { InstallOrUpdate-Application "Devolutions.RemoteDesktopManager" }
                "FortiClient VPN" { InstallOrUpdate-Application "Fortinet.FortiClientVPN" }
                "ScreenShot HD" { InstallOrUpdate-Application "Screenpresso.Screenpresso" }
                "Lightshot" { InstallOrUpdate-Application "Skillbrains.Lightshot" }
                "Telegram" { InstallOrUpdate-Application "Telegram.TelegramDesktop" }
                "Discord" { InstallOrUpdate-Application "Discord.Discord" }
                "WhatsApp Web" { InstallOrUpdate-Application "WhatsApp.WhatsAppDesktop" }
                "Hyper-V" { Activate-HyperV }
                "Windows SandBox" { Install-WindowsSandbox }
                "Winget" { Ensure-WingetInstalled }
                "Atualizar todas as aplicacoes" { Update-AllApplications }
                "Atualizar Windows e Drivers" { Update-WindowsAndDrivers }
                "Limpeza completa de disco" { Complete-DiskCleanup }
                "Manutencao do Windows" { Perform-WindowsMaintenance }
                "Modo Alto Desempenho" { 
                    Apply-HighPerformanceSettings
                    Log-Message "As configuracoes de alto desempenho foram aplicadas. Reinicie o computador para concluir a configuracao." 
                }
                "Otimizar Windows" { Optimize-Windows }
                default { Log-Message "Tarefa desconhecida: $task" "WARNING" }
            }
        } catch {
            Handle-Error -operation "executar $task" -exception $_
        }
    }

    $progressLabel.Text = "100% Concluido. Reinicie o dispositivo para concluir as configuracoes."
    $progressBar.Value = 100
    $progressBar.Refresh()
    Log-Message "Todas as operacoes foram concluidas com sucesso."
    Stop-Logging
}

# Create categories and add checkboxes
$categories = @{
    "Microsoft" = @("Microsoft 365 Apps", "Teams Trabalho", "Teams Pessoal", "PowerShell 7", "Microsoft Graph", "OneDrive", "DotNet", "VCRedist 2015+")
    "Navegadores" = @("Arc", "Firefox", "Chrome", "Opera GX", "Opera One", "Edge", "Vivaldi", "Brave")
    "Utilitarios" = @("7zip", "AnyDesk", "TeamViewer", "Remote Desktop Manager", "FortiClient VPN", "ScreenShot HD", "Lightshot", "Telegram", "Discord", "WhatsApp Web")
    "Sistema" = @("Hyper-V", "Windows SandBox", "Winget", "Atualizar todas as aplicacoes", "Atualizar Windows e Drivers", "Limpeza completa de disco", "Manutencao do Windows", "Modo Alto Desempenho", "Otimizar Windows")
}

# Create the main form
$form = New-UIElement -type "Form" -properties @{
    Text = "Jornada 365 - Windows Tools"
    Size = New-Object System.Drawing.Size(960, 720)
    StartPosition = "CenterScreen"
    BackColor = [System.Drawing.Color]::White
    FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    MaximizeBox = $false
    MinimizeBox = $true
    ShowInTaskbar = $true
    AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    TopMost = $false
}

# Allow the form to be draggable
$form.Add_MouseDown({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $form.Capture = $true
        $form.Tag = [System.Drawing.Point]::Subtract($form.PointToScreen([System.Windows.Forms.Control]::MousePosition), [System.Drawing.Size]$form.Location)
    }
})

$form.Add_MouseMove({
    if ($form.Capture -and $_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $form.Location = [System.Drawing.Point]::Subtract($form.PointToScreen([System.Windows.Forms.Control]::MousePosition), [System.Drawing.Size]$form.Tag)
    }
})

$form.Add_MouseUp({
    $form.Capture = $false
})

# Add logo
$logo = New-UIElement -type "PictureBox" -properties @{
    ImageLocation = "https://jornada365.cloud/wp-content/uploads/2024/03/Logotipo-Jornada-365-Home.png"
    SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    Size = New-Object System.Drawing.Size(180, 60)
    Location = New-Object System.Drawing.Point(20, 10)
}
$form.Controls.Add($logo)

# Add title label
$titleLabel = New-UIElement -type "Label" -properties @{
    Text = "Jornada 365 - Windows Tools"
    Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
    Size = New-Object System.Drawing.Size(600, 40)
    Location = New-Object System.Drawing.Point(240, 10)  # Adjusted to the right
    TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
}
$form.Controls.Add($titleLabel)

# Add subtitle label
$subtitleLabel = New-UIElement -type "Label" -properties @{
    Text = "Sua jornada comeca aqui  |  jornada365.cloud"
    Font = New-Object System.Drawing.Font("Segoe UI", 12)
    Size = New-Object System.Drawing.Size(600, 25)
    Location = New-Object System.Drawing.Point(240, 50)  # Adjusted to the right
    TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
}
$form.Controls.Add($subtitleLabel)

# Panel to hold checkboxes
$panel = New-UIElement -type "Panel" -properties @{
    Location = New-Object System.Drawing.Point(10, 90)
    Size = New-Object System.Drawing.Size(940, 400)
    BackColor = [System.Drawing.Color]::White
}
$form.Controls.Add($panel)

# Initialize positions
$initialXPos = 10
$initialYPos = 10
$columnWidth = 230

# Add categories and checkboxes to the panel
$xPos = $initialXPos
foreach ($category in $categories.Keys) {
    Add-CategoryAndCheckboxes -category $category -items $categories[$category] -xPos $xPos -yPos $initialYPos
    $xPos += $columnWidth
    if ($xPos + $columnWidth > $panel.Width) {
        $xPos = $initialXPos
        $initialYPos += 380
    }
}

# Progress bar and label
$progressLabel = New-UIElement -type "Label" -properties @{
    Text = "Progresso..."
    Font = New-Object System.Drawing.Font("Segoe UI", 10)
    Size = New-Object System.Drawing.Size(940, 20)
    Location = New-Object System.Drawing.Point(10, 490)
    TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
}
$form.Controls.Add($progressLabel)

$progressBar = New-UIElement -type "ProgressBar" -properties @{
    Size = New-Object System.Drawing.Size(600, 15)
    Location = New-Object System.Drawing.Point(180, 510)
    Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    ForeColor = [System.Drawing.Color]::DodgerBlue
    BackColor = [System.Drawing.Color]::LightGray
    MarqueeAnimationSpeed = 20
}
$form.Controls.Add($progressBar)

# Buttons panel
$buttonPanel = New-UIElement -type "Panel" -properties @{
    Location = New-Object System.Drawing.Point(10, 540)
    Size = New-Object System.Drawing.Size(940, 60)
    BackColor = [System.Drawing.Color]::White
}
$form.Controls.Add($buttonPanel)

# Function to create standard buttons
function Create-Button {
    param (
        [string]$text,
        [int]$xPos,
        [scriptblock]$onClick
    )
    $button = New-UIElement -type "Button" -properties @{
        Text = $text
        Size = New-Object System.Drawing.Size(200, 40)
        Location = New-Object System.Drawing.Point($xPos, 10)
        Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        BackColor = [System.Drawing.Color]::Black
        ForeColor = [System.Drawing.Color]::White
        TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        Cursor = [System.Windows.Forms.Cursors]::Hand
    }

    $button.FlatAppearance.BorderSize = 0
    $button.Add_Click($onClick)
    return $button
}

# Add buttons and centralize them
$buttons = @()
$buttons += Create-Button -text "Executar Todos" -xPos 10 -onClick {
    foreach ($checkbox in $global:checkboxes) {
        $checkbox.Checked = $true
    }
    Execute-Tasks
}
$buttons += Create-Button -text "Executar Selecionados" -xPos 220 -onClick {
    Execute-Tasks
}
$selectAllButton = Create-Button -text "Selecionar Todos" -xPos 430 -onClick {
    if ($selectAllButton.Text -eq "Selecionar Todos") {
        foreach ($checkbox in $global:checkboxes) {
            $checkbox.Checked = $true
        }
        $selectAllButton.Text = "Desmarcar Todos"
    } else {
        foreach ($checkbox in $global:checkboxes) {
            $checkbox.Checked = $false
        }
        $selectAllButton.Text = "Selecionar Todos"
    }
}
$buttons += $selectAllButton
$buttons += Create-Button -text "Encerrar" -xPos 640 -onClick {
    $form.Close()
}

# Calculate the center position for buttons
$buttonPanelWidth = $buttonPanel.Width
$totalButtonWidth = ($buttons | Measure-Object -Property Width -Sum).Sum + (($buttons.Count - 1) * 20)
$startXPos = [math]::Round(($buttonPanelWidth - $totalButtonWidth) / 2)

# Set button positions dynamically
$xPos = $startXPos
foreach ($button in $buttons) {
    $button.Location = New-Object System.Drawing.Point($xPos, 10)
    $buttonPanel.Controls.Add($button)
    $xPos += $button.Width + 20
}

# Run the form
[void]$form.ShowDialog()
