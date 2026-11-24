# ============================================================
#  Fake Game - Quest Scanner
# ============================================================

$ErrorActionPreference = 'Stop'

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { $Host.UI.RawUI.WindowTitle = "Fake Game - Quest Scanner" } catch {}
Clear-Host

# ---------- Caracteres de moldura (gerados por codigo, arquivo fica 100% ASCII) ----------
$B = @{
    TL = [char]0x256D; TR = [char]0x256E; BL = [char]0x2570; BR = [char]0x256F
    H  = [char]0x2500; V  = [char]0x2502; Bar = [char]0x2503; Dot = [char]0x2022
}

# ============================================================
#  HELPERS DE INTERFACE
# ============================================================

function Get-Width {
    # se o console nao informar a largura, retorna 0 (layout fica alinhado a esquerda)
    $w = 0
    try { $w = [int]$Host.UI.RawUI.WindowSize.Width } catch {}
    return $w
}

function Write-Center {
    param([string]$Text, [ConsoleColor]$Color = 'White')
    $pad = [Math]::Max(0, [int](((Get-Width) - $Text.Length) / 2))
    Write-Host ((' ' * $pad) + $Text) -ForegroundColor $Color
}

function Write-Box {
    param([string[]]$Lines, [int]$Width = 56, [ConsoleColor]$Border = 'DarkCyan')
    $pad  = [Math]::Max(0, [int](((Get-Width) - $Width - 2) / 2))
    $left = ' ' * $pad
    Write-Host ($left + $B.TL + ([string]$B.H * $Width) + $B.TR) -ForegroundColor $Border
    foreach ($l in $Lines) {
        $parts = $l -split '\|', 2
        $txt   = $parts[0]
        $col   = if ($parts.Count -gt 1) { $parts[1] } else { 'White' }
        $sp    = [Math]::Max(0, $Width - $txt.Length)
        $lp    = [int]($sp / 2); $rp = $sp - $lp
        Write-Host ($left + $B.V) -ForegroundColor $Border -NoNewline
        Write-Host ((' ' * $lp) + $txt + (' ' * $rp)) -ForegroundColor $col -NoNewline
        Write-Host $B.V -ForegroundColor $Border
    }
    Write-Host ($left + $B.BL + ([string]$B.H * $Width) + $B.BR) -ForegroundColor $Border
}

function Write-Status {
    param(
        [ValidateSet('info','ok','warn','error','load')] [string]$Type,
        [string]$Message
    )
    $map = @{
        info  = @{ Tag = ' INFO '; Bg = 'DarkCyan'   }
        ok    = @{ Tag = '  OK  '; Bg = 'DarkGreen'  }
        warn  = @{ Tag = ' AVISO'; Bg = 'DarkYellow' }
        error = @{ Tag = ' ERRO '; Bg = 'DarkRed'    }
        load  = @{ Tag = '  ..  '; Bg = 'DarkGray'   }
    }
    Write-Host ("  " + (Get-Date -Format 'HH:mm:ss') + " ") -ForegroundColor DarkGray -NoNewline
    Write-Host $map[$Type].Tag -ForegroundColor White -BackgroundColor $map[$Type].Bg -NoNewline
    Write-Host "  $Message" -ForegroundColor Gray
}

function Write-Divider {
    param([string]$Title = '', [ConsoleColor]$Color = 'DarkCyan')
    $cw = Get-Width
    $w  = if ($cw -gt 20) { [Math]::Min($cw - 4, 70) } else { 40 }
    if ($Title) {
        $line = ([string]$B.H * 2) + " $Title "
        $line += ([string]$B.H * [Math]::Max(0, $w - $line.Length))
    } else {
        $line = [string]$B.H * $w
    }
    Write-Host ("  " + $line) -ForegroundColor $Color
}

function Format-TimeLeft([datetime]$EndUtc) {
    $left = $EndUtc - [DateTime]::UtcNow
    if ($left.TotalDays -ge 1)  { return "{0}d {1}h" -f [int][Math]::Floor($left.TotalDays), $left.Hours }
    if ($left.TotalHours -ge 1) { return "{0}h {1}min" -f [int][Math]::Floor($left.TotalHours), $left.Minutes }
    return "{0}min" -f [Math]::Max(0, [int]$left.TotalMinutes)
}

