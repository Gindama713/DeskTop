# Full-page spinning donut (classic algorithm, PowerShell port).
$ErrorActionPreference = 'SilentlyContinue'
$E0 = [char]27
$green = "$E0[38;2;167;192;128m"
$aqua  = "$E0[38;2;131;192;146m"
$fg    = "$E0[38;2;232;226;209m"
$dim   = "$E0[38;2;104;116;106m"
$reset = "$E0[0m"

$charset = '.,-~:;=!*#$@'
$A = 0.0
$B = 0.0
$first = $true

while ($true) {
    $DW = 70; $DH = 28
    try {
        $DW = [math]::Min(90, [int]$Host.UI.RawUI.WindowSize.Width - 2)
        $DH = [math]::Min(34, [int]$Host.UI.RawUI.WindowSize.Height - 2)
    } catch { }
    if ($DW -lt 20) { $DW = 70 }
    if ($DH -lt 10) { $DH = 28 }

    $zb = New-Object 'double[]' ($DW * $DH)
    $buf = New-Object 'char[]' ($DW * $DH)
    for ($k = 0; $k -lt $buf.Length; $k++) { $buf[$k] = ' ' }

    for ($j = 0.0; $j -lt 6.28; $j += 0.075) {
        $ct = [math]::Cos($j); $st = [math]::Sin($j)
        for ($i = 0.0; $i -lt 6.28; $i += 0.035) {
            $cp = [math]::Cos($i); $sp = [math]::Sin($i)
            $h = $cp * $ct + 1
            $d = 1.0 / ($sp * $h * [math]::Sin($A) + $st * [math]::Cos($A) + 5)
            $t = $sp * $h * [math]::Cos($A) - $st * [math]::Sin($A)
            $x = [int]($DW / 2 + $DW * 0.34 * $d * ($cp * $sp * [math]::Sin($B) - $t * [math]::Cos($B)))
            $y = [int]($DH / 2 + $DH * 0.42 * $d * ($cp * $sp * [math]::Cos($B) + $t * [math]::Sin($B)))
            $n = [int](8 * (($st * [math]::Sin($A) - $sp * $ct * [math]::Cos($A)) * [math]::Cos($B) - $sp * $ct * [math]::Sin($A) - $st * [math]::Cos($A) - $cp * $ct * [math]::Sin($B)))
            if ($n -lt 0) { $n = 0 }
            if ($n -gt 11) { $n = 11 }
            if ($y -ge 0 -and $y -lt $DH -and $x -ge 0 -and $x -lt $DW) {
                $o = $x + $DW * $y
                if ($d -gt $zb[$o]) { $zb[$o] = $d; $buf[$o] = $charset[$n] }
            }
        }
    }

    $sb = New-Object System.Text.StringBuilder
    if ($first) { [void]$sb.Append("$E0[2J"); $first = $false }
    [void]$sb.Append("$E0[H")

    for ($yy = 0; $yy -lt $DH; $yy++) {
        for ($xx = 0; $xx -lt $DW; $xx++) {
            $ch = $buf[$xx + $DW * $yy]
            if ($ch -eq ' ') { [void]$sb.Append(' ') }
            else {
                $idx = $charset.IndexOf($ch)
                if ($idx -ge 8) { [void]$sb.Append("$fg$ch$reset") }
                elseif ($idx -ge 4) { [void]$sb.Append("$green$ch$reset") }
                else { [void]$sb.Append("$aqua$ch$reset") }
            }
        }
        [void]$sb.Append("`n")
    }

    [Console]::Write($sb.ToString())
    $A += 0.04
    $B += 0.02
    Start-Sleep -Milliseconds 20
}
