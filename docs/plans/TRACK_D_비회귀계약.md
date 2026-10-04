# 트랙 D — 비회귀 검증 계약 (Non-Regression Contract)

> 목적: **전 화면 디자인·모션 개선을 "시각만 변경, 기능은 보존"으로 강제**한다.
> 기준: 이 저장소에서 직접 확인한 테스트 자산 (2026-09-28 실측).
> 정본 수치는 `DEVELOPMENT_ROADMAP.md#baseline`을 가리킨다 — 이 문서는 값을 복사하지 않는다.

---

## 0. 이 계약이 지키려는 한 문장

디자인/모션 PR은 **라우트·가드·저장·센서·AI·PDF·보호자·관리자의 관찰 가능한 동작을
바꾸지 않는다.** 바꾸는 것은 색·간격·타이포·모션 토큰·레이아웃뿐이다.
그 경계를 사람 눈이 아니라 **테스트 계층**이 지킨다.

---

## 1. 실측된 방어선 (있는 것)

직접 확인한 자산이다. (`flutter analyze` 0e/0w, `flutter test` 320/320 — 정본 §baseline)

| 계층 | 파일/개수 | 무엇을 잠그나 |
|---|---|---|
| **모션 토큰 단위** | `test/unit/core/app_motion_test.dart` | 4단 값(press 100·fade 150·enter 200·route 300), 스태거 60, 안무 상한 400, 스프링(380/1), 오프닝 ≤ celebrateMax, pressScale 0.98 |
| **모션 토큰 가드** | `test/unit/core/motion_token_guard_test.dart` | `lib/` 화면 코드에 `Duration(milliseconds:)` 직접 사용 **금지**(면제 3경로만). 숫자로 쓴 모션을 실패시킴 |
| **모션 설정** | `test/unit/core/settings_provider_motion_test.dart` | reduceMotion 기본 꺼짐·저장, soundEffects 기본 켜짐·SoundService 즉시 반영 |
| **모션 위젯** | `test/widget/core/{ml_motion_widgets,fade_slide_in,staggered_column,pressable_scale,motion_settings}_test.dart` | 진입 안무·눌림·스태거 위젯의 재생/감소 동작 |
| **오프닝(콜드스타트)** | `test/widget/core/memory_opening_test.dart` | full/fadeOnly/none 3모드, 덮는 동안 앱 Semantics·티커 차단, 긴 프레임에 장면 안 건너뜀, ready 대기, 탭 스킵 |
| **대비(색)** | `test/unit/core/theme_contrast_test.dart` | 팔레트 조합 대비비를 **WCAG 공식으로 직접 계산**(텍스트 4.5:1 / 비텍스트 3:1). 색 상수 회귀 시 실패 |
| **팔레트 가드** | `test/unit/core/palette_guard_test.dart` | AA 미달 Material 원색을 화면 색으로 재도입하는 것 차단 |
| **접근성 가이드라인** | `test/widget/accessibility_guideline_test.dart` | 게임 6종에 `labeledTapTargetGuideline` + `androidTapTargetGuideline`(48dp) |
| **셸 nav 가림** | `test/widget/core/floating_pill_nav_test.dart` | 네비가 본문 위로 팽창 안 함, 309dp 오버플로 없음, 탭 ≥48dp, 라벨로 선택 |
| **저장(SQLite)** | `test/unit/core/{database_helper,database_v9_migration}_test.dart` | 스키마·v9 마이그레이션·읽기/쓰기 |
| **AI/Firestore 폴백 seam** | `test/unit/core/firebase_service_test.dart` (`setAvailableForTest(false)`) | 비가용 상태 주입 가능 |
| **이상 감지 정책** | `test/unit/core/step_anomaly_policy_test.dart` | `StepAnomalyPolicy` 경계 단일화 |
| **리포트 데이터** | `test/unit/reports/clinical_report_data_test.dart` | 지수 스케일·밴드 경계·라벨, MMSE/GDS 문자열 부재 |
| **게임 로직/완료** | `test/unit/training/*`, `test/widget/training/*` | 카탈로그·난이도·진행규칙·완료·오버플로·Semantics 텍스트 |
| **E2E 게이팅** | `run_maestro_tests.ps1` `$flows` **21개** (정본) | 셸 안에서 화면들이 함께 놓였을 때의 실동작 |
| **통합(비게이팅)** | `integration_test/{auth_flow,training_flow}_test.dart` | 실기기 앱 부팅→로그인→홈 |

**핵심 교훈(로드맵 §3.3):** 위젯 테스트는 "화면 하나가 스스로 잘 그려지는가"만 지키고
**"셸 안에서 함께 놓였을 때"는 못 지킨다.** 그래서 Container alignment 팽창 사고를
`flutter test` 273개가 전부 통과하면서 놓쳤고 Maestro 14/20이 깨진 뒤에야 잡혔다.
→ **디자인 변경의 최종 방어선은 E2E(Maestro)다.**

