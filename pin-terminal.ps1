param([int]$IntervalMs = 150)
Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
"@ -Name Pin -Namespace Dsh
$HWND_BOTTOM = [IntPtr]::new(1)
$flags = 0x0001 -bor 0x0002 -bor 0x0010
while ($true) {
    foreach ($p in (Get-Process wezterm-gui,alacritty -ErrorAction SilentlyContinue)) {
        $h = $p.MainWindowHandle
        if ($h -ne [IntPtr]::Zero -and [Dsh.Pin]::IsWindowVisible($h)) {
            [Dsh.Pin]::SetWindowPos($h, $HWND_BOTTOM, 0, 0, 0, 0, $flags) | Out-Null
        }
    }
    Start-Sleep -Milliseconds $IntervalMs
}