function Write-QuestCard {
    param($Quest, [int]$Index)

    $left = $Quest.End - [DateTime]::UtcNow
    # cor da barra lateral conforme urgencia
    $accent = if ($left.TotalHours -lt 24) { 'Red' } elseif ($left.TotalDays -lt 3) { 'Yellow' } else { 'Cyan' }

    $bar = "  " + $B.Bar + " "
    Write-Host ""
    Write-Host $bar -ForegroundColor $accent -NoNewline
    Write-Host ("#{0:00}  " -f $Index) -ForegroundColor DarkGray -NoNewline
    Write-Host $Quest.Name -ForegroundColor White

    $rows = @(
        @{ K = 'Jogo';    V = $Quest.Game;                                        C = 'Green'   }
        @{ K = 'Orbs';    V = ('{0:N0}' -f $Quest.Orb);                           C = 'Magenta' }
        @{ K = 'Tarefas'; V = ($Quest.Tasks -join ', ');                          C = 'Gray'    }
        @{ K = 'Expira';  V = ("{0}  (faltam {1})" -f $Quest.End.ToLocalTime().ToString('dd/MM HH:mm'), (Format-TimeLeft $Quest.End)); C = $accent }
    )
    if ($Quest.Link) { $rows += @{ K = 'Link'; V = $Quest.Link; C = 'DarkCyan' } }

    foreach ($r in $rows) {
        Write-Host $bar -ForegroundColor $accent -NoNewline
        Write-Host ("{0,-9}" -f $r.K) -ForegroundColor DarkGray -NoNewline
        Write-Host $r.V -ForegroundColor $r.C
    }
}

# ============================================================
#  BANNER
# ============================================================

$logo = @(
    '   ___  _   _ _____ ____ _____ '
    '  / _ \| | | | ____/ ___|_   _|'
    ' | | | | | | |  _| \___ \ | |  '
    ' | |_| | |_| | |___ ___) || |  '
    '  \__\_\\___/|_____|____/ |_|  '
)
$gradient = 'Cyan','Cyan','DarkCyan','Blue','DarkBlue'

Write-Host ""
for ($i = 0; $i -lt $logo.Count; $i++) {
    Write-Center $logo[$i] $gradient[$i]
    Start-Sleep -Milliseconds 40
}
Write-Host ""
Write-Box -Width 52 -Lines @(
    "D I S C O R D   Q U E S T   S C A N N E R|White"
    "automatic quest discovery  $($B.Dot)  v1.0|DarkGray"
)
Write-Host ""

# ============================================================
#  CONSULTAR FONTES
# ============================================================

$sources = @(
    'https://api.discordquest.com/api/quests',
    'https://raw.githubusercontent.com/lucifer-reborn/All-Discord-Quests/main/quests.json'
)

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $null
}

$all      = @{}
$sourceOK = 0

Write-Divider 'FONTES'
Write-Host ""

foreach ($url in $sources) {
    $hostName = ([Uri]$url).Host
    Write-Status load "Consultando $hostName..."
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 25
        $items = $response
        if ($response -isnot [array]) {
            $nested = Get-Prop $response 'quests'
            if ($nested) { $items = $nested }
        }

        $count = 0
        foreach ($q in $items) {
            $id = Get-Prop $q 'id'
            if ($id) { $all[[string]$id] = $q; $count++ }
        }

        $sourceOK++
        Write-Status ok "$hostName respondeu ($count registros)."
    }
    catch {
        Write-Status warn "$hostName indisponivel."
    }
}

# ============================================================
#  IDENTIFICAR MISSOES
# ============================================================

$now    = [DateTime]::UtcNow
$quests = @{}

$gameTaskTypes = @(
    'PLAY_ON_DESKTOP', 'PLAY_ON_MOBILE', 'PLAY_ON_PLAYSTATION', 'PLAY_ON_XBOX',
    'PLAY_ON_SWITCH', 'STREAM_ON_DESKTOP', 'COMPLETE_ACHIEVEMENT', 'PLAY_ACTIVITY'
)

