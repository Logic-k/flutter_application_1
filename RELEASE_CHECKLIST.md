# MemoryLink 릴리스 & Google Play 제출 체크리스트

> 기준일: 2026-07-12 · 버전 1.0.0+1 · 패키지 `com.teammemorylink.memorylink`
> 이 문서는 실제 스토어 업로드를 위한 실행 가이드다. 완료 항목은 근거와 함께 체크한다.

## 1. 이번 세션에서 처리한 릴리스 준비 작업

| 항목 | 상태 | 근거 |
|---|---|---|
| `flutter analyze` | ✅ 에러 0 (info 6) | 이 저장소에서 실행 확인 |
| `flutter test` | ✅ 117/117 통과 | 설정(3) + 건강 기록(6) 테스트 추가 포함 |
| **release AAB 빌드** | ✅ 성공 (64.3MB, 서명됨) | `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` |
| 패키지명 실제 식별자화 | ✅ | `com.teammemorylink.memorylink` |
| release `INTERNET` 등 권한 | ✅ | `AndroidManifest.xml` main에 선언 |
| 서명 설정 크래시 가드 | ✅ | `key.properties` 없을 때 debug 폴백 (`build.gradle.kts`) |
| R8 minify + resource shrink | ✅ | release 빌드에 활성화, proguard 규칙 존재 |
| 백그라운드 서비스 노출 축소 | ✅ | `BackgroundService` `exported=false` (실기기 재검증 필요) |
| Firestore 보안 규칙 파일 | ✅ | `firestore.rules` 신규(배포 전 Auth 도입 필요) |
| 개인정보 처리방침 페이지 | ✅ | `web/privacy.html` (배포 후 URL 확정) |
| 통합 설정 화면 | ✅ | `/settings` 라우트 + 프로필 진입점 |

## 2. 스토어 업로드 전 **반드시 처리해야 하는** 블로커 (P0)

1. **Firebase Auth 도입** — ✅ 코드 완료 (2026-07-13)
   - `AuthService.ensureSignedIn()`이 앱 시작 시 `signInAnonymously()` 호출 (실패 시 로컬 기능만 동작).
   - 소유권 필드 반영: `inquiries.authorUid`, `guardian_views.ownerUid`, `training_difficulty` 문서 ID `<uid>_<username>` + `ownerUid`.
   - `firestore.rules`를 실제 스키마에 맞게 갱신 (`global_stats/score_stats` 공유 집계 허용 — 베타 한계).
   - **남은 수동 작업: Firebase 콘솔에서 Authentication > 로그인 방법 > 익명 활성화** 후 규칙 배포.
   - 주의: 기존 username 키 `training_difficulty` 문서는 새 키와 호환되지 않음(베타 데이터라 신규 시작 결정). 데모 공지/FAQ 시드는 debug 빌드 전용으로 전환.
2. **개인정보 처리방침 실제 배포** — `firebase deploy --only hosting` 후 `https://memorylink-7af26.web.app/privacy.html` 접근 확인, `web/privacy.html`의 `[ ]` 항목(운영주체·연락처) 채우기.
3. **google-services.json 프로젝트 분리 점검** — dev/prod 분리, API 키 애플리케이션 제한(패키지명+SHA-1) 설정. (파일 자체는 공개 식별자만 포함하므로 커밋 유지 가능하나, 보안은 규칙+키 제한으로 확보)
4. **키스토어 백업** — `android/memorylink-release.jks`는 `.gitignore` 처리. 분실 시 앱 업데이트 불가하므로 안전한 곳에 별도 백업.
5. **실기기 QA** — 센서/보행 백그라운드 수집, 알림(정확 알람 권한), Health Connect, PDF 공유, 보호자 딥링크(`memorylink-7af26.web.app/guardian.html`).

## 3. 스토어 콘솔 입력 자료

### 앱 정보
- 앱 이름: MemoryLink (현재 라벨 `MemoryLink(beta)` — 정식 출시 시 `android:label` 변경)
- 카테고리: 건강/피트니스 (또는 의료)
- 콘텐츠 등급: 전체이용가 (설문 응답으로 확정)
- 대상 연령: 고령자 포함 전 연령

### 데이터 안전(Data safety) 섹션 매핑
| Play 콘솔 질문 | 응답 근거 |
|---|---|
| 개인정보 수집 여부 | 예 — 이름/나이/건강정보 |
| 건강·피트니스 데이터 | 예 — 걸음/보행/인지점수 |
| 음성/오디오 | 예 — 음성 진단(기기 내 처리) |
| 데이터 암호화 전송 | 예 — HTTPS(Firebase/Gemini) |
| 데이터 삭제 요청 수단 | 예 — 앱 내 "측정 데이터 초기화" |
| 제3자 공유 | Google(Firebase/Gemini) 처리 위탁 명시 |

> 주의: Data safety의 "수집/공유" 정의는 서버 전송 기준이다. 온디바이스 저장만 하는 항목은 "수집"에 해당하지 않을 수 있으나, 보호자 연결·AI 온라인 모드는 전송이 발생하므로 정확히 신고할 것.

### 권한 정당화(민감 권한)
- `RECORD_AUDIO`: 음성 인지 진단
- `ACTIVITY_RECOGNITION` / `health.READ_STEPS`: 보행·활동량 분석
- `FOREGROUND_SERVICE_HEALTH`: 백그라운드 걸음 수집
- `SCHEDULE_EXACT_ALARM`: 저녁 일기 알림 정시 발송
- `POST_NOTIFICATIONS`: 알림 표시

## 4. 버전 관리 전략
- `pubspec.yaml`의 `version: <name>+<code>` 단일 소스. 예) `1.0.0+1`.
- 스토어 업로드마다 **build number(+뒤)** 를 반드시 증가(중복 versionCode 거부됨).
- 빌드 명령: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- 온라인 AI 사용 시: `--dart-define=GEMINI_API_KEY=<키>` (앱에 상수 주입은 추출 위험 — 가능하면 사용자 키 입력만 권장)

## 5. 릴리스 빌드 명령 모음
```bash
# AAB (Play 업로드용)
flutter build appbundle --release

# APK (사이드로드/직접 배포 테스트용)
flutter build apk --release

# 개인정보 처리방침/보호자뷰 호스팅 배포
flutter build web && firebase deploy --only hosting

# Firestore 규칙 배포 (Auth 도입 후)
firebase deploy --only firestore:rules
```

## 6. 남은 제품 리스크 (출시 후 개선)
- 규칙 기반 인지/음성 점수의 임상 검증 부재 — "참고용" 고지 유지.
- Health Connect Android 자동 동기화 미완 (수면·혈압·식이는 `/health_input` 수동 기록으로 대체 제공 중).
- 이상감지 시 보호자 서버 푸시(SMS/FCM) 직접 전달 체계 미구현.
- 관리자 권한이 클라이언트 로컬 상태 기반 — 서버 검증 모델 필요.
