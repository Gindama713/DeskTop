# Collect real data from this machine and write assets/data.js for the wallpaper.
# Read-only: nothing on the system is modified.
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $root 'assets'
New-Item -ItemType Directory -Force -Path $assets | Out-Null

function Prop($path, $name) {
    (Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue).$name
}

# ---- identity / os
$user = $env:USERNAME
$host_ = $env:COMPUTERNAME
$build = [Environment]::OSVersion.Version.Build
$ver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue)
$osName = 'Windows ' + $build
if ($build -ge 22000) { $osName = 'Windows 11' } elseif ($build -ge 10240) { $osName = 'Windows 10' }
$osName = "$osName $($ver.DisplayVersion)".Trim()
if ($ver.UBR) { $osName += " ($build.$($ver.UBR))" }

# ---- hardware
$cpu = Prop 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' 'ProcessorNameString'
$cpu = ($cpu -replace '\s+', ' ').Trim()
$gpu = ''
$gpuKeys = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^\d{4}$' }
foreach ($k in $gpuKeys) {
    $d = (Get-ItemProperty $k.PSPath -Name DriverDesc -ErrorAction SilentlyContinue).DriverDesc
    if ($d -and $d -notmatch 'Basic|Remote|Mirror') { $gpu = $d; break }
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class MemInfo {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
  public class MEMORYSTATUSEX {
    public uint dwLength; public uint dwMemoryLoad; public ulong ullTotalPhys;
    public ulong ullAvailPhys; public ulong ullTotalPageFile; public ulong ullAvailPageFile;
    public ulong ullTotalVirtual; public ulong ullAvailVirtual; public ulong ullAvailExtendedVirtual;
    public MEMORYSTATUSEX() { this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
  }
  [DllImport("kernel32.dll", SetLastError=true)]
  public static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);
}
"@ -ErrorAction SilentlyContinue
$ramTotal = 0; $ramUsed = 0
$ms = New-Object MemInfo+MEMORYSTATUSEX
if ([MemInfo]::GlobalMemoryStatusEx($ms)) {
    $ramTotal = [math]::Round($ms.ullTotalPhys / 1GB, 1)
    $ramUsed = [math]::Round(($ms.ullTotalPhys - $ms.ullAvailPhys) / 1GB, 1)
}
$ticks = [double][Environment]::TickCount
$uptimeMin = [int]($ticks / 60000)
$uptime = '{0}h {1:D2}m' -f [int]($uptimeMin / 60), ($uptimeMin % 60)

# ---- disks
$cFree = 0; $cPct = 0
try {
    $di = New-Object System.IO.DriveInfo('C')
    $cFree = [math]::Round($di.AvailableFreeSpace / 1GB, 0)
    $tot = $di.TotalSize / 1GB
    if ($tot -gt 0) { $cPct = [math]::Round(100 * ($tot - $cFree) / $tot) }
} catch { }

# ---- folders
$pinned = @()
foreach ($n in @('Desktop','Downloads','Documents','IdeaProjects','go','tools','Pictures','Videos')) {
    $p = Join-Path $env:USERPROFILE $n
    if (Test-Path $p) {
        $count = (Get-ChildItem $p -Force -ErrorAction SilentlyContinue | Measure-Object).Count
        $pinned += [ordered]@{ name = $n; path = $p; count = $count }
    }
}

# ---- recent files (Documents + Downloads + Desktop, newest first)
$recent = @()
$cand = @()
foreach ($src in @('Documents', 'Downloads', 'Desktop')) {
    $p = Join-Path $env:USERPROFILE $src
    Get-ChildItem $p -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^desktop\.ini$|^\.' -and $_.Extension -ne '.lnk' } |
        ForEach-Object { $cand += $_ }
}
$cand | Sort-Object LastWriteTime -Descending | Select-Object -First 12 | ForEach-Object {
    if ($_.Length -ge 1MB) { $size = '{0:N1}M' -f ($_.Length / 1MB) }
    elseif ($_.Length -ge 1KB) { $size = '{0:N0}k' -f ($_.Length / 1KB) }
    else { $size = "$($_.Length)b" }
    $recent += [ordered]@{ name = $_.Name; size = $size; age = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalHours, 0) }
}

# ---- apps from start menu
$apps = @()
$seen = @{}
$dirs = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
$skip = 'uninstall|卸载|帮助|help|readme|文档|documentation|license|release note|更新|update|website|website link|administrative tools|nahimic|file explorer|任务计划|system information|事件查看器'
foreach ($d in $dirs) {
    Get-ChildItem $d -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object {
        $n = $_.BaseName
        if ($n -match $skip) { return }
        if ($n.Length -gt 22) { return }
        if ($seen.ContainsKey($n.ToLower())) { return }
        $seen[$n.ToLower()] = $true
        $apps += $n
    }
}
$apps = $apps | Select-Object -Unique
# prefer well known tools first
$priority = @('Visual Studio Code','Microsoft Edge','Steam','Windows PowerShell','PowerShell 7','IntelliJ IDEA','PyCharm','Docker Desktop','微信','WeChat','QQ','Clash','Figma','Obsidian','Notepad++','Terminal')
$ordered = @()
foreach ($p in $priority) {
    $m = $apps | Where-Object { $_ -eq $p } | Select-Object -First 1
    if ($m) { $ordered += $m }
}
foreach ($a in $apps) { if ($ordered -notcontains $a) { $ordered += $a } }
$apps = $ordered | Select-Object -First 16

