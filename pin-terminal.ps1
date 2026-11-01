# Pin terminal to bottom + keep fixed position. Geometry comes from layout.txt.
Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
public struct RECT { public int Left, Top, Right, Bottom; }
"@ -Name Pin -Namespace Dsh

$layoutFile = Join-Path $PSScriptRoot 'layout.txt'
$X = 444; $Y = 274
if (Test-Path $layoutFile) {
    foreach ($line in (Get-Content $layoutFile)) {
        if ($line -match '^\s*X\s*=\s*(-?\d+)') { $X = [int]$matches[1] }
        if ($line -match '^\s*Y\s*=\s*(-?\d+)') { $Y = [int]$matches[1] }
    }
}

$HWND_BOTTOM = [IntPtr]::new(1)
$PIN = 0x0010 -bor 0x0001 -bor 0x0002
$MOVE = 0x0001 -bor 0x0010

while ($true) {
    foreach ($p in (Get-Process wezterm-gui -ErrorAction SilentlyContinue)) {
        $h = $p.MainWindowHandle
        if ($h -eq [IntPtr]::Zero) { continue }
        $r = New-Object Dsh.Pin+RECT
        [Dsh.Pin]::GetWindowRect($h, [ref]$r) | Out-Null
        if (($r.Right - $r.Left) -gt 200 -and ($r.Left -ne $X -or $r.Top -ne $Y)) {
            [Dsh.Pin]::SetWindowPos($h, [IntPtr]::Zero, $X, $Y, 0, 0, $MOVE) | Out-Null
        }
        [Dsh.Pin]::SetWindowPos($h, $HWND_BOTTOM, 0, 0, 0, 0, $PIN) | Out-Null
    }
    Start-Sleep -Milliseconds 500
}