### README.md

# Jornada 365 - Windows Tools

![Jornada 365 Logo](https://jornada365.cloud/wp-content/uploads/2024/03/Logotipo-Jornada-365-Home.png)

Este repositório contém um script em PowerShell para automatizar a instalação, atualização e manutenção de várias ferramentas e configurações no Windows. Este script foi projetado para ser utilizado por administradores de sistema, engenheiros de TI e entusiastas que desejam otimizar e gerenciar suas máquinas Windows de forma eficiente.

## Funcionalidades

![Jornada 365 Logo](https://github.com/sesantanajr/j365_WinTools/blob/main/Jornada365-WindowsTools.png)

O script "Jornada 365 - Windows Tools" oferece as seguintes funcionalidades principais:

1. **Instalação e Atualização de Aplicativos**:
   - Microsoft 365
   - Microsoft Teams (Trabalho e Pessoal)
   - PowerShell 7
   - Microsoft Graph
   - OneDrive
   - .NET
   - VCRedist 2015+
   - Vários navegadores (Arc, Firefox, Chrome, Opera GX, Opera One, Edge, Vivaldi, Brave)
   - Utilitários (7zip, AnyDesk, TeamViewer, Remote Desktop Manager, FortiClient VPN, ScreenShot HD, Lightshot, Telegram, Discord, WhatsApp Web)

2. **Configurações do Sistema**:
   - Ativação do Hyper-V
   - Instalação do Windows Sandbox
   - Instalação do Winget
   - Atualização de todas as aplicações instaladas via Winget, Chocolatey, Scoop e WingetUI
   - Atualização do Windows e drivers
   - Limpeza completa de disco
   - Manutenção do Windows
   - Aplicação de configurações de alto desempenho
   - Otimização do Windows para melhor desempenho

3. **Interface Gráfica (GUI)**:
   - Uma interface gráfica interativa e amigável construída usando Windows Forms
   - Barras de progresso e logs detalhados para acompanhar a execução das tarefas

## Como Utilizar

### Requisitos

- Windows 10 ou superior
- PowerShell 5.1 ou PowerShell 7
- Conexão com a Internet para baixar e instalar as aplicações

### Passos para Execução

1. **Clone o Repositório**:
   ```sh
   git clone https://github.com/seu-usuario/j365_WinTools.git
   cd j365_WinTools
   ```

2. **Execute o Script**:
   Abra o PowerShell como administrador e execute o script:
   ```sh
   .\j365_WinTools.ps1
   ```

### Estrutura do Script

O script é dividido em várias seções para garantir modularidade e clareza:

1. **Inicialização e Definições Globais**:
   - Carrega as bibliotecas necessárias para Windows Forms e System.Drawing
   - Define variáveis globais para gerenciar checkboxes, progresso e tarefas

2. **Funções Auxiliares**:
   - `New-UIElement`: Criação de elementos da GUI dinamicamente
   - `Log-Message`: Registro de mensagens de log com níveis de severidade
   - `Handle-Error`: Tratamento de erros e exceções
   - `Start-Logging` e `Stop-Logging`: Início e término do registro de logs

3. **Funções de Tarefas**:
   - `Ensure-ServiceRunning` e `Stop-ServiceIfRunning`: Gerenciamento de serviços do Windows
   - `Ensure-WingetInstalled`, `Ensure-ScoopInstalled`, `Ensure-WingetUIInstalled`: Verificação e instalação de gerenciadores de pacotes
   - `InstallOrUpdate-Application`: Instalação ou atualização de aplicações específicas
   - `Update-AllApplications`: Atualização de todas as aplicações instaladas
   - `Update-WindowsAndDrivers`: Atualização do Windows e drivers
   - `Complete-DiskCleanup`, `Clean-TemporaryFiles`: Limpeza de disco e arquivos temporários
   - `Activate-HyperV`, `Install-WindowsSandbox`: Configurações de virtualização
   - `Apply-HighPerformanceSettings`: Aplicação de configurações de alto desempenho
   - `Perform-WindowsMaintenance`: Execução de manutenção do Windows
   - `Optimize-Windows`: Otimização do Windows para desempenho

4. **Interface Gráfica**:
   - Criação e configuração da janela principal e seus elementos (labels, checkboxes, botões, barras de progresso)

5. **Execução das Tarefas**:
   - Função `Execute-Tasks`: Execução das tarefas selecionadas pelo usuário na GUI

### Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e enviar pull requests para melhorias no script e na documentação.
