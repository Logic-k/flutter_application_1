# 트랙 A — MemoryLink 기능 인벤토리 & 비회귀 계약

> 작성 2026-09-28 · 방법: `lib/` 코드 직접 판독(문서 아님). 코드가 정본.
> 목적: 전 화면 디자인·모션 개선 시 **깨지면 안 되는 사용자 기능·데이터·불변조건**을 빠짐없이 고정.
> 코드는 수정하지 않았다. 이 문서는 진단·계약 문서다.

---

## 0. 검증 방법과 정본 규칙

- 진입점·경로·데이터·상태를 `lib/core/router.dart`, 각 feature screen/provider/service/repository에서 직접 읽어 확인.
- 문서(README/PROJECT_DOCS)와 코드가 다르면 **코드가 정본**이며 §7에 불일치를 표시.
- 자동화 방어선은 `run_maestro_tests.ps1`(게이팅 21) + `test/**`(320 통과, 44 파일, `DEVELOPMENT_ROADMAP.md §1` 실측) + `integration_test/`(2, 게이팅 외)에서 확인.

---

## 1. 경로 인벤토리 — GoRouter 44개 (router.dart 실측)

`createAppRouter`의 `routes:` 배열에 **정확히 44개** `GoRoute`가 있다(수동 카운트 확인). 7개 게임 경로는 `trainingActivityById('...').route`로 catalog에서 끌어오므로 하드코딩 문자열이 아니다 — **불변조건: 경로 문자열의 유일한 출처는 `training_catalog.dart`.**

### 1.1 인증·온보딩 게이트 (redirect 로직 = 최우선 불변조건)
| # | 경로 | 화면 | 게이트 불변조건 |
|---|---|---|---|
| 1 | `/login` | LoginScreen | 비로그인 기본 진입. 로그인+온보딩 완료 시 `/`, 미완료 시 `/consent` |
| 2 | `/register` | RegisterScreen | 성공 시 `context.go('/consent')` |
| 3 | `/` | MainNavScreen | 로그인 필수. 온보딩 미완료면 `/consent`로 밀림 |
| 4 | `/consent` | ConsentScreen | onboardingRoutes 집합 원소. → `/onboarding` |
| 5 | `/onboarding` | OnboardingScreen | → `/assessment` |
| 6 | `/assessment` | AssessmentScreen | → `/cognitive_tasks` |
| 7 | `/cognitive_tasks` | CognitiveTasksScreen | → `/assessment_result` |
| 8 | `/assessment_result` | AssessmentResultScreen | 고위험 시 `/dementia_centers` 안내, 완료 시 `/` |

> **redirect 불변조건 (절대 보존):**
> - `onboardingRoutes` 집합에 `/dementia_centers` 포함. **빠지면 초기평가 고위험 안내 버튼이 `/consent`로 되돌아간다** (router.dart 주석 명시).
> - `!AppConfig.isAdminPortalEnabled`면 `/admin*` 전체 → 홈/로그인. UI 숨김만으로는 딥링크·`adb am start` 못 막음.
> - `isAdminRoute && !adminLoggedIn` → `/admin_login`. `/admin_login`은 가드 제외.
> - 신규 가입자는 `hasCompletedOnboarding`까지 onboardingRoutes 밖 진입 불가.

### 1.2 메인 기능 경로
| # | 경로 | 화면 |
|---|---|---|
| 9 | `/report_options` | ClinicalReportOptionsScreen |
| 10 | `/training_hub` | TrainingHubScreen |
| 11 | `/training_history` | TrainingHistoryScreen |
| 12 | `/game/comparison` | ComparisonGame (catalog: comparison) |
| 13 | `/game/sequence` | SequenceGame |
| 14 | `/game/sudoku` | ShapeSudokuGame (id: shape_sudoku) |
| 15 | `/game/multiplication` | MultiplicationGame |
| 16 | `/game/shape_match` | ShapeMatchGame |
| 17 | `/game/categorization` | CategorizationGame |
| 18 | `/game/reading` | SentenceReadingGame (id: sentence_reading) |
| 19 | `/memory_garden` | DiaryScreen |
| 20 | `/diary_book` | DiaryBookScreen |
| 21 | `/guardian_link` | GuardianLinkScreen |
| 22 | `/voice_assessment` | VoiceAssessmentBlockedScreen (중지 안내) |
| 23 | `/dementia_centers` | DementiaCenterFinderScreen |
| 24 | `/ai_chat` | AiChatScreen |
| 25 | `/walking_dashboard` | WalkingDashboardScreen |
| 26 | `/training/recall` | DailyRecallPage (id: daily_recall) |
| 27 | `/profile` | ProfileScreen |
| 28 | `/ondevice-ai` | ModelDownloadScreen |
| 29 | `/settings` | SettingsScreen |
| 30 | `/health_input` | HealthInputScreen |

