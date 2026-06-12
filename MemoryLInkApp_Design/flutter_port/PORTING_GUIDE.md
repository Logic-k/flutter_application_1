# MemoryLink UI/UX 리디자인 — 역사적 포팅 가이드
### 방향 A · “라벤더 캄”

> [!IMPORTANT]
> **역사적 포팅 가이드**
>
> 이 문서는 초기 “라벤더 캄” 시안을 Flutter 앱에 옮길 때 사용한 마이그레이션 계획과
> 화면별 디자인 매핑을 보존한 참고 자료입니다. 아래의 명령형 문장과 “리스킨만 수행” 전제는
> 당시 계획을 설명하며, 현재 구현을 그대로 지시하거나 보장하지 않습니다.

> [!NOTE]
> **현재 상태**
>
> - 현재 구현의 source of truth는 `lib/core/theme.dart`, `lib/core/ml_widgets.dart`, `lib/main.dart`입니다.
> - 현재 앱 폰트는 번들된 `NanumGothic`입니다. Pretendard는 선택 가능한 대안일 뿐 아직 적용되지 않았습니다.
> - 현재 테마 모드는 `ThemeMode.system`이며 라이트 고정이 아닙니다.
> - 공용 테마, 공유 위젯, 플로팅 하단 네비게이션과 핵심 화면 리디자인은 대부분 적용되었습니다.
> - `assets/illustrations/brain_buddy.svg`와 `flutter_svg` 의존성은 존재하지만, 현재 `lib/` 코드에서는 마스코트를 사용하지 않습니다.
> - 리포트·프로필·온보딩·CS·관리자 화면 매핑에는 일부 미적용 또는 후속 백로그가 남아 있습니다.
> - 앱의 로직과 데이터 흐름은 이 문서 작성 이후 발전했습니다. 따라서 “기능·로직·라우팅·Provider를 건드리지 않는
>   외피 교체”라는 원래 전제는 현재 작업 규칙이 아니라 역사적 설명입니다.

초기 포팅 원칙은 기능·로직·라우팅·Provider를 유지하고 보이는 위젯만 교체하는 것이었습니다.
현재는 인증, 서비스, Provider, 라우팅 및 데이터 흐름도 함께 발전했으므로 실제 변경 전 현재 코드를 확인해야 합니다.

이 폴더에 들어있는 파일
| 파일 | 역할 | 적용 위치 |
|---|---|---|
| `theme.dart` | 라벤더 색·Pretendard·컴포넌트 테마 | `lib/core/theme.dart` **교체** |
| `ml_widgets.dart` | 재사용 위젯(네비/카드/타일/링/상태칩 등) | `lib/core/ml_widgets.dart` **추가** |
| `assets/brain_buddy.svg` | 브레인 버디 마스코트 | `assets/illustrations/` **추가** |

웹 시안(`MemoryLink 리디자인 A.html`)의 **컴포넌트 시트**가 각 위젯의 정답 모양입니다. 수치가 헷갈리면 시트를 보세요.

---

## STEP 1 — 폰트(Pretendard) 설치 `[대체 구현 완료]`

> 현재는 `lib/core/theme.dart`와 `pubspec.yaml`에 등록된 `NanumGothic`을 사용합니다.
> 아래 Pretendard 절차는 향후 폰트 변경을 위한 선택 참고이며 현재 적용 상태가 아닙니다.

앱이 한글인데 현재 `Outfit`(google_fonts)은 한글 글리프가 없습니다. 한글 가독성을 위해 **Pretendard** 로 교체합니다.