# ---- steam games
$games = @()
$steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction SilentlyContinue).SteamPath
if (-not $steam) { $steam = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath -ErrorAction SilentlyContinue).InstallPath }
if ($steam) {
    $common = Join-Path $steam 'steamapps\common'
    Get-ChildItem $common -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match 'Steamworks|Steam Controller|SteamVR') { return }
        $games += $_.Name
    }
}

# ---- git: first repo with .git found in common project roots
$git = $null
$roots = @((Join-Path $env:USERPROFILE 'IdeaProjects'), (Join-Path $env:USERPROFILE 'PyCharmMiscProject'), 'C:\Users\31772\Documents\deepseek-harness')
foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    $repo = Get-ChildItem $r -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName '.git') } | Select-Object -First 1
    if ($repo) {
        $branch = (& git -C $repo.FullName rev-parse --abbrev-ref HEAD 2>$null)
        $changes = @(& git -C $repo.FullName status --porcelain 2>$null)
        $git = [ordered]@{ repo = $repo.Name; branch = "$branch"; changes = $changes.Count }
        break
    }
}

# ---- documents listing + top processes (real, for the terminal pane)
$docs = @()
Get-ChildItem (Join-Path $env:USERPROFILE 'Documents') -Force -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 6 | ForEach-Object {
        if ($_.PSIsContainer) { $size = 'dir' }
        elseif ($_.Length -ge 1MB) { $size = '{0:N1}M' -f ($_.Length / 1MB) }
        elseif ($_.Length -ge 1KB) { $size = '{0:N0}k' -f ($_.Length / 1KB) }
        else { $size = "$($_.Length)b" }
        $docs += [ordered]@{ name = $_.Name; dir = $_.PSIsContainer; size = $size }
    }

$procs = @()
Get-Process -ErrorAction SilentlyContinue | Sort-Object -Property WS -Descending | Select-Object -First 3 | ForEach-Object {
    $procs += [ordered]@{ name = $_.ProcessName; mem = [math]::Round($_.WS / 1MB, 0) }
}

# ---- volumes + ipv4
$volumes = @()
try {
    [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and $_.DriveType -eq 'Fixed' } | ForEach-Object {
        $tot = $_.TotalSize / 1GB
        if ($tot -gt 0) {
            $free = [math]::Round($_.AvailableFreeSpace / 1GB, 0)
            $pct = [math]::Round(100 * (1 - $_.AvailableFreeSpace / $_.TotalSize))
            $volumes += [ordered]@{ name = $_.Name.Substring(0, 2); free = $free; used = [math]::Round($tot - $free, 0); pct = $pct }
        }
    }
} catch { }

$ips = @()
try {
    $ips = @([System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) |
        Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
        ForEach-Object { $_.IPAddressToString })
} catch { }

# ---- toolchain versions
$tools = @()
foreach ($t in @(
    @{ n = 'node';   c = 'node';       a = '-v' },
    @{ n = 'git';    c = 'git';        a = '--version' },
    @{ n = 'python'; c = 'python';     a = '--version' },
    @{ n = 'docker'; c = 'docker';     a = '--version' }
)) {
    if (-not (Get-Command $t.c -ErrorAction SilentlyContinue)) { continue }
    try {
        $out = (& cmd /c "$($t.c) $($t.a)" 2>$null | Select-Object -First 1)
        if ($out) {
            $v = ($out -replace '^(v|git version |Python |Docker version )', '').Trim()
            $tools += [ordered]@{ name = $t.n; ver = $v }
        }
    } catch { }
}

$data = [ordered]@{
    generated = (Get-Date).ToString('yyyy-MM-dd HH:mm')
    user = $user
    host = $host_
    os = $osName
    cpu = $cpu
    gpu = $gpu
    ramUsed = $ramUsed
    ramTotal = $ramTotal
    uptime = $uptime
    cFree = $cFree
    cUsedPct = $cPct
    folders = $pinned
    recent = $recent
    apps = @($apps)
    games = @($games)
    git = $git
    docs = $docs
    procs = $procs
    volumes = $volumes
    ip = $ips
    tools = $tools
    shell = $PSVersionTable.PSVersion.ToString()
    steamPath = $steam
}

$json = $data | ConvertTo-Json -Depth 6 -Compress
$out = Join-Path $assets 'data.js'
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($out, "window.DESKTOP_DATA = $json;", $enc)
Write-Output "wrote $out"
Write-Output ("apps: " + ($apps -join ', '))
Write-Output ("games: " + ($games -join ', '))
Write-Output ("git: " + $(if ($git) { "$($git.repo) $($git.branch) $($git.changes)" } else { 'none' }))
