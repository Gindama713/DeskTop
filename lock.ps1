# Floating lock button for the desktop terminal.
# Locked  -> the pin watchdog runs: terminal stays at the bottom, cannot be moved.
# Unlocked-> watchdog stops: drag / resize the window freely (Win+Arrow to snap).
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$root = 'E:\Apps\DesktopTerminal'
$stateFile = Join-Path $root 'lock.state'
$pinScript = Join-Path $root 'pin-terminal.ps1'

function Get-PinProcesses {
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*pin-terminal.ps1*' -and $_.ProcessId -ne $PID }
}

function Start-Pin {
    if (-not (Get-PinProcesses)) {
        Start-Process powershell -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden',
            '-ExecutionPolicy', 'Bypass', '-File', $pinScript -WindowStyle Hidden
    }
}

function Stop-Pin {
    Get-PinProcesses | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

# Locked = frameless; unlocked = title bar so the window can be dragged and resized.
function Set-Decor([bool]$frameless) {
    $cfg = Join-Path $env:USERPROFILE '.wezterm.lua'
    if (-not (Test-Path $cfg)) { return }
    $t = [IO.File]::ReadAllText($cfg, [Text.Encoding]::UTF8)
    $val = if ($frameless) { 'NONE' } else { 'TITLE' }
    $t = $t -replace "config\.window_decorations = '[A-Z]+'", "config.window_decorations = '$val'"
    [IO.File]::WriteAllText($cfg, $t, (New-Object Text.UTF8Encoding($false)))
}

$locked = if (Test-Path $stateFile) { (Get-Content $stateFile -Raw).Trim() -eq '1' } else { $true }

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.StartPosition = 'Manual'
$form.TopMost = $true
$form.Width = 52
$form.Height = 52
$form.BackColor = [System.Drawing.Color]::FromArgb(12, 26, 22)
$form.Opacity = 0.92
$form.ShowInTaskbar = $false

Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r); public struct RECT { public int Left, Top, Right, Bottom; }' -Name LockW -Namespace LockW
$wt = Get-Process wezterm-gui -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wt) {
    $r = New-Object LockW.LockW+RECT
    [LockW.LockW]::GetWindowRect($wt.MainWindowHandle, [ref]$r) | Out-Null
    $form.Left = $r.Right - 62
    $form.Top = $r.Top + 6
} else {
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Left = $screen.Right - 90
    $form.Top = 40
}

$label = New-Object System.Windows.Forms.Label
$label.Dock = 'Fill'
$label.TextAlign = 'MiddleCenter'
$label.Font = New-Object System.Drawing.Font('Microsoft YaHei', 16, [System.Drawing.FontStyle]::Bold)
$label.ForeColor = [System.Drawing.Color]::FromArgb(167, 192, 128)
$form.Controls.Add($label)

function Update-Look {
    if ($locked) {
        $label.Text = '锁'
        $label.ForeColor = [System.Drawing.Color]::FromArgb(230, 126, 128)
    } else {
        $label.Text = '开'
        $label.ForeColor = [System.Drawing.Color]::FromArgb(167, 192, 128)
    }
}

Update-Look
Set-Decor $locked
if ($locked) { Start-Pin } else { Stop-Pin }

# drag the button around
$script:dragging = $false
$script:dx = 0
$script:dy = 0
$form.Add_MouseDown({ param($s, $e) $script:dragging = $true; $script:dx = $e.X; $script:dy = $e.Y })
$form.Add_MouseMove({
    param($s, $e)
    if ($script:dragging) {
        $form.Left = $e.X + $form.Left - $script:dx
        $form.Top = $e.Y + $form.Top - $script:dy
    }
})
$form.Add_MouseUp({ param($s, $e) $script:dragging = $false })

$form.Add_Click({
    $script:locked = -not $script:locked
    Set-Content -Path $stateFile -Value ($(if ($script:locked) { '1' } else { '0' })) -Encoding ASCII
    if ($script:locked) { Start-Pin } else { Stop-Pin }
    Set-Decor $script:locked
    Update-Look
})

[System.Windows.Forms.Application]::Run($form)
