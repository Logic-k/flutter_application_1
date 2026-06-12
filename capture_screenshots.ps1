# MemoryLink 스크린샷 캡처 스크립트
# 사용법: .\capture_screenshots.ps1

$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "C:\maestro\maestro\bin;$env:PATH"

$projectRoot = $PSScriptRoot
Set-Location $projectRoot

# ── 에뮬레이터 확인 ──────────────────────────────────────────────
Write-Host ""
Write-Host "🔍 에뮬레이터 연결 확인 중..." -ForegroundColor Cyan
$devices = adb devices 2>&1 | Select-String "emulator"
if (-not $devices) {
    Write-Host "❌ 에뮬레이터가 연결되지 않았습니다. AVD를 먼저 실행하세요." -ForegroundColor Red
    exit 1
}
Write-Host "✅ $($devices.Line.Trim())" -ForegroundColor Green

# ── 출력 디렉토리 준비 ────────────────────────────────────────────
$outputDir = Join-Path $projectRoot "screenshots"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Write-Host ""
Write-Host "📁 저장 경로: $outputDir" -ForegroundColor Cyan

# ── 스크린샷 투어 Flow 실행 ───────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  MemoryLink 스크린샷 캡처 (14개 화면)" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "▶ screenshot_tour_flow 실행 중..." -ForegroundColor Cyan

$startTime = Get-Date
maestro test maestro/screenshot_tour_flow.yaml
$success = ($LASTEXITCODE -eq 0)
$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds)

# ── Maestro 결과 디렉토리에서 스크린샷 수집 ──────────────────────
$maestroTestsDir = Join-Path $env:USERPROFILE ".maestro\tests"

if (Test-Path $maestroTestsDir) {
    $latestRun = Get-ChildItem $maestroTestsDir |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestRun) {
        $pngs = Get-ChildItem $latestRun.FullName -Filter "*.png" -Recurse
        if ($pngs.Count -gt 0) {
            $count = 0
            foreach ($png in $pngs) {
                $dest = Join-Path $outputDir $png.Name
                Copy-Item $png.FullName $dest -Force
                $count++
            }
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host "  ✅ 스크린샷 $count 장 저장 완료  (${elapsed}s)" -ForegroundColor Green
            Write-Host "  📂 위치: $outputDir" -ForegroundColor Yellow
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  탐색기에서 열기: Start-Process '$outputDir'" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️  스크린샷 파일이 없습니다. flow 실행을 확인하세요." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "⚠️  Maestro 테스트 결과 디렉토리를 찾을 수 없습니다." -ForegroundColor Yellow
    Write-Host "    경로: $maestroTestsDir" -ForegroundColor DarkGray
}

if (-not $success) {
    Write-Host ""
    Write-Host "❌ Flow 실행 중 오류 발생 — 부분 스크린샷이 저장되었을 수 있습니다." -ForegroundColor Red
    exit 1
}
