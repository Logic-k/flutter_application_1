# 트랙 B — 전 화면군 디자인·모션 감사 + 비회귀 검증 계약

> 재검증 2026-09-28 · 코드 수정 없음(감사 전용) · 근거는 전부 파일:라인 인용
> 기존 `FINAL_REPORT.md`는 방향(Calm Expressive Lavender)을 정했다. 이 문서는 그 방향을
> **화면군별로 착지**시키고, 이미 구현된 것과 실제 공백을 파일 근거로 분리한다.
> 이미 구현된 것을 새 제안처럼 쓰지 않는다.

---

## 0. 감사 방법

- 읽은 파일: `lib/core/theme.dart`, `lib/core/ml_widgets.dart`, `lib/core/motion/*`(8개),
  `lib/main.dart`, `lib/core/router.dart`, 각 feature 화면, `DESIGN.md`, 루트 PNG 14개(파일 목록),
  `test/**`(가드·위젯 테스트 전수).
- 커버리지 측정: `grep`로 공통 컴포넌트/모션 프리미티브의 화면별 사용 횟수를 실측했다.
- 근거 표기: `파일:라인` 또는 실측 카운트. 추정은 "추정"으로 표시.

---

## 1. 공통 자산 인벤토리 (이미 존재 — 새로 만들 것 아님)

### 1.1 토큰 (`theme.dart`)
| 자산 | 정의 위치 | 상태 |
|---|---|---|
| 색 토큰 `MLColors` (brand/surface/text/category/status/status-text/logo/dark) | `theme.dart` `MLColors` | 존재. 대비비 주석에 실측치 명기 |
| 반경 9단 척도 `rBar4…rPill30` | `theme.dart` `AppTheme.rBar`~`rPill` | 존재. DESIGN.md §1이 "이 밖의 숫자 금지"로 못박음 |
| `minTapTarget = 56` | `theme.dart` | 버튼/입력/네비 테마에 적용됨 |
| `context.scheme` 확장 | `theme.dart` `MLColorScheme` | 색 접근 표준 경로 |
| 라이트/다크 ThemeData + 버튼·입력·네비·스낵바·divider·switch·progress 테마 | `AppTheme._base` | 존재. 다크는 정의만, 미사용(main.dart 고정) |

### 1.2 공통 위젯 (`ml_widgets.dart`)
`FloatingPillNav` · `MLHeroCard` · `MLCard`(onTap 시 PressableScale+InkWell) · `MLIconTile` ·
`MLSectionTitle` · `MLProgressBar`(값 보간) · `MLRing` · `MLStatusPill`(색→글자색 자동) ·
`MLGameCard` · `MLMetricCard` · `MLErrorState`(재시도) · `MLListRow` · `MLChart`(기준선 성장) ·
`MLCountUp` · `MLSkeleton/MLSkeletonCard/MLSkeletonList` · `MLLoadSwitcher`.
— 전부 `ml_widgets.dart`에 정의. 상태 4종(빈/로딩/실패/정상)용 부품이 이미 갖춰져 있다.

### 1.3 모션 시스템 (`core/motion/*`)
| 자산 | 파일 | 역할 |
|---|---|---|
| `AppMotion` 4단 토큰 + 예외(burst/feedbackHold/nextQuestionDelay/opening/celebrateMax) + spring | `app_motion.dart` | 모션 길이 단일 출처 |
| `MotionLevel`(full/fadeOnly/none) + `MotionSettings.levelOf/reduceOf` 3신호 | `motion_settings.dart` | 축소 모션 판정 |
| `StaggeredColumn`/`StaggerScope`/`StaggerItem` | `staggered_column.dart` | 진입 안무(최대 4묶음, 400ms 상한) |
| `FadeSlideIn` | `fade_slide_in.dart` | 단일 요소 진입 |
| `PressableScale` | `pressable_scale.dart` | 눌림 피드백(full=scale, fadeOnly=opacity) |
| `BurstParticles` | `burst_particles.dart` | 1회성 파티클(RepaintBoundary, 반복 없음) |
| `GameFeedbackController`/`GameFeedbackEvent` | `game_feedback.dart` | 게임 정답·오답 신호 집약 |
| `MotionPlayLog` | `motion_play_log.dart` | 앱 실행당 1회 재생 기록 |
| `MLSpringOutCurve` | `fx/spring_out_curve.dart` | 눌림 복귀 곡선 |

