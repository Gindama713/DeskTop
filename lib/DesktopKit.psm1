<#
.SYNOPSIS
  Shared helpers for every DeskTop pane.

.DESCRIPTION
  Panes are independent scripts. They only depend on this module, which gives them:
    - the merged config (config.json + defaults)
    - ANSI helpers built from the theme
    - a liveness check so a pane quits when WezTerm goes away
    - a data-directory resolver

  Nothing here knows about a specific pane, so adding or removing panes cannot break
  the rest of the system.
#>

$script:DkRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

function Get-DkRoot {
    return $script:DkRoot
}

function Get-DkConfig {
    $path = Join-Path $script:DkRoot 'config.json'
    $defaults = @{
        window   = @{ x = 444; y = 274; cols = 168; rows = 36; font_size = 8.5; opacity = 0.94 }
        theme    = @{
            bg = '#0c1a16'; fg = '#d3c6aa'; green = '#a7c080'; aqua = '#83c092'
            yellow = '#dbbc7f'; red = '#e67e80'; dim = '#68746a'; cursor = '#a7c080'
        }
        python   = 'python'
        data_dir = 'data'
        tabs     = @()
    }
    if (-not (Test-Path $path)) { return $defaults }

    try {
        $raw = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $defaults
    }

    foreach ($k in $defaults.Keys) {
        if (-not $raw.PSObject.Properties[$k]) {
            $raw | Add-Member -NotePropertyName $k -NotePropertyValue $defaults[$k]
        }
    }
    return $raw
}

function Get-DkTheme {
    $cfg = Get-DkConfig
    $t = $cfg.theme
    $esc = [char]27
    function Hex([string]$hex) {
        $h = $hex.TrimStart('#')
        return '{0};{1};{2}' -f [Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
    }
    return @{
        esc    = $esc
        reset  = "$esc[0m"
        fg     = "$esc[38;2;$(Hex $t.fg)m"
        bg     = "$esc[48;2;$(Hex $t.bg)m"
        green  = "$esc[38;2;$(Hex $t.green)m"
        aqua   = "$esc[38;2;$(Hex $t.aqua)m"
        yellow = "$esc[38;2;$(Hex $t.yellow)m"
        red    = "$esc[38;2;$(Hex $t.red)m"
        dim    = "$esc[38;2;$(Hex $t.dim)m"
    }
}

function Get-DkDataDir {
    $cfg = Get-DkConfig
    $dir = Join-Path $script:DkRoot $cfg.data_dir
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}

function Get-DkDataFile([string]$name) {
    return Join-Path (Get-DkDataDir) $name
}

<#
  Panes call this in their main loop. When the terminal is gone the pane exits,
  so restarts can never leave zombie processes behind.
#>
function Test-DkTerminalAlive {
    return [bool](Get-Process wezterm-gui -ErrorAction SilentlyContinue)
}

function Exit-DkIfOrphaned {
    if (-not (Test-DkTerminalAlive)) { exit }
}

function Write-DkBar([int]$pct, [int]$width) {
    $p = [math]::Min(100, [math]::Max(0, $pct))
    $fill = [math]::Round($width * $p / 100)
    return ('#' * $fill) + ('.' * ($width - $fill))
}

Export-ModuleMember -Function Get-DkRoot, Get-DkConfig, Get-DkTheme, Get-DkDataDir, Get-DkDataFile, Test-DkTerminalAlive, Exit-DkIfOrphaned, Write-DkBar
