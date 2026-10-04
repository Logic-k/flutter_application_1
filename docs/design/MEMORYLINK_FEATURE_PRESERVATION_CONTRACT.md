# MemoryLink 기능 보존·비회귀 계약

> 작성: 2026-09-28 · 목적: 디자인·모션 개편이 현재 기능, 경로, 저장, 권한, 폴백, 안전 동작을 바꾸지 않도록 고정한다.
> 코드가 문서보다 우선한다. 이 문서는 `lib/core/router.dart`, `training_catalog.dart`, Provider/Service/DB 코드, 테스트와 `run_maestro_tests.ps1`을 직접 대조해 작성했다.

## 1. 현재 정본 수치

| 항목 | 코드에서 재계산한 값 | 정본 |
|---|---:|---|
| GoRouter 경로 | **44** | `lib/core/router.dart`의 `GoRoute(` 수 |
| 메인 탭 | **5** | 홈·인지훈련·생활습관·리포트·내정보 |
| 훈련 활동 | **8** | 점수형 7 + 참여형 일상 회상 1 |
| SQLite v9 테이블 | **10** | users, scores, steps, DAU, diary, health, training progress 4종 |
| 일반 테스트 파일 | **53** | `test/**/*_test.dart` 현재 파일 수 |
| 일반 테스트 case | **394 / 394 통과** | 2026-09-28 `flutter test` 실측 |
| 통합 테스트 | **2파일 · 4 / 4 통과** | 2026-09-28 `emulator-5554`, `IS_EMULATOR=true` 실측 |
| Maestro 게이팅 | **21** | `run_maestro_tests.ps1`의 `$flows` 배열 |
| Maestro 최상위 YAML | **28** | 게이팅 외 데모·촬영 포함 |

`DEVELOPMENT_ROADMAP.md`의 320건/44파일 수치는 과거 실측 체크포인트다. 구현 단계의 합격 여부는 문서 숫자가 아니라 그 시점에 직접 실행한 `flutter test` 결과와 **기존 테스트 감소 0**으로 판정한다.

## 2. 절대 금지선

디자인 PR에서 다음을 하지 않는다.

1. 44개 `GoRoute`를 삭제·이름 변경·병합하지 않는다.
2. 5탭 순서, 라벨, `IndexedStack`, `FloatingPillNav`, 각 탭의 상태 보존 의미를 바꾸지 않는다.
3. 로그인·온보딩·관리자 redirect 조건을 바꾸지 않는다.
4. `onboardingRoutes`의 `/dementia_centers`를 제거하지 않는다. 제거하면 고위험 결과의 센터 안내가 `/consent`로 역류한다.
5. `trainingCatalog`의 ID, route, 점수 category, prerequisite, initial unlock을 바꾸지 않는다.
6. SQLite 스키마·마이그레이션·CRUD·초기화 삭제 범위를 바꾸지 않는다.
7. Firestore collection/field/ownerUid/token 구조를 바꾸지 않는다.
8. 센서 샘플링, 보행 계산, 이상 감지 임계값, 인지 점수·XP·난이도 알고리즘을 바꾸지 않는다.
9. 권한 요청 시점, 거부 시 graceful fallback, 익명 Firebase Auth를 바꾸지 않는다.
10. AI 제공자 우선순위 `Gemma local > Gemini > LocalFallback`을 바꾸지 않는다.
11. 임상/의료 문구, 점수 밴드, PDF 내용 의미를 디자인 PR에서 변경하지 않는다.
12. `/voice_assessment`의 “현재 중지” 상태를 다시 활성화하거나 삭제하지 않는다.
13. `ThemeMode.light` 고정을 임의로 해제하지 않는다. 다크 모드는 별도 대비·회귀 작업이다.
14. 새 상태관리·라우팅·애니메이션 패키지를 추가하지 않는다.
15. 기존 자동화 assertion을 새 UI에 맞추기 위해 약화하거나 삭제하지 않는다. 의미가 같은 새 selector로만 갱신한다.