foreach ($q in $all.Values) {

    $c = Get-Prop $q 'config'
    if (-not $c) { $c = $q }

    # periodo
    $startRaw = Get-Prop $c 'starts_at'
    $endRaw   = Get-Prop $c 'expires_at'
    if (-not $startRaw -or -not $endRaw) { continue }

    try {
        $start = [DateTimeOffset]::Parse([string]$startRaw).UtcDateTime
        $end   = [DateTimeOffset]::Parse([string]$endRaw).UtcDateTime
    } catch { continue }

    if ($start -gt $now -or $end -le $now) { continue }

    # orbs
    $rewards = Get-Prop (Get-Prop $c 'rewards_config') 'rewards'
    if (-not $rewards) { continue }

    $orb = 0
    foreach ($r in $rewards) {
        $quantity = Get-Prop $r 'orb_quantity'
        if ($null -ne $quantity) { $orb += [double]$quantity }
    }
    if ($orb -le 0) { continue }

    # tarefas de jogo
    $taskConfig = Get-Prop $c 'task_config_v2'
    if (-not $taskConfig) { $taskConfig = Get-Prop $c 'task_config' }
    $tasks = Get-Prop $taskConfig 'tasks'
    if (-not $tasks) { continue }

    $gameTasks = @()
    foreach ($property in $tasks.PSObject.Properties) {
        $type = Get-Prop $property.Value 'type'
        if (-not $type) { $type = $property.Name }
        if ($type -in $gameTaskTypes) { $gameTasks += [string]$type }
    }
    if ($gameTasks.Count -eq 0) { continue }

    # informacoes
    $messages    = Get-Prop $c 'messages'
    $application = Get-Prop $c 'application'

    $name = Get-Prop $messages 'quest_name'
    $game = Get-Prop $application 'name'
    if (-not $game) { $game = Get-Prop $messages 'game_title' }
    if (-not $name) { $name = 'Missao sem nome' }
    if (-not $game) { $game = 'Jogo nao identificado' }

    $link = Get-Prop $application 'link'
    if (-not $link) { $link = Get-Prop (Get-Prop $c 'cta_config') 'link' }

    # remover duplicatas
    $key = "$($name.ToLowerInvariant())|$($game.ToLowerInvariant())|$orb|$($end.Ticks)"
    if (-not $quests.ContainsKey($key)) {
        $quests[$key] = [PSCustomObject]@{
            Name  = $name
            Game  = $game
            Orb   = $orb
            Start = $start
            End   = $end
            Tasks = $gameTasks
            Link  = $link
        }
    }
}

# ============================================================
#  RESULTADOS
# ============================================================

$results  = @($quests.Values | Sort-Object End)
$totalOrb = ($results | Measure-Object -Property Orb -Sum).Sum
if (-not $totalOrb) { $totalOrb = 0 }

Write-Host ""
Write-Divider 'RESULTADO'
Write-Host ""

$srcColor = if ($sourceOK -eq $sources.Count) { 'Green' } elseif ($sourceOK -gt 0) { 'Yellow' } else { 'Red' }

Write-Host "  Missoes   " -ForegroundColor DarkGray -NoNewline
Write-Host $results.Count -ForegroundColor White
Write-Host "  Orbs      " -ForegroundColor DarkGray -NoNewline
Write-Host ('{0:N0} no total' -f $totalOrb) -ForegroundColor Magenta
Write-Host "  Fontes    " -ForegroundColor DarkGray -NoNewline
Write-Host "$sourceOK / $($sources.Count)" -ForegroundColor $srcColor

if ($results.Count -eq 0) {
    Write-Host ""
    if ($sourceOK -eq 0) {
        Write-Status error "Nenhuma fonte respondeu. Verifique sua conexao."
    } else {
        Write-Status info "Nenhuma missao de jogo ativa com orbs no momento."
    }
} else {
    $i = 1
    foreach ($quest in $results) {
        Write-QuestCard -Quest $quest -Index $i
        $i++
    }
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " $($B.Bar) " -ForegroundColor Red    -NoNewline; Write-Host "< 24h   " -ForegroundColor DarkGray -NoNewline
    Write-Host " $($B.Bar) " -ForegroundColor Yellow -NoNewline; Write-Host "< 3 dias   " -ForegroundColor DarkGray -NoNewline
    Write-Host " $($B.Bar) " -ForegroundColor Cyan   -NoNewline; Write-Host "com folga" -ForegroundColor DarkGray
}

Write-Host ""
Write-Divider
Write-Status ok "Consulta finalizada."
Write-Host ""
