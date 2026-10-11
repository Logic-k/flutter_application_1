# MemoryLink 안전 인계 템플릿

이 문서는 연구·개발 작업을 다른 환경에서 이어가기 위한 값과 절차의 목록입니다. 실제 비밀키, 비밀번호, 세션 토큰, 보호자 토큰, 실사용자 개인정보는 이 문서와 GitHub에 기록하지 않습니다.

## 현재 작업 기준

```text
Repository: https://github.com/Logic-k/flutter_application_1
Branch: devin/release-hardening
Commit: fa0b0f0
Flutter: 3.41.5
Purpose: MemoryLink Flutter 앱 개발·연구·QA 이어받기
```

다른 환경에서는 먼저 저장소와 브랜치를 받은 뒤, 이 문서의 변수 목록을 확인합니다.

```bash
git clone -b devin/release-hardening https://github.com/Logic-k/flutter_application_1.git
cd flutter_application_1
git checkout fa0b0f0
```

## 필요한 값 목록

아래 값은 실제 값을 적지 않은 이름 목록입니다. 값은 각 서비스의 공식 콘솔 또는 팀의 비밀 저장소에서 별도로 주입합니다.

```text
GEMINI_API_KEY=<별도 발급·보관>
SUPABASE_URL=<프로젝트 URL>
SUPABASE_ANON_KEY=<별도 발급·보관>
FIREBASE_PROJECT_ID=<프로젝트 ID>
FIREBASE_ANDROID_APP_ID=<Android 앱 ID>
FIREBASE_IOS_APP_ID=<iOS 앱 ID>
ADMIN_CODE_SHA256=<관리자 코드의 SHA-256 다이제스트>
DEMO_USERNAME=<테스트 계정 아이디>
DEMO_PASSWORD=<테스트 계정 비밀번호>
```

테스트 계정도 개인정보 또는 운영 계정과 같은 수준으로 취급합니다. 실제 계정값은 이 저장소, 이슈, PR, 로그, 스크린샷, AI 대화에 넣지 않습니다.

## 로컬 저장 위치

개발 머신에서는 다음처럼 Git에서 제외된 파일에만 기록합니다.

```text
private/ai_handoff.local.md
```

이 파일은 직접 만들어야 하며, 다음 형식을 사용합니다.

```text
GEMINI_API_KEY=
SUPABASE_URL=
SUPABASE_ANON_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_APP_ID=
ADMIN_CODE_SHA256=
DEMO_USERNAME=
DEMO_PASSWORD=
```

파일 생성 후 확인합니다.

```bash
git check-ignore -v private/ai_handoff.local.md
git status --short --ignored private/ai_handoff.local.md
```

실제 앱 실행에는 프로젝트의 기존 방식대로 `--dart-define` 또는 플랫폼별 공식 설정 파일을 사용합니다. 비밀값을 Dart 소스에 하드코딩하거나 APK에 포함하지 않습니다. `lib/core/app_secrets.dart.example`는 값이 없는 예시 파일이며, 실제 `app_secrets.dart`는 커밋하지 않습니다.

## 다른 AI에 전달할 안전한 요청문

다른 AI에는 다음 정보만 붙여넣습니다.

```text
MemoryLink Flutter 저장소 작업을 이어간다.
Repository: https://github.com/Logic-k/flutter_application_1
Branch: devin/release-hardening
Base commit: fa0b0f0
작업 기준 문서: docs/SECURE_HANDOFF_TEMPLATE.md
비밀값과 개인정보는 저장소·프롬프트·로그에 기록하지 말고, 필요한 변수명만 요청한다.
실제 값은 로컬 환경변수 또는 팀의 비밀 저장소에서 주입한다.
```

키를 확인하거나 오류를 재현해야 할 때는 전체 값을 공유하지 말고 `마지막 4자리`, 서비스 이름, 만료 여부, 오류 코드만 전달합니다. 키가 노출되었다고 의심되면 먼저 해당 키를 폐기·재발급하고, 이전 키를 저장소의 기록에서 지우는 것만으로 해결되었다고 간주하지 않습니다.

## 현재 상태

이번 템플릿에는 실제 비밀값을 넣지 않았습니다. 현재 작업 트리에서 제공되지 않은 키나 개인정보를 추정해 만들지 않았습니다. 이 파일은 다른 환경에서 필요한 값의 이름과 안전한 적용 순서를 공유하기 위한 인계 문서입니다.
