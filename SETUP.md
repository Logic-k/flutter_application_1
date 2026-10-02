# MemoryLink — 실행(재현) 안내

> **요약: 추가 계정·API 키·설정 파일 없이 그대로 빌드하고 실행할 수 있습니다.**
> **필수 요건: Flutter 3.41.5 이상 · Android SDK Platform 36 · JDK 17 이상.**
> 실제 빌드 성공 기록은 같은 폴더의 `BUILD_VERIFICATION.md` 를 보십시오.
> 아래 2줄이면 됩니다.
>
> ```
> flutter pub get
> flutter run          # 또는  flutter build apk --debug
> ```

---

## 1. 실행 환경

| 항목 | 버전 |
|---|---|
| Flutter | **3.41.5** (stable, 2026-03-17) |
| Dart | **3.11.3** (pubspec `sdk: ^3.11.3`) |
| Android compileSdk / targetSdk | **36** (Flutter Gradle Plugin 기본값 상속) |
| Android minSdk | **26** |
| JDK / jvmTarget | **17** |
| Android Gradle Plugin | 8.9.1 · Kotlin 2.1.0 · Gradle Wrapper 8.12 |

macOS/Windows/Linux 모두 동일합니다. iOS 프로젝트도 포함돼 있으나
심사 대상은 Android이며, iOS는 `GoogleService-Info.plist.example`만 들어 있습니다.

## 2. 첫 실행 시 만들어지는 것

- 로컬 **SQLite v9** 데이터베이스(테이블 11개)가 자동 생성됩니다.
- 릴리스가 아닌 빌드(`debug`/`profile`)에서는 **데모 계정과 시드 데이터**가 자동 입력됩니다.

| 구분 | 아이디 | 비밀번호 |
|---|---|---|
| 데모 사용자 | `kim_minjun` | `ci-demo-only-20261002` |
| 자동화 테스트용 관리자 | `admin` | `admin` |

> 보안상 `release` 빌드에서는 두 계정이 시드되지 않습니다
> (`lib/core/database_helper.dart`의 `if (!kReleaseMode)`).
> **심사용으로는 `flutter run` 또는 `flutter build apk --debug`를 사용해 주십시오.**

## 3. 외부 서비스 — 전부 없어도 동작합니다

이 앱은 외부 자격증명이 하나도 없는 상태를 **정상 동작 경로**로 설계했습니다.

| 서비스 | 용도 | 없을 때 동작 |
|---|---|---|
| **Firebase**(Firestore/Auth) | 보호자 안심 연결 동기화 | `FirebaseService.initialize()`가 예외를 받아 **로컬 전용 모드**로 계속합니다(`lib/core/firebase_service.dart:16-24`). 보호자 공유만 비활성화되고 나머지 기능은 전부 동작합니다. |
| **Google Gemini API** | AI 회상 대화 | 키가 없으면 `LocalFallbackProvider`(규칙 기반)로 자동 전환됩니다. 대화는 끊기지 않습니다. 키를 넣고 싶으면 앱 내 **설정 → AI 대화 → Gemini API 키**에 입력하거나 `--dart-define=GEMINI_API_KEY=...`로 주입하십시오. |
| **온디바이스 Gemma 모델** | 오프라인 AI 대화 | 사용자가 설정에서 명시적으로 내려받을 때만 사용합니다. 내려받지 않으면 위 폴백이 동작합니다. |
| **wttr.in** | 대화에 날씨 맥락 주입 | 키 불필요. 실패해도 날씨 문장만 빠집니다. |
| **공공데이터포털 치매안심센터** | 가까운 센터 안내 | **런타임 호출 없음.** `assets/data/dementia_centers.csv`에 전국 256곳이 동봉돼 있습니다. |

### `android/app/google-services.json` 에 대하여

이 저장소에는 **평가용 자리표시자**가 들어 있습니다.

- 이 파일이 필요한 이유는 런타임이 아니라 **빌드**입니다.
  `com.google.gms.google-services` Gradle 플러그인이 적용돼 있어 파일이 없으면
  `File google-services.json is missing.` 로 빌드가 실패합니다.
- 따라서 **패키지명(`com.teammemorylink.memorylink`)만 실제와 맞춘 더미 값**을 넣어
  빌드가 통과하도록 했습니다. 운영 프로젝트의 키·프로젝트 ID는 포함하지 않았습니다.
- 이 더미로는 Firebase 연결이 성립하지 않으며, 위 표대로 **로컬 전용 모드**로 실행됩니다.
- 실제 Firebase를 붙여 보시려면 Firebase Console에서 프로젝트를 만들고
  Android 앱을 패키지명 `com.teammemorylink.memorylink`로 등록한 뒤,
  내려받은 `google-services.json`으로 이 파일을 교체하시면 됩니다(선택 사항).

## 4. 검증 방법

```bash
flutter analyze          # 에러 0 · 경고 0 (남는 info는 전부 스타일 힌트)
flutter test             # 전부 통과
```

E2E는 [Maestro](https://maestro.mobile.dev) 플로우가 `maestro/`에 있습니다.
게이팅 대상 목록은 `run_maestro_tests.ps1`의 `$flows` 배열이 정본이며,
`maestro/helpers/`는 다른 flow가 불러 쓰는 조각이라 단독 실행 대상이 아닙니다.

```bash
maestro test maestro/login_flow.yaml
```

제출한 시연영상도 이 플로우로 녹화했습니다(`maestro/demo_recording_tta_2min.yaml`).

## 5. TTA 표준 적용 위치

지정 파일 상단에 `[TTA 표준 적용]` 주석 블록으로 표준번호·표준명·적용 지점을 명시했습니다.

| 표준 | 파일 |
|---|---|
| TTAK.KO-10.1397-Part4 | `lib/core/services/guardian_sync_service.dart` |
| TTAK.KO-10.1497 | `lib/core/ai/ai_chat_service.dart` · `lib/features/reports/clinical_report_generator.dart` |
| TTAK.KO-12.0414 | `lib/features/onboarding/consent_screen.dart` · `lib/core/database_helper.dart` |
| TTAK.KO-08.0057 (준용) | `lib/core/settings_provider.dart` · `lib/core/theme.dart` |
| TTAK.KO-11.0309/R1 | `sbom.json` (구성요소 199종, SHA-256 해시 포함) |

## 6. 포함하지 않은 것

빌드 산출물(`build/`, `.dart_tool/`, `.gradle/`), 서명 키(`*.jks`, `key.properties`),
운영 Firebase 설정, IDE·에이전트 설정 디렉터리, 개발 로그·스크린샷, 시연 영상 원본,
그리고 개발 머신의 SDK 절대경로가 담긴 `android/local.properties`를 제외했습니다.
(`local.properties`는 Flutter가 빌드 시 자동 생성하므로 없는 편이 재현에 유리합니다.)
