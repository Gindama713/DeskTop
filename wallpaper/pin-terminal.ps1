# Keep the desktop terminal pinned to the bottom of the normal z-order and
# locked to its slot: above the wallpaper, below every other window, focusable.
param(
    [int]$X = 666, [int]$Y = 720, [int]$W = 1638, [int]$H = 576,
    [int]$IntervalMs = 150
)

Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
'@ -Name Pin -Namespace Dsh

$HWND_BOTTOM = [IntPtr]::new(1)
$flags = 0x0010   # SWP_NOACTIVATE: never steal focus

while ($true) {
    $procs = Get-Process alacritty -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        $h = $p.MainWindowHandle
        if ($h -ne [IntPtr]::Zero -and [Dsh.Pin]::IsWindowVisible($h)) {
            [Dsh.Pin]::SetWindowPos($h, $HWND_BOTTOM, $X, $Y, $W, $H, $flags) | Out-Null
        }
    }
    Start-Sleep -Milliseconds $IntervalMs
}
