# MemoryLink 현재 상태 및 로드맵

> **2026-07-12 갱신 요약** (이 저장소에서 직접 실행 검증):
> - `flutter analyze` 에러 0 (info 3), `flutter test` **117/117 통과**, **release AAB 빌드 성공(64.3MB, 서명됨)**.
> - P0 보안·릴리스 항목 다수 반영됨: 비밀번호 sha256+salt 해싱, 온보딩 상태 DB 통합,
>   DifficultyProvider username 재바인딩, 패키지명 `com.teammemorylink.memorylink`,
>   release INTERNET 권한, 서명 크래시 가드, R8 minify, 보호자 토큰 `Random.secure()`.
> - 신규: **통합 설정 화면(`/settings`)**, **FINGER 건강 기록(`/health_input`: 수면·혈압·혈당·식이+추세, DB v8 `health_logs`)**, `firestore.rules`, `web/privacy.html`, `RELEASE_CHECKLIST.md`.
> - 남은 출시 블로커는 `RELEASE_CHECKLIST.md` §2 참조 (Firebase Auth 도입, 방침 배포, 실기기 QA).
>
> 아래 본문(6/8 기준)은 이력 보존용이며, 최신 릴리스 판단은 위 요약과 RELEASE_CHECKLIST를 따른다.

> 기준일: 2026-06-08
> 문서 역할: 저장소의 현재 구현, 외부 연동, QA 근거, 릴리스 차단 요인, 다음 작업 순서를 기록하는 권위 문서
> 제품 단계: 연구·캡스톤 프로토타입. 의료기기 또는 상용 서비스의 완성·검증 상태를 의미하지 않는다.

## 1. 상태 판정 기준

| 상태 | 의미 |
|---|---|
| 구현됨 | 저장소에 실행 경로와 핵심 로직이 존재한다. |
| 외부 연동됨 | Firebase, Gemini, Health 등 외부 서비스 호출 코드가 존재한다. 배포 환경에서의 성공을 자동으로 보장하지 않는다. |
| 자동 테스트 확인 | 관련 테스트가 저장소에 존재하거나 과거 자동화 범위에 포함된다. 현재 전체 테스트 통과와는 다르다. |
| 디바이스 확인 | 실제 Android 기기 또는 에뮬레이터에서 해당 흐름을 실행해 확인했다. |
| 프로토타입/스텁 | UI, 규칙 기반 대체 로직, 데모 데이터 또는 일부 호출 구조만 존재한다. |

2026-06-08 기준: Android 에뮬레이터(QA_Device, API 36, 1440×3120)에서 **debug APK 빌드 및 Maestro E2E 20개 플로우 전면 통과(20/20)** 확인. 센서, 권한, 백그라운드 서비스, Health, 알림, 딥링크의 실제 Android 동작은 추가 검증이 필요하다.

## 2. 현재 구현 상태

### 인증, 온보딩, 관리자

- **로컬 SQLite 기반 인증**이 구현되어 있다. `users` 테이블 조회로 로그인·회원가입하며 Firebase Authentication은 사용하지 않는다.
- 사용자 비밀번호와 자동 로그인 자격 증명이 SQLite 및 `SharedPreferences`에 평문으로 저장된다. 자동화용 `admin/admin` 및 데모 계정도 앱 DB에 시드된다.
- 사용자가 입력한 Gemini API 키도 `SharedPreferences`에 저장된다. 공유 운영 키를 Flutter 앱에 빌드 주입해도 추출될 수 있으므로, 운영 호출은 인증된 백엔드 프록시로 이동하고 사용자 소유 키를 허용할 경우 플랫폼 보안 저장소와 제한·회전 정책을 적용해야 한다.
- 온보딩 UI와 DB의 `has_completed_onboarding` 필드는 구현되어 있다. 다만 음성 평가 종료는 별도 `SharedPreferences` 값만 기록하고, 라우터는 DB 완료 상태를 기준으로 복원·리다이렉트하지 않아 재시작 및 재로그인 시 상태가 일관되지 않을 수 있다.
- 관리자 포털 UI, 로컬 통계/사용자 조회, Firestore 기반 CS 기능이 구현되어 있다. 관리자 진입 코드는 소스에 고정된 평문이며 로그인 상태는 로컬 preference로 복원되므로 실제 권한 검증 체계가 아니다.