### 1.3 CS센터 (사용자)
| # | 경로 | 화면 | 파라미터 |
|---|---|---|---|
| 31 | `/cs_center` | CsCenterScreen | |
| 32 | `/cs/notices` | NoticeListScreen | |
| 33 | `/cs/notice_detail/:id` | NoticeDetailScreen | pathParam id |
| 34 | `/cs/faq` | FaqScreen | |
| 35 | `/cs/inquiry_submit` | InquirySubmitScreen | |
| 36 | `/cs/my_inquiries` | MyInquiriesScreen | |
| 37 | `/cs/inquiry_detail/:id` | InquiryDetailScreen | pathParam id |

### 1.4 관리자 포털 (AppConfig 게이트)
| # | 경로 | 화면 | 파라미터 |
|---|---|---|---|
| 38 | `/admin_login` | AdminLoginScreen | |
| 39 | `/admin/dashboard` | AdminDashboardScreen | |
| 40 | `/admin/user_detail/:userId` | AdminUserDetailScreen | int userId |
| 41 | `/admin/cs_management` | AdminCsManagementScreen | |
| 42 | `/admin/notice_edit` | AdminNoticeEditScreen | extra Map(id,title,body,is_pinned) |
| 43 | `/admin/faq_edit` | AdminFaqEditScreen | extra Map(id,category,question,answer) |
| 44 | `/admin/inquiry_detail/:id` | AdminInquiryDetailScreen | pathParam id |

---

## 2. 비라우트 UI 인벤토리 (grep + 판독 확인)

라우터에 없지만 사용자가 실제로 도달하는 화면·상호작용. **리디자인 시 이 진입점들을 잃지 말 것.**

### 2.1 IndexedStack 탭 셸 — `main_nav_screen.dart`
- 5탭 `IndexedStack`: `[0]HomeScreen · [1]TrainingHubScreen · [2]WalkingDashboardScreen · [3]ReportsScreen · [4]ProfileScreen`.
- `FloatingPillNav`가 bottomNav (BottomNavigationBar 아님 — 교체 시 통합테스트 단언 낡음, §7).
- **불변조건:** 숨은 탭은 `TickerMode(enabled: i==selected)`로 꺼 둔다 — 진입 안무(StaggeredColumn)를 처음 그 탭을 여는 순간 1회 재생시키기 위함. `extendBody:true` + `FloatingPillNav.contentBottomInset`로 마지막 콘텐츠 가림 방지.

### 2.2 MaterialPageRoute (라우터 밖 push)
| 진입점 | 대상 | 위치 |
|---|---|---|
| ProfileScreen (2곳), SettingsScreen '프로필 편집' | EditProfileScreen | profile_screen.dart:31,154 · settings_screen.dart:230 |
| ClinicalReportOptions '미리보기' | `_PdfPreviewPage` | clinical_report_options_screen.dart:89 |

> **불변조건:** EditProfileScreen은 GoRoute가 없다 — 오직 MaterialPageRoute로만 도달. 라우트화하지 않는 한 이 push들을 제거하면 프로필 편집 진입 불가.

### 2.3 showDialog
| 다이얼로그 | 내용 | 위치 |
|---|---|---|
| 홈 알림 | "새로운 알림이 없습니다" AlertDialog | home_screen.dart:90 |
| AI 키 설정 | `_ApiKeyDialog` (저장/삭제/취소, obscure 입력) | ai_chat_screen.dart:167 |
| 데이터 초기화 확인 | StatefulBuilder + resetMeasurementData + progress refresh | settings_screen.dart:520 |
| 로그아웃 확인 | logout → `context.go('/login')` | settings_screen.dart:459 |
| 온디바이스 모델 다운로드 확인 | showDialog<bool> | model_download_screen.dart:90 |
| 관리자 삭제 확인 | showDialog<bool> | admin_cs_management_screen.dart:282 |

