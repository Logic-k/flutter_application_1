# Stage 3 — 기존 데이터로 만드는 제품 가치

- **목표 기간:** 3~5주
- **원칙:** 신규 민감정보 수집보다 이미 보유한 훈련·활동·일기·건강 기록을 정확하고 접근 가능하게 보여준다.
- **진입 조건:** 데이터 의미·삭제 계약과 stats 신뢰경계 확정

### S3-01 데이터 의미 사전과 훈련 타임라인
- **구분/목표:** 필수; 훈련 기록을 날짜별 세션·게임·점수·난이도로 추적 가능하게 한다.
- **근거:** 제품 판단; CCT 연구는 효과가 작고 훈련 과제 성과가 실제 생활/치매예방으로 전이된다고 보장하지 않는다.
- **현재 사실:** 7종 게임·적응 난이도·SQLite score가 있으나 장기 타임라인/설명 가치가 제한된다.
- **영향 파일:** training repositories/models/screens, DB query/index, tests.
- **선행/구현:** score, XP, streak, best의 정의·timezone·동점·누락·버전 규칙; 일/주 타임라인; 게임별 비교는 동일 버전/난이도 내 우선; 원시값과 표시값 분리.
- **제외:** 훈련 점수로 인지저하/질환 위험 추정, 집단 백분위를 임상 규준처럼 표현.
- **완료/검증:** seed DB에서 날짜·timezone·빈 날·중복 세션이 정확; 사용자 문구가 “훈련 기록”으로 제한; golden/widget/query test.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 구 schema 누락. migration 없이 read model부터 추가하고 feature flag로 이전 화면 복귀.

### S3-02 건강·생활 추세 화면
- **구분/목표:** 권장; 혈압·혈당·수면·식이의 입력 이력을 추세와 누락 상태로 제공한다.
- **근거:** 자기기록의 사용자 가치; Apple/Play 건강 데이터 최소화와 정확한 표시 요구.
- **현재 사실:** 건강 기록 입력 경로가 있으나 추세 활용이 제한되고 Health는 read-only이다.
- **영향 파일:** settings/health models, charts, repositories, export/delete.
- **선행/구현:** 단위·측정시각·source(manual/Health)·수정 이력; 단위 변환; 범위 밖 값은 입력 오류 확인만 하고 의학 판정하지 않음; source attribution; 숨김/삭제.
- **제외:** 진단 기준선 색상, 약물/치료 권고, 자동 Health write.
- **완료/검증:** 단위/날짜/source/빈 상태가 정확하고 삭제 즉시 반영; extreme input·timezone·DST·권한철회 테스트.
- **예상 비용/위험/중단·롤백 조건:** 5~9인일; 수치 오해 위험. 차트 해석 문구를 중립화하고 기능 플래그로 추세 숨김.

### S3-03 리포트·PDF 정확성
- **구분/목표:** 필수; 차트와 PDF가 실제 날짜·영역·데이터 유무를 정확히 반영한다.
- **근거:** Apple accurate metadata/health measurement, 일반 데이터 무결성 원칙.
- **현재 사실:** 리포트 차트에 날짜/영역/빈 상태 문제가 있고 `clinical_report_data.dart` 등에서 의미 혼동 가능. PDF 생성 성공률이 SLI 후보이다.
- **영향 파일:** `reports_screen.dart`, `clinical_report_data.dart`, PDF generator, chart widgets/tests.
- **선행/구현:** report period inclusive/exclusive 규칙; 4개 영역 mapping; no-data/partial-data; source/version/생성시각; “임상” 명칭 제거 또는 참고 기록으로 변경; 보행 CV 제외.
- **제외:** 자동 임상 해석, 검증 전 gait 지표, 사용자 간 규준 비교.
- **완료/검증:** fixture별 UI/PDF 값·날짜·영역 일치, 0/1/부분 데이터 정상; PDF 텍스트 extraction/golden, 공유 실패 UX, 성공률 계측.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일; 기존 PDF 소비자 혼란. schema/version 표기와 이전 형식 fallback.