### 평가와 음성

- 설문, 인지 과제, 결과 화면과 STT 기반 음성 입력 흐름이 구현되어 있다.
- **규칙 기반 음성 지표(TTR/WPM) 구현** 상태다. 어휘 다양성, 발화 속도, 발화량, 문장 완결성, 반복 및 위험 표현을 규칙으로 점수화한다.
- TFLite/MediaPipe 모델 파일 또는 온디바이스 LLM을 실제 추론에 사용하는 ML 파이프라인은 없다. 현재 `LocalAIService`는 규칙 기반 엔진이며 임상적 성능 검증도 없다.

### 인지 훈련과 적응형 난이도

- 훈련 허브, 일일 회상, 7종 미니게임과 정답/반응 시간 기반 레벨 조정 로직이 구현되어 있다.
- 난이도는 Firestore `training_difficulty/{username}`에서 읽고 쓰려는 외부 연동 의도가 구현되어 있다.
- `ChangeNotifierProxyProvider`가 기존 `DifficultyProvider` 인스턴스를 재사용하면서 생성 시의 `username`을 갱신하지 않는다. 최초 빈 사용자명으로 만들어진 인스턴스가 유지되면 Firestore 로드·저장이 무효화될 수 있는 사용자 바인딩 위험이 있다.
- `lib/features/training_corrupted/training_hub_screen.dart`는 파일시스템 손상 상태이며 정상 소스 또는 안전한 레거시 사본으로 취급할 수 없다.

### 보행, Health, 이상 감지

- `pedometer`, 가속도계, 자이로스코프 및 포그라운드/백그라운드 서비스 기반 보행 수집·분석 코드가 구현되어 있다.
- Health 연동은 **부분 구현**이다. iOS 백그라운드 콜백에서 최근 걸음 읽기 코드가 있으나 권한 요청, Android Health Connect 전체 흐름, 수면·혈압·혈당 수집 및 실제 기기 검증은 완료되지 않았다.
- 활동량 이상 감지는 로컬 규칙으로 계산되며, Firestore의 보호자 문서에 경고 상태를 기록하고 앱 내 로컬 알림을 표시하는 구조다. 보호자에게 직접 푸시/SMS를 발송하는 서버 전달 체계는 구현되어 있지 않다.

### 보호자, CS, 외부 서비스

- 보호자 토큰 링크, Firebase Hosting URL, Firestore `guardian_views` 동기화, 공유 UI가 구현되어 있다.
- 토큰 생성은 보안 난수 기반이 아니며 Firestore Security Rules의 최소 권한·토큰 접근 통제는 이 저장소에서 검증되지 않았다.
- 공지, FAQ, 문의와 관리자 CS 화면은 Firestore에 외부 연동된다. Firebase 설정, 네트워크, 배포 규칙이 갖춰진 환경에서만 실제 동작한다.
- Gemini 대화 호출과 로컬 폴백이 구현되어 있으나 API 키·네트워크·응답 품질에 대한 현재 QA 증거는 없다.
- `android/app/google-services.json`이 저장소에 추적되고 있어 개발·운영 Firebase 프로젝트 분리와 배포 키 제한 정책을 명시적으로 관리해야 한다.

### 리포트와 기관 연계

- 차트, 위험요인, 권고사항을 포함한 **4페이지 PDF 생성 구현** 및 미리보기·파일 공유 경로가 존재한다.
- PDF 생성의 실제 Android 파일/공유 동작과 다양한 데이터 조합의 레이아웃은 디바이스에서 재검증해야 한다.
- `ReferralScreen`은 전화·지도 실행 UI를 갖고 있으나 `GoRouter`에 해당 route가 등록되지 않아 앱에서 도달할 수 없는 상태다.

