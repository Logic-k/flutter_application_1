# iOS 빌드 안내 (시뮬레이터)

macOS + Xcode 환경에서 iOS 시뮬레이터로 MemoryLink를 빌드/실행하는 방법입니다.
(Android 빌드에는 영향을 주지 않습니다.)

## 사전 준비
- Xcode + Command Line Tools, CocoaPods 설치
- 최소 iOS 15.0 (Podfile에서 지정)

## 실행
```bash
flutter pub get
flutter run -d "iPhone 17" --dart-define=IS_EMULATOR=true
```
빌드만 확인하려면:
```bash
flutter build ios --simulator --debug --dart-define=IS_EMULATOR=true
```

`flutter run`이 자동으로 `pod install`을 수행하며, 첫 빌드는 MediaPipe/Firebase
컴파일로 수 분(약 5~10분) 걸립니다.

## `--dart-define=IS_EMULATOR=true`가 필요한 이유
이 플래그를 켜면 앱 시작 시 **Firebase 초기화와 백그라운드 서비스**를 건너뜁니다.
저장소에는 iOS용 `GoogleService-Info.plist`가 없으므로, 이 플래그 없이 실행하면
`Firebase.initializeApp()`에서 예외가 발생해 첫 화면이 뜨지 않습니다.

즉 이 플래그는 **백엔드 없이 UI를 시뮬레이터에서 확인**하기 위한 것입니다.

## 실제 Firebase 백엔드까지 붙이려면 (실기기/실서비스)
1. Firebase 콘솔에서 iOS 앱(Bundle ID `com.memorylink.app`) 등록
2. 내려받은 `GoogleService-Info.plist`를 `ios/Runner/`에 추가
3. `--dart-define=IS_EMULATOR=true` **없이** 빌드
4. 실기기 배포 시 Apple Developer 서명 필요 (HealthKit entitlement 포함)

## iOS 전용으로 적용된 설정 (참고)
- `ios/Podfile`: `use_frameworks! :linkage => :static` — flutter_gemma(MediaPipe)가
  정적 xcframework라 동적 링크와 섞이면 `pod install`이 실패함. 플랫폼/배포 타깃 15.0,
  permission_handler 매크로(SENSORS/NOTIFICATIONS) 추가.
- `ios/Runner/Info.plist`: `BGTaskSchedulerPermittedIdentifiers` 추가 —
  flutter_background_service의 네이티브 코드가 실행 시 이 식별자를 등록하므로
  없으면 앱이 즉시 크래시함.
