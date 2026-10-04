# 서드파티 소스 고지 (THIRD_PARTY_NOTICES)

pub.dev 의존성은 `pubspec.lock`과 각 패키지의 LICENSE 로 관리한다. 이 문서는 **소스를 복사해 개조한 코드**만 다룬다.

## flutterfx/flutterfx_widgets

- 출처: https://github.com/flutterfx/flutterfx_widgets (MIT, Copyright (c) 2024 FlutterFX)
- 성격: pub 패키지가 아닌 복사-붙여넣기 카탈로그. 저장소 루트에 LICENSE 파일이 없고 `packages/flutterfx_blur_fade/LICENSE` 와 README 가 MIT 를 명시한다.
- 규약: 복사본은 `lib/core/fx/` 에만 둔다. 파일 첫 줄에 원본 경로·커밋·MIT 를 표기하고 이 표에 등록한다. `test/documentation_consistency_test.dart` 가 검사한다.
- 계획: `docs/plans/07_FLUTTERFX_MOTION_UPGRADE.md`

| 복사본 | 원본 파일 | 커밋 | 변경 요약 |
|---|---|---|---|
| `lib/core/fx/spring_out_curve.dart` | `lib/tools/curves.dart` (`SpringOutCurve`) | `9089ad7` | 0→1 램프(easeOutCubic) 추가, 위상을 `t^tension` 으로 지연, 오버슈트 기본 0.2→0.05 |
