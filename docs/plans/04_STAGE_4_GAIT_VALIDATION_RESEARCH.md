# Stage 4 — 보행 실기기 검증·연구

- **목표 기간:** 내부 파일럿 4~6주; 외부 타당화 3~6개월 이상
- **기본 상태:** MemoryLink 보행 CV는 **연구/실험 지표**. 검증 전 리포트·보호자 공유·위험 표시·마케팅에서 제외한다.
- **연구 근거의 의미:** 2025 체계적 문헌고찰은 스마트폰 보행의 잠재력을 지지하지만 기기, 위치, 환경, 질환, 프로토콜에 따른 이질성이 크다. 타 앱/알고리즘의 상관·ICC·민감도는 MemoryLink 성능이 아니다.

### S4-01 버전형 세션 데이터 모델
- **구분/목표:** 필수; 재현 가능한 원시·파생 보행 세션을 저장한다.
- **근거:** 측정 타당성·추적성; 문헌은 센서 위치와 환경이 결과에 큰 영향을 준다고 보고한다.
- **현재 사실:** CV UI/실행 경로는 있으나 세션 저장·실기기 검증이 없다.
- **영향 파일:** gait models/repository/DB, `gait_session_card.dart`, `walking_dashboard_screen.dart`, export/test.
- **선행/구현:** sessionId, 시작/종료, monotonic timestamp, sampling rate/결측, device model/OS/app/algorithm version, sensor set, placement, protocol, surface/context, detected events, exclusions, derived cadence/interval/CV; consent와 retention.
- **제외:** 이름·전화번호 등 직접식별자와 원시 센서의 무기한 cloud upload.
- **완료/검증:** 같은 fixture+algorithm version이 같은 파생값; schema migration/export/import; 결측·중단·화면잠금 표시; 데이터 삭제 연동.
- **예상 비용/위험/중단·롤백 조건:** 6~10인일; 저장량/민감도 증가. 원시 데이터 보존을 짧게 하고 파생값만 장기 보존; 연구 기능 off.

### S4-02 측정 프로토콜·기기 범위 동결
- **구분/목표:** 필수; 앱 자체 성능을 평가할 고정 조건을 사전 정의한다.
- **근거:** 리뷰에서 hip/pocket이 흔하고 위치 불일치·바닥·home 환경이 오차 원인이다. controlled setting이 home보다 대체로 높은 타당성/신뢰성을 보였다.
- **현재 사실:** MemoryLink의 기기/센서 위치/거리/속도/신발/표면 프로토콜이 고정되지 않았다.
- **영향 파일:** 연구 protocol 문서, in-app 안내/voice guidance, device matrix.
- **선행/구현:** 1차 위치(예: 앞주머니/허리) 하나 선택; 직선 거리와 warm-up, 보행 속도, 회차, 휴식, 신발/보조기, 표면, phone orientation; 최소 Android/iOS·저/중/고 센서군; operator checklist.
- **제외:** 여러 위치·자유생활·이중과제를 한 번에 검증.
- **완료/검증:** 동결 protocol과 deviation form; 3명이 문서만 보고 동일 절차 수행; 세션에 deviation 기록.
- **예상 비용/위험/중단·롤백 조건:** 3~5인일; 대표성 제한. 1차 controlled protocol을 유지하고 home 일반화는 별도 연구.

### S4-03 내부 기술 파일럿
- **구분/목표:** 필수; 알고리즘/UX/데이터 품질 실패를 본 검증 전에 발견한다.
- **근거:** 타당도 연구 전 측정 시스템 안정화 원칙.
- **현재 사실:** 실기기 세션·결측·시작 성공률 baseline이 없다.
- **영향 파일:** test build, data pipeline, 연구 기록. production claim 변경 없음.
- **선행/구현:** 건강한 성인 내부 참가자 소규모, 기기별 반복 세션; 앱 시작 성공, 실제 샘플링, step event 수동 영상/계수, 결측/중단/발열/배터리, 사용성; 사전 exclusion rule.
- **제외:** 질병 분류, 임상적 민감도/특이도, 고령자 결과 일반화.
- **완료/검증:** 모든 지원 기기군에서 사전 정의한 데이터 완전성·시작 성공 기준 통과; 실패 유형/수정 이력; 알고리즘 freeze candidate.
- **예상 비용/위험/중단·롤백 조건:** 5~8인일+기기; 기준 미달 시 해당 기기 비지원 또는 연구 중단.

### S4-04 준거 측정과 타당도·신뢰도 연구
- **구분/목표:** 필수(외부 노출 승격 전); step event와 파생 지표를 수동 계수 또는 검증된 준거 장비와 대조한다.
- **근거:** 2025 리뷰의 concurrent validity/ICC 범위는 가능성을 보이나 MemoryLink CV 임계값을 검증하지 않는다.
- **현재 사실:** `<5/5~10/>10%` 임계값과 치매·낙상 의미는 MemoryLink 대상·프로토콜에서 검증되지 않았다.
- **영향 파일:** protocol/statistical analysis plan, frozen build/algorithm, de-identified dataset, report.
- **선행/구현:** 대상군·표본수는 power/precision 분석으로 결정; assessor blinding 가능성; video/manual heel-strike 또는 instrumented walkway/validated IMU; test-retest; device/placement strata; 사전등록 권장.
- **제외:** 앱 자체 계산을 준거로 사용, 연구 후 threshold 선택, 단일 질환 연구를 일반 고령자에 적용.
- **완료/검증:** step-event precision/recall, interval error, bias/LoA, ICC와 CI, CV repeatability, failure/결측률을 사전 계획대로 보고; raw-to-result audit 재현.
- **예상 비용/위험/중단·롤백 조건:** 15~30인일+장비/연구자; 표본 편향. 기준 미달 시 CV 비공개 유지하고 step count/세션 품질만 제공.

