# TODO pane: fzf picker over data/TODO.md. Enter toggles, Ctrl-N adds, Ctrl-D deletes.
$ErrorActionPreference = 'SilentlyContinue'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\DesktopKit.psm1') -Force

chcp 65001 > $null
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$th = Get-DkTheme
$file = Get-DkDataFile 'TODO.md'
$fzf = (Get-Command fzf.exe -ErrorAction SilentlyContinue).Source
if (-not $fzf) { $fzf = 'fzf' }

function Read-Lines {
    if (-not (Test-Path $file)) { return @('# TODO', '', '- [ ] first task') }
    return @([IO.File]::ReadAllLines($file, [Text.Encoding]::UTF8))
}
function Write-Lines([string[]]$ls) {
    [IO.File]::WriteAllText($file, (($ls -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($false)))
}
if (-not (Test-Path $file)) { Write-Lines @('# TODO', '', '- [ ] first task') }

while ($true) {
    Exit-DkIfOrphaned
    $lines = Read-Lines
    $rows = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match '^#{1,6}\s*(.*)$') {
            if ($matches[1].Trim()) { $rows.Add(("-1`t" + $th.aqua + '-- ' + $matches[1].Trim() + ' --' + $th.reset)) }
            continue
        }
        if ($l -match '^\s*- \[( |x)\]\s*(.*)$') {
            if ($matches[1] -eq 'x') { $rows.Add(("{0}`t{1}[x] {2}{3}" -f $i, $th.dim, $matches[2], $th.reset)) }
            else { $rows.Add(("{0}`t{1}[ ] {2}{3}" -f $i, $th.fg, $matches[2], $th.reset)) }
        }
    }

    $out = $rows | & $fzf --ansi --multi --expect=ctrl-n,ctrl-d --reverse `
        --delimiter="`t" --with-nth=2.. --prompt='task> ' `
        --header='Enter toggle · Ctrl-N add · Ctrl-D delete · Esc quit' `
        --pointer='>' --marker='*' --height=100% --no-info

    if (-not $out) { break }
    $arr = @($out)
    $key = $arr[0]
    $picked = @($arr | Select-Object -Skip 1)

    if ($key -eq 'ctrl-n') {
        Clear-Host
        Write-Host ''
        Write-Host '  new task (empty to cancel)' -ForegroundColor DarkGray
        $new = Read-Host '  task'
        if ($new) { $lines = Read-Lines; $lines += "- [ ] $new"; Write-Lines $lines }
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
