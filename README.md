# MemoryLink

**모바일 센서 기반 다중중재 치매 예방 플랫폼**  
캡스톤 디자인 프로젝트 | Flutter (Android / iOS)

---

## 프로젝트 개요

초기 치매 및 경도인지장애(MCI) 환자를 위한 Flutter 기반 크로스 플랫폼 앱입니다.  
스마트폰 내장 센서(가속도계, 자이로스코프)와 LLM 기반 음성 분석을 결합하여, 사용자가 일상 속에서 위험 신호를 조기 인지하고 다중중재 예방 루틴을 지속할 수 있도록 돕는 SaMD 수준의 플랫폼입니다.

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Flutter (Dart) |
| 상태 관리 | Provider (`ChangeNotifierProvider`, `ProxyProvider`) |
| 라우팅 | GoRouter |
| 클라우드 DB | Supabase |
| 로컬 DB | SQLite |
| 차트 | fl_chart |
| 음성 인식 | speech_to_text |
| 센서 | sensors_plus (가속도계/자이로스코프) |
| 걸음 수 | 자체 PedometerManager + 백그라운드 서비스 |
| 공유 | share_plus |
| 국제화 | intl (한국어 날짜/시간) |

---

## 주요 기능

- **인지 훈련** — 7종 미니게임 (계산·기억력·언어·집중력), 적응형 난이도(Closed-loop)
- **보행 분석** — 3축 가속도 기반 보행 변동성(CV) 측정, 치매 전조 지표 시각화
- **음성 평가** — STT 기반 실시간 음성 텍스트 변환 및 발화 분석
- **주간 리포트** — 인지 훈련 점수 시계열 차트, 뇌 연령 추정, 임상 리포트 생성
- **보호자 연계** — 보호자 공유 링크, 이상 감지 시 푸시 알림
- **기관 연계** — 치매안심센터 전화/지도 연동
- **관리자 포털** — 사용자 데이터 조회, CS 문의 답변

---

## 프로젝트 구조

```
lib/
├── core/
│   ├── services/          # 백그라운드 서비스, 이상 감지, AI 서비스
│   └── ...
├── features/
│   ├── auth/              # 로그인, 회원가입
│   ├── onboarding/        # 온보딩, 동의
│   ├── assessment/        # 초기 평가, 인지 과제
│   ├── voice_assessment/  # 음성 평가
│   ├── training/          # 인지 훈련 허브, 7종 미니게임
│   ├── gait_analysis/     # 보행 분석
│   ├── home/              # 홈 화면, 메모리 정원
│   ├── reports/           # 주간 리포트
│   ├── profile/           # 프로필, 보호자 연계
│   ├── cs/                # CS 센터
│   ├── admin/             # 관리자 포털
│   └── referral/          # 기관 연계
└── ...
```

---

## 시작하기

### 사전 요구사항

- Flutter SDK 3.x 이상
- Dart 3.x 이상
- Android Studio / Xcode

### 설치 및 실행

```bash
git clone https://github.com/Logic-k/flutter_application_1.git
cd flutter_application_1
flutter pub get
flutter run
```

### 환경 설정

Supabase 연결을 위해 프로젝트 루트에 환경 변수를 설정하세요.

---

## 개발 현황

### 구현 완료 기능

| 카테고리 | 주요 내용 | 상태 |
|---------|----------|------|
| 인증 | Supabase 로그인/회원가입, GoRouter 인증 가드 | ✅ |
| 온보딩 | 건강 데이터 수집 동의 절차, 민감 정보 미수집 방침 | ✅ |
| 초기 평가 | 인지 과제, 결과 화면 | ✅ |
| 음성 평가 | STT 실시간 변환, 발화 분석 점수 UI | ⚠️ LLM 미연결 |
| 인지 훈련 (7종) | 비교·구구단·순서기억·도형스도쿠·도형짝·단어분류·문장읽기 | ✅ |
| 적응형 난이도 | DifficultyProvider, 카테고리별 레벨 SQLite 저장 | ✅ |
| 보행 분석 | 가속도 기반 보행 변동성(CV), 백그라운드 Pedometer | ✅ |
| 홈 / 일상 루틴 | 실시간 걸음 수, MIND 식단 추천, 메모리 정원 | ✅ |
| 주간 리포트 | fl_chart 시계열 차트, 뇌 연령 추정, 임상 리포트 구조 | ✅ |
| 프로필 / 보호자 연계 | 보호자 공유 링크, 텍스트 크기 설정 | ✅ |
| CS 센터 | 공지사항, FAQ, 문의 제출/조회 | ✅ |
| 관리자 포털 | 사용자 조회, CS 문의 답변, 공지·FAQ 편집 | ✅ |
| 기관 연계 | 치매안심센터 전화/지도 연동 (url_launcher) | ✅ |
| 이상 감지 모니터 | 활동 미감지 시 보호자 푸시 알림 구조 | ✅ |

