# GitHub status pane: profile stats + unread notifications, refreshed every 60s.
$ErrorActionPreference = 'SilentlyContinue'
$E0 = [char]27
$green = "$E0[38;2;167;192;128m"
$dim   = "$E0[38;2;104;116;106m"
$fg    = "$E0[38;2;232;226;209m"
$reset = "$E0[0m"

function Get-Gh($argsList) {
    $out = & gh @argsList 2>&1
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($out | Out-String).Trim()
}

while ($true) {
    Clear-Host
    Write-Host ''
    Write-Host '  GITHUB' -ForegroundColor Green
    Write-Host '  ------------------------' -ForegroundColor DarkGray
    Write-Host ''

    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        Write-Host '  gh CLI 未安装' -ForegroundColor Yellow
        Write-Host '  winget install --id GitHub.cli' -ForegroundColor DarkGray
        Start-Sleep -Seconds 30
        continue
    }

    $user = Get-Gh @('api', 'user', '--jq', '.login')
    if (-not $user) {
        Write-Host '  未登录：运行 gh auth login' -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        continue
    }

    $name = Get-Gh @('api', 'user', '--jq', '.name // .login')
    $repos = Get-Gh @('api', 'user', '--jq', '.public_repos')
    $stars = Get-Gh @('api', 'user', '--jq', '[.owned_private_repos, .total_private_repos] | .[1] // 0')
    $followers = Get-Gh @('api', 'user', '--jq', '.followers')
    $notif = Get-Gh @('api', 'notifications', '--jq', 'length')

    Write-Host ("  " + $name + "  @" + $user) -ForegroundColor White
    Write-Host ''
    Write-Host ("  repos     " + $repos) -ForegroundColor DarkGray
    Write-Host ("  followers " + $followers) -ForegroundColor DarkGray
    Write-Host ("  unread    " + $notif) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  --- recent activity ---' -ForegroundColor DarkGray

    $events = & gh api "users/$user/events" --jq '.[0:6][] | .type + "  " + (.repo.name // "")' 2>$null
    if ($events) {
        foreach ($line in ($events -split "`n" | Select-Object -First 6)) {
            Write-Host ("  " + $line.Trim()) -ForegroundColor DarkGray
        }
    } else {
        Write-Host '  (no public events)' -ForegroundColor DarkGray
    }

    Write-Host ''
    Write-Host ('  refreshed ' + (Get-Date).ToString('HH:mm:ss')) -ForegroundColor DarkGray
    Start-Sleep -Seconds 60
}
