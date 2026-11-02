# Pomodoro pane: space start/pause, 1-5 presets, r reset, q quit.
$ErrorActionPreference = 'SilentlyContinue'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\DesktopKit.psm1') -Force

$th = Get-DkTheme

$digits = @{
    '0' = @(' #### ', '##  ##', '##  ##', '##  ##', '##  ##', '##  ##', ' #### ')
    '1' = @('  ##  ', ' #### ', '  ##  ', '  ##  ', '  ##  ', '  ##  ', '######')
    '2' = @(' #### ', '##  ##', '    ##', '   ## ', '  ##  ', ' ##   ', '######')
    '3' = @('##### ', '    ##', '    ##', ' #### ', '    ##', '    ##', '##### ')
    '4' = @('##  ##', '##  ##', '##  ##', '######', '    ##', '    ##', '    ##')
    '5' = @('######', '##    ', '##    ', '##### ', '    ##', '    ##', '##### ')
    '6' = @(' #### ', '##    ', '##    ', '##### ', '##  ##', '##  ##', ' #### ')
    '7' = @('######', '    ##', '   ## ', '  ##  ', ' ##   ', ' ##   ', ' ##   ')
    '8' = @(' #### ', '##  ##', '##  ##', ' #### ', '##  ##', '##  ##', ' #### ')
    '9' = @(' #### ', '##  ##', '##  ##', ' #####', '    ##', '    ##', ' #### ')
    ':' = @('      ', '  ##  ', '  ##  ', '      ', '  ##  ', '  ##  ', '      ')
}

function BigTime([string]$t) {
    $rows = @('', '', '', '', '', '', '')
    for ($r = 0; $r -lt 7; $r++) {
        $line = ''
        foreach ($ch in $t.ToCharArray()) {
            $g = $digits[[string]$ch]
            if ($g) { $line += $g[$r] } else { $line += '      ' }
            $line += ' '
        }
        $rows[$r] = $line
    }
    return $rows
}

$presets = @(
    @{ key = '1'; min = 25; name = 'FOCUS 25' },
    @{ key = '2'; min = 50; name = 'DEEP 50' },
    @{ key = '3'; min = 90; name = 'MARA 90' },
    @{ key = '4'; min = 15; name = 'BREAK 15' },
    @{ key = '5'; min = 5;  name = 'MICRO 5' }
)

$total = 25 * 60
$left = $total
$running = $false
$label = 'FOCUS 25'
$lastTick = Get-Date

[Console]::Write("$($th.esc)[2J")
while ($true) {
    Exit-DkIfOrphaned

    while ([Console]::KeyAvailable) {
        $k = [Console]::ReadKey($true)
        $ks = [string]$k.Key
        if ($ks -eq 'Spacebar') { $running = -not $running; continue }
        if ($ks -eq 'Q') { return }
        if ($ks -eq 'R') { $left = $total; $running = $false; continue }
        foreach ($p in $presets) {
            if ($ks -eq $p.key) { $total = $p.min * 60; $left = $total; $running = $false; $label = $p.name }
        }
    }

    $now = Get-Date
    if ($running) {
        $elapsed = ($now - $lastTick).TotalSeconds
        if ($elapsed -ge 1) {
            $left -= [int][math]::Floor($elapsed)
            $lastTick = $now
            if ($left -le 0) { $left = 0; $running = $false; [Console]::Beep(880, 250); [Console]::Beep(660, 250) }
        }
    } else { $lastTick = $now }

    $mm = [int]([math]::Floor($left / 60)); $ss = $left % 60
    $pct = if ($total -gt 0) { [int](100 * ($total - $left) / $total) } else { 0 }
    $state = if ($running) { $th.green + 'RUNNING' + $th.reset } else { $th.dim + 'PAUSED' + $th.reset }

    $out = New-Object System.Collections.Generic.List[string]
    $out.Add('')
    $out.Add('  ' + $th.dim + '+' + ('-' * 42) + '+' + $th.reset)
    $out.Add('  ' + $th.dim + '| ' + $th.reset + $th.aqua + 'POMODORO' + $th.reset + (' ' * 24) + $state + $th.dim + ' |' + $th.reset)
    $out.Add('  ' + $th.dim + '+' + ('-' * 42) + '+' + $th.reset)
    $out.Add('')
    foreach ($row in (BigTime ('{0:00}:{1:00}' -f $mm, $ss))) { $out.Add('   ' + $th.fg + $row + $th.reset) }
    $out.Add('')
    $out.Add('   ' + $th.yellow + $label + $th.reset + '   ' + $th.dim + "$pct%" + $th.reset)
    $out.Add('   ' + $th.aqua + (Write-DkBar $pct 34) + $th.reset)
    $out.Add('')
    $out.Add('  ' + $th.dim + '| 1 25m   2 50m   3 90m          |' + $th.reset)
    $out.Add('  ' + $th.dim + '| 4 15m   5 5m    r reset        |' + $th.reset)
    $out.Add('  ' + $th.dim + '| space start/pause    q quit    |' + $th.reset)
    $out.Add('  ' + $th.dim + '+' + ('-' * 42) + '+' + $th.reset)

    $w = 48
    try { $w = [math]::Max(30, [Console]::WindowWidth - 1) } catch { }
    [Console]::SetCursorPosition(0, 0)
    foreach ($l in $out) {
        $plain = [regex]::Replace($l, "$([char]27)\[[0-9;]*m", '')
        [Console]::Write($l + (' ' * [math]::Max(0, $w - $plain.Length)) + "`n")
    }
    Start-Sleep -Milliseconds 150
}
