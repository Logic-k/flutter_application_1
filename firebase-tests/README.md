# Firestore 규칙·보존기간 정리 테스트

로컬 에뮬레이터에서 두 가지를 검증한다. 운영 프로젝트에는 접속하지 않는다(`demo-` 프로젝트 ID만 사용).

- `rules.test.mjs`: `firestore.rules`의 허용·거부
- `retention.test.mjs`: 매일 정리 작업(`../firebase-ops/retention.mjs`)의 판정·삭제·로그 위생. Auth 에뮬레이터도 쓴다.

```
cd firebase-tests
npm ci
npx firebase-tools@15.19.0 emulators:exec --config ../firebase.json --project demo-memorylink --only firestore,auth "npm test"
```

필요한 것: Node 22, JDK 21. CI는 `.github/workflows/firestore-rules.yml`이 같은 명령을 돌린다.
규칙이나 보존기간을 바꾸면 이 테스트를 함께 고치고, 테스트가 실패하면 배포하지 않는다.
운영 절차는 `docs/release/DATA_DELETION_RUNBOOK.md`.
