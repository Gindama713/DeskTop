# LeetCode pane. Username comes from config.json, cookie from data/leetcode-cookie.txt.
$ErrorActionPreference = 'SilentlyContinue'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib\DesktopKit.psm1') -Force

$th = Get-DkTheme
$cfg = Get-DkConfig
$user = $cfg.leetcode.username
$cookieFile = Get-DkDataFile 'leetcode-cookie.txt'
$api = 'https://leetcode.cn/graphql/'
$apiNj = 'https://leetcode.cn/graphql/noj-go/'

$qProfile = 'query p($s:String!){ userProfilePublicProfile(userSlug:$s){ username siteRanking } }'
$qProgress = 'query p($s:String!){ userProfileUserQuestionProgress(userSlug:$s){ numAcceptedQuestions{ difficulty count } numFailedQuestions{ difficulty count } numUntouchedQuestions{ difficulty count } } }'
$qDaily = 'query questionOfToday { todayRecord { date question { title difficulty } } }'
$qContest = 'query userContestRankingInfo($userSlug: String!) { userContestRanking(userSlug: $userSlug) { attendedContestsCount rating globalRanking topPercentage } }'
$qCalendar = 'query userProfileCalendar($userSlug: String!, $year: Int) { userCalendar(userSlug: $userSlug, year: $year) { streak totalActiveDays recentStreak } }'
$qRecent = 'query recentACSubmissions($userSlug: String!) { recentACSubmissions(userSlug: $userSlug) { submitTime question { title } } }'

$cookie = ''
if (Test-Path $cookieFile) { $cookie = (Get-Content $cookieFile -Raw).Trim() }
$csrf = ''
if ($cookie -match 'csrftoken=([^;]+)') { $csrf = $matches[1] }

function Invoke-Lc([string]$query, [hashtable]$vars, [string]$ep = $api, [string]$op = '') {
    try {
        $body = @{ query = $query; variables = $vars } | ConvertTo-Json -Depth 8 -Compress
        $h = @{ Referer = 'https://leetcode.cn/'; Origin = 'https://leetcode.cn'; 'User-Agent' = 'Mozilla/5.0' }
        if ($cookie) { $h['Cookie'] = $cookie }
        if ($csrf) { $h['x-csrftoken'] = $csrf }
        if ($op) { $h['x-operation-name'] = $op }
        $r = Invoke-RestMethod -Uri $ep -Method Post -Body $body -ContentType 'application/json' -Headers $h -TimeoutSec 20
        if ($r.errors) { return $null }
        return $r
    } catch { return $null }
}

