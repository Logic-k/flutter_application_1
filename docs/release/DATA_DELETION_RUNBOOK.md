# 서버 데이터 보관·삭제 운영 절차

> 작성 2026-10-04 · 대상 Firebase 프로젝트 `memorylink-7af26`(무료 Spark 요금제)
> 공개 약속: [개인정보 처리방침 3번](../../site/privacy.html), [계정 및 데이터 삭제 안내](../../site/delete-account.html)
> 이 문서의 기간을 바꾸면 `firebase-ops/retention.mjs`의 `POLICY`, 두 처리방침 사본(`site/`·`landing/`),
> `PLAY_CONSOLE.md` 8번을 함께 고친다. `test/unit/core/privacy_policy_guard_test.dart`가 어긋남을 잡는다.

## 1. 서버에 무엇이 있고 언제 지워지나

| 위치 | 담긴 것 | 지우는 시점 | 누가 지우나 |
|---|---|---|---|
| `guardian_links/{토큰}` | 소유자 익명 uid, 만든 시각, 만료일 | 공유 중지·새 링크·서버 데이터 삭제 즉시 / 만료(마지막 소식 후 30일) 1일 뒤 | 앱 / 매일 정리 작업 |
| `guardian_views/{토큰}` | 보호자에게 보이는 이름·걸음 수·점수·이상 여부·시각·만료일 | 위와 같음(두 문서를 한 번에) | 앱 / 매일 정리 작업 |
| `guardian_views/{8·16자}` | 예전(v0·v1) 문서: 이름·전화번호 | 바로(2026-10-04 첫 정리에서 22개 삭제) | 매일 정리 작업 |
| `inquiries/{id}` + `replies` | 앱 아이디·제목·내용·상태·시각·작성자 uid | 앱의 서버 데이터 삭제 즉시 / 접수 365일 뒤 | 앱 / 매일 정리 작업 |
| `training_difficulty/{uid}_{아이디}` | 예전 버전의 난이도 | 새 버전 첫 훈련 때 기기로 옮기고 삭제 / 마지막 갱신 90일 뒤 | 앱 / 매일 정리 작업 |
| Firebase Auth 익명 계정 | 무작위 uid, 생성·마지막 사용 시각 | 서버 데이터 삭제 시(기기 계정 1개일 때) / 365일 미사용이고 남은 서버 데이터 없음 | 앱 / 매일 정리 작업 |
| `notices`, `faqs` | 운영 콘텐츠(개인정보 없음) | 지우지 않음 | 운영자(콘솔) |

## 2. 매일 정리 작업

- 위치: `.github/workflows/firestore-retention.yml` → `node firebase-ops/retention.mjs --apply`
- 시각: 매일 03:20 KST(`cron: 20 18 * * *`). **GitHub 규칙상 예약 실행은 기본 브랜치(main)에 이 파일이 있을 때만 돈다.**
- 무료 요금제에는 Firestore TTL 자동 삭제가 없다(TTL 삭제는 결제 활성화 필요). 그래서 이 작업이 대신 지운다.
- 안전장치
  - 필드 마스크로 소유자·시각 필드만 읽는다. 이름·전화번호·문의 본문을 읽지 않는다.
  - 로그에는 개수만 남긴다. 공개 저장소라 Actions 로그가 공개되기 때문이다. 토큰·uid는 찍지 않는다.
  - 읽은 뒤 바뀐 문서는 `updateTime` 전제조건으로 건너뛴다(`skipped`). 앱이 방금 연장한 링크를 지우지 않는다.
  - 한 번에 500건을 넘게 지울 계획이면 아무것도 지우지 않고 실패한다. 판정 오류로 인한 대량 삭제를 막는다.
  - 형식을 모르는 v2 문서는 지우지 않고 `guardian_kept_malformed`로 센다.
- 결과 확인: GitHub → Actions → "Firestore retention". 실패하면 GitHub이 cron을 마지막으로 바꾼 사람에게 메일을 보낸다.
- 손으로 돌리기: Actions → "Firestore retention" → Run workflow. `apply`를 끄면 미리보기만 한다(기본값).

### 실패했을 때

| 증상 | 할 일 |
|---|---|
| `HTTP 403 PERMISSION_DENIED` | 서비스 계정 역할(아래 4번)이 바뀌었는지 본다. 권한 목록을 다시 맞춘다. |
| auth 단계 실패(`google-github-actions/auth`) | 워크플로 파일 이름·브랜치가 GCP 공급자 조건과 같은지 본다. 이름을 바꿨다면 조건도 바꾼다. |
| `삭제 예정 N건이 상한 500건을 넘어 중단` | 미리보기로 `planned` 개수를 보고 원인을 찾는다. 정상이면 로컬에서 `--max-deletes=N`으로 한 번 돌린다. |
| `skipped`가 계속 늘어남 | 같은 문서가 매번 바뀌는 것이다. 앱이 만료일을 미는 중이면 정상이고 다음 날 다시 판정된다. |
| `unknown_collections`에 이름이 보임 | 새 컬렉션이 생겼다. 보관 기간을 정해 이 문서와 `retention.mjs`에 넣는다. |

