# MemoryLink — 개발 진행 상황 문서

> 최종 업데이트: 2026-06-04  
> 앱 이름: **MemoryLink**  
> 프로젝트 유형: 캡스톤 디자인 — 모바일 센서 기반 다중중재 치매 예방 플랫폼

---

## 1. 프로젝트 개요

초기 치매 및 경도인지장애(MCI) 환자를 위한 Flutter 기반 크로스 플랫폼 앱.  
스마트폰 내장 센서(가속도계, 자이로스코프)와 Gemini LLM 기반 AI 분석을 결합하여, 사용자가 일상 속에서 위험 신호를 조기 인지하고 다중중재(Multi-modal) 예방 루틴을 지속할 수 있도록 돕는 SaMD 수준의 플랫폼.

---

## 2. 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Flutter (Dart 3.11.3+) |
| 상태 관리 | Provider (`ChangeNotifierProvider`, `ProxyProvider`) |
| 라우팅 | GoRouter |
| 클라우드 DB | Firebase (Firestore) |
| 로컬 DB | SQLite (database_helper.dart) |
| AI / LLM | Google Gemini (`google_generative_ai`) |
| 차트 | fl_chart |
| 달력 | table_calendar |
| 음성 인식 | speech_to_text |
| 음성 출력 | flutter_tts |
| 오디오 녹음 | record |
| 센서 | sensors_plus (가속도계/자이로스코프) |
| 걸음 수 | 자체 PedometerManager + 백그라운드 서비스 |
| 이미지 | image_picker |
| 공유 | share_plus |
| 국제화 | intl (한국어 날짜/시간) |

---

## 3. 구현 완료 기능

### 3-1. 인증 (Auth)
| 파일 | 상태 |
|------|------|
| [lib/features/auth/login_screen.dart](lib/features/auth/login_screen.dart) | ✅ 완료 |
| [lib/features/auth/register_screen.dart](lib/features/auth/register_screen.dart) | ✅ 완료 |

- Firebase 기반 로그인/회원가입
- GoRouter 인증 가드 (미로그인 시 `/login` 리다이렉트)

---

### 3-2. 온보딩 (Onboarding)
| 파일 | 상태 |
|------|------|
| [lib/features/onboarding/onboarding_screen.dart](lib/features/onboarding/onboarding_screen.dart) | ✅ 완료 |
| [lib/features/onboarding/consent_screen.dart](lib/features/onboarding/consent_screen.dart) | ✅ 완료 |

- 건강 데이터 수집 동의 절차 포함
- 민감 정보(주민등록번호 등) 미수집 방침 반영

---

### 3-3. 초기 진단 / 평가 (Assessment)
| 파일 | 상태 |
|------|------|
| [lib/features/assessment/assessment_screen.dart](lib/features/assessment/assessment_screen.dart) | ✅ 완료 |
| [lib/features/assessment/cognitive_tasks_screen.dart](lib/features/assessment/cognitive_tasks_screen.dart) | ✅ 완료 |
| [lib/features/assessment/result_screen.dart](lib/features/assessment/result_screen.dart) | ✅ 완료 |
| [lib/features/voice_assessment/voice_assessment_screen.dart](lib/features/voice_assessment/voice_assessment_screen.dart) | ✅ 완료 (STT 구현, AI 분석은 시뮬레이션) |
| [lib/features/voice_assessment/voice_recording_service.dart](lib/features/voice_assessment/voice_recording_service.dart) | ✅ 완료 |

- `speech_to_text` 패키지를 이용한 실시간 음성 → 텍스트 변환
- 발화 분석 점수 산출 UI 완성
- **단, 실제 LLM 분석은 아직 시뮬레이션** → 4절 참조

---

### 3-4. 인지 훈련 허브 (Training Hub)
| 파일 | 상태 |
|------|------|
| [lib/features/training/training_hub_page.dart](lib/features/training/training_hub_page.dart) | ✅ 완료 |
| [lib/features/training/difficulty_provider.dart](lib/features/training/difficulty_provider.dart) | ✅ 완료 |
| [lib/features/training/daily_recall_page.dart](lib/features/training/daily_recall_page.dart) | ✅ 완료 |

#### 미니게임 (7종)
| 게임 | 파일 | 카테고리 | 상태 |
|------|------|---------|------|
| 누가 큰가요? | [comparison_game.dart](lib/features/training/games/comparison_game.dart) | 계산/판단력 | ✅ |
| 구구단 맞추기 | [multiplication_game.dart](lib/features/training/games/multiplication_game.dart) | 계산/판단력 | ✅ |
| 순서 기억하기 | [sequence_game.dart](lib/features/training/games/sequence_game.dart) | 기억력/순서 | ✅ |
| 도형 스도쿠 | [shape_sudoku_game.dart](lib/features/training/games/shape_sudoku_game.dart) | 기억력/순서 | ✅ |
| 도형 짝 맞추기 | [shape_match_game.dart](lib/features/training/games/shape_match_game.dart) | 집중/언어 | ✅ |
| 단어 분류 | [categorization_game.dart](lib/features/training/games/categorization_game.dart) | 집중/언어 | ✅ |
| 문장 읽기 | [sentence_reading_game.dart](lib/features/training/games/sentence_reading_game.dart) | 집중/언어 | ✅ |

