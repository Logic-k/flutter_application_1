# 08 — 앱 전역 모션 시스템·랜딩 고도화 계획 (딥리서치 결론)

- **기준일:** 2026-09-25
- **구분:** 별도 트랙 G(Stage 1~4와 독립). 07 트랙 F(게임 피드백·축하·진행 지표)가 끝난 자리에서 시작해 **앱 전역**(랜딩·온보딩·페이지 전환·대시보드·목록·차트·로딩)으로 모션을 확장한다
- **역할 분담:** 조사·계획·PR 리뷰는 Fable 5.1, 코드 실행은 Opus 5.5. §6 프롬프트는 Opus 5.5 세션에 그대로 붙여넣는 용도다
- **원칙:** `DESIGN.md` §4(4단 토큰·반복 금지·blur 금지)와 §0 `MOTION_INTENSITY 2`가 상위 규범이다. **의존성 추가 0**을 유지한다(근거 §2.1)
- **조사 방법:** 웹 딥리서치 워크플로우(5각도 검색 → 22출처 → 102주장 추출 → 25주장 3표 적대 검증 → 17확정·8기각) + 코드 감사(2026-09-25) + 보강 조사 2건(§3·§4)

---

## 0. 한 줄 결론

모션 고도화는 **새 패키지 도입이 아니라 이미 있는 `lib/core/motion` 프리미티브를 Flutter 코어 API로 앱 전역에 펼치는 일**이다. 검증 결과 `motor`·`flutter_animate`는 둘 다 축소 모션을 스스로 처리하지 않아 채택해도 우리 게이트를 다시 감싸야 하고, 스태거(단일 `AnimationController` + `Interval`)·페이지 전환(`CustomTransitionPage`)·차트 보간(fl_chart `duration`/`curve`)은 전부 의존성 0으로 가능하다. 코드 감사에서 드러난 실제 결핍은 기술이 아니라 **적용 범위**다 — 화면 40개 중 진입 모션 1곳, 눌림 프리미티브 1곳, 스피너 35곳, 토큰 우회 14곳, 랜딩 경로(네이티브 스플래시→로그인→온보딩→홈)는 통째로 정적이다. 함정 두 가지는 (a) 페이지 전환을 `CustomTransitionPage`로 덮으면 Android 예측형 뒤로가기의 "당겼다 취소" 기능을 잃으므로 뒤로가기 대상이 아닌 화면에만 쓰고, (b) 축소 모션은 "전부 끄기"가 아니라 **페이드는 남기고 이동·확대만 끄는 2단**이 WCAG 정의에 맞는 해석이라는 점이다. 순서는 **G-00 토큰 우회 정리 → G-01 축소 모션 3단·스태거 토큰 → G-02 `StaggeredColumn` → G-03 랜딩 경로 → G-04 대시보드·차트 → G-05 스켈레톤 → G-06 예측형 뒤로가기 실측 → G-07 선택**이며 약 8 작업일이다.

---

## 1. 현재 기준선 (2026-09-25 코드 감사)

| 영역 | 확인된 사실 | 계획상 의미 |
|---|---|---|
| 모션 기반 | `lib/core/motion/`에 `AppMotion` 4단 토큰(100/150/200/300ms)+`celebrateMax`·`burst`·`feedbackHold`·`pressScale`·`springOut`, `MotionSettings.reduceOf`(disableAnimations ∨ reduceMotion ∨ 앱 설정, 이미 `maybeDisableAnimationsOf` 속성별 접근자 사용), `FadeSlideIn`(200ms, 40ms 스태거, `playKey` 1회 재생), `PressableScale`, `BurstParticles`, `GameFeedback`, `MLSpringOutCurve` | 토대는 있다. 07 F-00~F-05 구현분은 **전부 미커밋**(9/21·9/24 작업 트리). 트랙 G 착수 전 커밋이 선행돼야 한다(§7-①) |
| 적용 범위 | 화면 파일 40개 중 `FadeSlideIn` 사용 **홈 1곳**, `PressableScale` 직접 사용 **온보딩 1곳**(MLCard·MLHeroCard 경유 간접 적용 있음), `Hero` 허브→게임 1곳 | 로그인·허브·리포트·일기·설정·CS·관리자 전부 정적 |
| 로딩 | `CircularProgressIndicator` **35곳**(스켈레톤 0곳). DESIGN §4는 "레이아웃 모양을 닮은 스켈레톤"을 요구 | G-05 |
| 토큰 우회 | 화면 코드의 `Duration(milliseconds:)` 직접 사용 **14곳**(모션 관련 9곳: ai_chat 300, assessment 300, cognitive_tasks **800**, diary 200, clinical_report_options 300×2·200×2, categorization_game 700 지연). 나머지는 센서 샘플링·AI 폴백 지연이라 모션 아님 | G-00. 800ms는 4단 밖이라 결정 필요(§7-②) |
| 랜딩 경로 | 초기 경로 `/login`. 네이티브 스플래시는 Flutter 기본 템플릿(`launch_background.xml` 미수정, `flutter_native_splash` 없음). 로그인 화면은 로고 110px+제목 정적. 온보딩 107줄 정적 `PageView`. 라우트 44개 전부 go_router 기본 전환 | G-03 |
| 페이지 전환 | `CustomTransitionPage`·`pageTransitionsTheme` 사용 0건. `AndroidManifest.xml` `<application>`에 `enableOnBackInvokedCallback` 없음. `MainActivity : FlutterFragmentActivity`. Flutter 3.41.5 | G-06 실측 선행 |
| 차트 | fl_chart 1.2.0 호출 5화면(reports·walking_dashboard·health_input·admin×2) 모두 `duration`/`curve` 미지정 → 150ms linear 기본. 진입 애니메이션 없음 | G-04 |
| 탭 골격 | `IndexedStack` + `FloatingPillNav`(`AnimatedContainer` 200ms) | 탭 간 전환 없음 유지(DESIGN §1 골격 고정) |
| 게이트 | test 345/345, analyze info 4, Maestro 게이팅 20/20, 콜드스타트 7.3s | 모든 PR 공통 완료 조건 |
| 규칙 파일 | 저장소 루트에 `CLAUDE.md` 없음 | G-00에서 모션 규칙 5줄짜리 `CLAUDE.md` 신설(§6-0) |

---

## 2. 딥리서치 결론 (근거 등급은 05 등록부 규약)

### 2.1 기술 지형 — 패키지는 넣지 않는다

