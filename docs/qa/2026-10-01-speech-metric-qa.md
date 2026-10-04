# AI 대화 측정 불가 처리 QA

기준일: 2026-10-01. 기준 HEAD: `27ca9d338351dfce2a3836ed03680b64309124d1`에 기존 사용자 변경과 이번 변경이 있는 로컬 작업 트리. 커밋·PR·배포는 하지 않았다.

## 변경 결과

사용자가 선택한 [측정 계약](2026-10-01-speech-metric-contract.md)을 적용했다. 실제 발화 시간이 없는 현재 STT와 타이핑 입력은 WPM·휴지 비율·종합 점수를 측정 불가로 표시한다. 대화·공백 토큰 수·텍스트 TTR은 유지한다. 점수 저장 버튼과 저장 함수가 결측 점수의 저장을 차단한다.

ChatMessage에 입력 출처와 선택적 실제 발화 시간을 추가했다. ChatSpeechMetrics가 AI 응답·대기 시간을 제외하고 사용자 텍스트와 유효한 음성 시간을 집계한다. 현재 STT에서는 해당 시간을 채우지 않는다. 사용자가 STT 원문을 수정하면 수정 음성으로 표시하고, 뒤늦은 STT 결과가 다음 입력을 덮어쓰지 않도록 한다. AI 응답 대기 중에는 종료·전송·편집·마이크 동작을 막는다.

LocalAIService는 빈 입력·시간 결측·비정상 수치를 null 점수와 `is_available=false`로 반환한다. 유효 입력의 기존 점수 산식과 임계값은 유지했다. 음성 진단 중지 화면과 DB 스키마는 변경하지 않았다.

## 자동 검증

| 검증 | 결과 | 증빙 파일 |
|---|---|---|
| 수정 전 유효 산식 기준선 | 23 통과 | valid-baseline.log |
| 수정 전 결측 재현 | 6 실패, 예상한 결함 확인 | invalid-before.log / .exit=1 |
| 변경 후 단위 테스트 | 50 통과 | unit.log / .exit=0 |
| 변경 후 화면 테스트 | 6 통과 | widget.log, 종료 코드 0 |
| 전체 회귀 테스트 | 510 통과 / 기존 2 skip | full-test.log / .exit=0 |
| 정적 분석 | 오류 0 / 경고 0 / 기존 info 4 | analyze.log / .exit=0 |
| Android debug APK | 빌드 성공, 에뮬레이터 설치 성공 | build.log, install.log / 각 .exit=0 |

로그와 스냅샷: `.omo/evidence/october-research-qa/2026-10-01-metric-contract/`.

새 테스트 4개 파일, 테스트 사례 56개다. 공백 입력, WPM/TTR/시간의 결측·0·음수·NaN·무한대, 공백 토큰화·구두점, 60토큰/30초=120 WPM, TTR .5, AI 대기 시간 제외, 타이핑·혼합·수정 음성 제외를 검증했다. 화면에서는 저장 호출 0회, 빈 대화 종료 거부, 응답 대기 중 중복 조작, 늦은 STT 결과 차단, 320×720 결과 화면의 오버플로 부재를 확인했다. STT 이벤트는 플랫폼 채널의 합성 이벤트다.

기존 skip은 `main_nav_shell_test.dart`의 309dp 오버플로와 `router_contract_test.dart`의 미온보딩 관리자 라우트 사례다. 이번에 해결하거나 테스트를 제거하지 않았다. 기존 info 4개는 ml_widgets.dart 두 곳, theme.dart, shape_match_game.dart에 있다.

LCOV 포함 파일 기준: LocalAIService 61/64줄, ChatSpeechMetrics 14/14줄, AI 채팅 화면 205/281줄. API 키 설정 등 이번 범위 밖 화면 경로는 미포함이다. 줄 커버리지는 임상 타당성·모든 분기의 정확성·실기기 동작을 입증하지 않는다.

## Android 확인

`flutter build apk --debug --dart-define=IS_EMULATOR=true` 성공(Gradle 142.9초) 후 emulator-5680에 `adb install -r`로 설치했다. 앱 데이터는 초기화하지 않았다.

Maestro로 홈 → AI 대화 → `Hello hello today` 입력 → 전송 → 2턴 확인 → 종료를 실행했다. TTR 66.7%, WPM·휴지 비율·종합 점수 측정 불가, 저장 버튼 disabled를 단언했다. 비활성 버튼을 눌러도 결과 화면을 유지함을 확인했다. chat-entry와 chat-result 두 흐름 모두 종료 코드 0이다. 기존 Maestro 파일과 셀렉터는 수정하지 않았다.

[결과 화면](../../.omo/evidence/october-research-qa/2026-10-01-metric-contract/chat-result.png), [입력 화면](../../.omo/evidence/october-research-qa/2026-10-01-metric-contract/chat-input.png), `maestro-entry.log`, `maestro-result.log` 및 각 debug 디렉터리에 실제 명령 결과가 있다. 스크린샷에서 카드·안내·버튼이 잘리지 않는 것을 직접 확인했다.

첫 부팅의 Android System UI 응답 지연 대화상자는 Wait로 처리한 후, 에뮬레이터 화면을 1440×3120/560dpi에서 720×1560/280dpi로 낮춰 검증했다. 이 환경 문제를 앱 결함으로 판정하지 않았다. 종료 시 화면 설정을 원복한다. 실제 마이크·STT 인식 품질·권한 거부·실제 발화 시간 수집과 전체 Maestro/인증·훈련 통합 흐름은 이번 표적 QA에서 실행하지 않았다.

## 보존 및 인계

이전 기준선의 196개 파일 해시를 다시 비교하여 이번 대상인 local_ai_service.dart, ai_chat_screen.dart, chat_message.dart 세 파일만 변경된 것을 확인했다. 기존 디자인·라우터·의존성 변경은 보존했다. 신규 집계 모델·테스트·문서·증빙은 별도로 추가했다. `dart format`과 일괄 스테이징은 실행하지 않았다.

실제 발화 시간 수집, 휴지 검출, 실제 테스터 데이터·독립 라벨 확보, 문헌에 근거한 임계값 타당성 검토, 원격 CI 및 PR 생성은 미완료다. 현재 변경은 잘못된 시간값으로 점수를 만드는 경로를 차단한 것이며 임상 정상/위험군 판별을 검증한 결과가 아니다.

다음 작업은 현재 공백 토큰 TTR 및 음성 시간 정의를 기준으로 문헌 대조표를 작성하고, FINGER·SUPERBRAIN 개입 근거와 음성 지표 판별 근거를 구분하는 것이다. 기존 수치를 지지할 동일 조건의 근거가 없으면 근거 공백으로 기록한다.