## 3. 이메일 삭제 요청 처리 (회신 7일 이내)

받는 곳: `teammemorylink@gmail.com`. 담당은 이 메일함 관리자(팀 대표)이고, **대체 담당자 한 명을 팀에서 정해 이 줄에 적는다.**

1. 받은 날 회신한다: "접수했습니다. 7일 이내에 처리하고 다시 알려 드리겠습니다."
2. 앱을 쓸 수 있는 요청자라면 앱 **설정 → 서버에 저장된 내 데이터 삭제**를 먼저 안내한다. 이 방법이 가장 정확하고 즉시 지운다.
3. 앱을 쓸 수 없으면 Firebase 콘솔(Firestore)에서 찾아 지운다.
   - 문의: `inquiries`에서 `username == 요청자 아이디`. 하위 `replies`를 먼저 지우고 문의를 지운다.
   - 예전 난이도: `training_difficulty`에서 `username == 요청자 아이디`.
   - 보호자 공유: `guardian_views`에서 `display_name == 보호자 화면에 보이는 이름`. 같은 이름이 여럿이면
     `last_sync` 시각을 요청자에게 확인한다. 찾은 문서와 **같은 ID의** `guardian_links` 문서를 함께 지운다.
   - 익명 계정은 uid를 알 수 없으면 찾지 않는다. 연결 데이터가 사라지면 365일 뒤 정리 작업이 지운다.
4. 지운 범위를 회신한다. 보호자 링크 주소나 uid는 메일에 적지 않는다.
5. 처리 기록을 **비공개 장소**(팀 드라이브 등, 공개 저장소 금지)에 남긴다: 접수일, 회신일, 지운 범위, 처리자.

## 4. 정리 작업의 권한 구성 (GCP, 2026-10-04 설정)

키 파일은 만들지 않았다. GitHub Actions의 OIDC 토큰을 Workload Identity Federation으로 교환한다.

| 항목 | 값 |
|---|---|
| 서비스 계정 | `firestore-retention@memorylink-7af26.iam.gserviceaccount.com` (사용자 관리 키 0개) |
| 맞춤 역할 | `projects/memorylink-7af26/roles/memorylinkRetention` |
| 역할 권한 | `datastore.databases.get`, `datastore.databases.getMetadata`, `datastore.entities.get`, `datastore.entities.list`, `datastore.entities.delete`, `firebaseauth.users.get`, `firebaseauth.users.delete` (만들기·수정 없음) |
| 풀 / 공급자 | `github-actions` / `memorylink-main` (프로젝트 번호 702473908574) |
| 공급자 조건 | 저장소 id `1227921451`, 소유자 id `106562218`, `ref == refs/heads/main`, `workflow_ref == Logic-k/flutter_application_1/.github/workflows/firestore-retention.yml@refs/heads/main`, 이벤트 `schedule`·`workflow_dispatch` |
| 가장 권한 | 서비스 계정의 `roles/iam.workloadIdentityUser` ← `principalSet://…/attribute.repository_id/1227921451` |
| 켠 API | `iam`, `iamcredentials`, `sts` |

2026-10-04 검증: 이 서비스 계정 토큰으로 운영 미리보기·적용을 돌렸다. 읽기·삭제 성공, 문서 만들기 403,
익명 계정 삭제 권한 확인(없는 uid로 탐침). 검증용으로 잠시 준 토큰 발급 권한은 회수했다.

**끊는 법**(정리 작업을 멈추거나 GitHub 신뢰를 없앨 때): 서비스 계정의 `workloadIdentityUser` 바인딩을 지우거나
공급자 `memorylink-main`을 사용 중지한다. 완전히 없애려면 공급자·풀·서비스 계정·맞춤 역할 순으로 지운다.

**보안 메모**: main에 push할 수 있는 사람은 이 워크플로를 바꿔 Firestore를 읽거나 지울 수 있다.
main 브랜치 보호(직접 push 금지, PR 필수)를 켜고, 로컬에 평문으로 남은 GitHub 토큰은 폐기한다.

## 5. 비상시 로컬 실행

```bash
# gcloud가 있으면(사용자 계정 토큰이므로 할당량 프로젝트를 함께 준다)
FIRESTORE_ACCESS_TOKEN="$(gcloud auth print-access-token)" GOOGLE_QUOTA_PROJECT=memorylink-7af26 \
  node firebase-ops/retention.mjs            # 미리보기
FIRESTORE_ACCESS_TOKEN="$(gcloud auth print-access-token)" GOOGLE_QUOTA_PROJECT=memorylink-7af26 \
  node firebase-ops/retention.mjs --apply    # 적용
```

테스트(에뮬레이터 전용): `firebase-tests/README.md`.
