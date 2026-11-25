# Fake Game + Quest Scanner
 
Abra o **PowerShell** (tecla Windows, digite `powershell`, Enter) e cole um dos comandos abaixo.
 
## Rodar direto (recomendado)
 
Baixa a versao mais nova e ja abre, sem deixar arquivo na Area de Trabalho:
 
```powershell
irm https://raw.githubusercontent.com/Ny3san/FakeGame_QuestScanner/main/FakeGame.bat -OutFile "$env:TEMP\FakeGame.bat"; Start-Process "$env:TEMP\FakeGame.bat"
```
 
## Baixar na Area de Trabalho e abrir
 
```powershell
irm https://raw.githubusercontent.com/Ny3san/FakeGame_QuestScanner/main/FakeGame.bat -OutFile "$HOME\Desktop\FakeGame.bat"; Start-Process "$HOME\Desktop\FakeGame.bat"
```
 
> Baixando pelo navegador o Windows marca o arquivo como "da internet" e o
> Controle de Aplicativo Inteligente bloqueia. Baixando por esses comandos, nao.
 
O `QuestScanner.ps1` nao precisa ser baixado: o `.bat` baixa sozinho quando voce escolhe a opcao 8.
 
---
 
## Linux (somente o Quest Scanner)
 
O `.bat` e exclusivo do Windows. No Linux da para rodar apenas o scanner de missoes.
 
### 1. Instalar o PowerShell (Fedora)
 
```bash
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
curl -sSL https://packages.microsoft.com/config/rhel/9/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
sudo dnf install powershell
```
 
> Se o `dnf` reclamar de dependencia, baixe o `.rpm` mais recente em
> https://github.com/PowerShell/PowerShell/releases e instale com
> `sudo dnf install ./powershell-*.rpm`.
 
### 2. Rodar o scanner
 
```bash
pwsh -c "irm https://raw.githubusercontent.com/Ny3san/FakeGame_QuestScanner/main/QuestScanner.ps1 | iex"
```
 
