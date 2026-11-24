@echo off
chcp 65001 >nul

:: ---- [UI] cores ANSI (somente visual) ----
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "cR=%ESC%[0m"
set "cCy=%ESC%[96m"
set "cDc=%ESC%[36m"
set "cW=%ESC%[97m"
set "cGr=%ESC%[90m"
set "cG=%ESC%[92m"
set "cY=%ESC%[93m"
set "cRd=%ESC%[91m"
set "cM=%ESC%[95m"

:: Verifica se esta como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo   %cY%[..]%cR% Solicitando permissao de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion
title Fake Game + Quest Scanner
color 0B

set "BASE=%LOCALAPPDATA%\FakeGameHelper"
set "FAKEBASE=%BASE%\fake_base.exe"

:: De onde o scanner .ps1 e baixado (API do GitHub = sem cache atrasado do raw)
set "PSURL=https://api.github.com/repos/Ny3san/FakeGame_QuestScanner/contents/QuestScanner.ps1?ref=main"
:: Copia baixada, executada a partir da pasta temp
set "PSDIR=%TEMP%\FakeGameHelper"
set "PSFILE=%PSDIR%\QuestScanner.ps1"
:: Reserva: ps1 que esteja do lado do .bat
set "PSLOCAL=%~dp0QuestScanner.ps1"

if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1
if not exist "%PSDIR%" mkdir "%PSDIR%" >nul 2>&1

:menu
set "GEXE="
set "GNAME="
set "QGAME="
set "QNAME="
set "QORB="
set "QTASKS="
set "QEND="
set "QLINK="
set "QEXE="
set "QTEXT="
set "HORAS="
set "OP="
set "TOP="
set "SEL="
set "QN=0"

cls
echo.
echo   %cDc%+------------------------------------------+%cR%
echo   %cDc%^|%cR%   %cW%F A K E   G A M E%cR%  %cGr%+%cR%  %cCy%QUEST SCANNER%cR%    %cDc%^|%cR%
echo   %cDc%+------------------------------------------+%cR%
echo.
echo   %cGr%-- QUESTS ATIVAS --------------------------%cR%
echo.

for /f "usebackq tokens=1-9 delims=|" %%A in (`findstr /b /c:"::Q|" "%~f0"`) do (
    set /a QN+=1
    echo     %cCy%[%%B]%cR%  %cW%%%D%cR%  %cGr%+%cR%  %cM%%%E Orbs%cR%
)

if "%QN%"=="0" (
    echo     %cGr%Nenhuma missao carregada.%cR%
    echo     %cGr%Use a opcao 8 para consultar o scanner.%cR%
)

echo.
echo   %cGr%-- FERRAMENTAS ----------------------------%cR%
echo.
echo     %cM%[8]%cR%  %cW%Atualizar missoes%cR% %cGr%(scanner)%cR%
echo     %cRd%[0]%cR%  %cW%Fechar todos%cR%
echo.
echo   %cGr%-------------------------------------------%cR%
echo.
set /p "OP=  %cCy%>%cR% Opcao %cGr%[1]%cR%: "
if "%OP%"=="" set OP=1
set "OP=%OP:"=%"
set "OP=%OP:(=%"
set "OP=%OP:)=%"
if "%OP%"=="0" goto :parar
if "%OP%"=="8" goto :scanner

for /f "usebackq tokens=1-9 delims=|" %%A in (`findstr /b /c:"::Q|" "%~f0"`) do (
    if "%%B"=="%OP%" (
        set "SEL=1"
        set "QGAME=%%C"
        set "QNAME=%%D"
        set "QORB=%%E"
        set "QTASKS=%%F"
        set "QEND=%%G"
        set "QLINK=%%H"
        set "QEXE=%%I"
        set "QTEXT=%BASE%\q%%B.txt"
    )
)

if not defined SEL (
    echo.
    echo   %cRd%[X]%cR% Opcao invalida.
    echo.
    pause
    goto :menu
)
if not defined QEXE set "QEXE=mission.exe"

echo.
echo   %cGr%-- TEMPO ----------------------------------%cR%
echo.
echo     %cCy%[1]%cR%  %cW%15 min%cR%
echo     %cCy%[2]%cR%  %cW%30 min%cR%
echo     %cCy%[3]%cR%  %cW%1 hora%cR%
echo     %cCy%[4]%cR%  %cW%2 horas%cR%
echo.
set /p "TOP=  %cCy%>%cR% Opcao %cGr%[1]%cR%: "
if "%TOP%"=="" set TOP=1
if "%TOP%"=="1" set HORAS=0.25
if "%TOP%"=="2" set HORAS=0.5
if "%TOP%"=="3" set HORAS=1
if "%TOP%"=="4" set HORAS=2
if not defined HORAS set HORAS=0.25

echo.
echo   %cGr%-------------------------------------------%cR%
echo.
echo   %cY%[..]%cR% Preparando...

call :build
if not exist "%FAKEBASE%" (
    echo.
    pause
    goto :menu
)