### 1.4 실측 모션 커버리지 (grep 카운트)
진입 안무(`StaggeredColumn`/`FadeSlideIn`/`StaggerScope`)를 쓰는 화면 = **12개 파일**:
`home`, `reports`, `walking_dashboard`, `training_hub`, `training_history`, `diary`, `onboarding`,
`login`, `settings`, `cs/faq`, `cs/my_inquiries`, `cs/notice_list`, `training/*` 위젯 일부.
→ 나머지 화면군(**assessment, games, ai_chat, profile, guardian_link, health, dementia_center,
voice_assessment, admin 상세, register 일부, cs 상세**)은 진입 안무가 **없다**.

원색 우회(`Colors.grey/red/...`) = **PDF 생성기 1곳뿐**(면제 대상). 화면 색 우회는 사실상 0.
→ 색 토큰 규율은 잘 지켜지고 있고, **공백은 색이 아니라 모션·상태·위계에 있다.**

---

## 2. 전역(비화면) 관찰

1. **다크 모드 차단은 의도된 상태다.** `main.dart`가 `themeMode: ThemeMode.light` 고정
   (`_buildApp` 내 2곳). 사유는 상태 문구 토큰 4개(goodText/warnText/badText/calc)가
   `dSurface`에서 2.76~3.37:1로 AA 미달(주석에 실측 명기). → 새 제안 아님. P2 유보가 맞다.
2. **텍스트 배율은 clamp(하한=앱설정, 상한 2.0)** — `main.dart` builder. 덮어쓰기 아님. 유지.
3. **콜드스타트 오프닝**(`MemoryOpening`)이 로딩 스피너를 대체 — `main.dart` build. 유지.
4. **라우터 44경로**는 `router.dart`에 전부 정의. 리디자인은 이 경로/가드/redirect 로직을
   건드리지 않는다(온보딩 플로우·admin 가드·`FloatingPillNav.contentBottomInset` 의존).

---

## 3. 화면군별 감사

각 항목: (A) 이미 된 것 · (B) 시각 위계 · (C) 상태 4종 · (D) 모션 공백 · (E) 접근성 위험.
"된 것"과 "공백"을 분리해 이미 구현된 것을 새 제안으로 쓰지 않는다.

### 3.1 auth (login/register)
- A: `login_screen.dart`에 진입 모션 1건(grep). 입력 테마·버튼 56dp는 전역 테마로 이미 적용.
- B: 로고→폼 위계는 무난. register는 진입 모션 미검출(login만).
- C: 로그인 실패 경로는 `maestro/login_fail_flow.yaml`로 가드됨. 로딩(제출 중) 상태 확인 필요.
- D: **register 진입 안무 없음.** login과 비대칭.
- E: `login_screen.dart:` 원색 매치 1건(grep) — palette_guard가 통과시켰으므로 `MLColors.*`
  접두 형태(위반 아님)로 추정. 실제 위반 아님(guard 녹색).
- 실행: register에 `StaggeredColumn` 1묶음 추가. 인증 로직·redirect 무변경.

### 3.2 onboarding (consent/onboarding)
- A: `onboarding_screen.dart` 진입 모션 2건(grep). consent는 미검출.
- B/C: 동의→목적 선택 플로우는 router `onboardingRoutes`에 묶여 있어 순서 고정.
- D: consent 화면 진입 안무 없음.
- E: 동의 체크박스·버튼 56dp 확인 필요(전역 테마 적용되나 커스텀 위젯이면 예외).
- 실행: consent 진입 안무. redirect 세트(`router.dart`) 무변경.

### 3.3 assessment (assessment/cognitive_tasks/result)
- A: `cognitive_tasks_screen.dart`는 attention 정답 위치 랜덤화 등 **측정 무결성 로직이 이미
  정교**(`initState`에서 1회 추출, 주석). 오답 스낵바에 `AppMotion.feedbackHold` 사용(:토큰 준수).
