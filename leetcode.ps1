# LeetCode CN pane: solved, rates, contest, activity, recent, daily.
$ErrorActionPreference = 'SilentlyContinue'
$userFile = Join-Path $PSScriptRoot 'leetcode-user.txt'
$cookieFile = Join-Path $PSScriptRoot 'leetcode-cookie.txt'
$api = 'https://leetcode.cn/graphql/'
$apiNj = 'https://leetcode.cn/graphql/noj-go/'
$E = [char]27
$green = "$E[38;2;167;192;128m"
$aqua  = "$E[38;2;131;192;146m"
$dim   = "$E[38;2;104;116;106m"
$fg    = "$E[38;2;232;226;209m"
$yellow = "$E[38;2;219;188;127m"
$red   = "$E[38;2;230;126;128m"
$reset = "$E[0m"

$qProfile  = 'query p($s:String!){ userProfilePublicProfile(userSlug:$s){ username siteRanking } }'
$qProgress = 'query p($s:String!){ userProfileUserQuestionProgress(userSlug:$s){ numAcceptedQuestions{ difficulty count } numFailedQuestions{ difficulty count } numUntouchedQuestions{ difficulty count } } }'
$qDaily    = 'query questionOfToday { todayRecord { date question { title difficulty } } }'
$qContest  = 'query userContestRankingInfo($userSlug: String!) { userContestRanking(userSlug: $userSlug) { attendedContestsCount rating globalRanking topPercentage } }'
$qCalendar = 'query userProfileCalendar($userSlug: String!, $year: Int) { userCalendar(userSlug: $userSlug, year: $year) { streak totalActiveDays recentStreak } }'
$qRecent   = 'query recentACSubmissions($userSlug: String!) { recentACSubmissions(userSlug: $userSlug) { submitTime question { title } } }'

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

function Bar([int]$pct, [int]$width) {
    $fill = [math]::Round($width * [math]::Min(100, [math]::Max(0, $pct)) / 100)
    return ('#' * $fill) + ('.' * ($width - $fill))
}

