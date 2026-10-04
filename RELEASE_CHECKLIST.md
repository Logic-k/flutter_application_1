# MemoryLink 릴리스 & Google Play 제출 체크리스트

> 기준일: 2026-07-12 · 버전 1.0.0+1 · 패키지 `com.teammemorylink.memorylink`
> 이 문서는 실제 스토어 업로드를 위한 실행 가이드다. 완료 항목은 근거와 함께 체크한다.

## 2026-07-23 인지훈련 게임화 추가 확인

- [ ] SQLite v8 실제 파일을 v9로 올린 뒤 기존 사용자와 임상 점수가 보존된다.
- [ ] 신규 사용자는 시작 활동 5개, 기존 v8 사용자는 8개 활동이 열린다.
- [ ] 비교 훈련 완료 후 XP, 숙련도, 일일 목표가 반영되고 구구단이 열린다.
- [ ] 앱 재시작과 오프라인 상태에서도 XP, 잠금 해제, 연속 학습이 유지된다.
- [ ] 같은 완료 버튼을 빠르게 눌러도 동일 시도 ID가 한 번만 저장된다.
- [ ] 글자 크기 1.0/1.2/1.4와 320dp 폭에서 잘림과 겹침이 없다.
- [ ] 측정 데이터 초기화 후 진행 데이터가 지워지고 시작 활동 5개가 복원된다.
- [ ] `flutter build apk --release` 산출물과 SHA-256을 기록한다.

게임화 API 연동은 이번 범위에서 보류한다. 진행 데이터는 SQLite v9 로컬
저장만 사용하며 HTTP/Firestore 동기화, 원격 DTO, 동기화 큐를 포함하지 않는다.
재개 조건은 개발/운영 환경 분리, 인증 백엔드 프록시, 서버 보관 키,
할당량/비용 제한, 개인정보 동의, 가짜 API 계약 테스트 완료다.

## 1. 2026-07-12 세션에서 처리한 릴리스 준비 작업