| 후보 | 확인 내용 | 판정 |
|---|---|---|
| `motor` 1.1.0 (2025-12) | M3 Expressive 스프링 토큰 12종이 androidx 원본과 수치 일치, Apple HIG 프리셋, `loop/pingPong` 반복 모드. **축소 모션 처리 없음**(`MotionController`가 `SemanticsBinding.disableAnimations`를 참조하지 않음). 검증 3-0 · 공식 소스 | **미채택.** 4단 토큰과 별도 스프링 체계가 생기고 게이트가 이중화. 대신 `expressiveSpatialDefault`(stiffness 380, damping ratio 0.8) **수치만 차용**해 코어 `SpringDescription`으로 둔다 |
| `flutter_animate` 4.5.2 | 2024-11 이후 **22개월 무릴리스**(오픈 이슈 34), 축소 모션 처리가 README·소스·이슈 어디에도 없음. `shimmer`는 반복이라 KWCAG 충돌. 검증 3-0 · 공식 페이지+GitHub | **미채택.** API 형태(`AnimateList.interval`)만 `StaggeredColumn` 설계에 참고 |
| Rive·Lottie·FragmentShader | 07 §1.2 판정 유지(구형 기기 GL 폴백 이중 검증 비용, 자산 파이프라인 부재) | 보류 |
| Flutter 코어 스태거 | 단일 `AnimationController`에 자식별 `Interval(i·step, i·step+span)`. 순차·겹침·공백을 한 타임라인에서 표현. 검증 3-0 · 공식 문서(2026-07 갱신) | **채택.** G-02 |
| `MediaQuery.disableAnimationsOf` | 속성별 접근자라 회전·키보드 등장 시 리빌드 없음. 검증 3-0 · 공식 API | 이미 적용됨(`maybeDisableAnimationsOf`). 신규 위젯도 `MotionSettings` 경유만 허용 |

### 2.2 페이지 전환·예측형 뒤로가기 — 덮어쓰기 금지

