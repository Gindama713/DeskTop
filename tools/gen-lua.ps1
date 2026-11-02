# Generates generated/panes.lua from config.json.
# WezTerm reads that Lua table, so config.json stays the single source of truth
# even on WezTerm builds that lack json_parse.
param([string]$Repo = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)))

$cfgPath = Join-Path $Repo 'config.json'
if (-not (Test-Path $cfgPath)) { throw "config.json not found at $cfgPath" }
$cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Quote-Lua([string]$s) {
    $escaped = $s.Replace('\', '\\')
    $escaped = $escaped.Replace("'", "\'")
    return "'" + $escaped + "'"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('-- generated from config.json by tools/gen-lua.ps1 - do not edit')
$lines.Add('return {')
$lines.Add('  tabs = {')

foreach ($tab in $cfg.tabs) {
    $lines.Add('    {')
    $lines.Add('      name = ' + (Quote-Lua $tab.name) + ',')
    $lines.Add('      panes = {')
    foreach ($pane in $tab.panes) {
        $args = @()
        foreach ($a in $pane.args) { $args += (Quote-Lua $a) }
        $line = '        { args = { ' + ($args -join ', ') + ' }'
        if ($pane.split) { $line += ', split = ' + (Quote-Lua $pane.split) }
        if ($null -ne $pane.size) { $line += ', size = ' + ([string]$pane.size) }
        $line += ' },'
        $lines.Add($line)
    }
    $lines.Add('      },')
    $lines.Add('    },')
}

$lines.Add('  },')
$lines.Add('}')

$dir = Join-Path $Repo 'generated'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$target = Join-Path $dir 'panes.lua'
[IO.File]::WriteAllText($target, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($false)))
Write-Host ('  panes.lua generated: ' + $target) -ForegroundColor DarkGray

# also emit window / theme / python so the Lua config has one source too
$s = New-Object System.Collections.Generic.List[string]
$s.Add('-- generated from config.json by tools/gen-lua.ps1 - do not edit')
$s.Add('return {')
$s.Add('  window = {')
$s.Add(('    x = ' + $cfg.window.x + ', y = ' + $cfg.window.y + ', cols = ' + $cfg.window.cols + ', rows = ' + $cfg.window.rows + ','))
$s.Add(('    font_size = ' + $cfg.window.font_size + ', opacity = ' + $cfg.window.opacity))
$s.Add('  },')
$s.Add(('  python = ' + (Quote-Lua $cfg.python) + ','))
$s.Add('  theme = {')
foreach ($k in @('bg','fg','green','aqua','yellow','red','dim','cursor')) {
    $s.Add(('    ' + $k + ' = ' + (Quote-Lua $cfg.theme.$k) + ','))
}
$s.Add('  },')
$s.Add('}')
[IO.File]::WriteAllText((Join-Path $dir 'settings.lua'), ($s -join "`r`n"), (New-Object Text.UTF8Encoding($false)))
Write-Host ('  settings.lua generated') -ForegroundColor DarkGray