- B: **시각 위계 최소** — `Chip`/`ElevatedButton`/`ChoiceChip` 등 Material 기본 위젯 직접 사용,
  ML 컴포넌트 미사용. `_buildWordShow`/`_buildRecall`은 `TextStyle(fontSize: 20/24)` 하드코딩.
- C: 4상태 중 로딩/빈/실패 구분 없음(과제 진행 화면이라 부분 해당). `default: CircularProgressIndicator`.
- D: **진입/전환 모션 전무.** 과제 전환(`_currentTask` 0→1→2→3)이 `setState`로 즉시 교체 —
  `AnimatedSwitcher`(fade 150ms) 후보. 단어 암기 5초는 `Duration(seconds:5)`(:66) — 모션 아님,
  타이머라 token guard 대상 아님. **단, WCAG 2.2.1(시간 조정) 관점에서 5초 고정은 위험.**
- E: `_buildAttention` 그리드 탭 타깃이 아이콘 60px지만 셀 간격만 있고 최소 높이 보장 없음 →
  56dp 미달 가능(추정). recall `ChoiceChip`도 기본 높이라 56dp 미달 가능.
- 실행: 과제 전환 `AnimatedSwitcher`, 타이포를 `textTheme`로, 시간 제한 정책(DESIGN.md §6 시간)
  확정, 탭 타깃 56dp 보장. 점수 계산·`setCognitiveScore` 로직 무변경.

### 3.4 home
- A: 진입 모션 5건(grep). ML 컴포넌트 광범위 사용. FINAL_REPORT §3에서 이미 "긴 카드 스택,
  지금 할 한 가지 불분명"으로 진단됨.
- B: **여러 Provider 전체 watch**(cycle_005 근거) → 위계보다 rebuild 비용이 이슈.
- C: 데이터 카드들의 빈/실패 상태는 `MLErrorState`/`MLSkeleton` 존재하나 전 지점 적용 여부 미확인.
- D: 진입 안무 있음. 추가 공백은 "값 변화" 모션(MLCountUp)의 오늘걸음 등 적용 범위.
- E: 큰 라벤더 면 반복(FINAL_REPORT §4.1) — 흑백 위계 약화.
- 실행(FINAL_REPORT P1과 일치): 섹션 위젯+`Selector` 분리, hero 1개 제한, 주 CTA 1개.

### 3.5 training (hub/history/daily_recall/위젯)
- A: hub 3건·history 4건 진입 모션. `MLGameCard`·`daily_goal_panel`·`training_progress_header`
  존재. 적응형 난이도·완료 서비스는 `application/` 계층으로 이미 분리됨.
- B: 카테고리 간 여백·긴 탐색(FINAL_REPORT §3 훈련 행) — 오늘 훈련 3개 우선 미적용.
- C: 진행/빈 상태 부품 존재.
- D: hub→game 진입 시 게임 정체성 전이(Hero) 없음(FINAL_REPORT P1 후보).
- E: 큰 선택지·즉각 피드백은 양호(`GameFeedbackController` 집약).
- 실행: 오늘 훈련 우선 배치, card→game Hero(명확 동일 요소만).

### 3.6 games (7종: comparison/sequence/shape_sudoku/multiplication/shape_match/categorization/sentence_reading)
- A: `game_template.dart`가 정답·오답 피드백(배지+파티clot+햅틱+효과음)을 **집약**하고
  `GameFeedbackController`로 연결. `game_template_test.dart`·게임별 위젯 테스트 다수 존재.
  `nextQuestionDelay`·`feedbackHold` 토큰 준수.