- **적응형 난이도(Closed-loop)**: `DifficultyProvider`로 게임 카테고리별 레벨 관리, SQLite 저장

---

### 3-5. 보행 분석 (Gait Analysis)
| 파일 | 상태 |
|------|------|
| [lib/features/gait_analysis/gait_screen.dart](lib/features/gait_analysis/gait_screen.dart) | ✅ 완료 |
| [lib/features/gait_analysis/gait_analyzer.dart](lib/features/gait_analysis/gait_analyzer.dart) | ✅ 완료 |
| [lib/features/gait_analysis/gait_provider.dart](lib/features/gait_analysis/gait_provider.dart) | ✅ 완료 |
| [lib/features/gait_analysis/pedometer_manager.dart](lib/features/gait_analysis/pedometer_manager.dart) | ✅ 완료 |
| [lib/features/gait_analysis/walking_dashboard_screen.dart](lib/features/gait_analysis/walking_dashboard_screen.dart) | ✅ 완료 |
| [lib/features/gait_analysis/precise_analysis_screen.dart](lib/features/gait_analysis/precise_analysis_screen.dart) | ✅ 완료 |
| [lib/core/services/background_service.dart](lib/core/services/background_service.dart) | ✅ 완료 |

**GaitAnalyzer 핵심 로직:**
- 3축 가속도 벡터 크기(Magnitude) 계산으로 걸음 감지
- 보행 변동성(Gait Variability, CV) 계산 — 치매 전조 지표
- 유효 보폭 간격 필터링 (300ms ~ 2000ms)
- 백그라운드에서 Pedometer 지속 동작

---

### 3-6. 홈 화면 (Home)
| 파일 | 상태 |
|------|------|
| [lib/features/home/home_screen.dart](lib/features/home/home_screen.dart) | ✅ 완료 |
| [lib/features/home/widgets/diet_recommendation_card.dart](lib/features/home/widgets/diet_recommendation_card.dart) | ✅ 완료 |

- 실시간 걸음 수 표시 (PedometerManager 연동)
- 오늘 날짜/인사말 (한국어 포맷)
- MIND 식단 추천 카드

---

### 3-7. 감정 일기 (Diary)
| 파일 | 상태 |
|------|------|
| [lib/features/diary/diary_screen.dart](lib/features/diary/diary_screen.dart) | ✅ 완료 |
| [lib/features/diary/diary_book_screen.dart](lib/features/diary/diary_book_screen.dart) | ✅ 완료 |
| [lib/features/diary/diary_provider.dart](lib/features/diary/diary_provider.dart) | ✅ 완료 |
| [lib/core/services/diary_notification_service.dart](lib/core/services/diary_notification_service.dart) | ✅ 완료 |

- 달력 기반 날짜 선택 (table_calendar)
- 감정 태그 및 자유 서술 일기 작성
- 날짜별 일기 조회 (diary_book_screen)
- 일기 작성 알림 서비스
- `/memory_garden` 경로가 이 화면으로 연결됨 (기억의 정원 → 일기 기능으로 개편)

---

### 3-8. AI 챗봇 (AI Chat)
| 파일 | 상태 |
|------|------|
| [lib/features/ai_chat/ai_chat_screen.dart](lib/features/ai_chat/ai_chat_screen.dart) | ✅ 완료 |
| [lib/features/ai_chat/models/chat_message.dart](lib/features/ai_chat/models/chat_message.dart) | ✅ 완료 |
| [lib/core/ai/gemini_provider.dart](lib/core/ai/gemini_provider.dart) | ✅ 완료 |
| [lib/core/ai/ai_key_service.dart](lib/core/ai/ai_key_service.dart) | ✅ 완료 |
| [lib/core/ai/local_fallback_provider.dart](lib/core/ai/local_fallback_provider.dart) | ✅ 완료 |

- Gemini API 기반 회상 요법 대화
- 날짜·시간·날씨 실시간 컨텍스트 주입
- 로컬 폴백 응답 (오프라인 대응)
- AI 제공자 인터페이스 추상화 (gemini / local fallback)

---