### 2.4 showModalBottomSheet
| 시트 | 내용 | 위치 |
|---|---|---|
| 이미지 소스 선택 | ImageSource (카메라/갤러리) | edit_profile_screen.dart:58 |
| 훈련 완료 결과 | `TrainingResultSheet` — XP·별·잠금해제·컨페티. `isDismissible:false, enableDrag:false` | training_completion_ui.dart:40 |

> **불변조건:** TrainingResultSheet는 게임 완료의 유일한 결과 표시 경로. `isDismissible:false`·`onContinue`의 `Navigator.pop`로만 닫힘 — 임의로 dismiss 가능하게 만들면 점수 저장 흐름·게이팅 flow가 깨진다.

### 2.5 외부 전화/SMS/URL (url_launcher)
| 동작 | URI | 위치 | 조건 |
|---|---|---|---|
| 보호자 전화 | `tel:$phone` | guardian_link_screen.dart:289 | emergencyContact 있을 때 |
| 보호자 문자 | `sms:$phone?body=...` | guardian_link_screen.dart:311 | 대시보드 URL 포함 |
| 이상감지 알림 탭 | `sms:$emergencyContact` | pedometer_manager.dart:274 (`handleNotificationTap`) | payload 존재 시 |
| 개인정보 처리방침 | `AppConfig.privacyPolicyUrl` (externalApplication) | settings_screen.dart:449 | 실패 시 SnackBar |
| Gemini 키 발급 | `aistudio.google.com/app/apikey` | settings_screen.dart:409 | |
| 온디바이스 모델 안내 | launchUrl | model_download_screen.dart:197 | |
| 치매안심센터 전화/지도 | `_launch(uri, externalApplication)` | dementia_center_finder_screen.dart:360 | 실패 시 SnackBar 2종 |

### 2.6 공유 (share_plus)
| 동작 | 내용 | 위치 |
|---|---|---|
| 보호자 링크 공유 | `Share.share(url, subject)` (카톡 등) | guardian_link_screen.dart:334 |
| 임상 리포트 공유 | `Share.shareXFiles([XFile(pdf)])` | clinical_report_options_screen.dart:94, 669 |

### 2.7 PDF preview / share (printing + share_plus)
- `ClinicalReportGenerator.generate(reportData)` → `File` 생성 → 두 갈래:
  - **공유**: `Share.shareXFiles` (기본 버튼)
  - **미리보기**: `_PdfPreviewPage` (MaterialPageRoute) → `PdfPreview(allowPrinting:true, allowSharing:false)` + AppBar 공유 아이콘
- **불변조건:** 미리보기 화면의 인쇄 허용(`allowPrinting:true`)과 자체 공유 아이콘이 실제 출력 경로. 4단계 마법사(유형→위험요인→보호자동반→확인)의 PageView 순서·NeverScrollableScrollPhysics 보존.

### 2.8 기타 시스템 UI
- `showLicensePage` — SettingsScreen '오픈소스 라이선스' (Pretendard OFL 등록됨, main.dart `_registerFontLicense`).
- 관리자 진입 히든: `version_label.dart:21` — 버전 라벨 롱프레스 → `/admin_login` (릴리스는 AppConfig 게이트).

---

## 3. 기능별 상세 — 진입점·데이터·권한·상태·방어선·불변조건

### 3.1 인증 (auth) — SQLite + 세션 토큰
- **진입점:** `/login`, `/register`.
- **데이터 R/W:** SQLite users 테이블(`getUser`, `insertUser`, `getUserBySessionToken`, `setSessionToken`, `recordDauIfNeeded`). SharedPreferences: `username`·`session_token`(평문 비번 저장 안 함, 구버전 마이그레이션).
- **네트워크/권한:** 없음(로컬). Firebase Anonymous Auth는 부트스트랩에서 별도.
- **상태:** 성공(로그인·자동로그인)/실패(세션 무효 debugPrint)/신규(온보딩 미완). `checkLoginStatus`는 저장 세션 없으면 DB 안 염(콜드스타트 40s→회피).
- **방어선:** `user_provider_test.dart`, `login_screen_test.dart`, `auth_flow_test.dart`(통합, 낡음 §7), maestro `login_flow`·`login_fail_flow`·`register_flow`.
- **불변조건:** 자동로그인 토큰 방식·평문 비번 미저장. redirect 게이트(§1.1). `register`→`/consent`.