### 기타 사용자 기능

- 홈, 프로필, 감정 일기, 체크리스트, 알림, 접근성 글자 크기, 소셜 랭킹 화면이 구현되어 있다.
- 일부 화면은 로컬 데모 데이터 또는 Firestore 데이터 가용성에 의존한다. 구현 존재를 실제 서비스 데이터 검증으로 해석하면 안 된다.

## 3. 외부 연동 경계

| 연동 | 현재 상태 | 미검증/위험 |
|---|---|---|
| Firestore | 보호자, CS, 소셜 통계, 적응형 난이도 호출 코드 존재 | Security Rules, 오프라인/실패 복구, 사용자 격리, 실제 배포 데이터 |
| Firebase Hosting | 보호자 웹 URL 생성 및 공유 | 배포 콘텐츠와 토큰 접근 통제 |
| Gemini | API 키가 있을 때 호출, 없으면 로컬 폴백 | 운영 키 관리, 네트워크 실패, 품질/안전성 |
| Health | iOS 걸음 읽기 일부 구현 | Android Health Connect, 권한 UX, 실제 기기, 기타 건강 데이터 |
| Android 센서/서비스 | 패키지 및 서비스 코드 존재 | 제조사별 백그라운드 제한, 재부팅, 배터리, 권한 거부 |
| 전화/지도 | `url_launcher` UI 존재 | route 미등록으로 현재 도달 불가 |

## 4. QA 기준선

### 2026-06-08 저장소 기준 (최근 검증)

- 단위 테스트 63개 (통과 여부 미확인, `flutter test` 미실행)
- 위젯 테스트 36개 (통과 여부 미확인, `flutter test` 미실행)
- 통합 테스트 5개 (통과 여부 미확인)
- **Maestro E2E flow 20개 — debug APK 기준 전면 통과(20/20) 확인 ✅** (2026-06-08, QA_Device 에뮬레이터)

> `flutter analyze`, `flutter test`, `flutter build --release`는 green 아님. 확인된 차단 요인은 아래 참조.

### 확인된 차단 요인

1. 테스트 helper가 과거 Supabase 기반 `DifficultyProvider` 생성자와 fake client를 계속 참조해 현재 Firestore 구현과 컴파일 계약이 맞지 않는다.
2. CI는 Flutter 3.32.0을 고정하지만 프로젝트는 Dart `^3.11.3` 및 현재 lockfile 생태계를 요구해 SDK/의존성 해석이 맞지 않는다.
3. `android/app/src/main/AndroidManifest.xml`에 release용 `INTERNET` 권한이 없다. 권한은 debug/profile manifest에만 있다.
4. Android 빌드는 로컬 Gradle cache 문제로 실패한 이력이 있어 캐시 정리 후 재현과 원인 분리가 필요하다.
5. **[해결]** ~~Android 에뮬레이터 없음~~ — QA_Device(API 36)에서 debug APK 빌드 및 Maestro 20/20 통과 확인. 단, 통합 테스트, 센서·권한·알림·Health·딥링크 QA는 추가 검증 필요.
6. `lib/features/training_corrupted/training_hub_screen.dart`는 파일시스템 손상 상태라 분석기 및 파일 탐색의 신뢰성을 떨어뜨린다.

## 5. 알려진 제품·보안 위험

- 평문 비밀번호 저장, 평문 자동 로그인 정보, 앱에 포함된 데모 자격 증명
- 소스에 고정된 관리자 코드와 클라이언트 로컬 상태만 사용하는 관리자 권한
- 보호자 토큰의 예측 가능성 및 Firestore Security Rules 미검증
- 난이도 provider의 로그인 사용자명 바인딩 실패 가능성
- DB와 preference로 분리된 온보딩 완료 상태 및 라우터 복원 누락
- 도달 불가능한 기관 연계 화면
- release 네트워크 권한, 패키지명, 서명 키 설정의 릴리스 준비 부족
- 건강 포그라운드 백그라운드 서비스의 `android:exported="true"` 외부 노출
- 의료적 위험 점수와 권고의 임상 검증 부재

