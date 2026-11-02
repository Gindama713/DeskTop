# DeskTop installer.
#  1) points wezterm.lua at this folder   2) installs ~/.wezterm.lua
#  3) seeds data/ from examples           4) builds the native pin watchdog
#  5) registers the startup shortcut
param(
    [string]$WezTermExe = '',
    [int]$LayoutX = 444,
    [int]$LayoutY = 274
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoLua = ($repo -replace '\\', '/')

Write-Host ''
Write-Host '  DeskTop installer' -ForegroundColor Green
Write-Host ('  repo: ' + $repo) -ForegroundColor DarkGray
Write-Host ''

# 1) LOCAL in wezterm.lua
$cfg = Join-Path $repo 'wezterm.lua'
$t = [IO.File]::ReadAllText($cfg, [Text.Encoding]::UTF8)
$t = [regex]::Replace($t, "(?m)^local LOCAL = '.*'", "local LOCAL = '$repoLua'")
[IO.File]::WriteAllText($cfg, $t, (New-Object Text.UTF8Encoding($false)))
Write-Host '  [1/5] wezterm.lua -> LOCAL updated' -ForegroundColor DarkGray

# 2) ~/.wezterm.lua
$dest = Join-Path $env:USERPROFILE '.wezterm.lua'
if (Test-Path $dest) { Copy-Item $dest ($dest + '.bak') -Force }
Copy-Item $cfg $dest -Force
Write-Host '  [2/5] ~/.wezterm.lua installed (previous one backed up)' -ForegroundColor DarkGray

# 3) data/
$data = Join-Path $repo 'data'
New-Item -ItemType Directory -Force -Path $data | Out-Null
foreach ($pair in @(@('TODO.md.example', 'TODO.md'), @('leetcode-user.txt.example', 'leetcode-user.txt'))) {
    $target = Join-Path $data $pair[1]
    if (-not (Test-Path $target)) {
        $example = Join-Path $data $pair[0]
        if (Test-Path $example) { Copy-Item $example $target -Force }
    }
}
Write-Host '  [3/5] data/ ready (edit data/TODO.md, data/leetcode-user.txt)' -ForegroundColor DarkGray

# 4) native pin watchdog
$csc = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$pinSrc = Join-Path $repo 'DeskPin.cs'
$pinExe = Join-Path $repo 'deskpin.exe'
$built = $false
if ((Test-Path $csc) -and (Test-Path $pinSrc)) {
    & $csc /nologo /target:winexe /optimize+ "/out:$pinExe" $pinSrc 2>$null | Out-Null
    $built = Test-Path $pinExe
}
@(
    '# window position for deskpin.exe (virtual pixels)',
    "X=$LayoutX",
    "Y=$LayoutY"
) | Set-Content -Path (Join-Path $repo 'layout.txt') -Encoding ASCII
if ($built) { Write-Host '  [4/5] deskpin.exe built' -ForegroundColor DarkGray }
else { Write-Host '  [4/5] csc missing - deskpin.exe not built, position stays whatever WezTerm picks' -ForegroundColor Yellow }

# 5) launcher + startup
if (-not $WezTermExe) {
    $found = Get-Command wezterm-gui.exe -ErrorAction SilentlyContinue
    if ($found) { $WezTermExe = $found.Source } else { $WezTermExe = 'wezterm-gui.exe' }
}
$launcher = Join-Path $repo 'start-terminal.cmd'
@(
    '@echo off',
    ('start "" "' + $WezTermExe + '"'),
    'if exist "%~dp0deskpin.exe" start "" /min "%~dp0deskpin.exe"'
) | Set-Content -Path $launcher -Encoding ASCII

$ws = New-Object -ComObject WScript.Shell
$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\DeskTop Terminal.lnk'
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $launcher
$s.WorkingDirectory = $repo
$s.WindowStyle = 7
$s.Save()
Write-Host '  [5/5] startup shortcut created' -ForegroundColor DarkGray

Write-Host ''
Write-Host '  done. run:' -ForegroundColor Green
Write-Host ('    ' + $launcher)
Write-Host ''
Write-Host '  add your own pane: drop a script in panes/, add it to config.json tabs[].panes[]' -ForegroundColor DarkGray
Write-Host ''