### 3.2 인지 훈련 (training) — 7게임 + daily_recall, 적응형 난이도
- **진입점:** 훈련 탭(TrainingHubScreen), 홈 추천(comparison/sequence), catalog 경로 8개.
- **데이터 R/W:** `SqliteTrainingProgressRepository`(training_progress·attempts). `TrainingCompletionService`가 시도 저장·잠금해제·XP·streak·mastery 계산. `UserProvider.setCognitiveScore(scoreCategory, persist:false)`로 점수 반영. DifficultyProvider(1~10, Firestore 재로딩).
- **권한/센서:** 없음. sentence_reading은 STT 가능성(게임 코드 확인 범위 밖이나 catalog scoreCategory 'voice').
- **상태:** 진행/정답·오답 피드백(색+아이콘+텍스트+햅틱)/완료(TrainingResultSheet)/잠금(prerequisiteId). `initialTrainingActivityIds`(5개 시작 개방).
- **방어선:** `training_completion_service_test`, `training_progress_provider/rules_test`, `training_catalog_test`, `game_template_test`, `scored_game_completion_test`, `daily_recall_completion_test`, `comparison/categorization_game_test`, `game_layout_overflow_test`, `game_semantics_text_test`, maestro `training_hub`·`training_game`·`training_progression`·`training_persistence`·`training_accessibility`.
- **불변조건:** catalog가 route·category·prerequisite의 유일 출처. 적응형 3연속 정답↑/2연속 오답↓, 1~10 클램프. 중복 제출은 attemptId(UUID)로 차단. 결과 시트 강제 표시. 게임 "VS" Semantics(explicitChildNodes). `nextQuestionDelay` 700ms(분류 게임), 정답/오답 배지 1.4초 머무름은 모션 4단 예외.

### 3.3 보행 분석 (gait) — 센서·백그라운드·이상감지·보호자
- **진입점:** 생활 탭(WalkingDashboardScreen), 홈 걷기 미니카드.
- **데이터 R/W:** SQLite daily_steps(`updateDailySteps`·`getTodaySteps`·`getWeeklySteps`). Firestore `guardian_views/{token}`·`global_stats` (GuardianSyncService).
- **권한/센서:** `Permission.activityRecognition`(필수), `Permission.notification`(포그라운드 알림). 가속도계·pedometer·flutter_background_service. 권한 중복요청 `_pendingPermissionRequest`로 합류(PlatformException→거부 간주).
- **상태:** 추적 on/off, 오늘 걸음·칼로리·거리, 주간 요약, 이상감지(StepAnomalyPolicy: 18시 이후·기준선 30% 미만). 로그아웃 시 추적 중지·0 리셋(계정 간 섞임 방지).
- **방어선:** `gait_analyzer_test`, `step_anomaly_policy_test`, `anomaly_monitor_test`, `walking_dashboard_screen_test`, `gait_session_card_test`.
- **불변조건:** 이상 판정의 유일 출처 `StepAnomalyPolicy`(pedometer와 guardian_sync가 같은 결론). 기준선에 오늘 제외. CV/걸음은 표본부족 시 null(0 아님). 칼로리 나이보정 0.4~1.0 클램프. 동기화 실패는 삼키지 않고 사용자 알림.

### 3.4 AI 회상 대화 (ai_chat) — Gemini/폴백 + STT
- **진입점:** `/ai_chat` (홈 AI 카드).
- **데이터 R/W:** `AiChatService.chat` (Gemini REST 또는 LocalFallback). 종료 시 `LocalAIService.analyzeText`(TTR·WPM) → 점수 → `UserProvider.setCognitiveScore('voice')` 저장(사용자 확인 후).
- **권한/센서:** 마이크(STT `speech_to_text`, ko_KR, 30s/3s). 네트워크(Gemini만; 폴백은 오프라인).
- **상태:** 세션시작(AI 인사)/진행(_aiTurnCount / 10)/로딩("AI가 생각 중")/종료·분석/빈 발화 거부(SnackBar). API키 다이얼로그.
- **방어선:** `speech_score_test`, maestro `ai_chat_flow`. (빈 상태 개선은 P0 백로그 — FINAL_REPORT §10.)
- **불변조건:** Gemini 키 없어도 폴백으로 동작. maxTurns=10. 사용자 발화 0이면 분석 안 함(0점 방지). 메시지 삽입 스크롤은 reduceMotion 시 jumpTo.