허용되는 변경은 레이아웃, 색·타입 토큰 적용, 공통 컴포넌트화, 상태 표현, 접근성, 목적 기반 모션, 화면별 UI 책임 분리다. 사용자에게 보이는 결과와 저장 부작용은 동일해야 한다.

## 3. 44개 GoRouter 경로 보존표

| # | 경로 | 화면·기능 | 반드시 보존할 계약 |
|---:|---|---|---|
| 1 | `/` | MainNavScreen | 5탭 상태 보존, floating nav, 로그인 후 기본 목적지 |
| 2 | `/login` | 로그인 | SQLite 자격 검증, 세션 토큰 저장, 실패 문구 |
| 3 | `/register` | 회원가입 | 계정 생성, 초기 5개 활동 unlock, `/consent` 이동 |
| 4 | `/onboarding` | 목표 선택 | 목표 선택 후 `/assessment` |
| 5 | `/consent` | 개인정보 동의 | 필수 동의 후 온보딩 진행 |
| 6 | `/assessment` | 초기 설문 | 설문 응답 유지, `/cognitive_tasks` |
| 7 | `/cognitive_tasks` | 초기 인지 과제 | 기존 과제·채점·점수 저장, 결과 이동 |
| 8 | `/assessment_result` | 초기 결과 | 온보딩 완료, 고위험 센터 안내, 홈 이동 |
| 9 | `/report_options` | 4단계 PDF 옵션 | 유형·위험요인·보호자 동반·확인, preview/share |
| 10 | `/training_hub` | 훈련 허브 | 진행도·잠금·오늘 목표·기록 진입 |
| 11 | `/training_history` | 훈련 기록 | 사용자별 시도, 날짜, 활동 필터 |
| 12 | `/game/comparison` | 비교 게임 | calculation 점수·난이도·XP·unlock |
| 13 | `/game/sequence` | 수열 게임 | logic 점수·난이도·XP·unlock |
| 14 | `/game/sudoku` | 그림 스도쿠 | memory 점수·난이도·XP |
| 15 | `/game/multiplication` | 구구단 | comparison 선행조건, calculation 점수 |
| 16 | `/game/shape_match` | 같은 모양 찾기 | attention 점수, perception 난이도 |
| 17 | `/game/categorization` | 범주화 | sequence 선행조건, logic 점수 |
| 18 | `/game/reading` | 문장 읽기 | shape_match 선행조건, voice 점수, STT |
| 19 | `/memory_garden` | 일기 작성 | 오늘만 편집, 과거 조회, 월 marker, STT, SQLite upsert |
| 20 | `/diary_book` | 일기 모아보기 | 날짜 내림차순, 빈 상태, 카드 탭 복귀 |
| 21 | `/guardian_link` | 보호자 연결 | token/QR, 수동 sync, tel/sms/share, 실패 노출 |
| 22 | `/voice_assessment` | 중지 안내 | 정확도 개선 전 중지 상태 유지 |
| 23 | `/dementia_centers` | 센터 찾기 | 지역 필터, CSV, 전화·지도, 1899-9988 |
| 24 | `/ai_chat` | AI 회상 대화 | STT, 10턴, provider fallback, 종료 분석, 명시적 점수 저장 |
| 25 | `/walking_dashboard` | 생활습관 | 추적 토글, 권한, daily_steps, gait session, 주간 차트 |
| 26 | `/training/recall` | 일상 회상 | 항상 unlock, 참여형 완료·XP, 점수 category 없음 |
| 27 | `/profile` | 프로필 단독 진입 | 탭과 동일 기능, 편집·설정·건강·연결 링크 |
| 28 | `/ondevice-ai` | Gemma 모델 | HF token, 다운로드 progress, provider 전환, 삭제 |
| 29 | `/settings` | 통합 설정 | 접근성·알림·AI·계정·데이터 초기화·라이선스·로그아웃 |
| 30 | `/health_input` | 건강 기록 | 일별 upsert, 14일 추세, 수면·혈압·혈당·식이·메모 |
| 31 | `/cs_center` | 고객센터 허브 | 공지·FAQ·문의·내 문의 4개 진입 |
| 32 | `/cs/notices` | 공지 목록 | Firestore 목록·빈/오류·상세 이동 |
| 33 | `/cs/notice_detail/:id` | 공지 상세 | id 전달·조회 |
| 34 | `/cs/faq` | FAQ | Firestore 카테고리/목록·빈/오류 |
| 35 | `/cs/inquiry_submit` | 1:1 문의 | 입력·제출·성공 피드백 |
| 36 | `/cs/my_inquiries` | 내 문의 | 사용자별 목록·상세·새 문의 |
| 37 | `/cs/inquiry_detail/:id` | 문의 상세 | 문의와 replies 조회 |
| 38 | `/admin_login` | 관리자 로그인 | digest 검증, 릴리스 포털 비활성 정책 |
| 39 | `/admin/dashboard` | 관리자 대시보드 | DAU/WAU/사용자/점수/위험군, admin guard |
| 40 | `/admin/user_detail/:userId` | 사용자 상세 | 사용자별 점수 이력 |
| 41 | `/admin/cs_management` | 관리자 CS | 공지·FAQ·문의 관리 |
| 42 | `/admin/notice_edit` | 공지 작성·수정 | `state.extra` 초기값, 생성/수정/삭제 |
| 43 | `/admin/faq_edit` | FAQ 작성·수정 | `state.extra` 초기값, 생성/수정/삭제 |
| 44 | `/admin/inquiry_detail/:id` | 문의 답변 | reply batch + 문의 상태 update |