### 3-9. 주간 리포트 (Reports)
| 파일 | 상태 |
|------|------|
| [lib/features/reports/reports_screen.dart](lib/features/reports/reports_screen.dart) | ✅ 완료 |
| [lib/features/reports/clinical_report_generator.dart](lib/features/reports/clinical_report_generator.dart) | ✅ 완료 |
| [lib/features/reports/clinical_report_options_screen.dart](lib/features/reports/clinical_report_options_screen.dart) | ✅ 완료 |
| [lib/features/reports/report_analyzer.dart](lib/features/reports/report_analyzer.dart) | ✅ 완료 |
| [lib/features/reports/widgets/social_ranking_view.dart](lib/features/reports/widgets/social_ranking_view.dart) | ✅ 완료 |

- `fl_chart`를 이용한 인지 훈련 점수 시계열 차트
- 뇌 연령 추정 카드
- 임상 리포트 생성 옵션 화면 (PDF/CSV 내보내기 구조)
- 소셜 랭킹 뷰

---

### 3-10. 프로필 / 보호자 연계 (Profile & Guardian)
| 파일 | 상태 |
|------|------|
| [lib/features/profile/profile_screen.dart](lib/features/profile/profile_screen.dart) | ✅ 완료 |
| [lib/features/profile/edit_profile_screen.dart](lib/features/profile/edit_profile_screen.dart) | ✅ 완료 |
| [lib/features/profile/guardian_link_screen.dart](lib/features/profile/guardian_link_screen.dart) | ✅ 완료 |
| [lib/core/services/guardian_sync_service.dart](lib/core/services/guardian_sync_service.dart) | ✅ 완료 |

- 보호자 공유 링크 제공 (GuardianLinkScreen)
- 텍스트 크기 조절 설정 (SettingsProvider)
- 보호자 동기화 서비스

---

### 3-11. CS 센터 (고객지원)
| 파일 | 상태 |
|------|------|
| [lib/features/cs/cs_center_screen.dart](lib/features/cs/cs_center_screen.dart) | ✅ 완료 |
| [lib/features/cs/notice_list_screen.dart](lib/features/cs/notice_list_screen.dart) | ✅ 완료 |
| [lib/features/cs/notice_detail_screen.dart](lib/features/cs/notice_detail_screen.dart) | ✅ 완료 |
| [lib/features/cs/faq_screen.dart](lib/features/cs/faq_screen.dart) | ✅ 완료 |
| [lib/features/cs/inquiry_submit_screen.dart](lib/features/cs/inquiry_submit_screen.dart) | ✅ 완료 |
| [lib/features/cs/my_inquiries_screen.dart](lib/features/cs/my_inquiries_screen.dart) | ✅ 완료 |
| [lib/features/cs/inquiry_detail_screen.dart](lib/features/cs/inquiry_detail_screen.dart) | ✅ 완료 |

---

### 3-12. 관리자 포털 (Admin)
| 파일 | 상태 |
|------|------|
| [lib/features/admin/admin_login_screen.dart](lib/features/admin/admin_login_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_dashboard_screen.dart](lib/features/admin/admin_dashboard_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_user_detail_screen.dart](lib/features/admin/admin_user_detail_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_cs_management_screen.dart](lib/features/admin/admin_cs_management_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_notice_edit_screen.dart](lib/features/admin/admin_notice_edit_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_faq_edit_screen.dart](lib/features/admin/admin_faq_edit_screen.dart) | ✅ 완료 |
| [lib/features/admin/admin_inquiry_detail_screen.dart](lib/features/admin/admin_inquiry_detail_screen.dart) | ✅ 완료 |

- 별도 인증 가드 (`/admin_login`)
- 사용자 데이터 조회, CS 문의 답변 기능

---

### 3-13. 기관 연계 (Referral)
| 파일 | 상태 |
|------|------|
| [lib/features/referral/referral_screen.dart](lib/features/referral/referral_screen.dart) | ✅ 완료 |

- 치매안심센터 전화/지도 앱 연동 (url_launcher)
- 치매 관련 긴급 연락처 안내

---

### 3-14. 이상 감지 모니터 (Anomaly Monitor)
| 파일 | 상태 |
|------|------|
| [lib/core/services/anomaly_monitor_service.dart](lib/core/services/anomaly_monitor_service.dart) | ✅ 완료 |

- 활동 미감지 시 보호자 푸시 알림 전송 구조

---

## 4. 미완성 / 플레이스홀더 기능