- Flutter는 기본 라우트 전환과 `PopScope`에서 Android 예측형 뒤로가기(제스처 추종·취소/확정)를 내장 지원한다. 그러나 **`pageTransitionsTheme`나 `CustomTransitionPage`로 전환을 덮으면 그 기능을 잃는다**(공식 breaking-change 문서 명시, flutter/flutter #183252 open). 검증 3-0 · 공식 문서.
- "3.41은 설정 없이 predictive back + FadeForwards가 기본"(0-3 기각), "매니페스트 한 줄이면 끝"(1-2 기각). 전제 조건이 여러 개다: Android 14+(13은 opt-in), 매니페스트 `enableOnBackInvokedCallback="true"`, `PopScope.canPop` 사전 결정, `FlutterFragmentActivity`에서 3.41.9 미동작 보고(#192551, 이후 수정). **우리 앱은 셋 다 미충족 상태**라 G-06 실측이 선행돼야 한다.
- 설계 결론: ① 탭 간 이동은 전환 없음 유지, ② 푸시 라우트는 Flutter 기본 전환을 쓰고 덮지 않는다, ③ 스플래시→홈 리빌·결과 시트처럼 **뒤로가기 대상이 아닌 화면에만** 자체 전환을 허용한다.

### 2.3 차트 — 진입 애니메이션은 직접 만든다

fl_chart 1.2.0의 모든 차트는 `ImplicitlyAnimatedWidget`이라 데이터 변경 시 자동 보간되고 제어 축은 `duration`(기본 150ms)·`curve`(기본 linear)뿐이다. **두 데이터 상태 사이만 보간하므로 첫 빌드 진입 애니메이션은 없다.** 0값 데이터로 첫 프레임을 그리고 `addPostFrameCallback`에서 실데이터로 교체하면 진입이 된다. 리스트 길이 변경 시 추가 요소는 스냅 인(#83). 검증 3-0 · 패키지 문서+설치 소스.

### 2.4 접근성 — 축소 모션은 2단이다

- WCAG 2.3.3(상호작용 애니메이션)은 **AAA**이고, "motion animation" 정의는 **크기·형태·위치를 바꾸지 않는 색·불투명도 변화를 제외**한다. 따라서 축소 모션 시 150ms 페이드는 유지하고 slide/scale/particle만 끄는 것이 표준 해석이다. KWCAG 2.2에는 2.3.3 등가 항목이 없고 6.2.2(자동 변경 콘텐츠 정지)·6.3.1(3~50Hz 깜빡임)만 있다. WCAG Level A인 2.2.2(5초 초과 자동 움직임 정지)·2.3.1(초당 3회 플래시)은 필수. 검증 3-0/2-1/3-0 · W3C 원문.
- 시사점: 현재 `reduceOf`는 불리언 하나라 "전부 끄기"다. 정답/오답 색 변화·페이드까지 사라지면 인지 피드백이 약해진다 → `MotionLevel {full, fadeOnly, none}` 3단으로 바꾼다(G-01). `GameFeedback` 오답 shake·플래시 주기가 3Hz를 넘지 않는지 점검.

### 2.5 고령자 근거 — 장식보다 성과 피드백

- 64세 이상 100명 조사(GSA 2020 학회 초록, 자기보고): 인지훈련 앱 지속 요인으로 **성과 피드백 53%**, 난이도 조절 47%, 해금 28%, 테마 변경 20%. 방향은 `MOTION_INTENSITY 2`(상태 변화 알림 모션만)와 일치. 2024 포커스그룹(n=21)도 "고령자는 구체적 성과 피드백을 더 강조". 검증 3-0 · 학회 초록(예비 등급).
- **기각된 주장**: "고령자는 더 짧고 느린 모션 선호", "한 번에 한 요소만", "움직이는 자극 수 제한"(PMC11925862, 모두 0-3). 따라서 스태거 간격·지속시간의 수치 근거는 없고, **DESIGN.md 토큰과 자체 사용자 테스트(n≥5)로 정한다.**

### 2.6 스플래시 연결

`flutter_native_splash`의 `preserve()/remove()`는 첫 Flutter 프레임을 지연할 뿐 크로스페이드를 제공하지 않는다. Android 12+는 시스템 SplashScreen API가 자체 퇴장 애니메이션을 적용하며 억제할 수 없다. 매끄러운 연결은 **첫 Flutter 라우트에 동일 로고를 같은 위치·배경색으로 그린 뒤 페이드아웃**하는 수작업이다(GitHub 이슈 #692, 실무 사례 등급, dpr 3에서만 검증). 우리는 패키지 없이 `launch_background.xml`·Android 12 `windowSplashScreen*` 테마로 같은 결과를 낸다.

---

## 3. 참고 모션 시스템·사례 (보강 조사)

1차 워크플로우에서 이 각도는 검증 통과 0건이라 별도 조사했다. 수치가 공개되지 않은 항목은 **미확인**으로 남기고 만들어 넣지 않았다.

| 패턴 | 출처·등급 | 확인 내용 | MemoryLink 적용 |
|---|---|---|---|
| 지속시간 하한·상한 | NN/g 애니메이션 지속시간 · 전문가 권고 | 단순 피드백 100ms("즉각"의 하한), 등장 200~300ms·퇴장은 더 짧게, 큰 화면 전환도 **400ms 상한**, 500ms↑는 "질질 끄는" 느낌. "너무 긴 것이 너무 짧은 것보다 훨씬 흔한 문제" | DESIGN 4단(100/150/200/300)이 그대로 부합. `StaggeredColumn` 총합 400ms 상한의 근거 |
| M3 duration·easing 토큰 | m3.material.io tokens-specs · 공식 문서 | short2 100ms, medium1 250ms, medium2 300ms; standard easing `cubic-bezier(0.2,0,0,1)`. emphasized 계수는 2차 자료마다 달라 **미확인** | 눌림 100ms·전환 300ms 정합. easing은 코어 `Curves.easeOutCubic`/`fastOutSlowIn`으로 대체 |
| M3 Expressive 스프링 | m3 how-it-works · 공식 문서 (+§2.1 androidx 토큰 원본) | spatial fast/default/slow는 컴포넌트 크기별, effects는 오버슈트 없음. Expressive 스킴은 저댐핑 바운스로 "히어로 모먼트" 용도이며 기능 중심 UI엔 Standard 스킴을 별도 제공 | **Standard 스킴만.** `AppMotion.spring` 수치(380/0.8)는 spatial default 차용, 오버슈트는 `MLSpringOutCurve` 0.05 유지 |
| Apple HIG Motion | developer.apple.com HIG · 공식 문서 | "빈번한 상호작용엔 모션을 넣지 말 것", 모션이 유일한 정보 전달 수단이면 안 됨(햅틱·소리 보완), 사용자가 건너뛸 수 있어야 함, Reduce Motion 시 슬라이드·줌 → **크로스페이드**로 대체 | `fadeOnly` 단계의 근거(§2.4와 일치). 진입 스태거는 **화면당 첫 1회**(`playKey`)만 — 탭 재진입·스크롤 복귀는 무모션 |
| 토스 모션 원칙 | toss.im 토스피드 · 자사 공식 블로그 | "100마디 말보다 1번의 움직임" — 의미 전달 목적일 때만. TDS의 ms·스프링 수치는 **미확인** | 원칙만 차용. 수치 근거로 쓰지 않음 |
| Duolingo 스트릭 마일스톤 | blog.duolingo.com · 공식 블로그 | 일반일은 숫자 카운트업만, **7/30/100/365일 마일스톤에만** 전면 커스텀 애니메이션. 재생 시간은 미공개 | 07 F-03의 "컨페티는 스트릭 갱신·최고점·주간 목표에만" 규칙 확인. 일반 완료는 카운트업(G-04 ④)까지 |
| "장식 컨페티 대신 실제 값 애니메이션" | 3자 분석(deconstructoroffun) · 블로그, 신뢰도 낮음 | 차트가 그려지고 숫자가 올라가는 것 자체가 축하 | 원칙상 부합하나 근거로 인용하지 않음 |

**시스템들이 명시적으로 경고하는 것**: 500ms 이상 지속(NN/g), 빈번한 조작에 붙는 모션과 모션 단독 피드백(Apple), 유틸리티 UI의 저댐핑 바운스(M3), 매 완료마다 축하(Duolingo). 네 가지 모두 DESIGN §4와 07·08 규칙에 이미 반영돼 있다.

---

## 4. Claude Design → Flutter 핸드오프 (보강 조사)

### 4.1 확인된 사실

- **Claude Design**(Anthropic Labs, 2026-04 리서치 프리뷰, Pro/Max/Team/Enterprise 베타)의 출력은 디자인·프로토타입·슬라이드·원페이저이며 내보내기는 PDF·PPTX·Canva·**단일 HTML**·폴더(zip, 소스 JSON)다. 설정 시 코드베이스·디자인 파일을 읽어 팀 디자인 시스템을 만들고 이후 자동 적용한다. 공식 발표문·헬프센터 등급.
- **Claude Code 핸드오프 번들**은 컴포넌트 트리·적용된 디자인 토큰·임베디드 에셋·구조화 스펙으로 구성되고 "Send to local coding agent / Claude Code Web"로 전달되며 Flutter를 포함한 프레임워크의 기존 파일 구조·컨벤션에 맞춰 배치한다. 실무 사례 등급(공식 발표문에는 번들 세부 항목 없음).
- **모션 스펙은 번들에 없다.** 공식 발표문·헬프센터 어디에도 motion/animation/transition 스펙 언급이 없고, HTML 프로토타입 안의 CSS `transition`으로만 암묵적으로 존재한다. **미확인이 아니라 "없음이 확인"**에 가깝다. → 우리가 "클로드 디자인으로 만든 앱과 다른 모션"을 원한다면 **모션은 사람이 별도 문서로 명시**해야 한다. 그 문서가 이 계획 §5와 아래 4.2 템플릿이다.
- `motion.md`(designmd.co)는 DESIGN.md에 duration·easing·transition 표현이 없어 에이전트가 매번 임의값을 고른다는 문제의식의 **커뮤니티 제안**(제품 아님). 구성: ① 용도 컬럼이 붙은 duration 스케일, ② 컴포넌트별 enter/exit 패턴, ③ "choreography over chaos"(동시에 다 움직이면 아무것도 안 움직인 것) — 의도된 스태거, ④ reduced-motion 폴백 매핑. Google `design.md` 저장소에도 같은 요청 이슈(#47)가 열려 있다. 블로그 등급.
- **W3C Design Tokens 포맷**: `duration` 타입은 `{value, unit(ms|s)}`, `cubicBezier` 타입은 `[x1,y1,x2,y2]` 배열. 공식 초안 등급.
- 도구: `claude-flutter-ui-skills`(★2, Flutter 안티패턴 규칙집, HTML→Flutter 변환기 아님, 유지보수 신호 약함), Google Stitch(Flutter 코드 export + 2026-03 MCP 서버, Labs 실험 단계), Figma 공식 Dev Mode MCP의 Flutter 1급 지원은 **미확인**. 결론: **변환 도구를 끼우지 않는다.** Claude Design HTML은 "정적 시안"으로만 쓰고, 모션은 4.2 포맷으로 사람이 쓰고 Opus 5.5가 구현한다.

### 4.2 MemoryLink 모션 스펙 포맷 (`docs/motion/*.md` 또는 DESIGN.md §4 부록)

새 모션 하나 = 아래 블록 하나. 6개 필드가 다 있어야 구현 프롬프트에 넣는다.

```yaml
name: home_dashboard_enter
trigger: 화면 첫 진입 1회 (탭 재진입·스크롤 복귀 제외)
duration: AppMotion.enter (200ms) + AppMotion.stagger (60ms) × (n−1), 총 ≤ 400ms
curve: Curves.easeOutCubic            # 또는 [x1,y1,x2,y2] cubicBezier
choreography: 인사 카드 → 오늘의 훈련 → 주간 스트릭 → 보행 요약, 각 8px 상향 + 페이드
reduced_motion: fadeOnly → 슬라이드 0·페이드만 / none → 즉시 최종 상태
test: t=0 opacity 0 · t=400ms 전부 1.0 · none에서 pump 1회 완료 · Maestro home 플로우 셀렉터 불변
```

### 4.3 CSS → Flutter 대응표 (시안 HTML의 `transition`을 읽을 때)

| 시안(CSS) | Flutter |
|---|---|
| `cubic-bezier(x1,y1,x2,y2)` | `Cubic(x1,y1,x2,y2)` |
| `ease-out` / `ease-in-out` | `Curves.easeOut` / `Curves.easeInOut` |
| M3 standard `(0.2,0,0,1)` | `Curves.fastOutSlowIn` 근사 |
| `@keyframes` 다단계 | `TweenSequence` + `TweenSequenceItem(weight)` |
| `transition-delay` / 순차 등장 | `Interval(start, end)` on 단일 controller |
| `transition: 300ms` | `AppMotion.route` (값을 옮기지 말고 **토큰으로 치환**) |
| `prefers-reduced-motion` | `MotionSettings.levelOf(context)` 3단 |

### 4.4 Claude Design을 계속 쓸 때의 워크플로우

1. Claude Design에서 **정적 시안 + 디자인 시스템**만 확정(색·타입·간격·컴포넌트). 시안집(9/24 아티팩트) 방식과 동일.
2. 모션은 시안을 보며 사람이 4.2 블록으로 작성(화면당 1~3개). 이때 DESIGN §4 4단 토큰과 §3 표의 상한을 넘는 값은 쓰지 않는다.
3. Opus 5.5 세션에 6-0 시작 프롬프트 + 해당 G-패킷 프롬프트 + 4.2 블록을 붙인다.
4. PR 완료 후 Fable 5.1에 6-8 리뷰 프롬프트. `design_review_shots.yaml`로 3단 스크린샷을 찍어 시안과 나란히 비교.
5. 규범과 시안이 충돌하면 시안이 아니라 DESIGN.md를 먼저 고친다(DESIGN.md 머리말 규칙).

---

## 5. 트랙 G 작업 패킷

모든 PR 공통 완료 조건: `flutter analyze` info ≤4 · `flutter test` 전부 통과(345+) · Maestro 게이팅 20/20 · **축소 모션 테스트**(`MotionLevel.none`에서 `pump` 1회 후 최종 상태, `fadeOnly`에서 오프셋 0) · 화면 코드에 `Duration(milliseconds:)` 0건(G-00 가드 테스트) · `pubspec.yaml` 변경 0건.

### G-00 토큰 우회 정리·규칙 파일
- **구분/기간:** 필수 · 0.5일 · 선행 없음
- **작업:** ① 모션 관련 9곳을 `AppMotion.*`로 치환(300→`route`, 200→`enter`, 700 지연→`feedbackHold` 또는 게임 규약 상수, **800은 §7-② 결정 후**). ② `test/unit/core/motion_token_guard_test.dart` 신설 — `palette_guard_test`와 같은 방식으로 `lib/` 중 `core/motion/`·`gait_sensing_service`·`local_fallback_provider` 제외 파일에서 `Duration(milliseconds` 0건 단언. ③ 루트 `CLAUDE.md` 신설(§6-0 내용 5줄).
- **완료 조건:** 가드 테스트 통과, analyze 변화 없음.

### G-01 축소 모션 3단·스태거 토큰
- **구분/기간:** 필수 · 0.5일 · G-00
- **작업:** ① `MotionSettings.levelOf(context)` → `MotionLevel {full, fadeOnly, none}`. 규칙: `disableAnimations`(Android 애니메이션 제거)=`none`, iOS `reduceMotion` 또는 앱 설정=`fadeOnly`. 기존 `reduceOf`는 `level != full`로 유지. ② `AppMotion.stagger = 60ms`(현 FadeSlideIn 40ms와 통일 여부 §7-③), `AppMotion.spring = SpringDescription(mass 1, stiffness 380, damping = 2·√380·0.8)`(motor/M3 expressive spatial default 수치 차용). ③ `FadeSlideIn`·`PressableScale`·`BurstParticles`·`GameFeedback`이 `fadeOnly`에서 이동·확대·파티클만 생략하고 페이드는 유지하도록 분기.
- **완료 조건:** `motion_settings_test`에 3신호×3단 조합 8케이스. 설정 화면 "움직임 줄이기" 토글 동작 Maestro 스텝 유지.

### G-02 `StaggeredColumn` 프리미티브
- **구분/기간:** 필수 · 1일 · G-01
- **작업:** `lib/core/motion/staggered_column.dart` — 단일 `AnimationController`(duration = `enter` + `stagger`×(n−1)), 자식 i에 `Interval(i·step, i·step+span)`(공식 스태거 문서 패턴), 페이드+8px 상향 슬라이드, `playKey`로 1회 재생(스크롤 복귀·탭 재진입 시 재생 금지), `TickerMode` 존중, 전체 안무 상한 **400ms**(`assert`). `level==none`이면 `controller.value = 1`, `fadeOnly`면 오프셋 0.
- **완료 조건:** 골든 3장(t=0/0.5/1.0), `none` 1프레임 완료, `TickerMode(enabled:false)` 예외 없음, 자식 7개 이상이면 assert.

### G-03 랜딩 경로 — 스플래시·로그인·온보딩
- **구분/기간:** 필수 · 2일 · G-02
- **작업:** ① `launch_background.xml`(v21 포함)·Android 12 `windowSplashScreenBackground`/`AnimatedIcon`에 `surface` 색+앱 아이콘 지정(패키지 없음). ② 첫 Flutter 라우트(로그인 또는 홈)의 첫 프레임에 **같은 크기·위치의 로고**를 그린 뒤 `addPostFrameCallback` 이후 `AppMotion.route` 안에서 로고 축소·상단 이동 + 나머지 요소 `StaggeredColumn` 진입(뒤로가기 대상 아님 → 자체 전환 허용). `runApp` 이전 작업 추가 금지(콜드스타트 7.3s 악화 금지). ③ 로그인 화면: 로고→제목→부제→입력 필드→버튼 스태거, 입력 필드 포커스 시 테두리 색 `fade`. ④ 온보딩 3장: 아이콘→제목→본문→목표 카드 `StaggeredColumn`, 페이지 전환은 `PageView` 기본 스와이프 유지, 자동 넘김 금지, 진행 점(dot)은 `AnimatedContainer` `fade`. ⑤ 등록 화면 단계 전환은 `AnimatedSwitcher(fade)`.
- **완료 조건:** `maestro/auth` 관련 플로우·`profile_flow.yaml` 셀렉터 변경 없이 통과. `--profile` DevTools timeline에서 첫 3초 UI/Raster 16ms 초과 프레임 수 보고. 축소 모션 3단 각각 스크린샷(`design_review_shots.yaml` 비게이팅).

### G-04 대시보드·목록·차트 진입
- **구분/기간:** 필수 · 1.5일 · G-02
- **작업:** ① 홈 `FadeSlideIn` 6블록(`_enter(0~5)`)을 `StaggeredColumn` 2그룹으로 통일(총 ≤400ms). ② 허브·리포트·일기·설정·훈련 기록·CS 목록에 `StaggeredColumn`(첫 진입 1회). ③ `lib/core/ml_widgets.dart`에 `MLChart` 래퍼 — fl_chart에 `duration = level==full ? AppMotion.enter : Duration.zero`, `curve = AppMotion.springOut` 주입, 첫 빌드 0값→실데이터 교체로 진입. 5화면 호출부 교체. ④ 리포트 점수·스트릭 숫자 `TweenAnimationBuilder<int>` 카운트업(`enter`, 1회).
- **완료 조건:** 위젯 테스트(차트 `duration` 주입값 3단), 기존 345 통과, Maestro 20/20.

### G-05 스켈레톤 로딩
- **구분/기간:** 권장 · 1일 · G-01
- **작업:** `MLSkeleton`(정적 `surfaceVariant` 블록, 반복 shimmer 없음) + 데이터 도착 시 `AnimatedSwitcher(AppMotion.fade)` 크로스페이드. 5탭 화면(홈·허브·리포트·일기·설정)과 훈련 기록·CS 목록의 스피너부터 교체(35곳 중 약 12곳). 관리자 화면은 제외.
- **완료 조건:** 각 화면 로딩 상태 위젯 테스트에서 `CircularProgressIndicator` 0건.

### G-06 예측형 뒤로가기 실측 (코드 최소)
- **구분/기간:** 필수 · 0.5일 · 선행 없음(병렬 가능)
- **작업:** `AndroidManifest.xml` `<application>`에 `android:enableOnBackInvokedCallback="true"` 추가 → API 34 에뮬레이터(`-gpu angle_indirect -port 5680`)에서 홈→설정 푸시 후 뒤로가기 제스처를 절반 당겼다 놓았을 때 **페이지가 따라오고 취소되는지** 확인. `FlutterFragmentActivity` 상태에서 미동작이면 `FlutterActivity` 전환 시 영향받는 플러그인(pubspec 기준) 목록을 이슈 초안으로. `CustomTransitionPage`·`pageTransitionsTheme` 추가 금지.
- **완료 조건:** 동작/미동작·Flutter 버전·스크린샷(adb shell screencap → pull) 보고. 이 결과가 G-07의 착수 조건.

### G-07 선택 — 공유 요소·상세 전환
- **구분/기간:** 선택 · 1일 · G-06 결과가 "동작"일 때만
- **작업:** 훈련 기록 카드→상세, 리포트 카드→상세에 `Hero`(허브→게임과 동일 규약). 결과 시트 등장은 `showModalBottomSheet` 기본 유지.

### G-08 검증·기록 (트랙 종료 시)
- `DEVELOPMENT_ROADMAP.md` §1 기준선 재측(test·analyze·Maestro·콜드스타트). `DESIGN.md` §4에 `MotionLevel` 3단·스태거 상한 400ms·`stagger` 토큰 추가. 05 등록부에 §2 근거 등록. 축소 모션 3단 실사용자 테스트(n≥5) 결과는 §7-④.

### 순서·일정

| 순서 | 패킷 | 기간 | 선행 |
|---|---|---|---|
| 0 | 07 F-00~F-05 미커밋분 커밋(§7-①) | 0.5일 | 사용자 결정 |
| 1 | G-00 + G-01 | 1일 | — |
| 2 | G-02 | 1일 | G-01 |
| 3 | G-03 | 2일 | G-02 |
| 4 | G-04 (+G-06 병렬) | 1.5일 | G-02 |
| 5 | G-05 | 1일 | G-01 |
| 6 | G-07 | 선택 | G-06 |
| — | G-08 | 0.5일 | 전부 |

총 **약 8 작업일**(G-07 제외). 06 힉스필드 일러스트 트랙 B는 G-03 이후 착수(로고·온보딩 일러스트가 첫 자산).

---

## 6. Opus 5.5 실행 프롬프트

사용법: 세션마다 **6-0 세션 시작 프롬프트**를 먼저 붙이고, 그다음 패킷 프롬프트 하나를 붙인다. PR 하나 = 프롬프트 하나. PR이 끝나면 **6-9 리뷰 프롬프트**를 Fable 5.1 세션에 붙인다.

### 6-0 세션 시작 (모든 세션 공통)

```
너는 MemoryLink Flutter 앱의 모션 구현 담당이다. 시작 전에 다음을 순서대로 읽어라:
DESIGN.md §0·§4·§5, docs/plans/08_MOTION_SYSTEM_GLOBAL.md 전체, docs/plans/07_FLUTTERFX_MOTION_UPGRADE.md §3,
lib/core/motion/ 전체 파일, lib/core/ml_widgets.dart.

고정 규칙(위반 시 작업 중단하고 보고):
1. pubspec.yaml 의존성 추가·변경 금지.
2. 화면 코드에서 Duration(milliseconds:) 직접 사용 금지. lib/core/motion/app_motion.dart 토큰만 쓴다. 새 값이 필요하면 코드가 아니라 DESIGN.md §4를 먼저 고치고 보고한다.
3. 모든 새 애니메이션은 MotionSettings.levelOf(context) 3단(full/fadeOnly/none)을 분기하고, 세 단계 위젯 테스트를 동반한다.
4. 자동 재생·반복 애니메이션 금지. 1회성 축하만 AppMotion.celebrateMax(2.5s) 안에서 허용.
5. CustomTransitionPage·pageTransitionsTheme 추가 금지(예측형 뒤로가기 취소 기능 상실). 뒤로가기 대상이 아닌 화면의 자체 전환만 허용.
6. Maestro yaml의 텍스트·key 셀렉터를 바꾸지 마라. 바꿔야 하면 먼저 보고.
7. 작업 시작 전 `git status`로 미커밋 파일을 확인하고, 이번 PR 관련 파일만 스테이징한다(다른 미추적 파일은 사용자 작업 상태).

완료 보고 형식: 변경 파일 목록 / `flutter analyze` 전후 info 수 / `flutter test` 통과 수 / 축소 모션 3단 테스트 이름 / 규범과 어긋나 못 한 것.
```

이 7줄은 루트 `CLAUDE.md`에도 동일하게 넣는다(G-00).

### 6-1 G-00 토큰 우회 정리

```
G-00을 수행해라. 목표: lib/ 화면 코드의 Duration(milliseconds:) 직접 사용 9곳을 AppMotion 토큰으로 치환하고 가드 테스트를 만든다.
대상: `grep -rn "Duration(milliseconds" lib --include=*.dart | grep -v core/motion` 결과 중 gait_sensing_service.dart(센서 샘플링)·local_fallback_provider.dart(AI 폴백 지연)를 제외한 전부.
매핑: 300→AppMotion.route, 200→AppMotion.enter, 150→AppMotion.fade, 100→AppMotion.press. categorization_game.dart:153의 700ms Future.delayed는 정답 후 다음 문항 지연이므로 AppMotion.feedbackHold(1400)로 바꾸지 말고, GameTemplate이 이미 같은 지연을 처리하는지 확인해 중복이면 제거, 아니면 AppMotion에 `nextQuestionDelay` 토큰을 추가하되 DESIGN.md §4 예외 목록에 한 줄 추가하고 보고해라.
cognitive_tasks_screen.dart:145의 800ms는 4단 밖이다. 치환하지 말고 어떤 애니메이션인지(무엇이 왜 800ms인지) 조사해 보고만 해라.
가드: test/unit/core/motion_token_guard_test.dart를 test/unit/core/palette_guard_test.dart와 같은 방식(파일 순회+정규식)으로 만들고 허용 목록은 core/motion/, gait_sensing_service.dart, local_fallback_provider.dart 세 개만.
CLAUDE.md: 저장소 루트에 없으면 6-0의 고정 규칙 7줄을 그대로 담아 신설.
완료 조건: 가드 테스트 통과, 기존 테스트 전부 통과, analyze info 변화 없음.
```

### 6-2 G-01 축소 모션 3단·토큰

```
G-01을 수행해라. lib/core/motion/motion_settings.dart에 `enum MotionLevel { full, fadeOnly, none }`과 `static MotionLevel levelOf(BuildContext context, {bool listen = true})`를 추가한다.
규칙: MediaQuery.maybeDisableAnimationsOf가 true → none. 그 외 platformDispatcher.accessibilityFeatures.reduceMotion 또는 SettingsProvider.reduceMotion이 true → fadeOnly. 둘 다 아니면 full. 기존 reduceOf는 `levelOf != full`을 반환하도록 유지(호출부 변경 없음).
근거: WCAG 2.3.3 "motion animation" 정의는 크기·형태·위치를 바꾸지 않는 불투명도 변화를 제외한다. 축소 모션에서 150ms 페이드는 남기고 이동·확대·파티클만 끈다.
app_motion.dart에 추가: `static const Duration stagger = Duration(milliseconds: 60);`(주석에 "StaggeredColumn 자식 간 간격") 및 `static final SpringDescription spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.8);`(주석에 "M3 Expressive spatial default 수치 차용, 패키지 미사용").
FadeSlideIn·PressableScale·BurstParticles·GameFeedback을 levelOf 분기로 바꿔라: fadeOnly에서 슬라이드 오프셋 0·scale 1·파티클 생략·페이드 유지, none에서 즉시 최종 상태.
테스트: test/unit/core/motion_settings_test.dart에 세 신호 조합 8케이스(기대 level 명시), 각 프리미티브 위젯 테스트에 fadeOnly 케이스 추가. 설정 화면 테스트·Maestro settings 스텝은 그대로 통과해야 한다.
```

### 6-3 G-02 StaggeredColumn

```
G-02를 수행해라. lib/core/motion/staggered_column.dart를 만든다.
사양: children 목록을 받아 단일 AnimationController(duration = AppMotion.enter + AppMotion.stagger × (n−1))로 구동. 자식 i는 Interval(start_i, end_i)(start_i = i·stagger/총길이, end_i = start_i + enter/총길이)에 FadeTransition + 8px 상향 SlideTransition(curve Curves.easeOutCubic). 공식 문서 docs.flutter.dev/ui/animations/staggered-animations 패턴 그대로.
제약: 총 길이 400ms 초과 시 assert(자식 최대 (400−200)/60+1 = 4개; 그 이상은 호출부가 그룹으로 묶는다). playKey(String) 인자로 앱 프로세스 내 1회만 재생(FadeSlideIn의 기존 playKey 저장소를 공유). TickerMode가 꺼져 있으면 재생하지 않고 최종 상태. levelOf: none → controller.value = 1.0, fadeOnly → 슬라이드 오프셋 0.
반복·자동재생 없음. 새 패키지 없음. 기존 FadeSlideIn 호출부는 건드리지 마라(G-04에서 교체).
테스트 test/widget/core/staggered_column_test.dart: (a) t=0/150ms/400ms 골든 3장(--update-goldens로 생성), (b) none에서 pump 1회 후 모든 자식 opacity 1.0, (c) fadeOnly에서 Transform/Slide 오프셋 0, (d) TickerMode(enabled:false)에서 예외 없음, (e) 자식 5개면 assert.
```

### 6-4 G-03 랜딩 경로

```
G-03을 수행해라. 범위: 네이티브 스플래시 → 로그인 → 온보딩 → 홈 첫 진입.
1) android/app/src/main/res/drawable/launch_background.xml과 drawable-v21에 배경색을 lib/core/theme.dart의 surface 색 HEX로, 중앙에 assets/icon/app_icon.png 계열 mipmap을 지정. values-v31 스타일에 windowSplashScreenBackground 같은 색, windowSplashScreenAnimatedIcon 앱 아이콘. 패키지(flutter_native_splash) 추가 금지.
2) LoginScreen: 첫 프레임에 로고를 네이티브 스플래시와 같은 화면 중앙·같은 크기로 그린다. addPostFrameCallback 후 AppMotion.route(300ms) 동안 로고가 현재 위치(110px 상단)로 이동·축소하고, 제목→부제→입력→버튼이 StaggeredColumn으로 등장. runApp 이전 작업 추가 금지. 로고 이동은 뒤로가기 대상이 아니므로 자체 애니메이션 허용, CustomTransitionPage 사용 금지.
3) OnboardingScreen(107줄): 각 페이지 아이콘→제목→본문→목표 카드를 StaggeredColumn으로. PageView 스와이프·버튼·자동 넘김 없음은 그대로. 페이지 지시 점은 AnimatedContainer(AppMotion.fade).
4) RegisterScreen 단계 전환은 AnimatedSwitcher(duration: AppMotion.fade).
검증: maestro/profile_flow.yaml과 auth 관련 플로우가 셀렉터 변경 없이 통과. `flutter run --profile`로 DevTools frame timing을 열어 앱 시작 후 3초 동안 UI/Raster 16ms 초과 프레임 수를 보고. maestro/design_review_shots.yaml(비게이팅)로 full/fadeOnly/none 각 스크린샷 1장씩 저장(스크린샷은 adb shell screencap 후 adb pull, PowerShell 리다이렉트 금지).
```

### 6-5 G-04 대시보드·차트

```
G-04를 수행해라.
1) home_screen.dart의 _enter(0~5) FadeSlideIn 6블록을 StaggeredColumn 그룹(4개 이하씩)으로 교체하되 첫 화면 총 안무 400ms 상한. training_hub_page·reports_screen·diary_screen·settings_screen·training_history_screen·notice_list_screen에 첫 진입 1회 StaggeredColumn 적용. IndexedStack 탭 재진입 시 재생 금지(playKey).
2) lib/core/ml_widgets.dart에 `MLChart` 래퍼: child 빌더에 (duration, curve)를 넘겨 fl_chart 생성자의 duration/curve로 주입. duration = levelOf==full ? AppMotion.enter : Duration.zero, curve = AppMotion.springOut. 첫 빌드는 y=0 데이터로 그리고 addPostFrameCallback에서 실데이터로 setState(진입 애니메이션). fl_chart는 두 데이터 상태 사이만 보간하므로 이 방식이 필요하다. 호출부 5곳(reports_screen.dart, walking_dashboard_screen.dart, health_input_screen.dart, admin_dashboard_screen.dart, admin_user_detail_screen.dart) 교체.
3) 리포트 점수·주간 활성일·스트릭 숫자는 TweenAnimationBuilder<int>(AppMotion.enter) 카운트업, levelOf!=full이면 즉시 표시.
테스트: MLChart 위젯 테스트(3단 duration 값), 홈·리포트 위젯 테스트 통과, 기존 전체 통과, Maestro 20/20.
```

### 6-6 G-05 스켈레톤

```
G-05를 수행해라. lib/core/ml_widgets.dart에 `MLSkeleton`(높이·너비·반경을 받는 정적 surfaceVariant 블록, 반복 shimmer 없음 — KWCAG 반복 금지)과 `MLSkeletonList(count, itemHeight)`를 만든다. 로딩→데이터 전환은 AnimatedSwitcher(duration: AppMotion.fade).
교체 대상: `grep -rn CircularProgressIndicator lib/features` 중 home·training_hub·reports·diary·settings·training_history·notice_list·faq·my_inquiries의 목록/카드 로딩 자리. 제출 버튼 안의 소형 스피너(진행 중 표시)와 관리자 화면은 제외.
스켈레톤 모양은 실제 레이아웃(카드 높이·줄 수)을 닮아야 한다(DESIGN §4). 각 화면 로딩 상태 위젯 테스트에서 CircularProgressIndicator finder가 0건, MLSkeleton이 1건 이상.
```

### 6-7 G-06 예측형 뒤로가기 실측

```
G-06을 수행해라. 코드 변경은 AndroidManifest.xml <application>에 android:enableOnBackInvokedCallback="true" 한 줄뿐이다.
절차: API 34 에뮬레이터를 `-gpu angle_indirect -port 5680`으로 기동(다른 GPU 백엔드는 ANR·크래시). 앱 설치 후 홈→설정 푸시, 시스템 뒤로가기 제스처를 화면 절반까지 당겼다가 되돌려 (1) 페이지가 손가락을 따라오는지 (2) 놓으면 취소되는지 확인. MainActivity가 FlutterFragmentActivity인 상태에서 flutter/flutter #192551(3.41.9 미동작 보고)이 재현되는지가 핵심.
보고: 동작/미동작, `flutter --version`, 스크린샷 2장(adb shell screencap /sdcard/x.png → adb pull). 미동작이면 FlutterActivity로 바꿀 때 영향받는 플러그인(pubspec 의존성 중 FragmentActivity를 요구하는 것: local_auth·image_picker 등)을 조사해 이슈 초안만 작성. Activity 전환·CustomTransitionPage·pageTransitionsTheme 추가는 하지 마라.
```

### 6-8 Fable 5.1 리뷰 프롬프트 (PR마다)

```
docs/plans/08_MOTION_SYSTEM_GLOBAL.md §5의 G-0N 패킷 기준으로 현재 브랜치 diff를 리뷰해라(/code-review high). 특히 확인할 것: (1) Duration(milliseconds:) 직접 사용 신규 0건, (2) 모든 신규 애니메이션에 MotionLevel 3단 분기와 테스트, (3) 반복·자동재생 없음, (4) CustomTransitionPage/pageTransitionsTheme 없음, (5) pubspec 변경 없음, (6) Maestro 셀렉터 변경 없음, (7) 스태거 총합 400ms 이하. 위반은 파일:줄로. 규범 자체가 틀렸다고 판단되면 코드가 아니라 DESIGN.md 수정을 제안해라.
```

---

## 7. 사용자 결정이 필요한 것

1. **07 F-00~F-05 미커밋분 커밋·PR 분할** — 트랙 G 착수 조건. 9/24 메모의 결정 ④와 동일.
2. **`cognitive_tasks_screen.dart:145`의 800ms** — 4단 밖. 검사 과제 규약(자극 노출 시간)이면 모션 토큰이 아니라 평가 상수로 분리, 장식이면 `route`로 축소.
3. **스태거 간격** — 현 `FadeSlideIn` 40ms vs 제안 60ms. 근거 수치가 없으므로(§2.5) 실기기에서 두 값을 보고 정한다.
4. **축소 모션 3단 실사용자 테스트** — `fadeOnly`가 65+ 사용자에게 상태 변화를 충분히 전달하는지 n≥5 확인. 결과에 따라 fadeOnly 기본을 유지하거나 none으로.
5. **랜딩 첫 화면** — 자동 로그인 사용자는 스플래시→홈 직행이라 로고 이동 안무를 홈에도 둘지(콜드스타트 체감 완화) 로그인에만 둘지.

---

## 7.1 실행 기록 (2026-09-25, 에뮬레이터 미사용 세션)

에뮬레이터가 다른 앱 테스트에 쓰이고 있어 **기기 검증(Maestro·`--profile` 프레임 측정·G-06 실측·스크린샷)은 하지 않았다.** 호스트에서 도는 `flutter analyze`·`flutter test`만 돌렸다. 전부 미커밋.

| 패킷 | 상태 | 계획과 달라진 점 |
|---|---|---|
| G-00 | 완료 | 9곳 치환. `cognitive_tasks` 800ms는 애니메이션이 아니라 **스낵바 표시 시간**(방해 과제 오답 안내)이었다 — 고령자가 한 줄을 읽기엔 짧아 `feedbackHold`(1.4초)로 바꿨다(§7-② 답). 분류하기 700ms는 `GameTemplate`에 같은 지연이 없어 `nextQuestionDelay` 토큰 + DESIGN §4.1 예외로. 리포트 옵션 카드 200ms는 테두리 색 전환이라 `enter`가 아니라 `fade`. 스크롤·페이지 이동 3곳은 축소 모션이면 `jumpTo`. 가드 테스트·루트 `CLAUDE.md` 신설 |
| G-01 | 완료 | `MotionLevel` 3단, `levelOf` 8조합 테스트. `PressableScale`은 fadeOnly에서 축소 대신 **불투명도 0.72**(눌림 피드백은 필수라 없애지 않음, `pressOpacity` 토큰). 결과 시트 별은 fadeOnly에서 커지지 않고 밝아지기만 |
| G-02 | 완료 | `StaggeredColumn` + 목록용 `StaggerScope`/`StaggerItem`(index가 칸 수를 넘으면 마지막 칸과 함께). 저장소에 골든 테스트 관례가 없어 골든 대신 t=0/150/400ms 수치 단언. `TickerMode` 꺼짐은 예외 없이 최종 상태로 그리고 **켜지는 순간 재생**(숨은 탭 대응). `MotionPlayLog`로 `FadeSlideIn`과 재생 기록 공유 |
| G-03 | 코드 완료·기기 미검증 | 스플래시 배경은 `surface`(#FFF)가 아니라 **로그인 첫 프레임 배경 `bg`(#F1F0FB)**. 로고는 110dp·26dp 모서리를 PNG에 구워(`drawable-*/splash_logo.png`) 8~11 layer-list와 12+ `windowSplashScreenAnimatedIcon`(288dp 캔버스 가운데)에 같은 크기로. `values-night-v31`도 둔다(night가 v31보다 우선). 로그인은 로고가 화면 중앙에서 제자리로 300ms 이동 후 제목→입력→버튼→가입 스태거. **온보딩은 3장 PageView가 아니라 '사용 목적' 한 화면**이어서 질문→카드 3장 스태거 + 선택 표시 페이드. **회원가입은 단계 전환이 없는 단일 폼**이라 관심 분야 칩에 눌림·색 페이드만 |
| G-04 | 완료 | 홈 6블록 → 4묶음. 허브·리포트·걷기·설정·훈련 기록·공지·FAQ·내 문의에 진입 스태거(일기는 입력 칸이 `Expanded`라 제외). `MLChart` 5화면(관리자 2화면은 진입 연출 없이 축소 모션 규칙만). 곡선은 `springOut`이 아니라 `easeOutCubic` — 스프링 오버슈트는 데이터 값을 5% 과장한다. 카운트업은 **오늘 걸음만 첫 진입 0→값**, XP·연속 학습은 값이 바뀔 때만(누적값을 매번 0부터 세면 "방금 얻은 것"으로 읽힘). 리포트에는 점수 숫자가 화면에 없어 카운트업 대상이 없었다 |
| G-05 | 완료 | `MLSkeleton`·`MLSkeletonCard`·`MLSkeletonList`·`MLLoadSwitcher`. 교체: 리포트·걷기·허브 코스·일기·설정 AI 카드·훈련 기록·공지·FAQ·내 문의(9곳). 실제 탭은 홈·허브·걷기·리포트·프로필이다(계획서의 "일기·설정 탭"은 실제 구조와 다름) |
| G-06 | 미착수 | 기기 실측 패킷이라 이번 세션 범위 밖. 매니페스트 한 줄도 실측 없이 넣으면 `FlutterFragmentActivity`에서 뒤로가기가 통째로 안 될 위험(#192551)이 있어 넣지 않았다 |
| G-08 | 일부 | DESIGN.md §4.1·§8 갱신. 기준선 재측(Maestro·콜드스타트)은 기기 필요 |

**다음 기기 세션에서 확인할 것:** ① Maestro 게이팅 20/20(특히 `login_flow`·`register_flow`·`profile_flow`·`training_hub_flow` — 셀렉터는 바꾸지 않았다), ② 스플래시→로그인 로고 위치가 8~11·12+에서 실제로 겹치는지(내비게이션 바가 창 높이에서 빠지는 기기는 세로로 최대 약 24dp 어긋날 수 있다), ③ `--profile` 첫 3초 16ms 초과 프레임 수, ④ 3단 스크린샷.

---

## 8. 참고 자료

- Flutter 공식: [Staggered animations](https://docs.flutter.dev/ui/animations/staggered-animations) · [Predictive back](https://docs.flutter.dev/platform-integration/android/predictive-back) · [Default Android page transition 변경](https://docs.flutter.dev/release/breaking-changes/default-android-page-transition) · [MediaQuery.disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html) · [PredictiveBackPageTransitionsBuilder](https://api.flutter.dev/flutter/material/PredictiveBackPageTransitionsBuilder-class.html)
- go_router: [Transition animations](https://pub.dev/documentation/go_router/latest/topics/Transition%20animations-topic.html)
- flutter/flutter 이슈: #183252(CustomTransitionPage와 예측형 뒤로가기), #152323(중첩 Navigator), #192551(FlutterFragmentActivity), #65874·#106499·#130976(reduce motion 자동 적용 부재)
- 패키지: [motor](https://pub.dev/packages/motor) · [flutter_animate](https://pub.dev/packages/flutter_animate) · [fl_chart 애니메이션 문서](https://github.com/imaNNeo/fl_chart/blob/master/repo_files/documentations/handle_animations.md) · fl_chart #83 · flutter_native_splash #692
- 접근성: [WCAG 2.1 Understanding 2.3.3](https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions.html) · [WCAG 2.2](https://www.w3.org/TR/WCAG22#animation-from-interactions) · [KWCAG 2.2](https://a11ykr.github.io/kwcag22/)
- 고령자: Roque & Harrell 2020, Innovation in Aging 4(S1):411 ([PMC7742787](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7742787/)) · Gerontologist 2024 gnad048 · 기각: PMC11925862
- 모션 토큰 원본: androidx `StandardMotionTokens.kt` / `ExpressiveMotionTokens.kt`