### 3.5 감정 일기 (diary / Memory Garden)
- **진입점:** `/memory_garden`(생활·홈), `/diary_book`(모아보기, AppBar 아이콘).
- **데이터 R/W:** DiaryProvider → SQLite diary(loadMonth·loadEntry·saveDiary). 홈이 `loadMonth`로 오늘 작성 여부 표시.
- **권한/센서:** 마이크 STT(ko_KR). 알림(저녁 7시 KST DiaryNotificationService).
- **상태:** 로딩(스켈레톤 크로스페이드)/오늘(편집+저장+음성)/과거(읽기전용 "수정 불가")/빈("작성하지 않았어요")/저장(SnackBar ✨). 미래 날짜 선택 차단.
- **방어선:** maestro `memory_garden_flow`. TableCalendar ko_KR, 365일 범위.
- **불변조건:** 과거 읽기전용·미래 차단. 저녁 알림 예약. STT partial은 base+recognized 교체(중복 누적 방지). 저장 성공 순간에만 성장 모션(FINAL_REPORT §4.4).

### 3.6 주간 리포트 + 임상 PDF (reports)
- **진입점:** 리포트 탭(ReportsScreen), `/report_options`(PDF 마법사).
- **데이터 R/W:** SQLite `getScoreHistory`. ReportAnalyzer 요약·권고. `ClinicalReportData.fromProviders` + `ClinicalReportGenerator.generate` → PDF File.
- **권한/센서:** 파일 공유(share_plus)·인쇄(printing). 네트워크 없음.
- **상태:** 로딩(스켈레톤)/정상(지표·차트·AI요약·권고)/빈(0 스팟 7개 고정). 마법사 4단계.
- **방어선:** `clinical_report_data_test`, `report_analyzer_test`, maestro `reports_flow`·`clinical_report_flow`.
- **불변조건:** 차트는 기준선(최솟값)에서 자람, reduceMotion 시 즉시 실값. 월~일 라벨 고정. tabular figures. 임상 면책 문구("선별 목적, 진단 대체 아님"). 자체 지표명(activityIndex 등, MMSE 아님 — ROADMAP §2). PDF는 Pretendard .ttf.

### 3.7 보호자 연계 (profile/guardian) — QR·Firestore·직접연락
- **진입점:** `/guardian_link` (프로필·설정).
- **데이터 R/W:** GuardianSyncService.getOrCreateToken(SharedPreferences `guardian_token_{userId}`), syncToFirestore(guardian_views/{token}), _updateGlobalStats. QR(qr_flutter)로 `guardian.html?token=` 인코딩.
- **권한/센서:** 네트워크(Firestore). tel/sms(url_launcher). Share.
- **상태:** 미동기화/동기화중/성공(시각)/실패(error SnackBar)/이상감지 배너.
- **방어선:** maestro `guardian_link_flow`.
- **불변조건:** 토큰 16자 암호학적 난수(URL만으로 열람 가능하므로). ownerUid=AuthService.uid(Firestore 규칙 소유권). 평상시 요약만, 이상 시에만 상황설명+비상연락처(TTA 표준 매핑). 동기화 실패 사용자 통지.

### 3.8 프로필·건강기록·설정
- **진입점:** 프로필 탭. `/settings`·`/health_input`·EditProfileScreen(MaterialPageRoute)·`/voice_assessment`(중지)·`/dementia_centers`·`/cs_center`·`/guardian_link`.
- **데이터 R/W:** UserProvider.updateMedicalInfo/updateName/updateUsername. HealthInput(혈압·혈당 등). SettingsProvider(fontSize·voice·haptic·sound·reduceMotion). SharedPreferences `diary_reminder_enabled`. AiKeyService.
- **권한/센서:** 카메라/갤러리(프로필 이미지, image bottom sheet). 알림 토글.
- **상태:** 설정 로딩(AI 카드 스켈레톤)/토글 즉시반영+SnackBar/초기화 확인 다이얼로그/로그아웃 확인.
- **방어선:** `settings_screen_test`, `health_input_screen_test`, `settings_provider_motion_test`, maestro `profile_flow`·`edit_profile_flow`.
- **불변조건:** 텍스트 배율 clamp(설정=바닥값, 상한 2.0, 시스템 배율 미덮어쓰기). reduceMotion 3단(full/fadeOnly/none). 측정데이터 초기화는 계정 유지·시작활동 재개방. 로그아웃은 세션 무효화+`/login`.

