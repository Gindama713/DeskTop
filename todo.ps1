# TODO pane: scrollable window over an editable file.
$ErrorActionPreference = 'SilentlyContinue'
$file = 'E:\Apps\DesktopTerminal\todo.txt'
$E = [char]27
$green = "$E[38;2;167;192;128m"
$aqua  = "$E[38;2;131;192;146m"
$dim   = "$E[38;2;104;116;106m"
$fg    = "$E[38;2;232;226;209m"
$yellow = "$E[38;2;219;188;127m"
$reset = "$E[0m"

function DW([string]$s) {
    $len = 0
    foreach ($ch in $s.ToCharArray()) { if ([int]$ch -gt 0x2E80) { $len += 2 } else { $len += 1 } }
    return $len
}
function Row([string]$marker, [string]$text, [string]$mc, [string]$tc, [int]$cw) {
    $inner = $marker + ' ' + $text
    $pad = $cw - (DW $inner)
    if ($pad -lt 0) { $pad = 0 }
    return '  ' + $dim + '|' + $reset + ' ' + $mc + $marker + $reset + ' ' + $tc + $text + $reset + (' ' * $pad) + ' ' + $dim + '|' + $reset
}

$offset = 0
$lastMod = [datetime]::MinValue
$cache = @()

[Console]::Write("$E[2J")
while ($true) {
    # reload when file changes
    $mtime = (Get-Item $file).LastWriteTime
    if ($mtime -ne $lastMod) {
        $cache = Get-Content $file -Encoding UTF8
        $lastMod = $mtime
    }
    $all = $cache

    # input
    while ([Console]::KeyAvailable) {
        $k = [Console]::ReadKey($true)
        switch ([string]$k.Key) {
            'DownArrow' { $offset++ }
            'UpArrow' { $offset-- }
            'PageDown' { $offset += 10 }
            'PageUp' { $offset -= 10 }
            'Home' { $offset = 0 }
            'End' { $offset = 9999 }
            'Q' { return }
        }
    }

    $rows = 24
    try { $rows = [math]::Max(8, [Console]::WindowHeight - 8) } catch { }
    $maxOffset = [math]::Max(0, $all.Count - $rows)
    if ($offset -gt $maxOffset) { $offset = $maxOffset }
    if ($offset -lt 0) { $offset = 0 }

    $cw = 62
    $border = '  ' + $dim + '+' + ('-' * ($cw + 2)) + '+' + $reset
    $range = if ($all.Count -eq 0) { 'empty' } else { ('{0}-{1} / {2}' -f ($offset + 1), [math]::Min($all.Count, $offset + $rows), $all.Count) }

    $out = New-Object System.Collections.Generic.List[string]
    $out.Add('')
    $out.Add($border)
    $hdr = 'TODO'
    $padH = $cw - (DW $hdr) - (DW $range) - 1
    if ($padH -lt 0) { $padH = 0 }
    $out.Add('  ' + $dim + '|' + $reset + ' ' + $aqua + $hdr + $reset + (' ' * $padH) + $dim + $range + ' ' + $dim + '|' + $reset)
    $out.Add($border)

    $slice = $all | Select-Object -Skip $offset -First $rows
    $open = 0; $done = 0
    foreach ($raw in $all) {
        if ($raw -match '^\[x\]') { $done++ }
        elseif ($raw -match '^\[\s?\]') { $open++ }
    }
    foreach ($raw in $slice) {
        $line = $raw.TrimEnd()
        if ($line -eq '') { $out.Add('  ' + $dim + '|' + $reset + (' ' * ($cw + 2)) + $dim + '|' + $reset); continue }
        if ($line.StartsWith('#')) {
            $txt = $line.TrimStart('#').Trim()
            if ($txt -eq '') { $out.Add('  ' + $dim + '|' + $reset + (' ' * ($cw + 2)) + $dim + '|' + $reset) }
            else { $out.Add((Row '#' $txt $aqua $aqua $cw)) }
            continue
        }
        if ($line -match '^\[x\]\s*(.*)$') { $out.Add((Row '[x]' $matches[1] $green $dim $cw)) }
        elseif ($line -match '^\[\s?\]\s*(.*)$') { $out.Add((Row '[ ]' $matches[1] $yellow $fg $cw)) }
        else { $out.Add((Row '[~]' $line $yellow $fg $cw)) }
    }

    $out.Add($border)
    $stat = "open $open  done $done"
    $pad = $cw - (DW $stat)
    if ($pad -lt 0) { $pad = 0 }
    $out.Add('  ' + $dim + '|' + $reset + ' ' + $yellow + "$open" + $reset + ' open  ' + $green + "$done" + $reset + ' done' + (' ' * [math]::Max(0, $pad - 4)) + ' ' + $dim + '|' + $reset)
    $out.Add($border)
    $out.Add('  ' + $dim + '  up/down scroll   q quit   file: todo.txt' + $reset)

    $w = 90
    try { $w = [math]::Max(30, [Console]::WindowWidth - 1) } catch { }
    [Console]::SetCursorPosition(0, 0)
    foreach ($l in $out) {
        $plain = [regex]::Replace($l, "$([char]27)\[[0-9;]*m", '')
        [Console]::Write($l + (' ' * [math]::Max(0, $w - (DW $plain))) + "`n")
    }
    Start-Sleep -Milliseconds 250
}
