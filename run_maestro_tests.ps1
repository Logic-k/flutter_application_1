# MemoryLink Maestro Test Runner
# 사용법: .\run_maestro_tests.ps1
# 옵션:  .\run_maestro_tests.ps1 -Flow login_flow  (단일 flow 실행)

param(
    [string]$Flow = ""
)

$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "C:\maestro\maestro\bin;$env:PATH"

$projectRoot = $PSScriptRoot
Set-Location $projectRoot

# ── 에뮬레이터 연결 확인 ────────────────────────────────────────────
Write-Host ""
Write-Host "🔍 에뮬레이터 연결 확인 중..." -ForegroundColor Cyan
$devices = adb devices 2>&1 | Select-String "emulator"
if (-not $devices) {
    Write-Host "❌ 에뮬레이터가 연결되지 않았습니다. AVD를 먼저 실행하세요." -ForegroundColor Red
    exit 1
}
Write-Host "✅ $($devices.Line.Trim())" -ForegroundColor Green

# ── 실행할 flow 목록 ────────────────────────────────────────────────
$flows = @(
    "maestro/login_flow.yaml",
    "maestro/login_fail_flow.yaml",
    "maestro/register_flow.yaml",
    "maestro/navigation_flow.yaml",
    "maestro/training_hub_flow.yaml",
    "maestro/profile_flow.yaml",
    "maestro/cs_center_flow.yaml",
    "maestro/reports_flow.yaml",
    "maestro/voice_assessment_flow.yaml",
    "maestro/social_ranking_flow.yaml",
    "maestro/guardian_link_flow.yaml",
    "maestro/home_detail_flow.yaml",
    "maestro/ai_chat_flow.yaml",
    "maestro/memory_garden_flow.yaml",
    "maestro/walking_dashboard_flow.yaml",
    "maestro/precise_gait_analysis_flow.yaml",
    "maestro/training_game_flow.yaml",
    "maestro/edit_profile_flow.yaml",
    "maestro/clinical_report_flow.yaml"
)

if ($Flow -ne "") {
    $flows = @("maestro/${Flow}.yaml")
    Write-Host "🎯 단일 flow 실행: $Flow" -ForegroundColor Yellow
}

# ── 테스트 실행 ────────────────────────────────────────────────────
$passed = 0
$failed = 0
$results = @()

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  MemoryLink Maestro Tests  (총 $($flows.Count)개)" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$startTime = Get-Date

foreach ($flow in $flows) {
    $flowName = [System.IO.Path]::GetFileNameWithoutExtension($flow)
    Write-Host ""
    Write-Host "▶ $flowName" -ForegroundColor Cyan -NoNewline

    $output = maestro test $flow 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ PASS" -ForegroundColor Green
        $passed++
        $results += "  ✅ PASS  $flowName"
    } else {
        Write-Host "  ❌ FAIL" -ForegroundColor Red
        $failed++
        $results += "  ❌ FAIL  $flowName"
        # 실패 시 마지막 에러 출력
        $errorLines = $output | Where-Object { $_ -match "FAILED|Error|not found" } | Select-Object -Last 3
        foreach ($line in $errorLines) {
            Write-Host "     $line" -ForegroundColor DarkRed
        }
    }
}

$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)

# ── 결과 요약 ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
foreach ($r in $results) {
    if ($r -match "PASS") {
        Write-Host $r -ForegroundColor Green
    } else {
        Write-Host $r -ForegroundColor Red
    }
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$color = if ($failed -eq 0) { "Green" } else { "Yellow" }
Write-Host ""
Write-Host "  결과: PASS $passed / FAIL $failed / TOTAL $($flows.Count)  (${elapsed}s)" -ForegroundColor $color
Write-Host ""

if ($failed -gt 0) { exit 1 } else { exit 0 }