---

## 2. 방어 안 되는 것 (구멍) — 새 테스트 필요

| 대상 | 왜 구멍인가 (실측) | 새 테스트 계층 |
|---|---|---|
| **44개 라우트 + 가드** | 라우터 리다이렉트(auth/onboarding/admin 포털)를 검증하는 테스트가 **0건**. 디자인 PR이 셸/진입점 위젯을 만지면 딥링크·가드가 조용히 깨질 수 있다 | **신규 위젯 테스트** — `createAppRouter`에 fake provider 주입해 44경로 build 스모크 + 가드 4분기(미로그인→/login, 온보딩 미완→/consent, 포털 off→홈, admin 미로그인→/admin_login) |
| **셸 통합(MainNavScreen)** | 5개 탭을 실제 셸에 올려 네비 가림·`contentBottomInset` 결합을 보는 위젯 테스트 없음(단독 `FloatingPillNav`만 있음) | **신규 위젯 테스트** — `MainNavScreen` pump, 각 탭 전환 시 하단 콘텐츠가 네비에 안 가리는지 |
| **PDF 바이트 생성** | `clinical_report_data_test`는 데이터만 검증. **실제 PDF 생성 경로를 태우는 테스트 0건**. 디자인 토큰이 PDF 위젯에 새면 렌더가 던질 수 있다 | **신규 단위/골든** — PDF 문서 build가 예외 없이 바이트 산출 + 면책 3문장·지표명 존재 |
| **보호자 안심 알림** | `syncAnomalyAlert`가 `Future<bool>` 반환·실패 시 문구 전환하도록 고쳤으나(§7) 이를 잠그는 테스트 없음 | **신규 단위** — Firestore 비가용 주입 시 false 반환 + "전송 실패" 문구 경로 |
| **AI 폴백 대화** | seam(`setAvailableForTest`)은 있으나 "키 없음/네트워크 없음 → LocalFallback 응답"을 잠그는 assert 없음 | **신규 단위** — `AiChatService`가 폴백 시 비어있지 않은 응답 |
| **센서/권한 중복 예외** | 통합 실행에서 `PedometerManager` 권한 중복 시 `PlatformException` 미처리가 드러남(§baseline) — 회귀 테스트 없음 | **신규 단위** — 권한 재요청 시 예외 삼키고 상태 유지 |
| **320dp / 200% 글자** | 309dp 케이스는 nav만 있음. **320dp × textScaler 2.0 오버플로**를 전 주요화면에서 보는 테스트 없음 | **신규 위젯(파라미터화)** — 주요 12화면 × {320dp, textScaler 2.0}에서 `takeException() == null` |
| **모션 감소(전역)** | 오프닝만 fadeOnly를 검증. `reduceMotion=true`일 때 **진입 안무·스태거가 실제로 즉시완료**되는지 화면 단위 검증 얕음 | **신규 위젯** — reduceMotion on 시 애니메이션 0프레임 완료 |
| **profile frame 성능** | 콜드스타트만 있음. profile 빌드 프레임/재빌드 회귀 지표 없음(로드맵 §8.2 "profile 재측정" 미완) | **신규 벤치** — `flutter run --profile` + 프레임 예산 수동 게이트(정본에 기록) |
| **auth_flow 통합 낡음** | `auth_flow_test` 0/3 실패 이력(BottomNavigationBar→FloatingPillNav 반영 후 단언 낡음) | **기존 갱신** — 게이팅에 포함하거나 CI 스모크로 승격 |

---

## 3. 관심사 → 테스트 계층 매핑

| 관심사 | 단위 | 위젯 | 셸 위젯(신규) | E2E(Maestro) | 통합 | 골든/벤치(신규) |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| 라우트/가드 | | | ● 신규 | ● navigation_flow | ● auth_flow | |
| SQLite 쓰기 | ● | | | ● persistence_flow | | |
| Firestore fallback | ● seam | | | | | |
| 센서/권한 | ● 신규 | | | | ● | |
| AI fallback | ● 신규 | | | ● ai_chat_flow | | |
| PDF | ● data | | | ● clinical_report_flow | | ● 신규(바이트) |
| 보호자 | ● 신규 | | | ● guardian_link_flow | | |
| 관리자 | | | ● 가드 | ● (cs_management) | | |
| 접근성(라벨/탭) | | ● | | ● training_accessibility | | |
| 대비(색) | ● | | | | | |
| 모션 감소 | ● | ● 얕음→보강 | | | | |
| 320dp/200% | | ● 부분→신규 | | | | |
| 하단 nav 가림 | | ● | ● 신규 | ● (14개 회귀 이력) | | |
| profile frame | | | | | | ● 신규 벤치 |