### Redirect 불변조건

- 미로그인 일반 사용자가 auth 외 경로 접근 → `/login`.
- 로그인 사용자가 `/login`·`/register` 접근 → 온보딩 미완료면 `/consent`, 완료면 `/`.
- 온보딩 미완료 사용자는 whitelist 6경로만 접근 가능.
- admin portal disabled 빌드에서 모든 `/admin*` → 일반 로그인 상태에 따라 `/` 또는 `/login`.
- `/admin_login` 외 admin 경로는 admin 세션 없으면 `/admin_login`.

## 4. GoRouter 밖의 사용자 표면

| 표면 | 진입 | 보존할 기능 |
|---|---|---|
| MemoryOpening | 앱 cold start | 설정 로드 후 시작, 로그인 확인과 겹침, skip, reduce motion |
| EditProfileScreen | 프로필·설정의 MaterialPageRoute | 이름·사진·의료정보 저장, camera/gallery/remove |
| PDF Preview | 리포트 옵션의 MaterialPageRoute | 파일 읽기, preview, print, app bar share |
| TrainingResultSheet | 게임 완료 bottom sheet | 점수·XP·unlock·목표·계속하기 |
| 이미지 선택 sheet | 프로필 편집 | gallery/camera/remove |
| API key dialog/editor | AI chat·설정 | 저장·삭제·provider 재선택 |
| 설정 dialog | 초기화·로그아웃·model 삭제 | 취소·확인·오류·중복 실행 방지 |
| 홈 알림 dialog | 홈 app bar | 현재 알림 상태 안내 |
| Open-source license | 설정 | Pretendard OFL 포함 license page |
| 외부 URL | privacy, AI Studio, HuggingFace, center map | system browser/지도 앱, 실패 피드백 |
| 전화·문자 | guardian, dementia center, anomaly notification | system tel/sms 앱 |
| System share | guardian link, PDF | Android/iOS sharesheet |

디자인 개편은 위 표면을 “라우터에 없으므로 미사용”으로 판단해 삭제하면 안 된다.

## 5. 데이터·권한·폴백 계약

### 5.1 SQLite v9