### S4-05 승격 기준과 외부 표시 심사
- **구분/목표:** 필수; 숫자를 본 뒤 유리하게 바꾸지 않도록 승격 조건을 사전 고정한다.
- **근거:** 투명한 연구·Apple 정확도 주장; 프로젝트 비의료 경계.
- **현재 사실:** 현재 임계값은 검증되지 않았고 외부 리포트/guardian 공유 가능성이 있다.
- **영향 파일:** feature flag, report/guardian/product copy, governance record.
- **선행/구현:** S4-04 전 threshold 승인. 최소 지표는 세션 시작 성공, 유효 세션 비율, step precision/recall, absolute/relative interval error, ICC/LoA, 기기군별 결측, adverse event. 목표 수치는 파일럿/통계 자문 후 확정.
- **제외:** p-value 하나로 승격, 전체 평균으로 취약 기기군 실패 은폐.
- **완료/검증:** 독립 검토자가 protocol 대비 결과를 판정; 통과해도 “측정 참고값”만 단계 노출, 질병/낙상 위험 문구는 별도 규제·임상 근거 없이는 금지.
- **예상 비용/위험/중단·롤백 조건:** 2~4인일; 사업 압력. feature flag/remote kill switch, 이전 공개값 제거.

### S4-06 이중과제는 연구 모드로 격리
- **구분/목표:** 향후; 단일과제 측정이 안정된 뒤 안전·윤리 검토 하에 연구한다.
- **근거:** SUPERBRAIN-MEET은 전문가 지도·다영역·24주 개입이며 MemoryLink 3분 이중과제 보행을 검증하지 않는다. 이중과제는 낙상 위험과 수행 혼란을 높일 수 있다.
- **현재 사실:** 앱은 3분 보행 중 40초마다 인지 미션을 제시하는 설명이 있으나 실기기 안전/효과 검증이 없다.
- **영향 파일:** gait dual-task UI/feature flags, consent/protocol/safety monitoring.
- **선행/구현:** S4-05 단일과제 통과; 연구책임자·안전위원; 대상/제외 기준, 보호자/관찰자, 즉시 중단, adverse event, IRB 필요성 판단; dual-task cost 정의.
- **제외:** 일반 사용자 기본 활성화, 집에서 무감독 위험 판정.
- **완료/검증:** 승인된 protocol/동의/중단 절차와 adverse-event review; 별도 연구 결과 없이는 production off.
- **예상 비용/위험/중단·롤백 조건:** 10~20인일+윤리/임상 협력; 신체 손상 위험. 즉시 연구 중단·feature kill.

### S4-07 인간대상 연구 거버넌스
- **구분/목표:** 조건부 필수; 일반 QA를 넘어 일반화 가능한 연구를 수행할 때 동의·윤리·데이터 관리를 갖춘다.
- **근거:** Apple 5.1.3은 연구 동의에 목적·기간·절차·위험/이익·기밀·연락처·철회를 요구하고 독립 윤리위원회 승인을 요구한다. 개인정보보호법·기관 규정을 함께 검토한다.
- **현재 사실:** capstone prototype과 제품 QA, 인간대상 연구 경계가 문서화되어 있지 않다.
- **영향 파일:** protocol, consent, DMP, recruitment, incident/withdrawal procedure. 제품 코드와 분리.
- **선행/구현:** 기관 IRB/법률 검토; data controller/processor, pseudonymization key 분리, 최소 보존, withdrawal/deletion, compensation, vulnerable older adult 지원, conflict disclosure.
- **제외:** 동의 없이 연구용 재사용, QA 데이터를 사후 연구로 전환.
- **완료/검증:** 승인번호/면제 근거, signed consent, access log, withdrawal drill, protocol deviation/adverse event report.
- **예상 비용/위험/중단·롤백 조건:** 기관 일정에 따라 수개월; 승인 전 모집/수집 금지. 제품 QA 범위로 축소.

## 해석 규칙

- 상관계수는 일치도나 개인 수준 정확도를 자동 의미하지 않는다. 가능한 경우 Bland–Altman bias/limits of agreement와 오류 분포를 함께 본다.
- ICC는 모집단 분산에 영향을 받으므로 absolute error, SEM/MDC, 결측률을 함께 보고한다.
- 질환 분류 민감도/특이도는 해당 질환·스펙트럼·threshold에서만 해석한다.
- CV는 충분한 step 수, event 오류, 평균 interval의 영향을 받는다. step 검출이 안정되지 않으면 CV를 계산해도 유효 지표로 취급하지 않는다.
