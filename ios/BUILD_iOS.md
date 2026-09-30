# iOS 빌드 안내

macOS + Xcode 환경에서 MemoryLink iOS 앱을 빌드·실행하는 방법입니다.
(Android 빌드에는 영향을 주지 않습니다.)

## 사전 준비
- Xcode + Command Line Tools, CocoaPods
- 최소 iOS 15.0 (Podfile과 Runner 배포 타깃 모두 15.0)

## 실행
```bash
flutter pub get
flutter run -d "iPhone 17"
```
빌드만 확인하려면:
```bash
flutter build ios --simulator --debug          # 시뮬레이터
flutter build ios --release --no-codesign      # 실기기용(서명 전) 컴파일 확인
```
`flutter run`/`flutter build`가 자동으로 `pod install`을 수행합니다. 첫 빌드는
MediaPipe/Firebase 컴파일로 수 분(약 5~10분) 걸립니다.

## `--dart-define=IS_EMULATOR=true`는 선택 사항입니다
앱은 첫 화면을 띄운 뒤(`runApp` 이후) 초기화를 진행하고, Firebase 초기화 실패도
잡아서 **로컬 전용 모드**로 계속 동작합니다. 따라서 `GoogleService-Info.plist`가
없어도 플래그 없이 정상 기동합니다(시뮬레이터에서 확인).
플래그를 켜면 만보기 백그라운드 서비스·Firebase·알림 준비를 아예 건너뜁니다.
**실기기·배포 빌드에는 넣지 마세요.**

## Firebase 백엔드 연결 (고객센터, 보호자 연동, 난이도 동기화)
1. Firebase 콘솔에서 iOS 앱을 등록합니다 (Bundle ID: `com.memorylink.app`).
2. 내려받은 `GoogleService-Info.plist`를 `ios/Runner/`에 **복사만** 하면 됩니다.
   - 이 파일은 `.gitignore` 대상이라 저장소에 올라가지 않습니다.
   - Runner 타깃의 `Copy GoogleService-Info.plist` 빌드 단계가 파일이 있을 때만
     앱 번들에 복사합니다. 없으면 빌드 로그에 경고만 남기고 로컬 전용 모드로 빌드됩니다.
   - 형식은 `ios/Runner/GoogleService-Info.plist.example` 참고.

## 실기기 배포 (TestFlight / App Store)
1. Apple Developer Program 가입 후 Xcode에서 `ios/Runner.xcworkspace`를 열고
   Runner 타깃 → Signing & Capabilities에서 Team을 지정합니다 (Automatic signing).
2. Capabilities: HealthKit(임상 기록 미사용), Background Modes(fetch, processing)가
   이미 설정돼 있습니다.
3. `flutter build ipa` 후 Xcode Organizer 또는 Transporter로 업로드합니다.

## iOS 스모크 테스트 (시뮬레이터)
`integration_test/ios_smoke_test.dart` — 기동·로그인, 걸음 권한 매핑, 만보기 스위치,
리포트 PDF 공유 시트를 실제 iOS 플러그인으로 확인합니다.
```bash
UDID=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl privacy "$UDID" grant motion com.memorylink.app   # 동작 및 피트니스 허용(재부팅 시 다시)
flutter test integration_test/ios_smoke_test.dart -d "$UDID"
```
시뮬레이터는 알림 권한을 미리 허용할 방법이 없어, 테스트는 알림 권한 응답만 대체합니다.

## iOS에서 알아둘 제약
- **백그라운드 만보기**: iOS는 Android 포그라운드 서비스처럼 상시 실행을 허용하지 않습니다.
  앱이 떠 있는 동안 CoreMotion으로 측정하며, 백그라운드 새로고침(BGAppRefresh)은
  iOS가 정하는 시점에만 짧게 실행됩니다.
- **하루 첫 실행 전 걸음**: 현재 로직은 그날 첫 이벤트 시점의 누적값을 기준(0보)으로
  삼습니다. iOS에서는 앱을 늦게 처음 열면 그 전 걸음이 빠지고, 18시 이후라면 활동량
  급감으로 잘못 판정될 수 있습니다. (출시 전 CoreMotion/HealthKit의 '오늘 0시부터'
  조회로 기준을 잡도록 보완 필요)
- **HealthKit**: 엔타이틀먼트와 권한 문구는 있으나 앱이 HealthKit 권한을 요청하지 않아
  현재 iOS 백그라운드 경로의 HealthKit 걸음 조회는 동작하지 않습니다.

## iOS 전용 설정 (참고)
- `ios/Podfile`: `use_frameworks! :linkage => :static` — flutter_gemma(MediaPipe)가
  정적 xcframework라 동적 링크와 섞이면 `pod install`이 실패함. 플랫폼/배포 타깃 15.0,
  permission_handler 매크로(SENSORS/NOTIFICATIONS) 추가.
- `ios/Runner/Info.plist`
  - `BGTaskSchedulerPermittedIdentifiers` — flutter_background_service 네이티브 코드가
    실행 시 이 식별자를 등록하므로 없으면 앱이 즉시 크래시함.
  - 카메라·사진 보관함 권한 문구 (프로필 사진, image_picker).
  - `LSApplicationQueriesSchemes`(tel, sms) — `canLaunchUrl`이 true를 돌려주기 위해 필요.
  - `CFBundleLocalizations`(ko).
- `ios/Runner/PrivacyInfo.xcprivacy` — 매니페스트 없이 사유 필요 API를 쓰는 플러그인
  (flutter_background_service_ios: UserDefaults, pedometer: 부팅 시각) 사유 선언.
- `ios/Runner/AppDelegate.swift` — 알림 센터 델리게이트 지정(앱이 켜져 있을 때도 알림 표시).
- 걸음 권한: iOS는 `Permission.sensors`(CoreMotion), Android는 `Permission.activityRecognition`.
- 공유: iPad와 iOS 26 iPhone은 공유 시트를 팝오버로 띄우므로 모든 공유 호출에
  `sharePositionOrigin`(`lib/core/share_origin.dart`)을 넘깁니다.
