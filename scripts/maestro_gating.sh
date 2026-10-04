#!/usr/bin/env bash
# Maestro 게이팅 실행 (CI용). 목록 정본은 maestro/gating_flows.txt — run_maestro_tests.ps1과 같은 목록이다.
# 에뮬레이터에 앱을 설치한 뒤 저장소 어디서든 실행한다: bash scripts/maestro_gating.sh
# 여러 줄 반복문을 워크플로에 두지 않는 이유: android-emulator-runner는 script를 줄마다 따로 실행한다.
set -u
cd "$(dirname "$0")/.."

passed=0
failed=0
results=""
while IFS= read -r line || [ -n "$line" ]; do
  flow="$(printf '%s' "$line" | tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  case "$flow" in '' | '#'*) continue ;; esac
  echo "::group::$flow"
  # maestro가 표준 입력을 읽어 목록 나머지를 삼키지 않게 막는다.
  if maestro test "$flow" < /dev/null; then
    passed=$((passed + 1))
    results="$results\nPASS: $flow"
  else
    failed=$((failed + 1))
    results="$results\nFAIL: $flow"
  fi
  echo "::endgroup::"
done < maestro/gating_flows.txt

echo ""
echo "=============================="
echo "결과: PASS $passed / FAIL $failed / TOTAL $((passed + failed))"
printf '%b\n' "$results"
[ "$failed" -eq 0 ] && [ "$passed" -gt 0 ]