### 미완성 / 플레이스홀더 기능

| 기능 | 현황 | 비고 |
|------|------|------|
| 온디바이스 LLM 음성 분석 | ⚠️ 시뮬레이션 | 실제 MediaPipe/TFLite 모델 미탑재 |
| 음성 발화 지표 추출 (TTR, 발화속도) | ⚠️ 부분 구현 | STT는 동작, LLM 파이프라인 미연결 |
| Health Connect / HealthKit 연동 | ⚠️ 자체 구현 | 플랫폼 공식 API 미연동 |
| 이중 과제 보행 알고리즘 | ⚠️ 미구현 | 보행 중 인지 미션 부여 기능 |
| FINGER 모델 — 혈압/혈당 입력 | ⚠️ 미구현 | 생활 습관 기록 입력 폼 |
| 소셜 봇 (회상 요법 챗봇) | ❌ 미구현 | 감정 일기 기반 AI 대화 |
| PDF 실제 생성 | ⚠️ 구조만 완성 | 파일 렌더링/공유 연결 필요 |
| training_corrupted 정리 | ⚠️ 레거시 | 구 버전 파일, 정리 필요 |

---

## 라우팅 구조

```
/login                          → 로그인
/register                       → 회원가입
/ (MainNavScreen)               → 하단 탭 네비게이션
  ├── 홈 (HomeScreen)
  ├── 훈련 (TrainingHubScreen)
  ├── 보행 (GaitScreen)
  ├── 리포트 (ReportsScreen)
  └── 기관 연계 (ReferralScreen)
/onboarding                     → 온보딩
/consent                        → 동의
/assessment                     → 초기 평가
/cognitive_tasks                → 인지 과제
/assessment_result              → 평가 결과
/game/comparison                → 비교 게임
/game/sequence                  → 순서 기억
/game/sudoku                    → 도형 스도쿠
/game/multiplication            → 구구단
/game/shape_match               → 도형 짝
/game/categorization            → 단어 분류
/game/reading                   → 문장 읽기
/gait                           → 보행 분석
/precise_gait_analysis          → 정밀 보행 분석
/walking_dashboard              → 걷기 대시보드
/memory_garden                  → 메모리 정원
/training/recall                → 일일 회상
/profile                        → 프로필
/guardian_link                  → 보호자 연결
/cs_center                      → CS 센터
/cs/notices, /cs/faq            → 공지사항, FAQ
/cs/inquiry_submit, ...         → 문의 관련
/admin_login                    → 관리자 로그인
/admin/dashboard                → 관리자 대시보드
/admin/user_detail/:userId      → 사용자 상세
/admin/cs_management            → CS 관리
/admin/notice_edit, /admin/faq_edit, /admin/inquiry_detail/:id
```

---

## 남은 과제 (우선순위 순)

1. **온디바이스 LLM 연결** — `local_ai_service.dart`에 MediaPipe Gemma 2B 또는 Google AI Edge 연동
2. **음성 발화 지표 파이프라인** — TTR(어휘 다양성), 발화 속도, 대명사 비율 계산 로직 구현
3. **PDF 실제 생성** — `clinical_report_generator.dart`에 pdf 패키지 연결
4. **FINGER 생활 습관 기록** — 수면, 혈압/혈당 입력 UI 추가
5. **이중 과제 보행** — 보행 중 인지 미션 부여 UI 및 속도 저하율 측정
6. **소셜 봇** — 감정 일기 기반 회상 요법 챗봇 화면
7. **training_corrupted 정리** — 레거시 파일 제거 또는 병합

---

## 라이선스

캡스톤 디자인 프로젝트 — 학술 목적으로 개발되었습니다.
