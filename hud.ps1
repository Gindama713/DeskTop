# HUD: ASCII bars, cpu load, network, disks.
$ErrorActionPreference = 'SilentlyContinue'

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class HudMemF {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
  public class M {
    public uint dwLength; public uint dwMemoryLoad; public ulong ullTotalPhys;
    public ulong ullAvailPhys; public ulong ullTotalPageFile; public ulong ullAvailPageFile;
    public ulong ullTotalVirtual; public ulong ullAvailVirtual; public ulong ullAvailExtendedVirtual;
    public M() { dwLength = (uint)Marshal.SizeOf(typeof(M)); }
  }
  [DllImport("kernel32.dll", SetLastError=true)]
  public static extern bool GlobalMemoryStatusEx([In, Out] M m);
}
"@

$E = [char]27
$green = "$E[38;2;167;192;128m"
$aqua  = "$E[38;2;131;192;146m"
$dim   = "$E[38;2;104;116;106m"
$fg    = "$E[38;2;232;226;209m"
$yellow = "$E[38;2;219;188;127m"
$reset = "$E[0m"

$banner = @(
  ' ██████╗ ██╗███╗   ██╗██████╗  █████╗ ███╗   ███╗ █████╗ ',
  '██╔════╝ ██║████╗  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗',
  '██║  ███╗██║██╔██╗ ██║██║  ██║███████║██╔████╔██║███████║',
  '██║   ██║██║██║╚██╗██║██║  ██║██╔══██║██║╚██╔╝██║██╔══██║',
  '╚██████╔╝██║██║ ╚████║██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║',
  ' ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝'
)

function Bar([int]$pct, [int]$width) {
    $fill = [math]::Round($width * [math]::Min(100, [math]::Max(0, $pct)) / 100)
    return ('#' * $fill) + ('.' * ($width - $fill))
}
function Trim([string]$s, [int]$n) { if ($s.Length -gt $n) { return $s.Substring(0, $n - 1) + '~' } else { return $s } }

$os = 'Windows'; $build = ''
try { $osv = Get-CimInstance Win32_OperatingSystem; $os = ($osv.Caption -replace 'Microsoft ', ''); $build = $osv.BuildNumber } catch { }
$cpuName = 'CPU'
try { $cpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim() } catch { }
$gpuName = 'GPU'
try { $gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { }
$ip = ''
try { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' } | Select-Object -First 1).IPAddress } catch { }

$prevRx = 0; $prevTx = 0
try {
    $st = Get-NetAdapterStatistics | Where-Object { $_.ReceivedBytes -gt 0 } | Measure-Object ReceivedBytes, SentBytes -Sum
    $prevRx = $st[0].Sum; $prevTx = $st[1].Sum
} catch { }

[Console]::Write("$E[2J")
while ($true) {
    $m = New-Object HudMemF+M
    [HudMemF]::GlobalMemoryStatusEx($m) | Out-Null
    $total = [math]::Round($m.ullTotalPhys / 1GB, 1)
    $used = [math]::Round(($m.ullTotalPhys - $m.ullAvailPhys) / 1GB, 1)
    $ramPct = [int][math]::Round(100 * ($m.ullTotalPhys - $m.ullAvailPhys) / $m.ullTotalPhys)

    $di = New-Object System.IO.DriveInfo('C')
    $free = [math]::Round($di.AvailableFreeSpace / 1GB)
    $diskPct = [int][math]::Round(100 * (1 - $di.AvailableFreeSpace / $di.TotalSize))

    $cpuPct = 0
    try { $cpuPct = [int](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime } catch { }

    $rx = 0; $tx = 0
    try {
        $st = Get-NetAdapterStatistics | Where-Object { $_.ReceivedBytes -gt 0 } | Measure-Object ReceivedBytes, SentBytes -Sum
        $rx = [math]::Max(0, ($st[0].Sum - $prevRx) / 1KB)
        $tx = [math]::Max(0, ($st[1].Sum - $prevTx) / 1KB)
        $prevRx = $st[0].Sum; $prevTx = $st[1].Sum
    } catch { }

    $dFree = 0; $eFree = 0
    try { $dFree = [math]::Round((New-Object System.IO.DriveInfo('D')).AvailableFreeSpace / 1GB) } catch { }
    try { $eFree = [math]::Round((New-Object System.IO.DriveInfo('E')).AvailableFreeSpace / 1GB) } catch { }

    $up = [int]([Environment]::TickCount / 60000)
    $upStr = '{0}d {1}h {2}m' -f [int]($up / 1440), [int](($up % 1440) / 60), [int]($up % 60)
    $now = Get-Date

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($l in $banner) { $lines.Add($green + $l + $reset) }
    $lines.Add('')
    $lines.Add('  ' + $dim + 'Gindama7013@' + $env:COMPUTERNAME + $reset + '   ' + $dim + $now.ToString('HH:mm:ss') + $reset)
    $lines.Add('  ' + $dim + ('-' * 50) + $reset)
    $lines.Add('')
    $lines.Add('  ' + $dim + 'os      ' + $reset + $fg + (Trim $os 30) + $reset)
    $lines.Add('  ' + $dim + 'shell   ' + $reset + $fg + 'powershell ' + $PSVersionTable.PSVersion + $reset)
    $lines.Add('  ' + $dim + 'cpu     ' + $reset + $fg + (Trim $cpuName 40) + $reset)
    $lines.Add('  ' + $dim + 'gpu     ' + $reset + $fg + (Trim $gpuName 40) + $reset)
    $lines.Add('')
    $lines.Add('  ' + $dim + 'cpu%    ' + $aqua + (Bar $cpuPct 14) + $reset + ' ' + $green + "$cpuPct%" + $reset)
    $lines.Add('  ' + $dim + 'mem     ' + $aqua + (Bar $ramPct 14) + $reset + ' ' + $green + "$used" + $reset + $dim + '/' + $reset + $green + "$total GiB" + $reset)
    $lines.Add('  ' + $dim + 'disk C  ' + $aqua + (Bar $diskPct 14) + $reset + ' ' + $green + "$free GiB free" + $reset)
    $lines.Add('')
    $lines.Add('  ' + $dim + 'disk D  ' + $reset + $fg + "$dFree GiB free" + $reset + '   ' + $dim + 'disk E  ' + $reset + $fg + "$eFree GiB free" + $reset)
    $lines.Add('  ' + $dim + 'net     ' + $reset + $green + ("down " + [int]$rx + " KB/s") + $reset + $dim + '  ' + $reset + $yellow + ("up " + [int]$tx + " KB/s") + $reset)
    $lines.Add('')
    $lines.Add('  ' + $dim + 'ip      ' + $reset + $yellow + $ip + $reset)
    $lines.Add('  ' + $dim + 'uptime  ' + $reset + $fg + $upStr + $reset)
    $lines.Add('')
    $lines.Add('  ' + $dim + 'claude  ·  ubuntu 24.04  ·  leetcode' + $reset)

    $w = 92
    try { $w = [math]::Max(40, [Console]::WindowWidth - 1) } catch { }

    [Console]::SetCursorPosition(0, 0)
    foreach ($l in $lines) {
        $plain = [regex]::Replace($l, "$([char]27)\[[0-9;]*m", '')
        $len = 0
        foreach ($ch in $plain.ToCharArray()) { if ([int]$ch -gt 0x2E80) { $len += 2 } else { $len += 1 } }
        $pad = [math]::Max(0, $w - $len)
        [Console]::Write($l + (' ' * $pad) + "`n")
    }

    Start-Sleep -Milliseconds 1000
}
