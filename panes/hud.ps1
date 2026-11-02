# HUD pane: system card. All styling comes from config.json via DesktopKit.
$ErrorActionPreference = 'SilentlyContinue'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\DesktopKit.psm1') -Force

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DkMem {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
  public class M {
    public uint dwLength; public uint dwMemoryLoad; public ulong ullTotalPhys;
    public ulong ullAvailPhys; public ulong ullTotalPageFile; public ulong ullAvailPageFile;
    public ulong ullTotalVirtual; public ulong ullAvailVirtual; public ulong ullAvailExtendedVirtual;
    public M() { dwLength = (uint)Marshal.SizeOf(typeof(M)); }
  }
  [DllImport("kernel32.dll")] public static extern bool GlobalMemoryStatusEx([In, Out] M m);
}
"@

$th = Get-DkTheme
$cfg = Get-DkConfig

$os = 'Windows'; $build = ''
try { $o = Get-CimInstance Win32_OperatingSystem; $os = ($o.Caption -replace 'Microsoft ', ''); $build = $o.BuildNumber } catch { }
$cpuName = 'CPU'
try { $cpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim() } catch { }
$gpuName = 'GPU'
try { $gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { }
$ip = ''
try { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' } | Select-Object -First 1).IPAddress } catch { }

function Trim([string]$s, [int]$n) { if ($s.Length -gt $n) { return $s.Substring(0, $n - 1) + '~' } else { return $s } }

[Console]::Write("$($th.esc)[2J")
while ($true) {
    Exit-DkIfOrphaned

    $m = New-Object DkMem+M
    [DkMem]::GlobalMemoryStatusEx($m) | Out-Null
    $total = [math]::Round($m.ullTotalPhys / 1GB, 1)
    $used = [math]::Round(($m.ullTotalPhys - $m.ullAvailPhys) / 1GB, 1)
    $ramPct = [int][math]::Round(100 * ($m.ullTotalPhys - $m.ullAvailPhys) / $m.ullTotalPhys)

    $di = New-Object System.IO.DriveInfo('C')
    $free = [math]::Round($di.AvailableFreeSpace / 1GB)
    $diskPct = [int][math]::Round(100 * (1 - $di.AvailableFreeSpace / $di.TotalSize))
    $dFree = 0; $eFree = 0
    try { $dFree = [math]::Round((New-Object System.IO.DriveInfo('D')).AvailableFreeSpace / 1GB) } catch { }
    try { $eFree = [math]::Round((New-Object System.IO.DriveInfo('E')).AvailableFreeSpace / 1GB) } catch { }

    $cpuPct = 0
    try { $cpuPct = [int](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime } catch { }

    $up = [int]([Environment]::TickCount / 60000)
    $upStr = '{0}d {1}h {2}m' -f [int]($up / 1440), [int](($up % 1440) / 60), [int]($up % 60)
    $now = Get-Date

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('')
    $lines.Add('  ' + $th.green + 'GINDAMA' + $th.reset)
    $lines.Add('  ' + $th.dim + $env:USERNAME + '@' + $env:COMPUTERNAME + $th.reset + '   ' + $th.dim + $now.ToString('HH:mm:ss') + $th.reset)
    $lines.Add('  ' + $th.dim + ('-' * 46) + $th.reset)
    $lines.Add('')
    $lines.Add('  ' + $th.dim + 'os      ' + $th.reset + $th.fg + (Trim $os 30) + $th.reset)
    $lines.Add('  ' + $th.dim + 'shell   ' + $th.reset + $th.fg + 'powershell ' + $PSVersionTable.PSVersion + $th.reset)
    $lines.Add('  ' + $th.dim + 'cpu     ' + $th.reset + $th.fg + (Trim $cpuName 44) + $th.reset)
    $lines.Add('  ' + $th.dim + 'gpu     ' + $th.reset + $th.fg + (Trim $gpuName 44) + $th.reset)
    $lines.Add('')
    $lines.Add('  ' + $th.dim + 'cpu%    ' + $th.aqua + (Write-DkBar $cpuPct 14) + $th.reset + ' ' + $th.green + "$cpuPct%" + $th.reset)
    $lines.Add('  ' + $th.dim + 'mem     ' + $th.aqua + (Write-DkBar $ramPct 14) + $th.reset + ' ' + $th.green + "$used" + $th.reset + $th.dim + '/' + $th.reset + $th.green + "$total GiB" + $th.reset)
    $lines.Add('  ' + $th.dim + 'disk C  ' + $th.aqua + (Write-DkBar $diskPct 14) + $th.reset + ' ' + $th.green + "$free GiB free" + $th.reset)
    $lines.Add('')
    $lines.Add('  ' + $th.dim + 'disk D  ' + $th.reset + $th.fg + "$dFree GiB" + $th.reset + '   ' + $th.dim + 'disk E  ' + $th.reset + $th.fg + "$eFree GiB" + $th.reset)
    $lines.Add('  ' + $th.dim + 'ip      ' + $th.reset + $th.yellow + $ip + $th.reset)
    $lines.Add('  ' + $th.dim + 'uptime  ' + $th.reset + $th.fg + $upStr + $th.reset)
    $lines.Add('')
    $lines.Add('  ' + $th.dim + 'tabs: stats · console · work' + $th.reset)

    $w = 92
    try { $w = [math]::Max(40, [Console]::WindowWidth - 1) } catch { }

    [Console]::SetCursorPosition(0, 0)
    foreach ($l in $lines) {
        $plain = [regex]::Replace($l, "$([char]27)\[[0-9;]*m", '')
        $len = 0
        foreach ($ch in $plain.ToCharArray()) { if ([int]$ch -gt 0x2E80) { $len += 2 } else { $len += 1 } }
        [Console]::Write($l + (' ' * [math]::Max(0, $w - $len)) + "`n")
    }
    Start-Sleep -Milliseconds 1000
}