범례: ● 있음 / ● 신규 = 새로 만들 것.

---

## 4. 게이트 (PR 통과 조건)

**디자인/모션 PR은 아래를 모두 통과해야 머지된다.**

```bash
flutter analyze                       # 에러 0 · 경고 0 (info는 정본 기준선 이내)
flutter test                          # 320/320 유지 (감소 금지, 신규는 증가)
flutter test integration_test/        # auth_flow·training_flow 실기기
.\run_maestro_tests.ps1               # 게이팅 21개 (emulator-5680, -gpu angle_indirect)
```

게이트 규칙:
- **테스트 수는 줄 수 없다.** 삭제하려면 로드맵에 사유를 남긴다(§baseline 드리프트 이력 참조).
- **모션 값 변경은 `app_motion_test.dart` + DESIGN.md §4를 먼저 고친다.** 화면 코드에 숫자 금지(가드가 막음).
- **색 변경은 `theme_contrast_test.dart`를 통과해야 한다.** AA 미달 시 자동 실패.
- **셸/네비/진입점을 만졌다면 Maestro 21개 필수.** 위젯 테스트만으론 §3.3 사고를 못 잡는다.

---

## 5. 시각-전용 변경 화이트리스트 / 블랙리스트

**허용(시각):** 색 토큰, 간격/패딩, 타이포, 반경/그림자, 모션 토큰(테스트 동반), 아이콘 스왑,
레이아웃 재배치(가드 통과 시), 애니메이션 커브.

**금지(기능) — 별도 PR·별도 리뷰:** 라우트 경로/가드 조건, provider 로직, DB 스키마/쿼리,
Firestore 소유권·읽기쓰기, 센서 파이프라인, AI 프롬프트/폴백 분기, PDF 데이터 산출,
보호자 전송 조건, 관리자 인증, 텍스트 **의미**(라벨 문구는 접근성 테스트가 잠그므로 신중).

> 회색지대(둘 다 건드림): 위젯을 재배치하며 `Semantics` label·`onTap`·key를 바꾸면
> **기능이다.** label은 접근성/E2E 테스트가, key는 Maestro selector가 의존한다.

---

## 6. Feature Flag & Rollback 전략

### 6.1 플래그로 감싼다
- `AppConfig`에 `redesign2026` 플래그 추가(`bool.fromEnvironment('REDESIGN_2026')`).
- 신규 디자인은 테마/모션 진입점에서 분기 — **런타임 스위치 하나로 구/신 전환.**
- 이유: 셸 팽창 사고처럼 E2E에서만 드러나는 회귀가 나와도, 재빌드 없이 구 UI로 되돌린다.
- 접근성 토큰(대비·탭 크기)은 플래그와 **무관하게 항상 신규값** — 회귀 금지 대상이라 되돌릴 것이 아니다.

### 6.2 롤백 단위
- **커밋 단위 = 화면 1개 또는 토큰 1묶음.** 큰 PR 금지(셸 사고가 14개 flow를 한 번에 깼다).
- 각 커밋은 `flutter test` + 관련 Maestro flow 통과 후에만 쌓는다.
- 롤백 순서: (1) 플래그 off → (2) 문제 커밋 revert → (3) 재발 방지 테스트 추가 후 재진입.

### 6.3 단계적 도입
1. 토큰 계층(색·모션·간격)부터 — 단위 테스트가 촘촘.
2. 개별 화면 — 위젯 + 320dp/200% 신규 테스트.
3. 셸(MainNavScreen·네비) — 셸 위젯 신규 + Maestro 21 전량.
4. 오프닝/전환 모션 — `memory_opening_test` + reduceMotion 보강.

---

## 7. 실행 순서 (요약)

1. **신규 테스트 먼저 작성**(§2): 라우터 가드, 셸 통합, 320dp/200%, PDF 바이트, 보호자/AI 폴백, reduceMotion 전역. → 현재 동작을 골든으로 고정.
2. `AppConfig.redesign2026` 플래그 추가, 테마/모션 진입점 분기.
3. §6.3 순서로 화면당 소커밋, 매 커밋 §4 게이트 통과.
4. 정본(`DEVELOPMENT_ROADMAP.md#baseline`)에 테스트 수·Maestro 수·프레임 예산 갱신.

---

> 이 계약의 전제: **위젯 테스트는 통과해도 셸에서 깨질 수 있다(§3.3 실사고).**
> 그래서 디자인 변경의 최종 판정은 언제나 Maestro 게이팅 21개다.
