# TODO via fzf: Enter toggle, Ctrl-N add, Ctrl-D delete, Esc quit.
$ErrorActionPreference = 'SilentlyContinue'

# force UTF-8 all the way to fzf
chcp 65001 > $null
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$file = Join-Path $PSScriptRoot 'TODO.md'
$fzf = 'C:\Users\31772\AppData\Local\Microsoft\WinGet\Links\fzf.exe'
$esc = [char]27

function Read-Lines {
    if (-not (Test-Path $file)) { return @('# TODO', '- [ ] 第一条任务') }
    return @([IO.File]::ReadAllLines($file, [Text.Encoding]::UTF8))
}
function Write-Lines([string[]]$ls) {
    [IO.File]::WriteAllText($file, (($ls -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($false)))
}

if (-not (Test-Path $file)) {
    Write-Lines @('# TODO', '', '- [ ] 第一条任务')
}

while ($true) {
    $lines = Read-Lines
    $rows = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match '^#{1,6}\s*(.*)$') {
            $title = $matches[1].Trim()
            if ($title) { $rows.Add(("-1`t$esc[38;5;109m-- $title --$esc[0m")) }
            continue
        }
        if ($l -match '^\s*- \[( |x)\]\s*(.*)$') {
            $done = $matches[1] -eq 'x'
            $txt = $matches[2]
            if ($done) { $rows.Add(("{0}`t{1}[x] {2}{3}" -f $i, "$esc[38;5;240m", $txt, "$esc[0m")) }
            else { $rows.Add(("{0}`t{1}[ ] {2}{3}" -f $i, "$esc[38;5;252m", $txt, "$esc[0m")) }
        }
    }

    $out = $rows | & $fzf --ansi --multi --expect=ctrl-n,ctrl-d --reverse `
        --delimiter="`t" --with-nth=2.. `
        --prompt='task> ' `
        --header='Enter 勾选/取消  ·  Ctrl-N 新增  ·  Ctrl-D 删除  ·  Esc 退出' `
        --pointer='>' --marker='*' --height=100% --no-info

    if (-not $out) { break }
    $arr = @($out)
    $key = $arr[0]
    $picked = @($arr | Select-Object -Skip 1)

    if ($key -eq 'ctrl-n') {
        Clear-Host
        Write-Host ''
        Write-Host '  新增任务（回车确认，直接回车取消）' -ForegroundColor DarkGray
        $new = Read-Host '  task'
        if ($new) {
            $lines = Read-Lines
            $lines += "- [ ] $new"
            Write-Lines $lines
        }
        continue
    }

    if ($picked.Count -eq 0) { continue }

    $idx = @()
    foreach ($p in $picked) { $idx += [int](($p -split "`t")[0]) }
    $lines = Read-Lines

    if ($key -eq 'ctrl-d') {
        $keep = @()
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($idx -notcontains $i) { $keep += $lines[$i] } }
        Write-Lines $keep
        continue
    }

    foreach ($k in $idx) {
        if ($k -lt 0 -or $k -ge $lines.Count) { continue }
        $l = $lines[$k]
        if ($l -match '^\s*- \[ \]') { $lines[$k] = $l -replace '^(\s*- )\[ \]', '${1}[x]' }
        elseif ($l -match '^\s*- \[x\]') { $lines[$k] = $l -replace '^(\s*- )\[x\]', '${1}[ ]' }
    }
    Write-Lines $lines
}
