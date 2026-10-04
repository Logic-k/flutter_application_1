# MemoryLink — 에이전트 작업 규칙

디자인 판단 기준은 `DESIGN.md`, 모션 계획은 `docs/plans/08_MOTION_SYSTEM_GLOBAL.md`, 실측 기준선은 `DEVELOPMENT_ROADMAP.md` §1이다.

## 모션 고정 규칙 (08 계획 §6-0)

1. `pubspec.yaml` 의존성 추가·변경 금지.
2. 화면 코드에서 `Duration(milliseconds:)` 직접 사용 금지. `lib/core/motion/app_motion.dart` 토큰만 쓴다. 새 값이 필요하면 코드가 아니라 `DESIGN.md` §4를 먼저 고치고 보고한다. (`test/unit/core/motion_token_guard_test.dart`가 막는다)
3. 모든 새 애니메이션은 `MotionSettings.levelOf(context)` 3단(full/fadeOnly/none)을 분기하고, 세 단계 위젯 테스트를 동반한다.
4. 자동 재생·반복 애니메이션 금지. 1회성 축하만 `AppMotion.celebrateMax`(2.5s) 안에서 허용.
5. `CustomTransitionPage`·`pageTransitionsTheme` 추가 금지(예측형 뒤로가기 취소 기능 상실). 뒤로가기 대상이 아닌 화면의 자체 전환만 허용.
6. Maestro yaml의 텍스트·key 셀렉터를 바꾸지 마라. 바꿔야 하면 먼저 보고.
7. 작업 시작 전 `git status`로 미커밋 파일을 확인하고, 이번 PR 관련 파일만 스테이징한다(다른 미추적 파일은 사용자 작업 상태).

## 저장소 관례

- `dart format`을 돌리지 않는다. 저장소의 압축 스타일이 깨진다.
- 색은 `lib/core/theme.dart` 토큰만(`palette_guard_test.dart`). 신호등 면 색(`good`·`warn`·`bad`·`read`)을 글자에 쓰지 않는다.
- 한글 커밋 메시지는 파일로 써서 `git commit -F`로 넣는다(PowerShell here-string이 깨진다).
