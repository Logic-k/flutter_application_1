# MemoryLink 프로젝트 문서

## 2026-07-23 인지훈련 게임화 기준

- 인지훈련은 8개 활동의 과정 지도로 구성한다. 신규 사용자는 비교, 수열,
  그림 스도쿠, 같은 모양 찾기, 일상 회상 5개 활동부터 시작한다.
- 완료 기록, XP, 레벨, 숙련도, 연속 학습, 잠금 해제는 **SQLite v9**에
  사용자 ID별로 저장한다.
- `training_scores`는 기존 임상/리포트 점수 이력이고, XP와 연속 학습은
  격려용 과정 지표다. 두 값을 서로 임상 지표로 해석하지 않는다.
- 게임화 API 연동은 이번 범위에서 보류한다. HTTP 저장소, Firestore 동기화,
  DTO, 동기화 큐, 백엔드 인증은 구현하지 않는다.
- 검증 기준 SDK는 Flutter 3.41.5이다. CI Android API 33과 로컬
  `QA_Device` Android API 36을 사용한다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [개발 환경 설정 가이드](#2-개발-환경-설정-가이드)
3. [전체 폴더 구조](#3-전체-폴더-구조)
4. [사용된 패키지(라이브러리) 설명](#4-사용된-패키지라이브러리-설명)
5. [핵심 파일 상세 설명](#5-핵심-파일-상세-설명-core-폴더)
6. [기능별 화면 상세 설명](#6-기능별-화면-상세-설명-features-폴더)
7. [데이터 흐름 설명](#7-데이터-흐름-설명)
8. [상태 관리(Provider) 설명](#8-상태-관리provider-설명)
9. [플랫폼별 설정 안내](#9-플랫폼별-설정-안내)
10. [자주 묻는 질문 (FAQ)](#10-자주-묻는-질문-faq)

---

## 1. 프로젝트 개요

### 앱 이름
**MemoryLink** (메모리링크)

### 목적
노인을 위한 종합 디지털 건강 관리 앱으로, 네 가지 핵심 기능을 제공합니다:
- **인지 훈련**: 뇌 훈련 게임으로 기억력, 계산력, 집중력 향상
- **보행 분석**: 스마트폰 센서로 걷는 패턴을 분석해 치매 위험도 평가
- **감정 일기**: 달력 기반 일기 작성으로 정서 상태 기록 및 관리
- **AI 챗봇**: Gemini 기반 회상 요법 대화로 인지 자극 및 정서 케어

### 기본 정보

| 항목 | 내용 |
|------|------|
| 버전 | 1.0.0+1 |
| 개발 언어 | Dart (Flutter 프레임워크) |
| 지원 플랫폼 | Android, iOS, Web |
| Dart SDK 제약 | `^3.11.3` (`pubspec.yaml`의 Dart 제약이며 Flutter 버전이 아님) |
| Flutter SDK | 저장소에 고정 버전 없음. 설치된 SDK가 위 Dart 제약을 지원해야 함 |
| 데이터 저장 방식 | 기능별 로컬 SQLite 또는 Firebase Firestore 사용 |
| AI 엔진 | 런타임 Gemini REST API (`http`) + API 키가 없을 때 로컬 폴백 |
| 기본 테스트 계정 | Maestro 데모: `kim_minjun` / `park_sonja` |

---

## 2. 개발 환경 설정 가이드

> Flutter를 처음 설치하시는 분을 위한 단계별 가이드입니다.

### 2-1. Flutter SDK 설치

1. [Flutter 공식 홈페이지](https://flutter.dev/docs/get-started/install)에서 본인의 운영체제에 맞는 SDK를 다운로드합니다.
2. 압축을 풀고 원하는 폴더에 저장합니다. (예: `C:\flutter`)
3. 시스템 환경 변수 `PATH`에 `C:\flutter\bin`을 추가합니다.
4. 터미널(명령 프롬프트)을 열고 아래 명령어로 설치를 확인합니다:
   ```
   flutter doctor
   ```
   모든 항목에 초록색 체크(✓)가 표시되면 완료입니다.

### 2-2. 프로젝트 의존성 설치

터미널에서 프로젝트 폴더로 이동 후 아래 명령어를 실행합니다:
```
cd d:\Test_Android\flutter_application_1
flutter pub get
```
이 명령어는 `pubspec.yaml`에 적힌 모든 패키지를 자동으로 다운로드합니다.

### 2-3. Firebase 설정

Firebase 기능을 사용하기 위해 다음 파일이 필요합니다:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

`main.dart`는 `FirebaseService.initialize()`를 조건 없이 호출합니다. 따라서 플랫폼별
Firebase 설정이 없거나 잘못되면 앱 시작 자체가 실패할 수 있습니다. Firestore를 쓰지 않는
로컬 기능만 실행하려는 경우에도 별도의 Firebase 초기화 우회 코드는 현재 없습니다.

### 2-4. 앱 실행

**안드로이드 에뮬레이터로 실행:**
```
flutter run
```

**특정 기기 선택 후 실행:**
```
flutter devices          ← 연결된 기기 목록 확인
flutter run -d [기기ID]  ← 원하는 기기로 실행
```

### 2-5. Maestro QA 자동화 실행

```
# 게이팅 flow 19개 실행(helpers와 screenshot flow는 별도)
maestro test maestro/

# 개별 flow 실행
maestro test maestro/[flow파일명].yaml
```

---

## 3. 전체 폴더 구조

```
flutter_application_1/            ← 프로젝트 최상위 폴더
│
├── lib/                          ← 앱의 모든 Dart 코드
│   │
│   ├── main.dart                 ← 앱 시작점
│   │
│   ├── core/                     ← 앱 전체 공통 기능
│   │   ├── router.dart           ← 화면 경로 설정
│   │   ├── theme.dart            ← 앱 전체 색상/폰트/디자인 (라벤더 캄)
│   │   ├── user_provider.dart    ← 사용자 정보 관리
│   │   ├── admin_provider.dart   ← 관리자 상태 관리
│   │   ├── settings_provider.dart← 앱 설정(글자 크기, 음성 등)
│   │   ├── database_helper.dart  ← SQLite 로컬 데이터베이스
│   │   ├── firebase_service.dart ← Firebase Firestore 연동
│   │   ├── local_ai_service.dart ← 온디바이스 AI (시뮬레이션)
│   │   ├── app_config.dart       ← 앱 전역 상수 설정
│   │   ├── ml_widgets.dart       ← ML 관련 공통 위젯
│   │   │
│   │   ├── ai/                   ← AI 제공자 모듈
│   │   │   ├── ai_provider_interface.dart ← AI 제공자 인터페이스
│   │   │   ├── gemini_provider.dart       ← Google Gemini 연동
│   │   │   ├── local_fallback_provider.dart ← 오프라인 대체 응답
│   │   │   └── ai_key_service.dart        ← AI 키 관리
│   │   │
│   │   └── services/             ← 백그라운드 서비스
│   │       ├── background_service.dart       ← 백그라운드 만보계
│   │       ├── voice_service.dart            ← TTS 음성 안내
│   │       ├── anomaly_monitor_service.dart  ← 이상 활동 감지
│   │       ├── guardian_sync_service.dart    ← 보호자 동기화
│   │       └── diary_notification_service.dart ← 일기 작성 알림
│   │
│   └── features/                 ← 기능별 화면
│       ├── auth/                 ← 로그인, 회원가입
│       ├── onboarding/           ← 온보딩, 동의
│       ├── navigation/           ← 하단 탭 메뉴
│       ├── home/                 ← 메인 홈 화면
│       ├── assessment/           ← 인지 평가
│       ├── voice_assessment/     ← 음성 인식 평가
│       ├── training/             ← 인지 훈련 게임 (7종)
│       │   ├── games/            ← 7개 게임 파일
│       │   └── widgets/          ← 게임 공통 템플릿
│       ├── gait_analysis/        ← 보행 분석
│       ├── diary/                ← 감정 일기 (작성/조회)
│       ├── ai_chat/              ← AI 챗봇 (Gemini)
│       ├── reports/              ← 건강 리포트
│       ├── profile/              ← 개인정보 및 보호자 연계
│       ├── cs/                   ← CS 센터 (7개 화면)
│       ├── admin/                ← 관리자 포털 (7개 화면)
│       └── referral/             ← 기관 연계
│
├── assets/                       ← 앱 자산 파일
│   ├── fonts/                    ← NanumGothic (Regular, Bold)
│   ├── icon/                     ← 앱 아이콘
│   ├── models/                   ← ML 모델 파일
│   └── illustrations/            ← 일러스트 이미지
│
├── test/                         ← 단위/위젯 테스트
├── integration_test/             ← 통합 테스트
├── maestro/                      ← Maestro QA 자동화 (게이팅 19개 + 스크린샷 1개)
├── android/                      ← 안드로이드 플랫폼 설정
├── ios/                          ← iOS 플랫폼 설정
└── pubspec.yaml                  ← 패키지 의존성 목록
```

---

## 4. 사용된 패키지(라이브러리) 설명

> `pubspec.yaml` 파일에 사용할 패키지를 나열하면 Flutter가 자동으로 다운로드합니다.

### 화면/UI 관련

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `go_router` | 17.1.0 | 화면 전환 관리 (URL 기반 라우팅) |
| `google_fonts` | 8.0.2 | 의존성에 포함되어 있으나 현재 앱 테마는 로컬 NanumGothic 사용 |
| `fl_chart` | 1.2.0 | 점수 추이 차트 |
| `table_calendar` | 3.1.2 | 일기 달력 UI |
| `lottie` | 3.1.2 | JSON 애니메이션 재생 |
| `flutter_svg` | 2.0.10 | SVG 이미지 렌더링 |

### 데이터 저장 관련

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `sqflite` | 2.4.2 | 스마트폰 내부 로컬 데이터베이스 |
| `firebase_core` | 3.6.0 | Firebase 초기화 |
| `cloud_firestore` | 5.4.4 | Firebase 클라우드 데이터베이스 |
| `shared_preferences` | 2.2.3 | 자동 로그인 등 간단한 설정 저장 |

### AI 관련

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `http` | 1.2.2 | Gemini REST API 및 날씨 API 통신 |
| `google_generative_ai` | 0.4.6 | 의존성에 남아 있으나 현재 Gemini 런타임 경로에서는 사용하지 않음 |

### 센서/하드웨어 관련

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `pedometer` | 4.0.1 | 만보계 (걸음 수 측정) |
| `sensors_plus` | 7.0.0 | 가속도/자이로 센서 |
| `speech_to_text` | 7.3.0 | 음성 → 텍스트 변환 |
| `flutter_tts` | 4.2.5 | 텍스트 → 음성 (TTS) |
| `record` | 6.2.0 | 오디오 녹음 |
| `vibration` | 3.1.8 | 진동 제어 |
| `health` | 11.1.1 | iOS HealthKit / Android Health Connect 연동 (부분 구현, 기기 검증 미완) |
| `image_picker` | 1.1.2 | 갤러리/카메라 이미지 선택 |

### 백그라운드/알림 관련

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter_background_service` | 5.0.10 | 앱 종료 후에도 만보계 실행 |
| `flutter_local_notifications` | 21.0.0 | 로컬 푸시 알림 |
| `permission_handler` | 12.0.1 | 마이크·걸음 수 등 권한 요청 |

### 기타 기능

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `provider` | 6.1.5+ | 상태 관리 (화면 간 데이터 공유) |
| `pdf` + `printing` | 3.11.1 | 임상 리포트 PDF 생성/출력 |
| `intl` | 0.19.0 | 한국어 날짜 형식 지원 |
| `audioplayers` | 6.6.0 | 오디오 파일 재생 |
| `qr_flutter` | 4.1.0 | 보호자 연결용 QR 코드 생성 |
| `url_launcher` | 6.3.2 | 외부 링크·전화 연결 |
| `share_plus` | 10.1.3 | 리포트 공유 |
| `http` | 1.2.2 | HTTP 통신 |

---

## 5. 핵심 파일 상세 설명 (core/ 폴더)

### 5-1. `main.dart` — 앱 시작점

**하는 일:**
1. Flutter 바인딩, KST timezone, 로컬 알림과 일기 알림 예약 초기화
2. 한국어 날짜 형식 초기화
3. `IS_EMULATOR`가 `false`일 때만 백그라운드 서비스 구성
4. 로컬 AI와 AI 대화 서비스 초기화
5. Firebase를 조건 없이 초기화
6. `UserProvider.checkLoginStatus()`로 저장된 자격증명 확인
7. 앱 전체 Provider를 등록하고 화면 표시

**등록되는 Provider 목록:**

| Provider | 역할 |
|----------|------|
| `UserProvider` | 사용자 정보 관리 |
| `AdminProvider` | 관리자 상태 관리 |
| `GaitProvider` | 보행 분석 데이터 관리 |
| `PedometerManager` | 걸음 수·칼로리·거리 |
| `SettingsProvider` | 글자 크기, 음성 안내 등 앱 설정 |
| `DifficultyProvider` | 게임 난이도 자동 조정 |
| `DiaryProvider` | 날짜별 자유 서술 일기 로드·저장 |

---

### 5-2. `core/router.dart` — 화면 경로 설정

앱 내 모든 화면의 경로를 정의합니다. GoRouter 기반이며 이중 인증 가드(일반 앱 / 관리자)를 지원합니다.

| 경로 | 화면 |
|------|------|
| `/login` | 로그인 화면 |
| `/register` | 회원가입 |
| `/` | 메인 탭 네비게이션 (5탭) |
| `/memory_garden` | 일기 작성 (DiaryScreen) |
| `/diary_book` | 일기 조회 (DiaryBookScreen) |
| `/ai_chat` | AI 챗봇 (Gemini) |
| `/voice_assessment` | 음성 평가 |
| `/report_options` | 임상 리포트 옵션 |
| `/gait` | 보행 분석 |
| `/profile` | 프로필 |

**자동 리디렉션:** 일반 앱 경로는 미로그인 시 `/login`으로 이동하고, 로그인한
사용자가 `/login` 또는 `/register`에 접근하면 `/`로 이동합니다. `/admin_login`을
제외한 관리자 경로는 별도의 `AdminProvider` 세션이 없으면 `/admin_login`으로
리디렉션됩니다. 일반 로그인과 관리자 로그인은 서로 다른 가드입니다.

---

### 5-3. `core/theme.dart` — 디자인 시스템 (라벤더 캄)

앱 전체의 색상·폰트·버튼 스타일을 정의합니다.

**색상 테마 (MLColors):**

| 역할 | 색상 | 색상코드 |
|------|------|---------|
| Primary (강조) | 라벤더 | `#6C5CE7` |
| Primary Deep | 딥 퍼플 | `#5847D6` |
| Primary Soft | 연보라 틴트 | `#ECE9FC` |
| 배경 | 연보라 화이트 | `#F1F0FB` |
| 카드 | 흰색 | `#FFFFFF` |
| 텍스트 | 딥 퍼플 네이비 | `#241F3D` |
| 양호 상태 | 그린 | `#3FBF8F` |
| 주의 상태 | 레드 | `#FF6B6B` |

**카테고리 색상 (게임/지표):**

| 카테고리 | 색상코드 |
|---------|---------|
| 계산·판단 | `#6C5CE7` (라벤더) |
| 논리·추론 | `#A66BE8` |
| 기억·지각 | `#38C9A6` (민트) |
| 스마트 케어 | `#FF7AA2` (핑크) |
| 읽기/걸음 | `#FFB74D` (앰버) |

**폰트:** 앱의 `ThemeData`와 PDF 리포트 모두 번들된 `NanumGothic`을 사용합니다.

**접근성:**
- 글자 크기 3단계 (1.0x / 1.2x / 1.4x)
- 라이트/다크 테마 지원
- Material Design 3

---

### 5-4. `core/user_provider.dart` — 사용자 상태 관리

**관리하는 정보:**
- 로그인/로그아웃 상태
- 개인 정보 (나이, 체중, 혈액형, 복용 약물)
- 인지 훈련 점수 (계산력, 논리력, 기억력, 집중력 각 0~10점)

**데이터 보존:**
- 인증 → 로컬 SQLite 기반 인증
- 로그인 성공 시 아이디와 비밀번호 → `SharedPreferences`에 평문 저장 후 자동 로그인에 재사용
- 훈련 점수 → `SQLite DB`

---

### 5-5. `core/database_helper.dart` — 로컬 데이터베이스

**DB 파일명:** `memorylink.db`

| 테이블 | 저장 내용 |
|--------|----------|
| `users` | 사용자 계정 (아이디, 비밀번호, 나이, 체중, 목표 등) |
| `training_scores` | 인지 훈련 점수 이력 |
| `training_attempts` | 활동별 완료 시도, 획득 XP, 서울 기준 완료일 |
| `training_user_progress` | 사용자별 총 XP와 현재/최장 연속 학습 |
| `training_activity_progress` | 활동별 최고 점수, 숙련도, 완료 횟수 |
| `training_unlocks` | 사용자별 열린 활동과 해제 근거 |
| `daily_steps` | 일별 걸음 수·칼로리·거리 |
| `checklist` | 일일 할 일 체크 |
| `daily_active_users` | 사용자별 일일 활성 기록(DAU, 사용자/날짜 중복 방지) |
| `diary_entries` | 사용자별 날짜 단위 자유 서술 일기 |

---

### 5-6. `core/firebase_service.dart` — Firebase 연동

Firebase는 범용 SQLite 동기화 계층이 아니라 기능별 저장소입니다.

**Firestore 소유 기능:**
- `CsService`: 공지사항, FAQ, 문의와 답변
- `DifficultyProvider`: 사용자별 훈련 난이도
- `GuardianSyncService`: 보호자 공유 뷰와 전역 통계
- `SocialRankingView`: `global_stats/score_stats` 읽기

SQLite의 사용자, 점수, 걸음, 체크리스트, DAU, 일기 전체를 Firestore와 자동
동기화하는 공통 큐나 오프라인 재전송 계층은 구현되어 있지 않습니다.

---

### 5-7. `core/ai/` — AI 제공자 모듈

| 파일 | 역할 |
|------|------|
| `ai_provider_interface.dart` | AI 제공자 공통 인터페이스 |
| `gemini_provider.dart` | `http`로 Gemini REST API 호출 및 사용 가능 모델 탐색 |
| `local_fallback_provider.dart` | API 키가 없거나 Gemini 호출이 실패할 때 로컬 응답 |
| `ai_key_service.dart` | 앱 입력 키를 SharedPreferences에 저장하고 dart-define 키보다 우선 제공 |

---

### 5-8. `core/services/background_service.dart` — 백그라운드 만보계

`main.dart`는 `IS_EMULATOR=false`일 때 서비스 구성을 수행하지만
`autoStart`는 `false`입니다. 실제 시작은 사용자의 보행 추적 설정과 권한 획득
흐름에 따라 조건부로 수행되며, 항상 실행되는 서비스가 아닙니다.

**필요한 안드로이드 권한:**
- `ACTIVITY_RECOGNITION` — 걸음 수 감지
- `FOREGROUND_SERVICE` — 백그라운드 실행
- `HIGH_SAMPLING_RATE_SENSORS` — 정밀 가속도계

---

### 5-9. `core/services/anomaly_monitor_service.dart` — 이상 활동 감지

**감지 로직:**
1. 최근 7일간 평균 걸음 수 계산
2. 오후 6시 이후에도 평균의 30% 미만이면 이상으로 판단
3. 보호자에게 알림 생성

---

## 6. 기능별 화면 상세 설명 (features/ 폴더)

### 6-1. 인증 (auth/)

- `LoginScreen` — 로컬 SQLite 기반 인증
- `RegisterScreen` — SQLite `users` 테이블에 신규 계정 생성
- 자동 로그인: 성공한 아이디와 비밀번호를 SharedPreferences에 저장해 재인증

---

### 6-2. 온보딩 (onboarding/)

- `OnboardingScreen` — 사용 목표 선택 (3가지)
- `ConsentScreen` — 개인정보 수집 동의

| 목표 | 대상 |
|------|------|
| 예방 목적 | 건강하지만 예방 차원으로 관리하고 싶은 분 |
| 걱정됨 | 기억력 감소가 걱정되는 분 |
| 가족을 위해 | 가족의 건강을 관리해드리려는 분 |

---

### 6-3. 인지 평가 (assessment/)

- `AssessmentScreen` — 자기 평가 설문 (10문항)
- `CognitiveTasksScreen` — 4단계 인지 과제 수행
- `AssessmentResultScreen` — 결과 화면

**4단계 평가:**

| 단계 | 과제 |
|------|------|
| 1 | 단어 3개 기억 |
| 2 | 산수 문제 (방해 과제) |
| 3 | 앞서 본 단어 회상 |
| 4 | 난이도 상승 집중력 과제 (5종) |

---

### 6-4. 인지 훈련 (training/)

**훈련 허브 (`TrainingHubScreen`):** 7가지 게임 목록 및 현재 레벨 표시

**7가지 게임:**

| 게임명 | 훈련 영역 | 내용 |
|--------|----------|------|
| 비교 게임 | 계산력 | 두 숫자/수식 중 더 큰 것 선택 |
| 수열 게임 | 논리력 | 등차·등비·삼각수 패턴 찾기 |
| 도형 스도쿠 | 기억력 | 3×3/4×4 격자 빈칸 채우기 |
| 곱셈 게임 | 계산력 | 구구단 문제 풀기 |
| 분류 게임 | 언어력 | 단어를 올바른 카테고리로 분류 |
| 도형 짝 | 지각력 | 같은 도형 빠르게 찾기 |
| 문장 읽기 | 집중력 | 독해 및 이해 문제 |

별도 `/training/recall` 경로에는 날짜 기반 **오늘의 회상** 활동도 구현되어 있습니다.

**난이도 자동 조정 (`DifficultyProvider`):**
- 레벨 1~10단계
- 3회 연속 정답이고, 반응 시간이 제공된 경우 최근 평균이 목표 시간 이하면 1단계 상승
- 2회 연속 오답이면 1단계 하락
- 사용자명이 설정된 경우 Firestore `training_difficulty/{username}`에 카테고리별 저장

---

### 6-5. 보행 분석 (gait_analysis/)

- `GaitScreen` — 보행 측정 세션
- `PreciseGaitAnalysisScreen` — 상세 바이오마커 분석
- `WalkingDashboardScreen` — 일별/주별 활동량 차트

**보행 지표:**

| 지표 | 의미 |
|------|------|
| 보폭 간격 | 발걸음 사이 시간 (300~2000ms 정상) |
| 보행 변동성 (CV) | 보폭 불규칙 정도 (낮을수록 안정) |
| 걸음 수 | 총 걸음 수 |

**활동량 계산식:**
- 이동 거리: `걸음 수 × 0.7 ÷ 1000` (km)
- 소모 칼로리: `걸음 수 × 0.04 × (체중/60) × 나이보정계수` (kcal)

---

### 6-6. 음성 평가 (voice_assessment/)

- `VoiceAssessmentScreen` — 음성 녹음 및 분석 화면

**검사 방법:**
1. 90초 동안 자유 발화 (한국어)
2. 음성 → 텍스트 변환 (speech_to_text)
3. 규칙 기반 음성 지표(TTR/WPM) 구현 및 문장 완결성 분석
4. 점수 환산 후 화면에 표시

현재 `LocalAIService`는 규칙 기반 엔진만 초기화합니다. TFLite 모델 파일은 보관되어
있지만 로딩·추론 코드는 연결되지 않았으며, 이 지표는 Gemini/LLM 분석 결과가 아닙니다.

---

### 6-7. 홈 화면 (home/)

**주요 카드:**

| 카드 | 내용 |
|------|------|
| 환영 인사 | 이름과 현재 날짜 |
| 식단 추천 | MIND 다이어트 기반 뇌 건강 음식 (날짜별 순환) |
| 오늘 걸음 수 | PedometerManager 실시간 연동 |
| 추천 훈련 | 오늘 추천 게임 3가지 |

**식단 추천 음식 (4가지 순환):**
- 블루베리 (항산화)
- 견과류 (오메가-3, 비타민 E)
- 시금치 (엽산, 철분)
- 고등어 (DHA, EPA)

---

### 6-8. 감정 일기 (diary/)

- `DiaryScreen` — 날짜 선택 및 일기 작성
- `DiaryBookScreen` — 과거 일기 목록 조회

**주요 기능:**
- `table_calendar` 기반 달력 UI로 날짜 선택
- 자유 서술 작성(현재 DB 스키마에는 별도 감정 태그 컬럼 없음)
- 날짜별 일기 기록 조회
- 일기 작성 알림 (`diary_notification_service`)
- `/memory_garden` 경로가 이 화면으로 연결됨

---

### 6-9. AI 챗봇 (ai_chat/)

- `AiChatScreen` — Gemini 기반 채팅 화면

**주요 기능:**
- Google Gemini API 기반 회상 요법 대화
- 날짜·시간·날씨 실시간 컨텍스트 자동 주입
- API 키 없음 또는 Gemini 호출 실패 시 로컬 폴백 응답
- AI 제공자 인터페이스 추상화 (향후 모델 교체 용이)

---

### 6-10. 리포트 (reports/)

- `ReportsScreen` — 주간 건강 리포트
- `ClinicalReportOptionsScreen` — 임상 리포트 옵션 선택

**주요 섹션:**

| 섹션 | 내용 |
|------|------|
| 뇌 나이 카드 | 4가지 인지 점수 + 추이 |
| 사회적 순위 | 익명 집단 백분위 비교 |
| 점수 차트 | 과거 평가 꺾은선 그래프 |
| 요약/인사이트 | 저장된 점수와 활동 데이터를 바탕으로 한 결정적 규칙 계산 |

**임상 리포트 (`ClinicalReportGenerator`):**
- 4페이지 PDF 생성 구현
- 포함: 환자 정보, 보행 안정성, MMSE 점수, GDS 수준
- NanumGothic 폰트 한국어 지원

---

### 6-11. 프로필 (profile/)

- `ProfileScreen` — 프로필 메인
- `EditProfileScreen` — 의료 정보 수정
- `GuardianLinkScreen` — 보호자 연결 (QR 코드)

**관리 정보:**
- 나이, 체중, 혈액형, 복용 약물, 기저 질환
- 비상 연락처
- 앱 설정 (글자 크기, 음성, 진동)

---

### 6-12. 하단 탭 메뉴 (navigation/)

| 탭 | 화면 |
|----|------|
| 홈 | `HomeScreen` |
| 인지 훈련 | `TrainingHubScreen` |
| 생활 습관 | `WalkingDashboardScreen` |
| 리포트 | `ReportsScreen` |
| 프로필 | `ProfileScreen` |

---

## 7. 데이터 흐름 설명

### 7-1. 로그인 흐름

```
사용자가 아이디/비밀번호 입력
         ↓
   UserProvider.login()
         ↓
   DatabaseHelper.getUser() (SQLite 조회)
         ↓
  로그인 성공 → SharedPreferences 저장 (자동 로그인)
         ↓
     MainNavScreen (메인 화면)
```

### 7-2. 훈련 게임 점수 저장 흐름

```
게임 플레이 완료
         ↓
  DifficultyProvider.updatePerformance()
  (3회 연속 정답, 선택적 목표 시간 또는 2회 연속 오답으로 조정)
         ↓
  Firestore training_difficulty/{username}
  (레벨이 바뀌고 사용자명이 정상 바인딩된 경우)
         ↓
  UserProvider.setCognitiveScore()
         ↓
  DatabaseHelper.insertScore() (SQLite 저장)
         ↓
  ReportsScreen에서 차트로 확인
```

### 7-3. 보행 분석 흐름

```
BackgroundService 시작
         ↓
  Pedometer → 실시간 걸음 수
  Accelerometer → 50개 샘플씩 수집
         ↓
  PedometerManager (걸음 수·칼로리·거리 계산)
         ↓
  GaitProvider → GaitAnalyzer
  (보폭 감지, 변동성 계산)
         ↓
  Firebase Firestore 업로드 (선택적)
```

### 7-4. AI 챗봇 흐름

```
사용자 메시지 입력
         ↓
  날짜·시간·날씨 컨텍스트 주입
         ↓
  GeminiProvider.sendMessage()
  API 키 없음 또는 요청 실패 → LocalFallbackProvider
         ↓
  Future<String> 응답 완료 후 UI 표시
```

### 7-5. 로컬과 클라우드의 경계

인증, 인지 점수, 걸음, 체크리스트, DAU, 일기는 SQLite가 소유합니다. CS,
훈련 난이도, 보호자 공유, 전역 통계는 각 기능이 Firestore를 직접 사용합니다.
모든 로컬 데이터를 먼저 저장한 뒤 연결 시 일괄 동기화하는 보편적 오프라인
동기화는 없습니다.

---

## 8. 상태 관리(Provider) 설명

### 앱에서 사용하는 Provider 목록

| Provider | 관리 데이터 | 사용 화면 |
|----------|----------|---------|
| `UserProvider` | 사용자 정보, 인지 점수 | 전체 |
| `AdminProvider` | 관리자 로그인 상태 | 관리자 포털 |
| `GaitProvider` | 보행 분석 상태 | 보행 관련 |
| `PedometerManager` | 걸음 수, 칼로리, 거리 | 홈, 생활 |
| `SettingsProvider` | 글자 크기, 음성, 진동 | 전체 |
| `DifficultyProvider` | 게임 레벨, 성적 기록 | 훈련 |
| `DiaryProvider` | 날짜별 자유 서술 일기 | 홈, 일기 작성/조회 |

### Provider 사용 예시 (Dart)

```dart
// 데이터 읽기 (화면 자동 새로고침)
final user = context.watch<UserProvider>();
Text(user.username)

// 데이터 읽기 (새로고침 불필요)
final settings = context.read<SettingsProvider>();

// 데이터 변경
context.read<UserProvider>().login('id', 'password');
```

---

## 9. 플랫폼별 설정 안내

### 9-1. 안드로이드 (`android/app/src/main/AndroidManifest.xml`)

| 권한 | 이유 |
|------|------|
| `RECORD_AUDIO` | 음성 평가 마이크 |
| `ACTIVITY_RECOGNITION` | 만보계 걸음 수 |
| `FOREGROUND_SERVICE` | 앱 종료 후 만보계 실행 |
| `FOREGROUND_SERVICE_HEALTH` | 건강 포그라운드 서비스 |
| `WAKE_LOCK` | 화면 꺼져도 서비스 실행 |
| `RECEIVE_BOOT_COMPLETED` | 재시작 후 서비스 자동 시작 |
| `HIGH_SAMPLING_RATE_SENSORS` | 고정밀 가속도계 |
| `READ_STEPS` / `WRITE_STEPS` | Android Health Connect 걸음 데이터 |
| `SCHEDULE_EXACT_ALARM` | 일기 알림 예약 |
| `POST_NOTIFICATIONS` | 알림 표시 |

> `INTERNET` 권한은 현재 `debug`와 `profile` manifest에는 있지만
> `android/app/src/main/AndroidManifest.xml`에는 없습니다. Gemini와 Firestore를
> 사용하는 Android release 빌드는 배포 전에 main manifest에 권한을 추가해야 합니다.

### 9-2. iOS (`ios/Runner/Info.plist`)

| 설정 | 값 |
|------|---|
| 앱 표시 이름 | MemoryLink(beta) |
| 지원 화면 방향 | 세로, 가로(좌/우) |

---

## 10. 자주 묻는 질문 (FAQ)

**Q. 인터넷 없이도 앱이 작동하나요?**  
A. 네. 인지 훈련, 보행 분석, 일기 작성, 리포트 등 기본 기능은 모두 오프라인에서 동작합니다.  
   AI 챗봇은 API 키가 없거나 요청에 실패하면 로컬 폴백으로 전환됩니다.
   다만 Firebase는 시작 시 조건 없이 초기화되고, Firestore 기능에는 인터넷과
   올바른 Firebase 설정이 필요합니다. 범용 Firestore 동기화는 없습니다.

---

**Q. 앱을 닫아도 걸음 수가 측정되나요?**  
A. Android에서는 에뮬레이터 여부, 사용자 설정, 권한에 따라 백그라운드 서비스가 조건부 시작됩니다.
   배터리 최적화가 켜져 있으면 강제 종료될 수 있으니, 설정 → 앱 → MemoryLink → 배터리 → '제한 없음'으로 설정하세요.

---

**Q. 게임 레벨이 자동으로 바뀌는 이유는?**  
A. `DifficultyProvider`가 3회 연속 정답 또는 2회 연속 오답을 기준으로 조정합니다. 반응 시간이 전달된 게임은 최근 평균이 목표 시간 이내인지도 확인합니다. (1~10단계)

---

**Q. AI 챗봇이 응답하지 않는 경우는?**  
A. Gemini API 키가 유효한지 확인하세요. 인터넷 미연결 시에는 로컬 폴백 응답으로 전환됩니다.

---

**Q. PDF 리포트 한글이 깨지는 경우는?**  
A. `assets/fonts/NanumGothic-Bold.ttf` 파일 위치와 `pubspec.yaml` 폰트 선언을 확인하세요.

---

## 11. QA 현황과 현재 한계

- 기본 검증: `flutter analyze --no-fatal-infos`, `flutter test`
- Android 통합 기준: CI API 33, 로컬 `QA_Device` API 36
- 게임화 검증: 초기 잠금, 완료, XP/숙련도, 다음 활동 해제, 재시작 복원,
  중복 탭, 오프라인, 글자 크기 1.0/1.2/1.4
- Play Store 업로드 전에는 release AAB와 별도로 실기기 센서, 알림,
  Health Connect, PDF 공유를 재검증해야 한다.

*문서 최종 수정일: 2026년 7월 23일*
*앱 버전: 1.0.0+1*