### 3.9 음성 평가 (중지) — voice_assessment
- `/voice_assessment` → VoiceAssessmentBlockedScreen(안내 화면). **불변조건:** 실제 평가 미노출, 안내만. `voice_assessment_blocked_screen_test`·maestro `voice_assessment_flow`가 이 상태를 고정.

### 3.10 치매안심센터 찾기 (dementia_center) — 공공데이터
- **진입점:** `/dementia_centers`(프로필·초기평가 고위험).
- **데이터 R/W:** CSV 에셋(국립중앙의료원 공공데이터) → repository. **위치정보 수집 안 함**(화면 명시).
- **권한/센서:** 없음. 전화/지도 launchUrl(externalApplication).
- **상태:** 목록/검색/전화·지도 실패 SnackBar 2종/도움전화 카드.
- **방어선:** `dementia_centers_asset_test`, `dementia_center_repository_test`, `dementia_center_csv_test`, `dementia_center_finder_screen_test`, maestro `dementia_center_flow`.
- **불변조건:** 공공누리 출처표시 문구. 위치 비수집 문구. CSV 파싱 무결성.

### 3.11 CS 센터 (사용자) + 관리자 포털
- **CS 진입점:** `/cs_center`→notices/faq/inquiry_submit/my_inquiries + detail(:id).
- **관리자 진입점:** 버전 라벨 롱프레스→`/admin_login`→dashboard→user_detail/cs_management/notice_edit/faq_edit/inquiry_detail.
- **데이터 R/W:** CsService(Firestore notices/faqs/inquiries). AdminProvider. 데모 시드는 kDebugMode만(배포 규칙상 클라 쓰기 거부).
- **권한/센서:** 네트워크(Firestore).
- **상태:** 목록/상세/작성/빈/삭제 확인 다이얼로그.
- **방어선:** `cs_service`(간접), maestro `cs_center_flow`. admin은 게이팅 flow 없음(§7 리스크).
- **불변조건:** 릴리스에서 `ADMIN_CODE_SHA256` 미주입 시 포털 진입점·라우트 부재(AppConfig). 관리자 코드 평문 미포함(SHA-256). redirect가 딥링크 차단.

### 3.12 콜드 스타트 오프닝 (opening)
- **진입점:** 앱 실행(main.dart `MemoryOpening`, `start:settings.isLoaded, ready:!isLoading`).
- **상태:** 2.4초 브랜드 애니메이션, 로딩과 겹침, 아무곳 탭 건너뛰기, reduceMotion 분기.
- **방어선:** `memory_opening_test`, maestro `opening_flow`(자동로그인 타이밍 주의 — ROADMAP §1).
- **불변조건:** 앱 실행당 1회·celebrateMax 안쪽. 네이티브 스플래시와 동일 위치 로고에서 시작. 덮는 동안 하위 접근성 트리 차단(TalkBack/Maestro가 가려진 입력 미탭). fadeOnly=페이드, none=즉시.

---

## 4. 전역 모션·테마 불변조건 (theme.dart / core/motion / DESIGN.md 실측)

- **색 유일 출처 `theme.dart`.** 원색 직접 사용 0 — `palette_guard_test.dart`가 차단.
- **화면 Duration 직접 사용 금지** — `motion_token_guard_test.dart`. 4단만(100/150/200/300ms) + 명시 예외 4종(파티클 600ms, 컨페티 2.5s, 배지 1.4s, nextQuestionDelay 700ms, opening 2.4s).
- **MotionLevel 3단**(full/fadeOnly/none) — `settings_provider_motion_test`·`motion_settings_test`. 새 모션은 3단 분기+테스트 필수(DESIGN §8 Pre-Flight).
- **대비**: 본문 4.5:1·큰글자 3:1 — `theme_contrast_test.dart`(계산 검증). 상태문구 글자 전용 토큰(goodText/warnText/badText).
- **최소 터치 56dp**(`minTapTarget`), 플로팅 내비 48dp 예외 — `floating_pill_nav_test`·`accessibility_guideline_test`.
- **진입 안무** StaggeredColumn ≤400ms·묶음≤4·실행당 1회(playKey) — `staggered_column_test`·`fade_slide_in_test`·`ml_motion_widgets_test`·`pressable_scale_test`·`app_motion_test`.
- **다크 모드 차단됨**(`ThemeMode.light` 고정) — 상태문구 토큰 4개 다크 대비 미달. 임의로 `ThemeMode.system` 되돌리지 말 것.