[Console]::Write("$($th.esc)[2J")
while ($true) {
    Exit-DkIfOrphaned

    $buf = New-Object System.Text.StringBuilder
    function W([string]$s) { [void]$buf.AppendLine($s) }

    $prof = Invoke-Lc $qProfile @{ s = $user }
    $prog = Invoke-Lc $qProgress @{ s = $user }
    $daily = Invoke-Lc $qDaily @{ }
    $contest = Invoke-Lc $qContest @{ userSlug = $user } $apiNj 'userContestRankingInfo'
    $calendar = Invoke-Lc $qCalendar @{ userSlug = $user; year = (Get-Date).Year } $apiNj 'userProfileCalendar'
    $recent = Invoke-Lc $qRecent @{ userSlug = $user } $apiNj 'recentACSubmissions'

    $acc = @{}; $fail = @{}; $todo = @{}
    if ($prog) {
        foreach ($x in $prog.data.userProfileUserQuestionProgress.numAcceptedQuestions) { $acc[$x.difficulty] = [int]$x.count }
        foreach ($x in $prog.data.userProfileUserQuestionProgress.numFailedQuestions) { $fail[$x.difficulty] = [int]$x.count }
        foreach ($x in $prog.data.userProfileUserQuestionProgress.numUntouchedQuestions) { $todo[$x.difficulty] = [int]$x.count }
    }
    $eA = $acc['EASY']; $mA = $acc['MEDIUM']; $hA = $acc['HARD']
    $eF = $fail['EASY']; $mF = $fail['MEDIUM']; $hF = $fail['HARD']
    $eT = $todo['EASY']; $mT = $todo['MEDIUM']; $hT = $todo['HARD']
    $solved = $eA + $mA + $hA
    $failed = $eF + $mF + $hF
    $untouched = $eT + $mT + $hT
    $bank = $solved + $failed + $untouched
    $progress = if ($bank -gt 0) { [int](100 * $solved / $bank) } else { 0 }
    $accRate = if (($solved + $failed) -gt 0) { [int](100 * $solved / ($solved + $failed)) } else { 0 }

    W ''
    W ('  ' + $th.green + 'LEETCODE' + $th.reset + '  ' + $th.dim + (Get-Date).ToString('HH:mm:ss') + $th.reset)
    W ('  ' + $th.dim + ('-' * 42) + $th.reset)
    W ''
    W ('  ' + $th.dim + 'user      ' + $th.reset + $th.fg + $user + $th.reset)
    $rank = $null
    if ($prof -and $prof.data.userProfilePublicProfile) { $rank = $prof.data.userProfilePublicProfile.siteRanking }
    if ($rank -and $rank -ne 100000) { W ('  ' + $th.dim + 'rank      ' + $th.reset + $th.fg + '#' + $rank + $th.reset) }
    else { W ('  ' + $th.dim + 'rank      unranked' + $th.reset) }

    W ''
    W ('  ' + $th.aqua + 'SOLVED' + $th.reset + '    ' + $th.fg + $solved + $th.reset + $th.dim + ' / ' + $bank + '  (' + $progress + '%)' + $th.reset)
    W ('  ' + $th.dim + 'easy      ' + $th.reset + $th.green + $eA + $th.reset + $th.dim + ' ok  ' + $th.reset + $th.red + $eF + $th.reset + $th.dim + ' fail  ' + $eT + ' left' + $th.reset)
    W ('  ' + $th.dim + 'medium    ' + $th.reset + $th.yellow + $mA + $th.reset + $th.dim + ' ok  ' + $th.reset + $th.red + $mF + $th.reset + $th.dim + ' fail  ' + $mT + ' left' + $th.reset)
    W ('  ' + $th.dim + 'hard      ' + $th.reset + $th.red + $hA + $th.reset + $th.dim + ' ok  ' + $th.red + $hF + $th.reset + $th.dim + ' fail  ' + $hT + ' left' + $th.reset)
    W ''
    W ('  ' + $th.dim + 'progress  ' + $th.aqua + (Write-DkBar $progress 26) + $th.reset + ' ' + $th.fg + $progress + '%' + $th.reset)
    W ('  ' + $th.dim + 'accuracy  ' + $th.aqua + (Write-DkBar $accRate 26) + $th.reset + ' ' + $th.fg + $accRate + '%' + $th.reset)

    W ''
    W ('  ' + $th.aqua + 'CONTEST' + $th.reset)
    if ($contest -and $contest.data.userContestRanking) {
        $cr = $contest.data.userContestRanking
        W ('  ' + $th.dim + 'rating    ' + $th.reset + $th.fg + [math]::Round($cr.rating) + $th.reset + $th.dim + '  (' + [math]::Round($cr.topPercentage, 1) + '%)' + $th.reset)
        W ('  ' + $th.dim + 'attended  ' + $th.reset + $th.fg + $cr.attendedContestsCount + $th.reset)
        W ('  ' + $th.dim + 'global    ' + $th.reset + $th.fg + '#' + $cr.globalRanking + $th.reset)
    } else { W ('  ' + $th.dim + 'no data (cookie?)' + $th.reset) }

    W ''
    W ('  ' + $th.aqua + 'ACTIVITY' + $th.reset)
    if ($calendar -and $calendar.data.userCalendar) {
        W ('  ' + $th.dim + 'streak    ' + $th.reset + $th.yellow + $calendar.data.userCalendar.streak + $th.reset + $th.dim + ' days' + $th.reset)
        W ('  ' + $th.dim + 'active    ' + $th.reset + $th.fg + $calendar.data.userCalendar.totalActiveDays + $th.reset + $th.dim + ' days' + $th.reset)
    } else { W ('  ' + $th.dim + 'no data (cookie?)' + $th.reset) }

    W ''
    W ('  ' + $th.aqua + 'RECENT' + $th.reset)
    if ($recent -and $recent.data.recentACSubmissions) {
        foreach ($s in ($recent.data.recentACSubmissions | Select-Object -First 4)) {
            $d = [DateTimeOffset]::FromUnixTimeSeconds([long]$s.submitTime).ToLocalTime().ToString('MM-dd')
            W ('  ' + $th.dim + $d + '  ' + $th.reset + $th.fg + $s.question.title + $th.reset)
        }
    } else { W ('  ' + $th.dim + 'no data (cookie?)' + $th.reset) }

    W ''
    W ('  ' + $th.aqua + 'DAILY' + $th.reset)
    if ($daily -and $daily.data.todayRecord) {
        $rec = $daily.data.todayRecord[0]
        $diff = $rec.question.difficulty
        $dc = if ($diff -eq 'Easy') { $th.green } elseif ($diff -eq 'Medium') { $th.yellow } else { $th.red }
        W ('  ' + $dc + $diff.PadRight(9) + $th.reset + $th.fg + $rec.question.title + $th.reset)
    } else { W ('  ' + $th.dim + 'not available' + $th.reset) }

    W ''
    W ('  ' + $th.dim + 'refreshed ' + (Get-Date).ToString('HH:mm:ss') + $th.reset)

    [Console]::SetCursorPosition(0, 0)
    [Console]::Write($buf.ToString())
    Start-Sleep -Seconds 60
}