## 6. 우선순위 로드맵

### P0 보안

1. 평문 사용자 비밀번호와 `SharedPreferences` 자격 증명을 제거하고 안전한 인증/세션 저장 방식으로 교체한다.
2. 공유 Gemini 운영 키는 앱에 포함하지 않고 인증된 백엔드 프록시에서 보관·호출한다. 사용자 소유 키 입력을 유지한다면 플랫폼 보안 저장소와 키 제한·회전 정책을 적용한다.
3. 하드코딩 관리자 코드와 로컬 관리자 상태를 제거하고 서버 검증 권한 모델을 도입한다.
4. 보호자 토큰을 암호학적 난수로 발급하고 Firestore Security Rules로 사용자·보호자·관리자 접근을 분리한다.
5. 개발·운영 Firebase 구성을 분리하고 추적 중인 `google-services.json`의 프로젝트·API 제한을 점검한다.
6. 외부 노출이 불필요한 Android 백그라운드 서비스를 비공개로 전환한다.
7. 데모 계정, 개인정보 보존 범위와 로그 노출을 점검한다.

### P0 QA/CI

1. stale Supabase test helper를 현재 Firestore 기반 인터페이스에 맞추고 단위·위젯 테스트 컴파일을 복구한다.
2. CI Flutter/Dart 버전을 프로젝트 SDK 및 lockfile과 일치시킨다.
3. 난이도 provider가 로그인 변경 시 올바른 username으로 재생성 또는 재바인딩되도록 수정하고 회귀 테스트를 추가한다.
4. 온보딩 완료 상태를 단일 저장소로 통합하고 앱 재시작·로그아웃·재로그인 복원 테스트를 추가한다.
5. 손상 파일을 격리·복구한 뒤 `flutter analyze`, `flutter test`, 통합 테스트, Maestro 게이트를 순서대로 green으로 만든다.

### P0 릴리스 기반

1. release manifest의 `INTERNET` 및 필수 런타임 권한을 검토·추가하고 권한 거부 UX를 검증한다.
2. `com.example.flutter_application_1` 패키지명을 실제 제품 식별자로 변경하고 Firebase 설정을 다시 연결한다.
3. release signing의 `key.properties` 부재 처리와 비밀 관리 방식을 정리한다.
4. Gradle cache 실패를 깨끗한 환경에서 재현하고 APK/AAB 빌드를 고정한다.
5. Android 에뮬레이터 또는 실제 기기를 준비해 센서, 백그라운드, 알림, Health, 딥링크, PDF 공유를 검증한다.
6. 기관 연계 route와 사용자 진입점을 연결한다.

### ML 확장

1. Health Connect/HealthKit 권한·동기화 계층을 완성하고 걸음·수면 등 실제 데이터를 검증한다.
2. FINGER 기반 수면, 혈압/혈당, 운동, 식이 입력과 추세 리포트를 추가한다.
3. 보행 중 인지 과제와 이중 과제 비용 지표를 구현한다.
4. 규칙 기반 음성 분석을 유지 가능한 기준선으로 고정한 뒤 TFLite/MediaPipe 모델을 별도 실험으로 추가한다.
5. 데이터셋, 편향, 성능 지표, 설명 가능성, 임상 검토 없이 ML 결과를 진단으로 노출하지 않는다.

## 7. 완료 판정 조건

기능은 코드 존재만으로 완료 처리하지 않는다. 해당 기능의 로컬 로직, 외부 연동 실패 처리, 자동 테스트, Android 디바이스 흐름, 보안·개인정보 검토가 모두 확인된 뒤에만 릴리스 가능 상태로 승격한다. 이 문서의 현재 항목은 구현 범위와 위험을 기록한 것이며 무조건적인 제품 완료 선언이 아니다.