### S3-04 오류·권한·오프라인 상태 UX
- **구분/목표:** 필수; silent failure를 사용자에게 행동 가능한 상태로 바꾼다.
- **근거:** 접근성·투명성·안전한 실패 원칙.
- **현재 사실:** guardian alert 실패가 숨겨지고 AI/Health/Firestore가 network/permission에 따라 실패할 수 있다.
- **영향 파일:** 공통 error model, gait/guardian/AI/report/health screens, localization/tests.
- **선행/구현:** `loading/empty/offline/permission-denied/partial/retryable/fatal` 상태 사전; 마지막 성공시각; retry/cancel; 데이터 손실 없는 optimistic UI; 기술 메시지와 사용자 메시지 분리.
- **제외:** 모든 오류를 “잠시 후 다시”로 뭉개기, 실패를 성공처럼 표시.
- **완료/검증:** 핵심 5경로에 상태별 UI와 semantics; airplane mode/권한거부/timeout/partial seed widget·integration test.
- **예상 비용/위험/중단·롤백 조건:** 4~7인일; UI 복잡도. 공통 component를 단계 적용하고 기존 화면으로 feature rollback.

### S3-05 접근성 자동·실기기 검증
- **구분/목표:** 필수; 고령 사용자 핵심 경로의 탭 크기·라벨·대비·확대·스크린리더를 검증한다.
- **근거:** Flutter 공식 `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`; Android Accessibility Scanner/TalkBack 병행 권장.
- **현재 사실:** 접근성 요구가 기존 로드맵에 있으나 현재 UI 전체 자동 Gate는 미확인. KWCAG 2.2 국가표준 전문은 이번 기준일에 재검증 보류.
- **영향 파일:** widget tests, theme/components, 핵심 screens, CI/manual matrix.
- **선행/구현:** 로그인→홈→훈련→기록→리포트→삭제 핵심 journey; semantics label/hint/order; textScale 200%; 색상 외 상태표시; 44/48dp 기준; motion/timeout 대안.
- **제외:** 자동 guideline만으로 전체 적합성 선언, KWCAG 준수 인증 주장.
- **완료/검증:** 핵심 화면 guideline test 0 failure; TalkBack/VoiceOver/Scanner 실기기 결과; 키보드/스위치 접근 검토; 예외는 owner/기한.
- **예상 비용/위험/중단·롤백 조건:** 6~10인일; 레이아웃 변경. 작은 component 단위 적용, 접근성을 낮추는 롤백 금지.

### S3-06 지표 명칭·설명 정리
- **구분/목표:** 필수; 계산값과 사용자에게 보이는 의미를 일치시킨다.
- **근거:** 오해 방지와 accurate metadata.
- **현재 사실:** `gaitStability`가 실제 CV가 아니라 걸음 목표 달성률이며 명칭이 임상적 안정성처럼 보인다.
- **영향 파일:** gait/report models, UI strings, migration/export schema.
- **선행/구현:** 지표 사전; `goalCompletionRate` 등 실제 계산명으로 변경; CV는 연구 전용 namespace/feature flag; tooltip에 데이터 source와 한계.
- **제외:** 호환성을 이유로 오해 명칭 계속 노출.
- **완료/검증:** 코드/화면/export에서 같은 의미·단위; legacy 데이터 migration test; “안정성/위험” grep 검토.
- **예상 비용/위험/중단·롤백 조건:** 3~5인일; API 호환성. versioned alias를 내부에만 유지하고 UI는 즉시 수정.

### S3-07 개인정보 최소 제품 계측
- **구분/목표:** 권장; 제품 개선에 필요한 성공/실패만 집계한다.
- **근거:** Apple/Play 최소수집, MASVS PRIVACY.
- **현재 사실:** 크래시프리, 걷기 시작, PDF 성공률의 측정 정의가 필요하다.
- **영향 파일:** telemetry wrapper, consent/settings, dashboard.
- **선행/구현:** event allowlist, random/pseudonymous session, coarse device/OS, no raw health/diary/prompt/token; opt-out; retention; SLI 분모/분자.
- **제외:** 사용자 건강 프로필, 광고 타기팅, cross-app tracking.
- **완료/검증:** schema test에서 금지 필드 reject; opt-out 전송 0; dashboard를 test event로 재현; privacy 문서와 일치.
- **예상 비용/위험/중단·롤백 조건:** 4~7인일; 재식별/SDK 위험. 자체 최소 endpoint 또는 계측 off.

## Stage 3 출시 판단

제품 화면은 사용자가 “무엇을 언제 기록/훈련했는지”를 이해하게 해야 하며, “이 수치가 질병 위험을 뜻한다”는 해석을 유도하면 No-Go다. 접근성, 빈 상태, 데이터 source, 삭제 반영을 기능 완료 정의에 포함한다.