echo   %cG%[OK]%cR% Compilado com sucesso

set "INST=%BASE%\i%RANDOM%"
mkdir "%INST%" >nul 2>&1
set "DEST=%INST%\%QEXE%"
copy /y "%FAKEBASE%" "%DEST%" >nul

powershell -NoProfile -Command "Unblock-File '%DEST%' -ErrorAction SilentlyContinue" >nul 2>&1

echo   %cG%[OK]%cR% Iniciando %cW%%QGAME%%cR% %cGr%(%HORAS%h)%cR%

start "" "%DEST%" %HORAS% "%QGAME% - %QNAME%" normal "%QTEXT%"

echo.
echo   %cY%[i]%cR%  %cGr%Se aparecer aviso do Windows:%cR% %cW%Mais informacoes%cR% %cGr%-%cR% %cW%Executar mesmo assim%cR%
echo.
pause
goto :menu

:scanner
echo.
echo   %cY%[..]%cR% Baixando o QuestScanner.ps1...

set "TEMPS="
del /f /q "%PSFILE%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Headers @{'Accept'='application/vnd.github.raw'; 'User-Agent'='FakeGame'} -Uri ('%PSURL%' + '&t=' + [DateTime]::UtcNow.Ticks) -OutFile '%PSFILE%' -TimeoutSec 25; exit 0 } catch { exit 1 }"
if exist "%PSFILE%" for %%A in ("%PSFILE%") do if %%~zA GTR 2000 set "TEMPS=1"

:: Se o arquivo baixado for uma versao antiga (sem exportacao), descarta e usa a copia local.
if defined TEMPS (
    findstr /c:"SpliceBat" "%PSFILE%" >nul 2>&1
    if errorlevel 1 set "TEMPS="
)

if not defined TEMPS (
    del /f /q "%PSFILE%" >nul 2>&1
    if exist "%PSLOCAL%" (
        echo   %cY%[i]%cR% Baixei uma versao antiga ou falhou. Usando a copia local...
        copy /y "%PSLOCAL%" "%PSFILE%" >nul
        findstr /c:"SpliceBat" "%PSFILE%" >nul 2>&1
        if not errorlevel 1 set "TEMPS=1"
    )
)

if not defined TEMPS (
    echo.
    echo   %cRd%[X]%cR% O QuestScanner.ps1 baixado esta desatualizado e nao ha copia local valida.
    echo       %cGr%Baixe o QuestScanner.ps1 novo e coloque ao lado do .bat, ou tente de novo em alguns minutos.%cR%
    echo.
    pause
    goto :menu
)

echo   %cG%[OK]%cR% Pronto %cGr%- %PSFILE%%cR%
echo.

:: O scanner coleta as quests e reescreve o bloco "::Q|..." no fim deste .bat.
:: Se algo mudou, ele grava "%~f0.new" e a gente troca o arquivo em execucao.
:: O bloco fica no fim do arquivo justamente para os offsets das linhas nao mudarem.
del /f /q "%~f0.new" >nul 2>&1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%" -ExportDir "%BASE%" -SpliceBat "%~f0"

if exist "%~f0.new" (
    move /y "%~f0.new" "%~f0" >nul 2>&1
    echo.
    echo   %cG%[OK]%cR% Menu atualizado com as quests do scanner.
) else (
    echo.
    echo   %cY%[i]%cR% Nenhuma alteracao necessaria no menu.
)
echo.
pause
goto :menu

:parar
powershell -NoProfile -Command "Get-Process | Where-Object { $_.Path -like ($env:LOCALAPPDATA + '\FakeGameHelper\*') } | Stop-Process -Force" >nul 2>&1
for /d %%D in ("%BASE%\i*") do rmdir /s /q "%%D" >nul 2>&1
echo.
echo   %cG%[OK]%cR% Tudo fechado.
echo.
pause
goto :menu

:build
rem Gera/reaproveita fake_base.exe (janela fake). A flag v2 forca recompilar.
if exist "%FAKEBASE%" if exist "%BASE%\v2.flag" exit /b 0

del /f /q "%FAKEBASE%" >nul 2>&1
del /f /q "%BASE%\fake.cs" >nul 2>&1
del /f /q "%BASE%\v2.flag" >nul 2>&1