| 기능 | 파일 | 현황 | 비고 |
|------|------|------|------|
| 온디바이스 LLM 음성 분석 | [lib/core/local_ai_service.dart](lib/core/local_ai_service.dart) | ⚠️ 시뮬레이션 | 실제 MediaPipe/TFLite 모델 미탑재 |
| 음성 발화 지표 추출 (TTR, 발화속도) | voice_assessment_screen | ⚠️ 부분 구현 | STT는 동작, LLM 분석 파이프라인 미연결 |
| Health Connect / HealthKit 연동 | pedometer_manager | ⚠️ 자체 구현 | 플랫폼 공식 API 미연동 |
| 이중 과제 보행 알고리즘 | gait 관련 | ⚠️ 미구현 | 보행 중 인지 미션 부여 기능 |
| FINGER 모델 — 혈압/혈당 입력 | home_screen | ⚠️ 미구현 | 생활 습관 기록 (수면, 혈관) 입력 폼 |
| Standard Export (PDF 실제 생성) | clinical_report_generator | ⚠️ 구조만 완성 | 실제 파일 렌더링/공유 연결 필요 |
| training_corrupted 정리 | [lib/features/training_corrupted/](lib/features/training_corrupted/) | ⚠️ 레거시 | 구 버전 파일, 정리 필요 |

---

## 5. 라우팅 전체 구조

```
/login                           → 로그인
/register                        → 회원가입
/ (MainNavScreen)                → 하단 탭 네비게이션
  ├── 홈 (HomeScreen)
  ├── 훈련 (TrainingHubScreen)
  ├── 생활 (WalkingDashboardScreen)
  ├── 리포트 (ReportsScreen)
  └── 프로필 (ProfileScreen)
/onboarding                      → 온보딩
/consent                         → 동의
/assessment                      → 초기 평가
/cognitive_tasks                 → 인지 과제
/assessment_result               → 평가 결과
/voice_assessment                → 음성 평가
/game/comparison                 → 비교 게임
/game/sequence                   → 순서 기억
/game/sudoku                     → 도형 스도쿠
/game/multiplication             → 구구단
/game/shape_match                → 도형 짝
/game/categorization             → 단어 분류
/game/reading                    → 문장 읽기
/gait                            → 보행 분석
/precise_gait_analysis           → 정밀 보행 분석
/walking_dashboard               → 걷기 대시보드
/memory_garden                   → 일기 작성 (DiaryScreen)
/diary_book                      → 일기 조회 (DiaryBookScreen)
/ai_chat                         → AI 챗봇 (Gemini)
/training/recall                 → 일일 회상
/report_options                  → 임상 리포트 옵션
/profile                         → 프로필
/guardian_link                   → 보호자 연결
/cs_center                       → CS 센터
/cs/notices, /cs/faq             → 공지사항, FAQ
/cs/notice_detail/:id            → 공지사항 상세
/cs/inquiry_submit, ...          → 문의 관련
/admin_login                     → 관리자 로그인
/admin/dashboard                 → 관리자 대시보드
/admin/user_detail/:userId       → 사용자 상세
/admin/cs_management             → CS 관리
/admin/notice_edit, /admin/faq_edit, /admin/inquiry_detail/:id
```

---

## 6. 전체 진행률 요약

| 카테고리 | 완료 | 미완성 |
|---------|------|-------|
| 인증 | ✅ | — |
| 온보딩 | ✅ | — |
| 초기 평가 (UI) | ✅ | LLM 실제 연결 |
| 음성 분석 | ⚠️ 부분 | 온디바이스 AI |
| 인지 훈련 (7종 게임) | ✅ | — |
| 적응형 난이도 | ✅ | — |
| 보행 분석 (가속도계) | ✅ | 이중 과제, HealthKit |
| 홈 / 일상 루틴 | ✅ | 혈압·수면 입력 |
| 감정 일기 | ✅ | — |
| AI 챗봇 (Gemini) | ✅ | — |
| 주간 리포트 | ✅ | PDF 실제 생성 |
| 보호자 연계 | ✅ | 긴급 알림 고도화 |
| 기관 연계 | ✅ | — |
| CS 센터 | ✅ | — |
| 관리자 포털 | ✅ | — |
| FINGER 생활 습관 입력 | ❌ | 전체 미구현 |

---

## 7. 남은 과제 (우선순위 순)

1. **온디바이스 LLM 연결** — `local_ai_service.dart`에 MediaPipe Gemma 2B 또는 Google AI Edge 연동
2. **음성 발화 지표 파이프라인** — TTR(어휘 다양성), 발화 속도, 대명사 비율 계산 로직 구현
3. **PDF 실제 생성** — `clinical_report_generator.dart`에 pdf 패키지 연결
4. **FINGER 생활 습관 기록** — 수면, 혈압/혈당 입력 UI 추가
5. **이중 과제 보행** — 보행 중 인지 미션 부여 UI 및 속도 저하율 측정
6. **Health Connect / HealthKit 연동** — health 패키지로 걸음 수·수면 실데이터 수집
7. **training_corrupted 정리** — 레거시 파일 제거 또는 병합