> 아래 수치는 **2026-07-12 당시** 실측이며 그대로 보존한다(그 세션의 기록이다).
> 현재 값은 [DEVELOPMENT_ROADMAP.md §1 실측 기준선](DEVELOPMENT_ROADMAP.md#baseline)을 볼 것.

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
   - 콘솔 익명 로그인 활성화 완료 (2026-07-13, 사용자 수행).
   - 주의: 기존 username 키 `training_difficulty` 문서는 새 키와 호환되지 않음(베타 데이터라 신규 시작 결정). 데모 공지/FAQ 시드는 debug 빌드 전용으로 전환.
2. **개인정보 처리방침 실제 배포** — ✅ 완료 (2026-07-13). 문의처 Team MemoryLink / teammemorylink@gmail.com 확정, `https://memorylink-7af26.web.app/privacy.html` HTTP 200 확인. Play 콘솔에 이 URL 입력.
3. **google-services.json 프로젝트 분리 점검** — ✅ API 키 애플리케이션 제한 적용됨 (2026-07-13, 외부 REST 호출 차단 확인).
   - release SHA-1: `6A:9A:38:51:EC:45:A9:E7:FA:76:41:63:3C:A9:CB:A1:E7:02:89:2C`
   - **debug SHA-1도 등록 필요** (미등록 시 개발 빌드에서 익명 로그인 차단): `EA:80:B6:AB:2A:8E:34:12:94:99:93:CF:70:33:D6:25:F1:E5:87:69`
4. **키스토어 백업** — `android/memorylink-release.jks`는 `.gitignore` 처리. 분실 시 앱 업데이트 불가하므로 안전한 곳에 별도 백업. (사용자 확인 필요)
5. **Firestore 보안 규칙 배포** — ✅ 완료 (2026-07-13). 익명 Auth 활성화 후 `firebase deploy --only firestore:rules` 실행.
   검증: guardian_views 비인증 읽기 404(정상 통과), notices 비인증 읽기 403(정상 거부).
6. **실기기 QA** — 걸음 측정 백그라운드 수집과 하트비트, 일기 알림(켜기·권한 거부·재부팅 뒤 유지), 활동량 이상 알림의 문자 확인 창, PDF 공유, 보호자 링크가 브라우저로 열리는지, 계정과 모든 데이터 삭제.

## 3. 스토어 콘솔 입력 자료

### 앱 정보
- 앱 이름: MemoryLink (현재 라벨 `MemoryLink(beta)` — 정식 출시 시 `android:label` 변경)
- 카테고리: 건강/피트니스 (또는 의료)
- 콘텐츠 등급: 전체이용가 (설문 응답으로 확정)
- 대상 연령: 고령자 포함 전 연령

### 데이터 안전(Data safety) 섹션
- 정본은 `PLAY_CONSOLE.md` 8번(2026-10-04 갱신)이다. 예전 이 자리의 7월 표(음성 진단·Gemini·측정 데이터 초기화)는 지금 앱과 맞지 않아 지웠다.

### 권한 정당화(민감 권한) — 2026-10-04 매니페스트 기준
- `RECORD_AUDIO`: 음성 받아쓰기(STT) — 일기·AI 채팅·문장 읽기 훈련의 마이크 입력. 녹음 파일은 저장·전송하지 않고 기기 음성인식 결과 텍스트만 사용한다
- `ACTIVITY_RECOGNITION`: 사용자가 켠 걸음 측정
- `FOREGROUND_SERVICE_HEALTH`: 사용자가 켠 동안 걸음 수를 세는 포그라운드 서비스(선언 답안은 `PLAY_CONSOLE.md` 9번)
- `POST_NOTIFICATIONS`: 일기 알림과 걸음 측정 상시 알림. 앱을 열 때가 아니라 사용자가 켤 때 묻는다
- `RECEIVE_BOOT_COMPLETED`: 사용자가 켠 일기 알림을 재부팅 뒤 다시 건다. 걸음 측정은 재부팅 뒤 자동으로 시작하지 않는다
- Health Connect 권한과 `SCHEDULE_EXACT_ALARM`·`HIGH_SAMPLING_RATE_SENSORS`는 선언하지 않는다(감사 P0-09·P0-04)

## 4. 버전 관리 전략
- `pubspec.yaml`의 `version: <name>+<code>` 단일 소스. 예) `1.0.0+1`.
- 스토어 업로드마다 **build number(+뒤)** 를 반드시 증가(중복 versionCode 거부됨).
- 빌드 명령: `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
- release 빌드는 업로드 키(`android/key.properties`)가 없으면 멈춘다(2026-10-04, 감사 P0-14). debug 키로 서명된 "release"는 더 이상 나오지 않는다. 스토어에 올리지 않을 점검용 release가 필요하면 `flutter build appbundle --release -P allowUnsignedRelease=true`(서명 없음).
- 온디바이스 AI(flutter_gemma)와 모델 다운로드는 2026-10-04에 지웠다. 네이티브 라이브러리가 16KB 페이지 기기에서 돌지 않았다(감사 P0-11). 출시 전 `python scripts/check_16kb.py build/app/outputs/bundle/release/app-release.aab`로 모든 .so가 16KB 정렬인지 확인한다.
- 병합 매니페스트 권한이 Play 신고와 같은지 `python scripts/check_release_manifest.py build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`로 확인한다. 플러그인 업데이트가 권한을 더하면 여기서 멈춘다. 두 검사와 '키 없이 release가 멈추는지'는 CI PR Gate 5단계가 서명 없는 AAB로 매번 돌린다(`.github/workflows/test.yml`).
- 출시 범위는 `docs/release/ADR-001_first_release_scope.md`가 정본이다. 새 빌드를 배포할 때 처리방침 6번과 삭제 안내 페이지에 "설정 → 계정과 모든 데이터 삭제"를 추가해 Hosting·Pages에 배포한다.
- 생성형 AI(Gemini)는 출시 빌드에서 기본으로 꺼져 있다(규칙 기반 대화만). 켜려면 `--dart-define=ENABLE_GENERATIVE_AI=true`가 필요하고, 그 전에 출시 감사 P0-10(인앱 신고·키 노출·무료 등급 약관)을 해결한다. 앱에 개발자 Gemini 키를 넣지 않는다.

## 5. 릴리스 빌드 명령 모음
```bash
# AAB (Play 업로드용). 테스트용 플러그인이 섞이지 않게 깨끗한 상태에서 만든다
flutter clean
flutter build appbundle --release
python scripts/check_16kb.py build/app/outputs/bundle/release/app-release.aab
python scripts/check_release_manifest.py build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
# .so는 9개(libapp·libflutter·libdatastore_shared_counter × 3 ABI)여야 한다. libsqlite3.so가 보이면
# 테스트용 sqflite_common_ffi가 섞인 것이니 flutter clean 뒤 다시 만든다(2026-10-05 깨끗한 빌드 57.9MB로 확인)

# APK (사이드로드/직접 배포 테스트용)
flutter build apk --release

# 개인정보 처리방침/보호자뷰 호스팅 배포 (site/ 폴더를 그대로 올린다)
firebase deploy --only hosting

# Firestore 규칙 배포: 에뮬레이터 규칙 테스트가 먼저 통과해야 한다 (firebase-tests/README.md)
cd firebase-tests && npm ci && npx firebase-tools@15.19.0 emulators:exec --config ../firebase.json --project demo-memorylink --only firestore,auth "npm test" && cd ..
# 보호자 링크 v2 규칙은 '쓰기 거부 시 새 링크 발급' 경로가 든 앱이 먼저 나가야 한다(2026-10-04 백엔드 설계)
firebase deploy --only firestore:rules
firebase deploy --only hosting
```

## 6. 남은 제품 리스크 (출시 후 개선)
- 규칙 기반 인지/음성 점수의 임상 검증 부재 — "참고용" 고지 유지.
- Health Connect Android 자동 동기화 미완 (수면·혈압·식이는 `/health_input` 수동 기록으로 대체 제공 중).
- 이상감지 시 보호자 서버 푸시(SMS/FCM) 직접 전달 체계 미구현.
- 관리자 권한이 클라이언트 로컬 상태 기반 — 서버 검증 모델 필요.
