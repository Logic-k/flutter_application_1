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
자세한 내용은 [PROGRESS.md](PROGRESS.md)를 참조하세요.

---

## 개발 현황

전체 진행 상황은 [PROGRESS.md](PROGRESS.md)에서 확인할 수 있습니다.

| 카테고리 | 상태 |
|---------|------|
| 인증 / 온보딩 | ✅ 완료 |
| 인지 훈련 (7종 게임) | ✅ 완료 |
| 보행 분석 | ✅ 완료 |
| 음성 평가 (STT) | ⚠️ 부분 완료 |
| 주간 리포트 | ✅ 완료 |
| 소셜 봇 (회상 요법) | ❌ 미구현 |
| 온디바이스 LLM 연결 | ❌ 미구현 |

---

## 라이선스

캡스톤 디자인 프로젝트 — 학술 목적으로 개발되었습니다.
