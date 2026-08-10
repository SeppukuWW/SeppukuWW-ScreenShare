#Requires -RunAsAdministrator
<#
.SYNOPSIS
  SeppukuWW Screenshare — SERVICE STATUS, boot/uptime, диски, BAM/Prefetch,
  PowerShell logging, event history.
  by SeppukuWW
#>

$ErrorActionPreference = 'Continue'

function Get-SsLogDir {
    $dir = Join-Path $env:USERPROFILE 'Desktop\SeppukuWW-SS-Logs'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}
function Start-SsReport([string]$Name) {
    $dir = Get-SsLogDir
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $script:SsReportName = $Name
    $script:SsReportPath = Join-Path $dir ("{0}_{1}.log" -f $Name, $stamp)
    try { Start-Transcript -Path $script:SsReportPath -Force | Out-Null } catch {}
    Write-Host ("[*] FULL SS LOG → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
}
function Stop-SsReport {
    try { Stop-Transcript | Out-Null } catch {}
    if ($script:SsReportPath -and (Test-Path -LiteralPath $script:SsReportPath)) {
        Write-Host ("[*] FULL SS LOG SAVED → {0}" -f $script:SsReportPath) -ForegroundColor Cyan
    }
}

$esc = [char]27
$script:BrandName = 'SeppukuWW'
$script:ToolName = 'SeppukuWW Screenshare'

function Enable-AnsiConsole {
    if ($script:AnsiReady) { return }
    try {
        if (-not ('Native.ConsoleVT' -as [type])) {
            Add-Type -ErrorAction Stop -Namespace Native -Name ConsoleVT -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
        }
        $h = [Native.ConsoleVT]::GetStdHandle(-11)
        $mode = [uint32]0
        if ([Native.ConsoleVT]::GetConsoleMode($h, [ref]$mode)) {
            [void][Native.ConsoleVT]::SetConsoleMode($h, ($mode -bor 0x0004))
        }
        $script:AnsiReady = $true
    }
    catch { $script:AnsiReady = $false }
}

function Write-Ansi([string]$Text) { [Console]::Write($Text) }

function Get-BloodPalette {  # SeppukuWW purple 3D theme
    if ($script:BloodPalette) { return $script:BloodPalette }
    $script:BloodPalette = @{
        ShadowFar  = "$esc[38;2;28;0;55m"
        ShadowNear = "$esc[38;2;70;15;120m"
        Mid        = "$esc[38;2;130;50;210m"
        Blood      = "$esc[38;2;160;70;240m"
        Hot        = "$esc[38;2;195;110;255m"
        Glow       = "$esc[38;2;220;160;255m"
        Drip       = "$esc[38;2;100;40;170m"
        Dim        = "$esc[38;2;90;85;110m"
        Soft       = "$esc[38;2;190;180;210m"
        Green      = "$esc[38;2;80;220;120m"
        Reset      = "$esc[0m"
        Bold       = "$esc[1m"
    }
    return $script:BloodPalette
}


function Write-BloodBanner {
    param([string]$Subtitle = 'ScreenShare Tool')
    Enable-AnsiConsole
    $c = Get-BloodPalette
    # SEPPUKUWW — 3D layers (shadow + mid + front), purple only
    $art = @(
        '███████╗███████╗██████╗ ██████╗ ██╗   ██╗██╗  ██╗██╗   ██╗██╗    ██╗██╗    ██╗',
        '██╔════╝██╔════╝██╔══██╗██╔══██╗██║   ██║██║ ██╔╝██║   ██║██║    ██║██║    ██║',
        '███████╗█████╗  ██████╔╝██████╔╝██║   ██║█████╔╝ ██║   ██║██║ █╗ ██║██║ █╗ ██║',
        '╚════██║██╔══╝  ██╔═══╝ ██╔═══╝ ██║   ██║██╔═██╗ ██║   ██║██║███╗██║██║███╗██║',
        '███████║███████╗██║     ██║     ╚██████╔╝██║  ██╗╚██████╔╝╚███╔███╔╝╚███╔███╔╝',
        '╚══════╝╚══════╝╚═╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝  ╚══╝╚══╝ '
    )
    Write-Host ''
    # depth layer 1 (far)
    foreach ($line in $art) { Write-Ansi ("    $($c.ShadowFar)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    # depth layer 2 (near)
    foreach ($line in $art) { Write-Ansi ("  $($c.ShadowNear)$line$($c.Reset)`n") }
    Write-Ansi ("$esc[$($art.Count)A")
    # front 3D face (bright purple gradient)
    $grad = @($c.Glow, $c.Hot, $c.Blood, $c.Blood, $c.Mid, $c.ShadowNear)
    for ($i = 0; $i -lt $art.Count; $i++) {
        Write-Ansi ("$($c.Bold)$($grad[$i])$($art[$i])$($c.Reset)`n")
    }
    Write-Ansi ("$($c.Drip)  $($('═' * 78))$($c.Reset)`n")
    $tag = "by SeppukuWW"
    Write-Ansi ("$($c.Bold)$($c.Hot)$tag$($c.Reset)  $($c.Glow)$Subtitle$($c.Reset)  $($c.Dim)v3-purple-3d$($c.Reset)`n")
    Write-Host ''
}



function Write-BloodFoot {
    param([string]$Subtitle = '')
    # brand once in banner — no footer spam
    Write-Host ''
}


function Write-Section([string]$Text) {
    Enable-AnsiConsole
    $c = Get-BloodPalette
    $line = '─' * [Math]::Max(8, (58 - $Text.Length))
    Write-Host ''
    Write-Ansi ("$($c.Dim)┌─$($c.Hot)▓$($c.Reset) $($c.Soft)$Text$($c.Reset) $($c.Dim)$line$($c.Reset)`n")
}

function Write-KV([string]$Key, [string]$Value, [ConsoleColor]$Color = 'White') {
    Write-Host ("  {0,-28}" -f $Key) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $Color
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = [Security.Principal.WindowsPrincipal]::new($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Get-FriendlyUptime([TimeSpan]$Span) {
    '{0}д {1:D2}ч {2:D2}м {3:D2}с' -f $Span.Days, $Span.Hours, $Span.Minutes, $Span.Seconds
}

function Get-TruncatedText([string]$Text, [int]$Max) {
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    if ($Text.Length -le $Max) { return $Text }
    if ($Max -le 3) { return $Text.Substring(0, $Max) }
    return $Text.Substring(0, $Max - 3) + '...'
}

function Get-RegDwordSafe([string]$Path, [string]$Name) {
    try {
        if (-not (Test-Path $Path)) { return $null }
        return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    }
    catch { return $null }
}

function Write-HealthBar([int]$Alive, [int]$Total) {
    $c = Get-BloodPalette
    if ($Total -le 0) { return }
    $width = 28
    $filled = [Math]::Round(($Alive / $Total) * $width)
    $bar = ('█' * $filled) + ('░' * ($width - $filled))
    $pct = [Math]::Round(($Alive / $Total) * 100)
    $color = if ($pct -ge 85) { $c.Green } elseif ($pct -ge 60) { "$esc[38;2;230;180;40m" } else { $c.Hot }
    Write-Ansi ("  $color$bar$($c.Reset)  $($c.Soft)$Alive/$Total ($pct%)$($c.Reset)`n")
}

function Write-ServiceStatusLine {
    param([string]$Name, [string]$Display, [bool]$Ok, [string]$Right)
    $c = Get-BloodPalette
    $namePad = '{0,-14}' -f $Name
    $midPad  = '{0,-44}' -f (Get-TruncatedText $Display 44)

    if ($Ok) {
        Write-Ansi (" $($c.Green)●$($c.Reset) $($c.Green)$namePad$($c.Reset) $($c.Dim)$midPad$($c.Reset) $($c.Dim)|$($c.Reset) $($c.Green)$Right$($c.Reset)`n")
    }
    else {
        Write-Ansi (" $($c.Hot)✖$($c.Reset) $($c.Hot)$namePad $midPad$($c.Reset) $($c.ShadowNear)|$($c.Reset) $($c.Bold)$($c.Hot)$Right$($c.Reset)`n")
    }
}

function Get-BamStatus {
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam'
    $display = 'Background Activity Moderator Driver'
    if (-not (Test-Path $path)) {
        return @{ Ok = $false; Text = 'ВЫЛЕЧЕНА'; Display = $display }
    }
    try {
        $start = [int](Get-ItemProperty $path).Start
        $ok = ($start -ne 4)
        return @{
            Ok = $ok
            Text = $(if ($ok) { 'Enabled' } else { 'ВЫЛЕЧЕНА' })
            Display = $display
        }
    }
    catch {
        return @{ Ok = $false; Text = 'ВЫЛЕЧЕНА'; Display = $display }
    }
}

function Get-PolicyFlag([string]$RelPath, [string]$Name) {
    foreach ($root in @(
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell',
        'HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell'
    )) {
        $val = Get-RegDwordSafe (Join-Path $root $RelPath) $Name
        if ($null -ne $val) { return [int]$val }
    }
    return $null
}

# ===== START =====
Start-SsReport 'Services'
Write-BloodBanner -Subtitle $script:ToolName

if (-not (Test-IsAdmin)) {
    Write-Section 'ERROR'
    Write-Host '  Нужны права администратора.' -ForegroundColor Magenta
    Write-BloodFoot
    return
}

Write-Host ("  {0}" -f ('═' * 64)) -ForegroundColor Magenta
Write-KV 'Компьютер' $env:COMPUTERNAME
Write-KV 'Пользователь' $env:USERNAME
Write-KV 'Сейчас' (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $caption = ($os.Caption -replace '\s+', ' ').Trim()
    Write-KV 'ОС' ("{0} (Build {1})" -f $caption, $os.BuildNumber)
}
catch {}
Write-Host ("  {0}" -f ('═' * 64)) -ForegroundColor Magenta

$WatchServices = [ordered]@{
    'SysMain'    = 'SysMain'
    'PcaSvc'     = 'Служба помощника по совместимости программ'
    'DPS'        = 'Служба политики диагностики'
    'EventLog'   = 'Журнал событий Windows'
    'Schedule'   = 'Планировщик задач'
    'Bam'        = 'Background Activity Moderator Driver'
    'DusmSvc'    = 'Использование данных'
    'AppInfo'    = 'Сведения о приложении'
    'CDPSvc'     = 'Служба платформы подключенных устройств'
    'DcomLaunch' = 'Модуль запуска процессов DCOM-сервера'
    'PlugPlay'   = 'Plug and Play'
    'WSearch'    = 'Windows Search'
    'DiagTrack'  = 'Функциональные возможности для подключенных пользователей и телеметрия'
    'Power'      = 'Питание'
}

# Один проход по службам + PID start times — быстрее, чем дергать каждую отдельно
$svcMap = @{}
Get-Service -ErrorAction SilentlyContinue | ForEach-Object {
    $svcMap[$_.Name.ToLowerInvariant()] = $_
}

$procStartCache = @{}
$svcPid = @{}
try {
    Get-CimInstance Win32_Service -Property Name, State, ProcessId -ErrorAction Stop | ForEach-Object {
        if ($_.State -eq 'Running' -and [int]$_.ProcessId -gt 0) {
            $procId = [int]$_.ProcessId
            $svcPid[$_.Name.ToLowerInvariant()] = $procId
            if (-not $procStartCache.ContainsKey($procId)) {
                $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($p -and $p.StartTime) { $procStartCache[$procId] = $p.StartTime }
            }
        }
    }
}
catch {}

function Resolve-ServiceCached([string]$Name) {
    $key = $Name.ToLowerInvariant()
    if ($svcMap.ContainsKey($key)) { return $svcMap[$key] }
    $hit = $svcMap.Keys | Where-Object { $_ -like "$key*" -or $_ -like "$key_*" } | Select-Object -First 1
    if ($hit) { return $svcMap[$hit] }
    return $null
}

Write-Section 'SERVICE STATUS'
Write-Host ("  {0,-14} {1,-44}   {2}" -f 'SERVICE', 'DISPLAY NAME', 'STATE') -ForegroundColor DarkGray
Write-Host ("  {0}" -f ('┄' * 68)) -ForegroundColor Magenta

$healed = 0
$alive  = 0
$healedNames = New-Object System.Collections.Generic.List[string]

foreach ($name in $WatchServices.Keys) {
    $fallbackDisplay = $WatchServices[$name]

    if ($name -eq 'Bam') {
        $bam = Get-BamStatus
        if ($bam.Ok) { $alive++ } else { $healed++; [void]$healedNames.Add('Bam') }
        Write-ServiceStatusLine -Name 'Bam' -Display $bam.Display -Ok $bam.Ok -Right $bam.Text
        continue
    }

    $svc = Resolve-ServiceCached $name
    if (-not $svc) {
        $healed++
        [void]$healedNames.Add($name)
        Write-ServiceStatusLine -Name $name -Display $fallbackDisplay -Ok $false -Right 'ВЫЛЕЧЕНА'
        continue
    }

    $display = if ($svc.DisplayName) { $svc.DisplayName } else { $fallbackDisplay }
    $running = ($svc.Status -eq 'Running')
    $disabled = ("$($svc.StartType)" -eq 'Disabled')

    if ($running) {
        $alive++
        $right = (Get-Date).ToString('HH:mm:ss')
        $pidKey = $svc.Name.ToLowerInvariant()
        if ($svcPid.ContainsKey($pidKey)) {
            $procId = $svcPid[$pidKey]
            if ($procStartCache.ContainsKey($procId)) {
                $right = $procStartCache[$procId].ToString('HH:mm:ss')
            }
        }
        Write-ServiceStatusLine -Name $svc.Name -Display $display -Ok $true -Right $right
    }
    else {
        $healed++
        [void]$healedNames.Add($svc.Name)
        $label = if ($disabled) { 'ВЫЛЕЧЕНА' } else { 'ВЫЛЕЧЕНА' }
        Write-ServiceStatusLine -Name $svc.Name -Display $display -Ok $false -Right $label
    }
}

$total = $WatchServices.Count
Write-Host ("  {0}" -f ('┄' * 68)) -ForegroundColor Magenta
$c = Get-BloodPalette
Write-Ansi ("  $($c.Green)● alive: $alive$($c.Reset)   $($c.Hot)✖ вылечено: $healed$($c.Reset)`n")
Write-HealthBar -Alive $alive -Total $total
if ($healedNames.Count -gt 0) {
    Write-KV 'Вылеченные' (($healedNames | Select-Object -First 8) -join ', ') Red
}

Write-Section 'BOOT / UPTIME'

$boot = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime }
catch {
    try { $boot = [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject Win32_OperatingSystem).LastBootUpTime) } catch {}
}

if ($boot) {
    Write-KV 'Последняя загрузка' ($boot.ToString('yyyy-MM-dd HH:mm:ss'))
    $up = (Get-Date) - $boot
    $upColor = if ($up.TotalHours -lt 1) { 'Yellow' } else { 'Cyan' }
    Write-KV 'Аптайм' (Get-FriendlyUptime $up) $upColor
    if ($up.TotalMinutes -lt 30) {
        Write-KV 'Замечание' 'Свежая перезагрузка (<30м)' Yellow
    }
} else {
    Write-KV 'Последняя загрузка' 'Недоступно' Yellow
}

$hb = Get-RegDwordSafe 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'
if ($null -ne $hb) {
    $hbText = if ($hb -eq 1) { 'ON (быстрый запуск)' } else { 'OFF' }
    Write-KV 'Hiberboot' $hbText $(if ($hb -eq 1) { 'Yellow' } else { 'Green' })
}

Write-Section 'DISKS'
try {
    Get-CimInstance Win32_LogicalDisk -ErrorAction Stop | Sort-Object DeviceID | ForEach-Object {
        $sizeGB = if ($_.Size) { '{0:N1} ГБ' -f ($_.Size / 1GB) } else { '—' }
        $freeGB = if ($_.FreeSpace) { '{0:N1} ГБ' -f ($_.FreeSpace / 1GB) } else { '—' }
        $label  = if ($_.VolumeName) { $_.VolumeName } else { '(без метки)' }
        $fs     = if ($_.FileSystem) { $_.FileSystem } else { '?' }
        $pctFree = if ($_.Size -and $_.FreeSpace) { [Math]::Round(($_.FreeSpace / $_.Size) * 100) } else { $null }
        $line = ("  {0}  {1,-18}  {2,-6}  {3,-10} free {4}" -f $_.DeviceID, $label, $fs, $sizeGB, $freeGB)
        if ($null -ne $pctFree -and $pctFree -lt 10) {
            Write-Host ("{0}  ({1}%!)" -f $line, $pctFree) -ForegroundColor Yellow
        } else {
            Write-Host $line
        }
    }
}
catch {
    Write-Host '  Диски недоступны' -ForegroundColor Yellow
}

Write-Section 'BAM / PREFETCH'

$bamSvcPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam'
$bamUserPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings'
$bamUserPathAlt = 'HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings'
$startMap = @{ 0 = 'Boot'; 1 = 'System'; 2 = 'Automatic'; 3 = 'Manual'; 4 = 'Disabled' }

if (Test-Path $bamSvcPath) {
    try {
        $bp = Get-ItemProperty $bamSvcPath
        $st = if ($null -ne $bp.Start -and $startMap.ContainsKey([int]$bp.Start)) { $startMap[[int]$bp.Start] } else { "$($bp.Start)" }
        Write-KV 'bam Start' $st $(if ("$st" -eq 'Disabled') { 'Red' } else { 'Green' })
    }
    catch { Write-KV 'bam' 'не прочитан' Yellow }
} else {
    Write-KV 'bam' 'ключ отсутствует' Red
}

$userRoot = $null
if (Test-Path $bamUserPath) { $userRoot = $bamUserPath }
elseif (Test-Path $bamUserPathAlt) { $userRoot = $bamUserPathAlt }

if ($userRoot) {
    $sids = @(Get-ChildItem $userRoot -ErrorAction SilentlyContinue)
    $entryCount = 0
    foreach ($sidKey in $sids) {
        $props = Get-ItemProperty $sidKey.PSPath -ErrorAction SilentlyContinue
        if ($props) {
            $entryCount += @($props.PSObject.Properties | Where-Object {
                $_.Name -notmatch '^PS' -and $_.Name -ne '(default)'
            }).Count
        }
    }
    Write-KV 'UserSettings' ("{0} SID, {1} записей" -f $sids.Count, $entryCount) $(if ($entryCount -eq 0) { 'Yellow' } else { 'Green' })
} else {
    Write-KV 'UserSettings' 'нет / очищен' Red
}

foreach ($pair in @(
    @{ Name = 'EnablePrefetcher'; Label = 'Prefetcher' },
    @{ Name = 'EnableSuperfetch'; Label = 'Superfetch' }
)) {
    $val = Get-RegDwordSafe 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' $pair.Name
    if ($null -eq $val) {
        Write-KV $pair.Label 'не задано' Yellow
    } else {
        Write-KV $pair.Label ("{0} = {1}" -f $pair.Name, $val) $(if ($val -eq 0) { 'Red' } else { 'Green' })
    }
}

$pf = Join-Path $env:SystemRoot 'Prefetch'
if (Test-Path $pf) {
    $pfItem = Get-Item $pf -Force
    $pfFiles = @(Get-ChildItem $pf -Filter *.pf -ErrorAction SilentlyContinue)
    $ro = [bool]($pfItem.Attributes -band [IO.FileAttributes]::ReadOnly)
    Write-KV 'Prefetch folder' ("{0} .pf | ReadOnly={1}" -f $pfFiles.Count, $ro) $(if ($ro -or $pfFiles.Count -eq 0) { 'Red' } else { 'Green' })
    if ($pfFiles.Count -gt 0) {
        $newest = ($pfFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        $oldest = ($pfFiles | Sort-Object LastWriteTime | Select-Object -First 1)
        Write-KV 'Newest .pf' ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f $newest.LastWriteTime, $newest.Name)
        Write-KV 'Oldest .pf' ("{0:yyyy-MM-dd HH:mm:ss}" -f $oldest.LastWriteTime)
    }
} else {
    Write-KV 'Prefetch folder' 'ОТСУТСТВУЕТ' Red
}

Write-Section 'POWERSHELL LOGGING STATUS'

$sb = Get-PolicyFlag 'ScriptBlockLogging' 'EnableScriptBlockLogging'
$mod = Get-PolicyFlag 'ModuleLogging' 'EnableModuleLogging'
$tr = Get-PolicyFlag 'Transcription' 'EnableTranscripting'

function Format-PsLogState($Val) {
    if ($null -eq $Val) { return @{ Text = 'Not configured'; Color = 'DarkGray' } }
    if ([int]$Val -eq 1) { return @{ Text = 'Enabled'; Color = 'Green' } }
    return @{ Text = 'Disabled'; Color = 'Red' }
}

$sbS = Format-PsLogState $sb
$modS = Format-PsLogState $mod
$trS = Format-PsLogState $tr
Write-KV 'ScriptBlockLogging' $sbS.Text $sbS.Color
Write-KV 'ModuleLogging' $modS.Text $modS.Color
Write-KV 'Transcription' $trS.Text $trS.Color

$execPol = Get-ExecutionPolicy -List | Where-Object { $_.Scope -in 'LocalMachine','CurrentUser','Process' }
foreach ($ep in $execPol) {
    Write-KV ("ExecutionPolicy/{0}" -f $ep.Scope) "$($ep.ExecutionPolicy)" DarkGray
}

Write-Section 'EVENT HISTORY'

function Get-WinEventsSafe {
    param([string]$LogName, [string]$FilterXPath, [int]$MaxEvents = 15)
    try { Get-WinEvent -LogName $LogName -FilterXPath $FilterXPath -MaxEvents $MaxEvents -ErrorAction Stop }
    catch { @() }
}

Write-Host '  Очистки (Security 1102 / System 104):' -ForegroundColor DarkGray
$clears = @()
$clears += Get-WinEventsSafe -LogName 'Security' -FilterXPath '*[System[(EventID=1102)]]' -MaxEvents 8
$clears += Get-WinEventsSafe -LogName 'System'   -FilterXPath '*[System[(EventID=104)]]'  -MaxEvents 8

if ($clears.Count -eq 0) {
    Write-Host '    (не найдено)' -ForegroundColor DarkGray
} else {
    $clears | Sort-Object TimeCreated -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host ("    {0:yyyy-MM-dd HH:mm:ss}  {1}  ID={2}" -f $_.TimeCreated, $_.LogName, $_.Id) -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '  Выключения / BSOD (41, 6008, 1074, 6006, 6005):' -ForegroundColor DarkGray
$shutdownFilter = '*[System[(EventID=41 or EventID=6008 or EventID=1074 or EventID=6006 or EventID=6005)]]'
$shutdowns = Get-WinEventsSafe -LogName 'System' -FilterXPath $shutdownFilter -MaxEvents 12
if ($shutdowns.Count -eq 0) {
    Write-Host '    (не найдено)' -ForegroundColor DarkGray
} else {
    foreach ($e in $shutdowns) {
        $color = if ($e.Id -in 41, 6008) { 'Red' } else { 'Gray' }
        $msg = ($e.Message -split "`n")[0]
        if ($msg.Length -gt 80) { $msg = $msg.Substring(0, 80) + '...' }
        Write-Host ("    {0:yyyy-MM-dd HH:mm:ss}  ID={1,-5}  {2}" -f $e.TimeCreated, $e.Id, $msg) -ForegroundColor $color
    }
}

Write-Host ''
Write-Host '  Смена времени (System 1 / Security 4616):' -ForegroundColor DarkGray
$timeEv = @()
$timeEv += Get-WinEventsSafe -LogName 'System'   -FilterXPath '*[System[(EventID=1)] and System[Provider[@Name="Microsoft-Windows-Kernel-General"]]]' -MaxEvents 8
$timeEv += Get-WinEventsSafe -LogName 'Security' -FilterXPath '*[System[(EventID=4616)]]' -MaxEvents 8

if ($timeEv.Count -eq 0) {
    Write-Host '    (не найдено)' -ForegroundColor DarkGray
} else {
    $timeEv | Sort-Object TimeCreated -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host ("    {0:yyyy-MM-dd HH:mm:ss}  {1}  ID={2}" -f $_.TimeCreated, $_.LogName, $_.Id) -ForegroundColor Magenta
    }
}

Write-Section 'VERDICT'
if ($healed -eq 0) {
    Write-Host '  Система чистая по службам — вылеченных нет.' -ForegroundColor Green
} elseif ($healed -le 3) {
    Write-Host ("  Подозрительно: вылечено {0} служб(и). Запусти Service-Enabler.ps1." -f $healed) -ForegroundColor Yellow
} else {
    Write-Host ("  СИЛЬНО ЧИСТИЛИ: вылечено {0} служб. Смотри BAM/Prefetch/ивенты." -f $healed) -ForegroundColor Magenta
}

Stop-SsReport
Write-BloodFoot -Subtitle $script:ToolName
