# DeskTop installer: wires wezterm.lua to this folder, builds the pin watchdog, registers autostart.
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

# 1) point wezterm.lua at this folder
$cfg = Join-Path $repo 'wezterm.lua'
$t = [IO.File]::ReadAllText($cfg, [Text.Encoding]::UTF8)
$t = [regex]::Replace($t, "(?m)^local LOCAL = '.*'", "local LOCAL = '$repoLua'")
[IO.File]::WriteAllText($cfg, $t, (New-Object Text.UTF8Encoding($false)))
Write-Host '  [1/5] wezterm.lua -> LOCAL updated' -ForegroundColor DarkGray

# 2) install to ~/.wezterm.lua
$dest = Join-Path $env:USERPROFILE '.wezterm.lua'
if (Test-Path $dest) {
    Copy-Item $dest ($dest + '.bak') -Force
    Write-Host '  [2/5] existing ~/.wezterm.lua backed up' -ForegroundColor DarkGray
}
Copy-Item $cfg $dest -Force
Write-Host '  [2/5] ~/.wezterm.lua installed' -ForegroundColor DarkGray

# 3) layout.txt
$layout = Join-Path $repo 'layout.txt'
if (-not (Test-Path $layout)) {
    @(
        '# window position in virtual pixels',
        "X=$LayoutX",
        "Y=$LayoutY",
        'W=1108',
        'H=590'
    ) | Set-Content -Path $layout -Encoding ASCII
}
Write-Host '  [3/5] layout.txt ready' -ForegroundColor DarkGray

# 4) compile the native pin watchdog (~25 MB instead of ~90 MB of PowerShell)
$csc = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$pinExe = Join-Path $repo 'deskpin.exe'
$pinSrc = Join-Path $repo 'DeskPin.cs'
$havePin = $false
if ((Test-Path $csc) -and (Test-Path $pinSrc)) {
    & $csc /nologo /target:winexe /optimize+ "/out:$pinExe" $pinSrc 2>$null | Out-Null
    $havePin = Test-Path $pinExe
}
if ($havePin) { Write-Host '  [4/5] deskpin.exe built' -ForegroundColor DarkGray }
else { Write-Host '  [4/5] csc not found - PowerShell fallback will be used' -ForegroundColor Yellow }

# 5) launcher + startup shortcut
if (-not $WezTermExe) {
    $found = Get-Command wezterm-gui.exe -ErrorAction SilentlyContinue
    if ($found) { $WezTermExe = $found.Source } else { $WezTermExe = 'wezterm-gui.exe' }
}
$launcher = Join-Path $repo 'start-terminal.cmd'
$lines = @(
    '@echo off',
    ('start "" "' + $WezTermExe + '"'),
    'if exist "%~dp0deskpin.exe" (',
    '  start "" /min "%~dp0deskpin.exe"',
    ') else (',
    '  start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0pin-terminal.ps1"',
    ')'
)
Set-Content -Path $launcher -Value $lines -Encoding ASCII

$ws = New-Object -ComObject WScript.Shell
$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\DeskTop Terminal.lnk'
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = $launcher
$s.WorkingDirectory = $repo
$s.WindowStyle = 7
$s.Description = 'DeskTop terminal'
$s.Save()
Write-Host '  [5/5] startup shortcut created' -ForegroundColor DarkGray

Write-Host ''
Write-Host '  done. run:' -ForegroundColor Green
Write-Host ('    ' + $launcher)
Write-Host '  tabs: Alt+Left / Alt+Right' -ForegroundColor DarkGray
Write-Host ''