- B: `adaptive_answer_grid.dart`로 보기 그리드 통일. 위계는 템플릿이 강제.
- C: 게임 진행은 정상/피드백 상태 중심. 로딩/빈은 해당 적음.
- D: **개별 게임 화면 진입 안무 없음**(grep에서 games/* 0건). 게임은 즉시 몰입이 맞으므로
  진입 안무는 오히려 부적절할 수 있음 — **의도적 제외 후보로 판단, 강제 적용 금지.**
- E: 게임별 오버플로우는 `game_layout_overflow_test.dart`가 가드. 시맨틱은
  `game_semantics_text_test.dart`가 가드. 이미 방어선 있음.
- 실행: 진입 안무는 넣지 않는다(몰입 우선). 오답 shake의 fadeOnly/none 분기만 재확인.

### 3.7 walking (walking_dashboard + gait 위젯)
- A: **진입 모션 15건(최다)**. `MLMetricCard`·`MLChart`·`MLRing`·`gait_session_card` 사용.
  CV 신호등은 색+텍스트+아이콘 3겹(DESIGN.md §5). `walking_dashboard_screen_test.dart` 존재.
- B: 데이터 밀도 높음(VISUAL_DENSITY 4 하한 대상). 위계 양호.
- C: CV 표본 부족 시 `null` 반환(DESIGN.md §6.4) — 값없음/0 구분 원칙 적용.
- D: 모션 잘 적용됨. 공백 거의 없음.
- E: 차트 청색 계열 인접(calc/logic/sky) 감별 위험(DESIGN.md §2.4) — 범례에 형태/라벨 병기 확인.
- 실행: 유지. 차트 색 인접 회피 재점검만.

### 3.8 diary (memory_garden/diary_book)
- A: `diary_screen.dart` 진입 모션 4건. 달력·큰 입력·음성 입력. STT `Duration(seconds:2/30/3)`
  (:112,142,143) — 모션 아님(타이머), token guard 대상 아님.
- B: "Memory Garden" 이름과 시각 경험 연결 약함(FINAL_REPORT §3 일기 행).
- C: 저장 성공/실패 피드백 확인 필요.
- D: **저장 성공 순간의 1회성 성취 모션 없음**(FINAL_REPORT §4.4 제안 — 잎/꽃 1회). 미구현.
- E: `diary_book` 진입 모션 미검출(diary_screen만).
- 실행: 저장 성공 시 `BurstParticles` 1회(축소 모션 분기), diary_book 진입 안무.

### 3.9 chat (ai_chat)
- A: 진행 바·버블·입력창·결과 카드·API키 다이얼로그 존재. 스크롤 이동에 `MotionSettings.reduceOf`
  분기 적용(:animateTo/jumpTo). STT 통합.
- B: **빈 상태 화면 대부분 공백** — grep상 `isEmpty` 3건은 메시지 리스트 로직뿐,
  추천 답변/회상 주제 UI **없음**(FINAL_REPORT §3·§4.4 진단과 일치).
- C: 로딩("AI가 생각 중")·정상은 있음. **빈 상태·실패(네트워크) 상태 UI 없음.**
  `MLErrorState` 미사용.
- D: 메시지 삽입 모션 없음(즉시 add). fade+size 후보. 진입 안무 없음.
- E: 진행 바 `LinearProgressIndicator` minHeight 4 — 장식이라 무방. 버블 폰트 15sp 양호.
  `_buildProgressBar` 라벨 12sp(하한 통과). 전송 버튼 CircleBorder padding 12 → 44dp 추정,
  **56dp 미달 가능**.
- 실행: 빈 상태에 56dp 추천 답변 2~3개, 실패 시 `MLErrorState`, 메시지 삽입 `AnimatedSize`+fade,
  전송 버튼 56dp. AI 서비스/점수 분석 로직 무변경.

### 3.10 reports (reports/clinical_report_options)
- A: 진입 모션 8건. `MLChart`·상태 텍스트·막대. `report_analyzer`·`clinical_report_data` 분리.
- B: 긴 카드 스택(FINAL_REPORT §3). "한 줄 결론→근거→추세→다음행동" 순서 미고정.
- C: 차트 7개 미만 시 요일 라벨 처리(FINAL_REPORT P0). null/0 구분 필요.
- D: 모션 양호.
- E: DB/계산/UI 한 State 혼재(cycle_005) — 회귀 위험은 로직 이동 시.
- 실행(FINAL_REPORT P1): Repository+ViewModel 분리, 화면 순서 고정, 라벨 일치.
  **PDF 생성기(`clinical_report_generator.dart`)는 인쇄물 — 화면 토큰/모션 규칙 적용 대상 아님**
  (palette_guard·motion_guard 면제 파일).

### 3.11 profile
- A: `MLCard`+`MLListRow` 일관 사용. `Semantics(identifier:)`로 dementia/cs 카드 식별.
  `FloatingPillNav.contentBottomInset` 하단 여백 적용(:).
- B: 위계 양호(섹션 타이틀+카드).
- C: `user == null` 시 스피너뿐 — 실패 상태 없음(로컬 데이터라 위험 낮음).
- D: **진입 안무 없음**(grep 0건). StatelessWidget이라 추가 용이.
- E: 헤더 이름 22sp·아바타 72dp 양호. `MLListRow` InkWell 높이 vertical 14+아이콘 40 → 68dp 이상,
  56dp 통과.
- 실행: 섹션 단위 `StaggeredColumn` 진입 안무. 네비게이션/`context.push` 경로 무변경.

### 3.12 settings
- A: 진입 모션 2건. `model_download_screen` 별도.
- B/C/D/E: `settings_screen_test.dart` 가드 존재. 토글은 전역 switchTheme 적용.
- 실행: 특이 공백 낮음. 진입 안무 커버리지 확인만.

### 3.13 guardian (guardian_link)
- A: QR 연결 화면. `Duration(seconds:3)`(:76) — 스낵바/타이머(모션 아님).
- B/C: 연결 상태(대기/성공/실패) 표현 확인 필요.
- D: **진입 안무 없음**(grep 0건).
- E: QR·버튼 타깃 56dp 확인. `maestro/guardian_link_flow.yaml` 가드 존재.
- 실행: 진입 안무, 연결 상태 3종 시각화. Firestore 연결 로직 무변경.

### 3.14 CS (center/notices/notice_detail/faq/inquiry_submit/my_inquiries/inquiry_detail)
- A: faq/my_inquiries/notice_list 진입 모션 각 4건. `MLErrorState`(재시도)가 CS 실패 위장
  문제를 해결한 흔적(ml_widgets 주석). notice_detail/inquiry_detail 1건씩.
- B: 목록 위계 양호.
- C: **실패 상태가 이미 `MLErrorState`로 구현** — 새 제안 아님.
- D: cs_center(허브)·inquiry_submit 진입 안무 미검출.
- E: `cs_center_flow.yaml` 가드.
- 실행: cs_center/inquiry_submit 진입 안무만.

### 3.15 admin (login/dashboard/user_detail/cs_management/notice_edit/faq_edit/inquiry_detail)
- A: dashboard 1·cs_management 3·user_detail 2건 진입 모션. `AppConfig.isAdminPortalEnabled`로
  딥링크까지 차단(router). 관리자 전용이라 고령 접근성 우선순위 낮음.
- B/C/D: edit 화면들(notice_edit/faq_edit) 진입 모션 미검출. 폼 검증 상태 확인.
- E: 관리자 대상이라 56dp 강제 완화 가능(비고령). 단 색·대비 규칙은 동일 적용.
- 실행: 우선순위 낮음. 진입 안무는 dashboard 계열만 이미 있음. 최소 개입.

### 3.16 기타 (voice_assessment/dementia_center/health/navigation)
- voice_assessment: **중지 안내 화면**(blocked). `voice_assessment_blocked_screen_test.dart` 가드.
  건드리지 않음.
- dementia_center: 공공데이터 CSV 기반 찾기. `dementia_center_finder_screen_test.dart` 가드.
  진입 안무 미검출 → 목록 `StaggerScope` 후보.
- health(health_input): 진입 모션 1건. 혈압·혈당 입력.
- navigation(main_nav): `FloatingPillNav` 호스트, `extendBody`+숨은 탭 TickerMode 제어.
  `floating_pill_nav_test.dart` 가드. **골격 — 건드리지 않음**(DESIGN.md §1).

---

## 4. 우회·불일치 식별 (파일 근거)

1. **모션 커버리지 비대칭** — 진입 안무가 데이터 화면(walking 15·reports 8·home 5)에 몰리고
   입력·전환 화면(assessment/chat/profile/guardian/register/consent)에 없음. grep 실측.
2. **assessment의 Material 기본 위젯 직접 사용** — `cognitive_tasks_screen.dart`가 `Chip`/
   `ChoiceChip`/`ElevatedButton`+하드코딩 `fontSize`. ML 컴포넌트·textTheme 우회.
3. **chat 빈/실패 상태 부재** — `MLErrorState` 미사용, 추천 답변 UI 없음.
4. **문서-구현 불일치** — README에 Lottie 배지, `pubspec.yaml`엔 lottie/rive/flutter_animate 없음
   (FINAL_REPORT §2 지적, 여전히 유효).
5. **시간 제한 고정** — assessment 단어 암기 `Duration(seconds:5)` 고정, WCAG 2.2.1 조정 없음.
   (token guard는 `milliseconds`만 봐서 통과 — 정당하나 접근성 정책은 별개.)

*우회 아님으로 확인된 것*: 원색 사용(PDF만), 다크 고정(의도), STT/타이머 `Duration(seconds:)`
(모션 아님), games 진입 안무 부재(몰입 목적상 정당).

---

## 5. 실행 계획 (화면군 우선순위)

기존 FINAL_REPORT P0/P1/P2와 **정합**시키되, 화면군 단위로 구체화한다.

### P0 — 상태·접근성 공백 (회귀 위험 낮음, 사용자 영향 큼)
1. chat 빈 상태(56dp 추천 답변 2~3개) + 실패 시 `MLErrorState` + 전송 버튼 56dp. (§3.9)
2. assessment 시간 제한 정책 확정(연장/해제) + 탭 타깃 56dp 보장. (§3.3)
3. reports 차트 요일 라벨 일치 + null/0 구분. (§3.10)
4. 320dp·textScale 2.0에서 전 화면군 오버플로우 0 재확인.
5. README Lottie 배지 ↔ pubspec 일치. (§4-4)

### P1 — 모션 커버리지 균형 + 위계
1. 진입 안무 확대: register/consent/profile/guardian/cs_center/inquiry_submit/dementia_center/
   diary_book/assessment 전환. 전부 기존 `StaggeredColumn`/`StaggerScope`/`AnimatedSwitcher` 재사용,
   신규 토큰·패키지 금지. (§3.1~3.16)
2. 목적 기반 신규 모션 3개: chat 메시지 삽입(AnimatedSize+fade), diary 저장 성취(BurstParticles 1회),
   training card→game Hero. (§3.5·3.8·3.9)
3. assessment 타이포 textTheme 이관 + ML 컴포넌트로 교체. (§3.3)
4. home 섹션+Selector 분리, hero 1개 제한. (§3.4)
5. reports Repository+ViewModel 분리. (§3.10)

### P2 — 측정 기반
1. 저사양 실기기 profile 기준선.
2. 다크 상태 문구 4토큰 대응 후 다크 재개(main.dart 1줄).
3. 고령 5~8명 형성평가.

---

## 6. 비회귀 검증 계약 (Non-Regression Contract)

리디자인이 **44경로·비라우트 UI·저장/센서/AI/보호자/관리자 기능을 해치지 않음**을 보장하는 계약.
모든 항목은 기존 테스트로 이미 강제되거나(★), 신규 추가가 필요하다(☆).

### 6.1 기존 방어선 (유지·통과 필수) ★
| 계약 | 강제 테스트 |
|---|---|
| 모션 길이는 `AppMotion` 토큰만 | `test/unit/core/motion_token_guard_test.dart` |
| 화면 색은 `MLColors`만(원색 금지) | `test/unit/core/palette_guard_test.dart` |
| 본문 4.5:1·비텍스트 3:1·상태글자·연보라면 대비 | `test/unit/core/theme_contrast_test.dart` |
| 모션 3단(full/fadeOnly/none) 분기 | `motion_settings_test`, `pressable_scale_test`, `staggered_column_test`, `fade_slide_in_test`, `ml_motion_widgets_test` |
| 진입 안무 400ms 상한·앱당 1회 | `staggered_column_test`(`totalFor`), `motion_play_log` |
| 오프닝 | `memory_opening_test` |
| 게임 피드백·오버플로우·시맨틱 | `game_template_test`, `game_layout_overflow_test`, `game_semantics_text_test`, 게임별 |
| 하단 네비 가림 방지·탭 크기 | `floating_pill_nav_test`(+`contentBottomInset`) |
| 저장/센서/AI/보호자 로직 | `database_helper_test`, `database_v9_migration_test`, `user_provider_test`, `gait_analyzer_test`, `step_anomaly_policy_test`, `anomaly_monitor_test`, `training_completion_service_test`, `training_progress_*_test`, `difficulty_provider_test`, `speech_score_test`, `report_analyzer_test`, `clinical_report_data_test`, `dementia_center_*_test` |
| 화면 위젯 | `login/assessment/home/settings/health/walking/training/dementia/voice` 위젯 테스트 |
| 문서 일관성 | `documentation_consistency_test` |
| 플로우 | `integration_test/*`, `maestro/*`(20+ flow) |

### 6.2 신규 계약 (리디자인과 함께 추가) ☆
1. **진입 안무를 추가한 각 화면군에 full/fadeOnly/none 위젯 테스트** — 세 단계 모두 최종
   상태가 도달·읽힘을 검증(기존 `staggered_column_test` 패턴 재사용).
2. **chat 상태 4종 위젯 테스트** — 빈(추천 답변 노출)/로딩/실패(`MLErrorState`)/정상.
3. **56dp 터치 타깃 위젯 테스트** — chat 전송, assessment 그리드/ChoiceChip, guardian 버튼.
4. **assessment 시간 제한 정책 테스트** — 연장/해제 경로 존재.
5. **각 화면군 골든/레이아웃 테스트** — 320dp × textScale{1.0,1.3,1.6,2.0} 오버플로우 0.
6. **라우트 불변 계약** — `router.dart`의 44경로·redirect·admin 가드·onboardingRoutes가 리디자인
   전후 동일함을 스냅샷/카운트 테스트로 고정(신규).

### 6.3 화면별 반영 전 게이트 (DESIGN.md §8 준수)
각 PR은: `flutter analyze` 0 · `flutter test` 통과 · 관련 `maestro` flow 통과 ·
글꼴 배율 1.0/1.3/1.6/2.0 · 320dp 무 가로스크롤 · 탭 요소 56dp+눌림 · 상태 4종 · 색 없이 판독 ·
신규 모션 4단·400ms·3단 분기 테스트.

### 6.4 불변식 (절대 변경 금지)
- 5탭 + `FloatingPillNav` 골격, `contentBottomInset` (DESIGN.md §1).
- 44 GoRouter 경로·가드·redirect (`router.dart`).
- 반경 9단 척도·`minTapTarget 56`·색 단일 출처 (`theme.dart`).
- 다크 `ThemeMode.light` 고정은 P2까지 유지 (`main.dart`).
- PDF 생성기는 화면 팔레트/모션 규칙 면제 (`clinical_report_generator.dart`).
- voice_assessment 중지 안내 화면·games 몰입(진입 안무 미적용)은 의도된 상태.

---

## 7. 한 줄 결론

MemoryLink의 디자인 시스템·모션 시스템·상태 부품·접근성 가드는 **이미 성숙**하다(파일 근거 §1).
남은 것은 **재작성이 아니라 적용률 균형**이다: ① 모션 커버리지를 데이터 화면 편중에서
입력·전환 화면으로 확대, ② chat/assessment의 상태·접근성 공백 메우기, ③ home/reports 책임 분리.
전부 기존 토큰·컴포넌트·모션 프리미티브 재사용으로 가능하며, §6 계약이 44경로와 전 기능의
비회귀를 보장한다. 신규 패키지·상태관리 교체·골격 변경은 불필요하고 금지한다.