[Console]::Write("$E[2J")
while ($true) {
    if (-not (Get-Process wezterm-gui -ErrorAction SilentlyContinue)) { exit }
    $buf = New-Object System.Text.StringBuilder
    function W([string]$s) { [void]$buf.AppendLine($s) }

    $user = if (Test-Path $userFile) { (Get-Content $userFile -Raw).Trim() } else { 'qian-xk' }
    $prof  = Invoke-Lc $qProfile  @{ s = $user }
    $prog  = Invoke-Lc $qProgress @{ s = $user }
    $daily = Invoke-Lc $qDaily    @{ }
    $year = (Get-Date).Year
    $contest  = Invoke-Lc $qContest  @{ userSlug = $user } $apiNj 'userContestRankingInfo'
    $calendar = Invoke-Lc $qCalendar @{ userSlug = $user; year = $year } $apiNj 'userProfileCalendar'
    $recent   = Invoke-Lc $qRecent   @{ userSlug = $user } $apiNj 'recentACSubmissions'

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

    $rank = $null
    if ($prof -and $prof.data.userProfilePublicProfile) { $rank = $prof.data.userProfilePublicProfile.siteRanking }

    W ''
    W ('  ' + $green + 'LEETCODE' + $reset + '  ' + $dim + (Get-Date).ToString('HH:mm:ss') + $reset)
    W ('  ' + $dim + ('-' * 42) + $reset)
    W ''
    W ('  ' + $dim + 'user      ' + $reset + $fg + $user + $reset)
    if ($rank -and $rank -ne 100000) { W ('  ' + $dim + 'rank      ' + $reset + $fg + '#' + $rank + $reset) }
    else { W ('  ' + $dim + 'rank      unranked' + $reset) }

    W ''
    W ('  ' + $aqua + 'SOLVED' + $reset + '    ' + $fg + $solved + $reset + $dim + ' / ' + $bank + '  (' + $progress + '%)' + $reset)
    W ('  ' + $dim + 'easy      ' + $reset + $green + $eA + $reset + $dim + ' ok  ' + $reset + $red + $eF + $reset + $dim + ' fail  ' + $reset + $dim + $eT + ' left' + $reset)
    W ('  ' + $dim + 'medium    ' + $reset + $yellow + $mA + $reset + $dim + ' ok  ' + $reset + $red + $mF + $reset + $dim + ' fail  ' + $reset + $dim + $mT + ' left' + $reset)
    W ('  ' + $dim + 'hard      ' + $reset + $red + $hA + $reset + $dim + ' ok  ' + $reset + $red + $hF + $reset + $dim + ' fail  ' + $reset + $dim + $hT + ' left' + $reset)

    W ''
    W ('  ' + $dim + 'progress  ' + $aqua + (Bar $progress 26) + $reset + ' ' + $fg + $progress + '%' + $reset)
    W ('  ' + $dim + 'accuracy  ' + $aqua + (Bar $accRate 26) + $reset + ' ' + $fg + $accRate + '%' + $reset)

    W ''
    W ('  ' + $aqua + 'CONTEST' + $reset)
    if ($contest -and $contest.data.userContestRanking) {
        $cr = $contest.data.userContestRanking
        W ('  ' + $dim + 'rating    ' + $reset + $fg + [math]::Round($cr.rating) + $reset + $dim + '  (' + [math]::Round($cr.topPercentage, 1) + '%)' + $reset)
        W ('  ' + $dim + 'attended  ' + $reset + $fg + $cr.attendedContestsCount + $reset + $dim + ' contest(s)' + $reset)
        W ('  ' + $dim + 'global    ' + $reset + $fg + '#' + $cr.globalRanking + $reset)
    } else { W ('  ' + $dim + 'no data (cookie?)' + $reset) }

    W ''
    W ('  ' + $aqua + 'ACTIVITY' + $reset)
    if ($calendar -and $calendar.data.userCalendar) {
        $cal = $calendar.data.userCalendar
        W ('  ' + $dim + 'streak    ' + $reset + $yellow + $cal.streak + $reset + $dim + ' days' + $reset)
        W ('  ' + $dim + 'active    ' + $reset + $fg + $cal.totalActiveDays + $reset + $dim + ' days total' + $reset)
    } else { W ('  ' + $dim + 'no data (cookie?)' + $reset) }

    W ''
    W ('  ' + $aqua + 'RECENT' + $reset)
    if ($recent -and $recent.data.recentACSubmissions) {
        $i = 0
        foreach ($s in ($recent.data.recentACSubmissions | Select-Object -First 4)) {
            $i++
            $t = [DateTimeOffset]::FromUnixTimeSeconds([long]$s.submitTime).ToLocalTime().ToString('MM-dd')
            W ('  ' + $dim + $t + '  ' + $reset + $fg + $s.question.title + $reset)
        }
    } else { W ('  ' + $dim + 'no data (cookie?)' + $reset) }

    W ''
    W ('  ' + $aqua + 'DAILY' + $reset)
    if ($daily -and $daily.data.todayRecord) {
        $rec = $daily.data.todayRecord[0]
        $diff = $rec.question.difficulty
        $dc = if ($diff -eq 'Easy') { $green } elseif ($diff -eq 'Medium') { $yellow } else { $red }
        W ('  ' + $dc + $diff.PadRight(9) + $reset + $fg + $rec.question.title + $reset)
    } else { W ('  ' + $dim + 'not available' + $reset) }

    W ''
    W ('  ' + $dim + 'refreshed ' + (Get-Date).ToString('HH:mm:ss') + $reset)

    [Console]::SetCursorPosition(0, 0)
    [Console]::Write($buf.ToString())
    Start-Sleep -Seconds 60
}
