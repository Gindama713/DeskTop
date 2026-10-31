# Render the wallpaper to a PNG with headless Edge so it can be reviewed without installing anything.
param([int]$Width = 1920, [int]$Height = 1080, [string]$Out = "preview.png")
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) { throw "Edge not found at $edge" }
$page = Join-Path $root 'index.html'
$uri = ([System.Uri]$page).AbsoluteUri
$outPath = Join-Path $root $Out
if (Test-Path $outPath) { Remove-Item $outPath -Force }
$profile = Join-Path $env:TEMP ('dsh-edge-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$edgeArgs = @(
    '--headless=new', '--disable-gpu', '--hide-scrollbars',
    '--force-device-scale-factor=1',
    "--window-size=$Width,$Height",
    "--user-data-dir=$profile",
    '--no-first-run', '--no-default-browser-check',
    '--virtual-time-budget=6000',
    "--screenshot=$outPath",
    $uri
)
& $edge @edgeArgs 2>$null | Out-Null
Start-Sleep -Milliseconds 300
Remove-Item $profile -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path $outPath) {
    $f = Get-Item $outPath
    Write-Output "wrote $($f.FullName) ($([math]::Round($f.Length / 1KB, 1)) KB)"
} else {
    Write-Output 'screenshot failed'
    exit 1
}
