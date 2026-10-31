# LeetCode CN pane: profile / solved / contest / recent.
$ErrorActionPreference = 'SilentlyContinue'
$userFile = 'E:\Apps\DesktopTerminal\leetcode-user.txt'
$uri = 'https://leetcode.cn/graphql/'
$E = [char]27
$green = "$E[38;2;167;192;128m"
$aqua  = "$E[38;2;131;192;146m"
$dim   = "$E[38;2;104;116;106m"
$fg    = "$E[38;2;232;226;209m"
$yellow = "$E[38;2;219;188;127m"
$red   = "$E[38;2;230;126;128m"
$reset = "$E[0m"

function Invoke-Lc([string]$query, [hashtable]$vars) {
    try {
        $body = @{ query = $query; variables = $vars } | ConvertTo-Json -Depth 6 -Compress
        $r = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json' `
            -Headers @{ Referer = 'https://leetcode.cn/'; Origin = 'https://leetcode.cn'; 'User-Agent' = 'Mozilla/5.0' } -TimeoutSec 20
        if ($r.errors) { return $null }
        return $r
    } catch { return $null }
}

$qProgress = 'query p($s:String!){ userProfileUserQuestionProgress(userSlug:$s){ numAcceptedQuestions{ difficulty count } } }'
$qProfile  = 'query p($s:String!){ userProfilePublicProfile(userSlug:$s){ username siteRanking } }'
$qContest  = 'query p($s:String!){ userContestRanking(userSlug:$s){ attendedContestsCount rating globalRanking topPercentage } }'
$qRecent1  = 'query p($s:String!){ recentAcSubmissionList(username:$s, limit:8){ title } }'
$qRecent2  = 'query p($s:String!){ recentAcSubmissions(userSlug:$s, limit:8){ question { title } submitTime } }'

[Console]::Write("$E[2J")
while ($true) {
    $buf = New-Object System.Text.StringBuilder
    function W([string]$s) { [void]$buf.AppendLine($s) }

    $user = if (Test-Path $userFile) { (Get-Content $userFile -Raw).Trim() } else { 'qian-xk' }

    $p = Invoke-Lc $qProgress @{ s = $user }
    $prof = Invoke-Lc $qProfile @{ s = $user }
    $contest = Invoke-Lc $qContest @{ s = $user }
    $recent = Invoke-Lc $qRecent1 @{ s = $user }
    if (-not $recent) { $recent = Invoke-Lc $qRecent2 @{ s = $user } }

    $easy = 0; $med = 0; $hard = 0
    if ($p -and $p.data.userProfileUserQuestionProgress) {
        foreach ($x in $p.data.userProfileUserQuestionProgress.numAcceptedQuestions) {
            switch ($x.difficulty) {
                'EASY' { $easy = [int]$x.count }
                'MEDIUM' { $med = [int]$x.count }
                'HARD' { $hard = [int]$x.count }
            }
        }
    }

    W ''
    W ('  ' + $green + 'LEETCODE' + $reset + '  ' + $dim + (Get-Date).ToString('HH:mm:ss') + $reset)
    W ('  ' + $dim + ('─' * 40) + $reset)

    W ''
    W ('  ' + $aqua + 'PROFILE' + $reset)
    W ('  ' + $dim + 'user      ' + $reset + $fg + $user + $reset)
    $rank = $null
    if ($prof -and $prof.data.userProfilePublicProfile) { $rank = $prof.data.userProfilePublicProfile.siteRanking }
    if ($rank -and $rank -ne 100000) { W ('  ' + $dim + 'ranking   ' + $reset + $fg + '#' + $rank + $reset) }
    else { W ('  ' + $dim + 'ranking   unranked' + $reset) }

    W ''
    W ('  ' + $aqua + 'SOLVED' + $reset)
    W ('  ' + $dim + 'total     ' + $reset + $fg + ($easy + $med + $hard) + $reset)
    W ('  ' + $dim + 'easy      ' + $reset + $green + $easy + $reset)
    W ('  ' + $dim + 'medium    ' + $reset + $yellow + $med + $reset)
    W ('  ' + $dim + 'hard      ' + $reset + $red + $hard + $reset)

    W ''
    W ('  ' + $aqua + 'CONTEST' + $reset)
    if ($contest -and $contest.data.userContestRanking) {
        $cr = $contest.data.userContestRanking
        W ('  ' + $dim + 'attended  ' + $reset + $fg + $cr.attendedContestsCount + $reset)
        W ('  ' + $dim + 'rating    ' + $reset + $fg + [int]$cr.rating + $reset)
        W ('  ' + $dim + 'top       ' + $reset + $fg + [math]::Round($cr.topPercentage, 1) + '%' + $reset)
    } else { W ('  ' + $dim + 'no contest data' + $reset) }

    W ''
    W ('  ' + $aqua + 'RECENT' + $reset)
    $items = @()
    if ($recent -and $recent.data) {
        if ($recent.data.recentAcSubmissionList) { $items = $recent.data.recentAcSubmissionList }
        elseif ($recent.data.recentAcSubmissions) {
            $items = $recent.data.recentAcSubmissions | ForEach-Object { [pscustomobject]@{ title = $_.question.title } }
        }
    }
    if ($items.Count -gt 0) {
        $i = 0
        foreach ($it in ($items | Select-Object -First 8)) {
            $i++
            W ('  ' + $dim + $i.ToString() + '. ' + $reset + $fg + $it.title + $reset)
        }
    } else {
        W ('  ' + $dim + 'no recent data' + $reset)
    }

    W ''
    W ('  ' + $dim + 'refreshed ' + (Get-Date).ToString('HH:mm:ss') + $reset)

    [Console]::SetCursorPosition(0, 0)
    [Console]::Write($buf.ToString())
    Start-Sleep -Seconds 60
}