(
echo using System;
echo using System.Globalization;
echo using System.IO;
echo using System.Text;
echo using System.Windows.Forms;
echo using System.Drawing;
echo class P {
echo   [STAThread] static void Main^(string[] a^) {
echo     double h = 0.25;
echo     try { h = double.Parse^(a[0].Replace^(",", "."^), CultureInfo.InvariantCulture^); } catch {}
echo     if ^(h ^<= 0^) h = 0.25;
echo     DateTime fim = DateTime.Now.AddHours^(h^);
echo     string titulo = a.Length ^> 1 ? a[1] : "Missao";
echo     string texto = null;
echo     if ^(a.Length ^> 3 ^&^& a[3].Length ^> 0 ^&^& File.Exists^(a[3]^)^) {
echo       try { texto = File.ReadAllText^(a[3], Encoding.UTF8^); } catch {}
echo     }
echo     if ^(texto == null ^|^| texto.Trim^(^).Length == 0^) {
echo       string tipo = a.Length ^> 2 ? a[2] : "normal";
echo       if ^(tipo == "dune"^) texto = "MISSAO: DUNE PART THREE\r\n\r\nReivindique 840 Orbs\r\nAssemble, prime, and pack Thumpers";
echo       else if ^(tipo == "exterm"^) texto = "MISSAO: EXTERMINAUTS TRAILER\r\n\r\nReivindique 240 Orbs\r\nAssista ao video para ganhar 240 Orbs";
echo       else texto = "Jogo / Missao ativo...";
echo     }
echo     Form f = new Form^(^);
echo     f.Text = titulo;
echo     f.Size = new Size^(640, 420^);
echo     f.MinimumSize = new Size^(420, 280^);
echo     f.StartPosition = FormStartPosition.CenterScreen;
echo     f.BackColor = Color.FromArgb^(30, 20, 50^);
echo     f.ForeColor = Color.FromArgb^(180, 140, 255^);
echo     Label rodape = new Label^(^);
echo     rodape.Dock = DockStyle.Bottom;
echo     rodape.Height = 30;
echo     rodape.TextAlign = ContentAlignment.MiddleCenter;
echo     rodape.BackColor = Color.FromArgb^(20, 12, 36^);
echo     rodape.ForeColor = Color.FromArgb^(130, 100, 190^);
echo     rodape.Font = new Font^("Segoe UI", 9, FontStyle.Regular^);
echo     TextBox box = new TextBox^(^);
echo     box.Multiline = true;
echo     box.ReadOnly = true;
echo     box.BorderStyle = BorderStyle.None;
echo     box.ScrollBars = ScrollBars.Vertical;
echo     box.Dock = DockStyle.Fill;
echo     box.BackColor = Color.FromArgb^(30, 20, 50^);
echo     box.ForeColor = Color.FromArgb^(180, 140, 255^);
echo     box.TextAlign = HorizontalAlignment.Center;
echo     box.Font = new Font^("Segoe UI", 11, FontStyle.Bold^);
echo     box.Text = texto;
echo     f.Controls.Add^(box^);
echo     f.Controls.Add^(rodape^);
echo     Timer t = new Timer^(^);
echo     t.Interval = 1000;
echo     t.Tick += delegate {
echo       TimeSpan left = fim - DateTime.Now;
echo       if ^(left.TotalSeconds ^<= 0^) { f.Close^(^); return; }
echo       if ^(left.TotalDays ^>= 1^) rodape.Text = string.Format^("{0}d {1}h restantes", ^(int^)left.TotalDays, left.Hours^);
echo       else if ^(left.TotalHours ^>= 1^) rodape.Text = string.Format^("{0}h {1}min restantes", ^(int^)left.TotalHours, left.Minutes^);
echo       else rodape.Text = string.Format^("{0}min restantes", ^(int^)left.TotalMinutes + 1^);
echo     };
echo     t.Start^(^);
echo     Application.Run^(f^);
echo   }
echo }
) > "%BASE%\fake.cs"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if not exist "%CSC%" (
    echo   %cRd%[X]%cR% Nao encontrei o compilador csc.exe
    exit /b 1
)

"%CSC%" /nologo /target:winexe /out:"%FAKEBASE%" /r:System.Windows.Forms.dll /r:System.Drawing.dll "%BASE%\fake.cs"

if not exist "%FAKEBASE%" (
    echo.
    echo   %cRd%[X]%cR% Falhou ao compilar.
    exit /b 1
)

echo ok > "%BASE%\v2.flag"
exit /b 0

:: ===== QUESTS:BEGIN =====
::Q|1|Arknights: Endfield|New Operator: Argent Flow|700|PLAY_ON_DESKTOP, PLAY_ON_PLAYSTATION|25/11 01:00|https://akendfield.gryphline.com/d27t/V1D6DPQ|Endfield.exe
::Q|2|Roblox|Illegal Soccer|700|PLAY_ON_DESKTOP|25/11 22:00|https://www.roblox.com/pl/games/126987974021910/Illegal-Soccer?gsrb...|Roblox.exe
::Q|3|Firefox|Firefox Browser|700|PLAY_ON_DESKTOP|06/12 22:00|https://firefox.com/get/?p=discord utm_source=discord utm_campaign=...|Firefox.exe
::Q|4|EVE Online|EVE Online|700|PLAY_ON_DESKTOP|07/12 22:00|https://www.eveonline.com/?utm_source=discord utm_medium=cpm utm_ca...|exefile.exe
::Q|5|Where Winds Meet|Anniversary Claim over $150 in rewards|700|PLAY_ON_DESKTOP, PLAY_ON_PLAYSTATION|19/12 04:59|https://store.steampowered.com/app/3564740/480?utm_source=DiscordOrbs|wwm.exe
:: ===== QUESTS:END =====