| 데이터 | 쓰기 | 읽기·표시 | 보존 조건 |
|---|---|---|---|
| users/session | register/login/edit/settings | auth/profile/router | password hash+salt, random session token, legacy migration 유지 |
| training_scores | 평가·게임·AI 결과 저장 | 홈·리포트·관리자·guardian | category와 0~100 의미 유지 |
| training_attempts/progress/unlocks | completion service | 허브·기록·홈 | attempt idempotency, XP, streak, prerequisite 유지 |
| daily_steps | background/pedometer | 홈·walking·guardian | 사용자·날짜 분리, 거리·칼로리 계산 유지 |
| daily_active_users | login/auto-login | admin | 일자별 insert-or-ignore 유지 |
| diary_entries | diary save | 달력·모아보기 | 하루 1건 upsert, 3년 보관, 오늘만 편집 UI 유지 |
| health_logs | health save | 건강 추세·PDF data | 하루 1건, nullable vitals, 최근 14일 유지 |

**데이터 초기화의 정확한 범위:** training 진행 4개 테이블(`training_attempts`, `training_user_progress`, `training_activity_progress`, `training_unlocks`)과 `training_scores`, `daily_steps`, `health_logs`만 삭제한다. `users`, `diary_entries`, `daily_active_users`, guardian token과 설정은 삭제하지 않는다. UI 문구와 실제 범위가 계속 일치해야 한다.

### 5.2 AI

- 대화 메시지는 현재 화면 메모리에만 존재하며 자동 영구 저장되지 않는다.
- 종료 시 사용자 발화로 LocalAI 분석을 수행한다.
- 결과는 사용자가 `결과 저장하기`를 눌렀을 때만 `voice` score로 SQLite에 저장한다.
- provider 우선순위는 local model → Gemini API → rule fallback이다.
- API key/HF token은 SharedPreferences, model은 내부 파일로 관리한다.
- 오류/키 없음에서도 LocalFallback이 응답해야 한다. 디자인이 로딩 상태를 영구 고정하면 안 된다.

### 5.3 보행·센서·알림

- 추적 토글 시 activityRecognition과 notification을 함께 요청하되 측정 필수 권한은 activityRecognition이다.
- 거부·중복 요청 `PlatformException` 시 앱이 크래시하지 않고 추적 off로 남아야 한다.
- background service는 사용자 설정이 켜지고 권한이 있을 때만 실행한다.
- logout/계정 전환 시 이전 사용자의 추적·수치를 새 사용자에게 섞지 않는다.
- gait session은 현재 `GaitProvider` 메모리 요약만 제공하고 DB에 저장하지 않는다.
- 이상 감지는 `StepAnomalyPolicy` 단일 정책을 사용한다.
- Firestore anomaly sync 실패 시 로컬 알림이 직접 문자 전송을 안내해야 한다.

### 5.4 Firestore

- Firebase 초기화 실패 시 로컬 전용 모드로 앱이 계속 실행된다.
- Anonymous Auth의 `ownerUid` 소유권 모델을 유지한다.
- `guardian_views/{token}` 필드와 16자 `Random.secure` token을 유지한다.
- CS는 `notices`, `faqs`, `inquiries`, `replies` 구조를 유지한다.
- guardian sync의 `global_stats/score_stats` 업데이트는 UI가 제거됐어도 현재 부작용이다. 디자인 PR에서 제거하지 않고 별도 제품 결정으로 다룬다.

### 5.5 설정 SharedPreferences

`username`, `session_token`, `font_size`, `voice_guidance`, `haptic_feedback`, `reduce_motion`, `sound_effects`, `diary_reminder_enabled`, Gemini API key, HF token, guardian token, pedometer baseline을 보존한다. 저장 key 이름을 디자인 리팩터링 중 변경하지 않는다.

## 6. 기존 자동화 방어선

| 기능군 | 기존 방어선 |
|---|---|
| 로그인·실패·가입 | Maestro login/login_fail/register + auth integration |
| 5탭·홈 | navigation, home_detail, profile, reports Maestro |
| 훈련 | hub/game/progression/persistence/accessibility Maestro + 다수 unit/widget + training integration |
| AI | ai_chat Maestro, LocalAI 단위 경로 일부 |
| 일기 | memory_garden Maestro + diary 간접 widget 경로 |
| 리포트/PDF | reports/clinical_report Maestro + report data/analyzer unit |
| 보호자 | guardian_link Maestro + anomaly policy unit |
| 센터 | dementia_center Maestro + CSV/repository/widget test |
| 모션·디자인 | app_motion, token guard, palette guard, contrast, press/stagger/opening widget tests |
| 보행·건강 | gait analyzer/session/walking/health widget tests |
| CS | cs_center Maestro, 화면별 오류 처리 코드 |