**방법 A (권장 · 번들):**
1. [Pretendard 릴리스](https://github.com/orioncactus/pretendard/releases)에서 `Pretendard-Regular/Medium/SemiBold/Bold.otf`(또는 ttf) 4종 다운로드 → 이미 있는 `assets/fonts/` 에 복사.
2. `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.otf
        - asset: assets/fonts/Pretendard-Medium.otf
          weight: 500
        - asset: assets/fonts/Pretendard-SemiBold.otf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.otf
          weight: 700
```

**방법 B (빠른 폴백):** 폰트를 번들하기 전이라면 `theme.dart` 의 `_fontFamily` 를 `null` 로 두면 시스템 한글 폰트로 동작합니다. (디자인 의도와 약간 달라질 수 있음)

> 더 이상 `google_fonts` 의 `GoogleFonts.outfitTextTheme(...)` 은 쓰지 않습니다. 새 `theme.dart` 가 textTheme 을 직접 정의합니다.

---

## STEP 2 — 테마 교체 `[대부분 완료]`

초기 계획은 `flutter_port/theme.dart`를 `lib/core/theme.dart`로 옮기는 것이었습니다.
현재는 `lib/core/theme.dart`가 유지보수 대상이며, `lib/main.dart`에서
`AppTheme.lightTheme` / `AppTheme.darkTheme`와 `ThemeMode.system`을 사용합니다.

### 색 토큰 표 (코드에 색을 직접 쓸 때는 `MLColors.*` 사용)
| 토큰 | 값 | 용도 |
|---|---|---|
| `MLColors.primary` | `#6C5CE7` | 강조 · 버튼 · 활성 탭 |
| `MLColors.primarySoft` | `#ECE9FC` | 연한 틴트 배경 |
| `MLColors.bg` | `#F1F0FB` | 스캐폴드 배경 |
| `MLColors.surface` | `#FFFFFF` | 카드 |
| `MLColors.line` | `#ECEAF4` | 경계선 |
| `MLColors.text` / `textSoft` / `textFaint` | `#241F3D` / `#716C8C` / `#A6A2BC` | 본문 위계 |
| `calc / logic / mem / care / read` | 라벤더/보라/민트/핑크/앰버 | 게임·지표 카테고리 |
| `good / warn / bad` | `#3FBF8F` / `#FFB020` / `#FF6B6B` | 신호등 상태 |

> **하드코딩 색 정리:** 기존 화면들이 `Colors.blue.shade700`, `Colors.orange.shade50` 등을
> 직접 쓰고 있습니다. 카테고리 색은 `MLColors.calc/logic/mem/...` 로, 상태색은 `MLColors.good/warn/bad`
> 로 바꾸면 톤이 통일됩니다. (한 번에 다 안 바꿔도 됩니다 — 화면별로 점진 적용 가능)

---

## STEP 3 — 공용 위젯 추가 `[완료]`

초기 템플릿은 현재 `lib/core/ml_widgets.dart`에 반영되어 있습니다. 필요한 화면에서는
```dart
import '../../core/ml_widgets.dart';
```
제공 위젯: `FloatingPillNav`, `MLHeroCard`, `MLCard`, `MLIconTile`, `MLSectionTitle`,
`MLProgressBar`, `MLRing`, `MLStatusPill`, `MLGameCard`, `MLMetricCard`, `MLListRow`.

---

## STEP 4 — 하단 네비를 “플로팅 알약”으로 (핵심 변경) `[완료]`

현재 `lib/features/navigation/main_nav_screen.dart`는 `FloatingPillNav`를 사용합니다.
아래 코드는 초기 교체 방식의 참고 예시입니다.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,                       // ← 콘텐츠가 네비 뒤까지 채워지도록
    body: _widgetOptions.elementAt(_selectedIndex),
    bottomNavigationBar: FloatingPillNav(   // ← 표준 NavigationBar 대체
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,                 // 기존 콜백 그대로
      // items 기본값이 홈/인지훈련/생활습관/리포트/내정보 라 생략 가능
    ),
  );
}
```

> `extendBody: true` 때문에 각 탭 화면의 스크롤 끝에 **여백 ~100px** 를 줘야 마지막 카드가
> 네비에 안 가립니다. 각 화면의 가장 바깥 `SingleChildScrollView` 패딩을
> `EdgeInsets.fromLTRB(22, 6, 22, 110)` 처럼 하단만 키우세요.

---

## STEP 5 — 화면별 적용 매핑 `[핵심 화면 대부분 완료 · 일부 백로그]`

아래는 초기 화면별 디자인 매핑입니다. 핵심 화면에는 대부분 반영되었지만 현재 위젯 구조와
데이터 흐름은 이후 변경되었을 수 있습니다. 리포트와 프로필 등은 항목별로 현재 코드를 확인해야 합니다.

### 🏠 `home_screen.dart`
| 기존 | 교체 |
|---|---|
| `_buildHeaderCard(...)` 의 `Container(gradient...)` | `MLHeroCard(child: ...)` — 인사/걸음·훈련 스탯 그대로 |
| `_buildMemoryGardenCard` | `MLCard(onTap: → '/memory_garden', child: Row[ MLRing(value: totalProgress, color: MLColors.mem) + 텍스트 ])` |
| `_buildRecommendedTraining` 의 `_buildTrainingItem` | `MLCard` + `MLIconTile(icon, color: MLColors.calc/logic)` + 우측 `FilledButton('시작')` |
| `_buildBrainHealthCard` 의 `_buildMetricBar` | 라벨 + 점수 + `MLProgressBar(value: score/100, color: …)` |
| 헤더 배경 | `theme.colorScheme.surface` → `MLColors.bg` (테마가 이미 처리) |

### 🧠 `training/training_hub_page.dart`
- `_buildProgressBanner` → `MLHeroCard` (종합 % 진행 바)
- 카테고리 헤더: 기존 “좌측 컬러 보더” 유지하되 색을 `MLColors.calc/logic/mem/care` 로.
- `GridView` 의 게임 카드 → **`MLGameCard(icon, color, title, desc, level, onTap: ()=>context.push(route))`** 로 통째 교체.
  현재 `_GameItem` 의 필드(`title/description/icon/color/route/level`)가 그대로 매핑됩니다.

### 🎮 게임 화면들 (`training/games/*.dart`)
- 상단 AppBar/진행률은 테마가 자동 적용. 정답/오답 선택지 버튼만 톤 정리:
  - 선택/정답 = `MLColors.primary` 배경 + 흰 글씨, 미선택 = `surface` + `line` 보더, 라운드 `20`.
- 게임 결과는 `GameDone` 시안 참고: 트로피 + 컨페티 + 최종 점수 카드 + [다시 풀기 / 돌아가기].
  현재 `AlertDialog`(`_showResultDialog`)를 풀스크린 결과로 바꾸려면 별도 화면으로, 유지하려면 다이얼로그 내용만 재스타일.
- **누가 큰가요?(비교 게임)**: 좌/우 두 카드 + 가운데 VS, 하단 "= 같으면 가운데 터치 =". **AI 요소 없음** — 순수 숫자/수식 비교. `_buildChoiceCard` 를 `MLCard` 톤(라운드 20·라벤더 보더)으로만 정리.

### 📊 `reports/reports_screen.dart`
- `_buildBrainAgeCard` 상단 점수 → `MLHeroCard` + `MLRing(value: .., color: Colors.white)`.
- `_buildIndicatorBar` 의 상태 뱃지 → **`MLStatusPill(label: '양호/보통/주의', color: MLColors.good/warn/bad)`**, 바는 `MLProgressBar`.
- `_buildChartCard` 의 `LineChart` → **STEP 6 의 곡선 area 설정**으로 교체(색 `MLColors.primary`).
- `_buildAISummaryCard` → `MLCard(soft)` + `MLColors.primary` 헤더, 권고 항목은 체크 아이콘 + 텍스트.

### 🚶 `gait_analysis/walking_dashboard_screen.dart`
- 원형 게이지 → `MLRing(value: progress, size: 194, stroke: 17, color: MLColors.primary, center: 걸음수 텍스트)`.
- 정밀 분석 CTA → `MLHeroCard`.
- “오늘의 성과” 그리드 → `MLMetricCard` 4개 (걸음/거리/칼로리/시간, 색 `read/calc/bad/good`).
- 주간 막대그래프 → **STEP 6 의 막대 설정**.

### 👤 `profile/profile_screen.dart`
- 헤더 → `MLCard` 안에 아바타(원형 → 라운드 사각 24) + 이름/나이 + “프로필 수정” 아웃라인 버튼.
- 각 섹션의 `Card` + `ListTile` → `MLCard(padding: 0)` 안에 **`MLListRow`** 나열.
  - 토글 항목: `trailing: Switch(...)` (음성 안내/진동/다크 모드).
  - 다크 모드 토글을 추가하려면 기존 `SettingsProvider` 에 themeMode 만 연결(로직 신규).

### 🌱 `home/memory_garden_screen.dart`
- 배경 그라디언트/Lottie는 유지. 하단 진행 카드 → `MLCard` + `MLProgressBar`(신체활동=`read`, 두뇌훈련=`calc`).
- 마스코트/일러스트는 STEP 7.

### 🔐 `auth/login_screen.dart`
- 상단 자물쇠 아이콘 → 라운드 박스(`primarySoft`) 안에 **브레인 버디 마스코트**(STEP 7).
- 입력칸은 테마의 `inputDecorationTheme` 가 자동 적용. 로그인 버튼은 `FilledButton`.

---

## STEP 6 — 차트(fl_chart) 스타일 `[부분 적용 · 참고 설정]`

이미 `fl_chart` 를 쓰고 있으니 **설정값만** 바꿉니다.

**리포트 — 곡선 영역 그래프**
```dart
LineChartData(
  gridData: const FlGridData(show: false),
  titlesData: const FlTitlesData(show: false),
  borderData: FlBorderData(show: false),
  lineBarsData: [
    LineChartBarData(
      spots: spots,
      isCurved: true, curveSmoothness: 0.35,
      color: MLColors.primary,
      barWidth: 3.5, isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (s, _) => s.x == spots.last.x, // 마지막 점만
        getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
          radius: 5, color: MLColors.primary, strokeColor: Colors.white, strokeWidth: 2.5),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [MLColors.primary.withValues(alpha: 0.28), MLColors.primary.withValues(alpha: 0.0)]),
      ),
    ),
  ],
)
```

**생활습관 — 둥근 막대 그래프** (`_makeGroupData` 의 rod 만 교체)
```dart
BarChartRodData(
  toY: y, width: 16, color: MLColors.primary,
  borderRadius: BorderRadius.circular(8),                       // 둥글게
  backDrawRodData: BackgroundBarChartRodData(
    show: true, toY: 12000, color: MLColors.primary.withValues(alpha: 0.10)),
)
```

---

## STEP 7 — 일러스트(마스코트) 적용 `[자산 준비 완료 · lib 미사용]`

현재 `flutter_svg` 의존성과 `assets/illustrations/brain_buddy.svg` 자산은 준비되어 있습니다.
다만 현재 `lib/`에서는 이 자산을 참조하지 않습니다. 실제 적용 시 예시는 다음과 같습니다.
```dart
import 'package:flutter_svg/flutter_svg.dart';
SvgPicture.asset('assets/illustrations/brain_buddy.svg', width: 92);
```
적용처: 로그인 히어로, 홈 헤더 우측, “vs AI” 게임의 ‘나’ 아바타, 기억의 정원 빈 상태.
색을 강조색에 맞춰 바꾸려면 `colorFilter: ColorFilter.mode(MLColors.primary, BlendMode.srcIn)` 사용.

---

## STEP 8 — 현재 체크리스트

- [x] 공용 라이트/다크 테마를 `lib/core/theme.dart`에 구성
- [x] 공용 위젯을 `lib/core/ml_widgets.dart`에 구성
- [x] 5개 탭에 `FloatingPillNav` 적용
- [x] 시스템 설정을 따르는 `ThemeMode.system` 적용
- [x] `NanumGothic` 폰트 번들 및 테마 적용
- [x] `flutter_svg` 의존성과 브레인 버디 SVG 자산 등록
- [ ] 브레인 버디를 실제 `lib/` 화면에 적용
- [ ] 리포트·프로필·온보딩·CS·관리자 매핑의 잔여 항목을 화면별 재검토
- [ ] 다크 모드 카드/텍스트 대비와 플로팅 네비 하단 가림을 전체 화면에서 회귀 점검
- [ ] 남은 하드코딩 색을 필요에 따라 `MLColors.*`로 정리
- [ ] 전체 `flutter analyze`, `flutter test`, `flutter build` 상태는 프로젝트의 최신 QA 문서와 실행 결과로 확인

### 역사적 권장 적용 순서
`theme.dart` → `FloatingPillNav`(STEP 4) → 홈 → 트레이닝 센터 → 리포트 → 생활습관 → 내 정보 → 로그인 → 정원.
이 순서는 신규 포팅 순서를 기록한 것이며, 현재 유지보수 우선순위는 최신 로드맵을 따릅니다.

---

## STEP 9 — 잔여 화면 매핑 (첫 실행 · 게임 · CS · 관리자) `[부분 적용 · 백로그 참고]`

아래 매핑은 첫 실행, 게임, CS, 관리자 화면의 디자인 참고안입니다. 일부는 적용되었지만 전체 완료를
의미하지 않으며, 특히 데이터와 라우팅은 작성 당시와 달라졌을 수 있습니다.

### 첫 실행 플로우
- `onboarding/consent_screen.dart` — `CheckboxListTile` → 동의 카드 행: `MLCard` 안에 체크박스(라벤더) + 제목 + `필수/선택` `MLStatusPill`(필수=bad, 선택=textSoft 톤). 필수 모두 체크 시 하단 `FilledButton` 활성.
- `onboarding/onboarding_screen.dart` — 목적 카드(`_buildGoalCard`)를 `MLIconTile`(예방=mem, 우려=calc, 가족=care) + 선택 시 라벤더 보더·우측 체크 원. 시안 `사용 목적` 참고.
- `auth/register_screen.dart` — 입력칸은 `inputDecorationTheme` 자동 적용. 관심 분야 3-세그먼트 칩, "선택 정보" `ExpansionTile` 유지. 시안 `회원가입`.
- `assessment/assessment_screen.dart` — 상단 `LinearProgressIndicator`(라벤더), 가운데 질문(큰 타이포) + 마스코트, 하단 [예 / 아니오] 큰 버튼(선택=primary). 시안 `자가 체크`.
- `assessment/result_screen.dart` — 원형 테두리 점수 → `MLRing`(점수 색=good/warn/bad). 하단 의료 면책 배너는 warn 톤 카드. 시안 `검사 결과`.

### 게임 (`training/games/*` + `widgets/game_template.dart`)
- `GameTemplate` 를 시안 **GameShell** 형태로 한 번만 리스타일하면 7개 게임에 일괄 반영:
  AppBar(닫기·목표시간 칩·`n/총`), 라벤더 `LinearProgressIndicator`, `primarySoft` 목표 카드.
- 선택지/정답 = `primary` 채움, 미선택 = `surface`+`line` 보더(라운드 16~18). 정답 강조는 `good`.
- 화면별: 비교(누가 큰가요?)=좌/우 카드+VS, 구구단=수식+4지선다 그리드, 범주화=단어칩+세로 보기,
  수열=숫자박스+?+4지선다, 스도쿠=그리드+심볼 보기+권장시간 칩, 모양찾기=큰 도형+그리드,
  문장읽기=문장 카드+마이크 FAB, 음성평가=마이크 비주얼라이저+녹음 버튼.

### 프로필 · CS
- `profile/edit_profile_screen.dart` — 아바타(라운드 사각 + 카메라 배지) + 섹션별 `EditField`(아이콘+값). 시안 `정보 수정`.
- `cs/cs_center_screen.dart` — 메뉴 4개를 `MLCard`+`MLIconTile`(색 calc/mem/care/read). 상단 헤드셋 히어로.
- `cs/faq_screen.dart` — 카테고리 헤더(primary) + `ExpansionTile`을 `MLCard`로, 펼침 답변은 `primarySoft` 박스.
- `cs/inquiry_submit_screen.dart` — 제목/내용 입력(자동 테마) + 글자수 카운터 + `FilledButton`.
- `cs/my_inquiries_screen.dart` — 행마다 `MLCard` + 답변완료=good / 대기중=warn `MLStatusPill`, FAB는 라벤더 pill.
- `cs/notice_list_screen.dart` — `MLCard` + 고정 배지(primary) + 제목/본문 2줄/날짜.
- `referral/referral_screen.dart` — 기관 카드(`MLCard` + tonal 버튼) + "통합 연계" `FeatureRow`(라벤더 보더).

### 관리자 (`admin/*`) — 내부용, 어두운 톤 유지
- AppBar 를 `MLColors.primary` 배경 + 흰 글씨로(사용자 앱과 구분). 요약 카드 3개, 위험 사용자 = `bad` 톤,
  평균 점수 = **STEP 6 막대 차트**, 회원 목록 = 이니셜 아바타 행. 로그인은 다크 배경 + 라벤더 버튼.
  관리자는 데이터 밀도가 우선이라 사용자 앱만큼 부드럽게 만들 필요는 없습니다.

---

## STEP 10 — 초기 디자인 기준값과 현재 상태

아래 값은 초기 시안의 기준값입니다. 더 이상 변경 불가한 “LOCKED” 계약이 아니며,
현재 동작은 `lib/core/theme.dart`, `lib/core/ml_widgets.dart`, `lib/main.dart`를 우선합니다.

| 항목 | 초기 기준 | 현재 상태 / source of truth |
|---|---|---|
| 강조색(Primary) | `#6C5CE7` (라벤더) | 현재 `lib/core/theme.dart`의 `MLColors.primary`에 유지 |
| 그라디언트 | `#7C6FF0 → #9E7DF6` | 현재 `lib/core/theme.dart`의 `MLColors.grad`에 유지 |
| 테마 모드 | 라이트 기본 | 현재 `lib/main.dart`에서 `ThemeMode.system` 사용 |
| 폰트 | Pretendard 제안 | 현재 `NanumGothic`; Pretendard는 선택 사항이며 미적용 |
| 글자 크기 배수 | 1.0 기본 | `SettingsProvider` 값과 `lib/main.dart`의 `TextScaler`로 런타임 반영 |
| 모서리 둥글기 | 카드 26 · 버튼 14 · 타일 16 | 현재 `lib/core/theme.dart`의 토큰에 유지 |
| 캐릭터 마스코트 | 브레인 버디 사용 계획 | SVG 자산/의존성은 있으나 현재 `lib/`에서 미사용 |
| 하단 네비 | 플로팅 알약 | 현재 `lib/core/ml_widgets.dart`와 `main_nav_screen.dart`에 적용 |

> 색 변경 시에도 `MLColors.primary`와 `MLColors.grad`만으로 모든 화면이 자동 변경된다고 가정하지 말고,
> 남아 있는 직접 지정 색과 화면별 스타일을 함께 검색해 확인해야 합니다.