---

## 5. 자동화 방어선 요약 (정본: run_maestro_tests.ps1 + DEVELOPMENT_ROADMAP §1)

- **flutter test:** 320/320 통과, 44 파일(실측 기준선).
- **flutter analyze:** 에러 0·경고 0·info 4(스타일).
- **Maestro 게이팅 21** (배열이 정본): login/login_fail/register/navigation/training_hub/profile/cs_center/reports/voice_assessment/guardian_link/home_detail/ai_chat/memory_garden/training_game/edit_profile/clinical_report/training_progression/training_persistence/training_accessibility/dementia_center/opening. 게이팅 제외 4(데모·스크린샷).
- **integration_test 2**(게이팅 외): training_flow(통과), auth_flow(낡음 §7).
- **실행 환경 불변조건:** Maestro는 `-gpu angle_indirect` 포그라운드. swiftshader=ANR, host=WGL 크래시.

---

## 6. 리디자인 시 절대 보존할 최상위 불변조건 (요약 체크리스트)

1. GoRoute 44개 경로 문자열·파라미터·게임 catalog 매핑 유지. 게임 경로는 catalog 경유.
2. redirect 게이트(인증·온보딩·admin·dementia_centers 포함) 로직 불변.
3. 비라우트 진입점 보존: EditProfileScreen/PdfPreview(MaterialPageRoute), 6 다이얼로그, 2 바텀시트, tel/sms/URL 7종, Share 3종, showLicensePage, 버전 롱프레스 admin.
4. 5탭 IndexedStack + FloatingPillNav 골격, TickerMode·contentBottomInset.
5. 데이터 경로: SQLite(users·scores·daily_steps·diary·training) + SharedPreferences(session·token·reminder·guardian_token) + Firestore(guardian_views·global_stats·cs). setCognitiveScore·attemptId·토큰 규칙.
6. 권한/센서: activityRecognition·notification·마이크(STT)·카메라. 권한 중복요청 합류. 로그아웃 시 추적 정지.
7. 네 상태(빈/로딩/실패/정상) + null≠0 유지. 스켈레톤·크로스페이드.
8. 모션·테마 가드 테스트(palette/motion_token/contrast/motion_level)와 예외 5종 유지.
9. StepAnomalyPolicy 단일 판정·기준선 오늘 제외·동기화 실패 통지.
10. 임상 면책·자체 지표명·공공데이터 출처·관리자 SHA-256 게이트.
11. 320dp·배율 1.0/1.3/1.6/2.0 무오버플로. 색만으로 정보 전달 0.
12. 320 테스트·21 Maestro flow·analyze info 4 회귀 0.

---

## 7. 코드-문서 불일치 (코드가 정본)

1. **README Lottie 배지 vs pubspec** — README 기술스택에 Lottie 표기이나 `pubspec.yaml`에 lottie/rive/flutter_animate 없음. 모션은 네이티브(core/motion). (FINAL_REPORT §2도 지적.)
2. **integration_test/auth_flow_test 낡음** — `BottomNavigationBar` 단언이나 실제는 `FloatingPillNav`(lib에 BottomNavigationBar 0건). ROADMAP §1 기록. 게이팅 외라 CI 미차단.
3. **social_ranking 제거됨** — SocialRankingView·flow·07/08 스크린샷 관련. `_updateGlobalStats`는 남아 EMA 계산하나 UI 소비처 없음(사실상 미출시 데이터). 리디자인 시 부활 오해 주의.
4. **README "44개 경로" vs 화면 목록 26개** — README 화면 경로 목록은 축약본. router.dart 44 GoRoute가 정본(admin/cs 세부 포함).
5. **다크 모드** — README/문서 톤과 달리 코드는 `ThemeMode.light` 하드 고정(main.dart). darkTheme 정의만 존재, 미사용.
6. **루트 스크린샷(01~14 png) 날짜 낡음** — 2026-07 UI. 현재 코드는 스켈레톤·오프닝·contentBottomInset 반영. 진단 방향용만, 최종 증거 아님.
7. **admin 포털 게이팅 flow 부재** — 7개 admin 라우트에 대응하는 Maestro 게이팅 flow 없음(위젯 테스트도 admin 미커버). 리디자인 시 회귀 사각지대 — 수동 QA 필요.
