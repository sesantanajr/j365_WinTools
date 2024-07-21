### README.md

# Jornada 365 - Windows Tools

![Jornada 365 Logo](https://jornada365.cloud/wp-content/uploads/2024/03/Logotipo-Jornada-365-Home.png)

## Descrição

**Jornada 365 - Windows Tools** é um script de pós-instalação do Windows desenvolvido para otimizar, atualizar e manter sistemas Windows 10 e 11. Este script oferece uma interface gráfica amigável para selecionar e executar diversas tarefas, como instalação de aplicativos, atualização de drivers e otimização do sistema.

## Funcionalidades

- **Instalação de Aplicativos**: Instala e atualiza uma variedade de aplicativos populares, incluindo navegadores, utilitários e ferramentas de produtividade.
- **Atualização de Drivers e Windows**: Garante que o Windows e todos os drivers estejam atualizados, incluindo atualizações opcionais.
- **Otimização do Sistema**: Desativa serviços desnecessários, remove programas de inicialização indesejados e ajusta as configurações visuais para o melhor desempenho.
- **Limpeza de Disco**: Realiza uma limpeza completa do disco, incluindo arquivos temporários e cache.
- **Manutenção do Windows**: Executa comandos como `sfc`, `dism`, `chkdsk`, `gpupdate` e `ipconfig` para garantir a integridade e a performance do sistema.
- **Modo de Alto Desempenho**: Configura o plano de energia para maximizar o desempenho.
- **Instalação de Dependências**: Instala e atualiza automaticamente todas as dependências necessárias, como o Microsoft Visual C++.

- ![Jornada 365 Windows Tools](https://github.com/sesantanajr/j365_WinTools/blob/main/jornada365%20-%20windowns%20tools.png)

## Instruções de Uso

1. **Baixe o Script**: Baixe o script `Jornada365_WindowsTools.ps1` do repositório.
2. **Execute o Script**: Abra o PowerShell como administrador e execute o script:
   ```powershell
   cd ~\Downloads
   powershell -ExecutionPolicy Bypass -File .\j365_WinTools.ps1
   ```
3. **Selecione as Tarefas**: Use a interface gráfica para selecionar as tarefas que deseja executar.
4. **Execute**: Clique no botão "Executar Selecionados" para iniciar as tarefas escolhidas.

## Tarefas Disponíveis

### Microsoft
- Microsoft 365
- Microsoft Teams Trabalho
- Microsoft Teams Pessoal
- PowerShell 7
- Microsoft Graph
- OneDrive
- NetFramework
- Microsoft Visual C++

### Navegadores
- Arc
- Firefox
- Chrome
- Opera GX
- Opera One
- Edge
- Vivaldi
- Brave

### Utilitários
- 7zip
- AnyDesk
- TeamViewer
- Remote Desktop Manager
- FortiClient VPN
- ScreenShot HD
- Lightshot
- Telegram
- Discord
- WhatsApp Web

### Sistema
- Hyper-V
- Windows SandBox
- Winget
- Atualizar todas as aplicações
- Atualizar Windows e Drivers
- Limpeza completa de disco
- Manutenção do Windows
- Modo Alto Desempenho
- Otimizar Windows

## Solução de Problemas

- **Código de Saída 6 do Winget**: O script fecha automaticamente todos os processos relacionados antes de iniciar a instalação ou atualização.
- **Comando DISM**: O comando `dism` é executado com um tempo limite para evitar travamentos.
- **Instalação de Dependências**: Todas as dependências necessárias são instaladas e atualizadas automaticamente.
- 
---

**Jornada 365 - Windows Tools** é desenvolvido e mantido por [Sérgio Sant'Ana Júnior](https://jornada365.cloud).

---

Se precisar de mais informações ou tiver dúvidas, entre em contato pelo site [Jornada 365](https://jornada365.cloud).