### 현재 사각지대

1. 전체 44경로와 redirect 정책을 잠그는 router test가 없다.
2. `MainNavScreen` 안에서 5개 탭과 floating nav를 함께 검증하는 셸 통합 widget test가 부족하다.
3. 이 계획 작성 시점 기준 일반 테스트는 394/394 통과했다. 구현 wave 시작마다 다시 실행해 감소·회귀를 차단해야 한다.
4. 두 integration test는 `emulator-5554`, `IS_EMULATOR=true`에서 4/4 통과했지만 `run_maestro_tests.ps1` 게이팅에는 포함되지 않는다.
5. PDF 생성 파일의 magic bytes/page count를 확인하는 단위 테스트가 없다.
6. GuardianSync Firestore 성공·실패와 `syncAnomalyAlert` contract test가 없다.
7. `AiChatService` 3단 provider 선택과 네트워크 실패 fallback contract test가 없다.
8. 320dp × text scale 2.0 전 화면 matrix가 없다.
9. TalkBack/VoiceOver의 실제 읽기 순서와 Switch/Voice Access 실기기 검증이 없다.
10. profile mode frame·rebuild·startup 성능 기준선이 없다.
11. admin 7개 경로를 실제 E2E로 보호하는 게이팅 flow가 없다.
12. 상태 복원(앱 background/lock/orientation)과 폼 입력 보존 검증이 없다.

## 7. 모든 디자인 PR의 합격 게이트

### 자동

```text
flutter analyze
flutter test
flutter test integration_test/
run_maestro_tests.ps1
```

- analyze error/warning 0, 기존 info 증가 0.
- 기존 테스트 파일·테스트 case 감소 0.
- integration test 전부 통과.
- Maestro 게이팅 21/21 통과. selector가 바뀌어도 assertion 의미는 약화하지 않는다.

### 화면·접근성

- 320dp, 360dp, 600dp, 840dp에서 기능 parity.
- text scale 1.0/1.3/1.6/2.0에서 정보·버튼 손실 0.
- Android 48dp 최소; MemoryLink 주요 CTA 56dp. floating nav 48dp 예외 유지.
- 일반 텍스트 4.5:1, 큰 텍스트·필수 비텍스트 3:1.
- 색 없이 상태를 이해 가능.
- full/fadeOnly/none에서 정보와 결과가 동일.
- TalkBack/VoiceOver/Voice Access로 모든 핵심 기능 도달.
- back/predictive back에서 데이터 손실 0.

### 기능

디자인 변경 전후 동일 fixture로 SQLite row와 Provider 결과를 비교한다. 화면만 달라지고 다음은 같아야 한다.

- 로그인 목적지와 onboarding guard
- 점수·XP·잠금·난이도
- 일기·건강·걸음 row
- AI 저장 시점과 category
- guardian 문서 payload
- PDF 데이터 모델
- reset 삭제 범위
- admin gate

## 8. 롤백 원칙

- 커밋 단위는 토큰 한 묶음 또는 화면 한 개다.
- 기능 로직과 시각 리팩터링을 같은 커밋에 섞지 않는다.
- 큰 화면은 새 presentation widget을 병렬로 만든 뒤 동일 ViewModel/Provider에 연결한다.
- 런타임 디자인 플래그가 필요하면 `AppConfig`에 새 플래그를 **제안·추가**할 수 있으나 현재 존재하는 기능으로 간주하지 않는다.
- 접근성 수정과 데이터 안전 수정은 구 UI로 롤백하지 않는다.
- 게이트 실패 시 다음 화면으로 진행하지 않고 해당 화면 커밋만 되돌린다.
