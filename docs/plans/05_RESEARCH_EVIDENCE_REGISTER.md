# 공식 정책 및 연구 근거 등록부

- **기준일:** 2026-08-30
- **사용법:** 정책·법령은 의무/권장의 출처로, 연구는 가능성·한계·검증 설계의 출처로만 사용한다. 연구 결과를 MemoryLink 효능 또는 정확도로 직접 전이하지 않는다.
- **강도:** A=공식 법령/플랫폼 정책, B=공식 기술문서, C=동료평가 RCT·체계적 문헌고찰/메타분석, D=프로젝트 감사·판단

## 1. 공식 정책·법령·기술 문서

| ID | 출처·날짜 | 확인된 사실 | MemoryLink 적용 | 강도/재검증 |
|---|---|---|---|---|
| O-01 | [Firebase AI Logic — App Check](https://firebase.google.com/docs/ai-logic/app-check), 문서 갱신 2026-08-27 | 2026-11-02부터 Firebase AI Logic 요청에 App Check enforcement가 자동 필수이며 해제 불가. 유효 token 없는 요청 차단. debug token/build은 production·공개 저장소 금지. Flutter replay protection 최소 AI Logic 4.15.0+, App Check 4.10.0+ 제시 | AI ADR 시한. Firebase AI Logic 선택 시 Stage 1/2 도입. **일반 Gemini REST 직접 호출을 자동 보호하지 않음** | B; SDK/날짜를 구현 직전 재검증 |
| O-02 | [Firebase App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers) | production provider로 Android Play Integrity, Apple App Attest/DeviceCheck 등을 사용. enforcement 전 metrics 모니터링 권장 | debug/production 분리, 단계적 enforcement | B; 콘솔 지원 상태 재검증 |
| O-03 | [Firestore TTL](https://firebase.google.com/docs/firestore/ttl), 갱신 2026-08-26 | 만료 후 보통 24시간 내 삭제; 그 전 query/lookup에 보일 수 있음; subcollection 미삭제; 비트랜잭션; delete 비용/trigger 발생 | 계정 삭제 완료 수단으로 단독 사용 금지. retention 보조만 허용 | B; 재검증 낮음 |
| O-04 | [Firestore Rules unit testing](https://firebase.google.com/docs/rules/unit-tests) | v9 `@firebase/rules-unit-testing`, emulator context와 allow/deny assertion 제공, production 자원 미접촉 | Stage 2 rules 회귀 Gate | B; 패키지 API 구현 시 확인 |
| O-05 | [Google Play 계정 삭제](https://support.google.com/googleplay/android-developer/answer/13327111) | 앱 내 계정 생성 시 인앱 삭제와 재설치 없이 요청 가능한 웹 URL 필요. 연계 데이터 삭제가 원칙, 합법 보존은 고지. 외부 processor에도 삭제 요청 | Auth/Firestore/Storage/local/guardian/AI processor 삭제 workflow | A; 제출 직전 정책 재검증 |
| O-06 | [Google Play Target API](https://support.google.com/googleplay/android-developer/answer/11926878) | 2026-08-31부터 mobile 새 앱/업데이트는 Android 16/API 36+, 기존 앱 가용성은 API 35+, 연장 가능 시점 2026-11-01 | 현재 merged manifest target 36은 기술 기준 충족. 실제 signed AAB/Play pre-review는 별도 증거 | A; 매 제출 전 재검증 |
| O-07 | [Health Connect 앱 게시](https://developer.android.com/health-and-fitness/health-connect/publish), 갱신 2026-03-10 | Play 정책 검토, Data Safety, Health Apps declaration 필수. user-facing 기능에 필요한 최소 data type만 요청하고 각 목적을 상세 설명. privacy URL 일치 | READ data type만 선언, 미사용 WRITE 제거 후보, 선언-런타임 대조 | A/B; 제출 시 재검증 |
| O-08 | [Android exact alarms](https://developer.android.com/develop/background-work/services/alarms), 갱신 2026-08-14 | 대부분 앱은 inexact 사용. exact는 사용자 대면 기능이 정시 동작을 요구하는 경우에만. Android 12+ special access/permission, 배터리 비용 | 단순 일기 알림은 inexact 기본; exact 권한 제거 후보 | B/A(Play 별도 정책); 구현/제출 전 재검증 |
| O-09 | [Android FGS types](https://developer.android.com/develop/background-work/services/fgs/service-types) | API 34+ type별 manifest와 permission/prerequisite. microphone은 while-in-use 제한/RECORD_AUDIO, health는 관련 health/activity 권한 | health와 microphone service 분리 또는 FGS 제거, Play type 선언 일치 | B/A; target 36 동작 재검증 |
| O-10 | [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility-testing) | tap target, labeled target, text contrast guideline을 widget test로 실행; Scanner/TalkBack/semantics와 병행 | Stage 3 자동+실기기 Gate | B; Flutter upgrade 시 API 확인 |
| O-11 | [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), 갱신 2026-06-08 | 1.4.1 건강 측정 정확도/방법 근거, 1.6 보안, 2.3 정확한 metadata, 5.1 privacy/minimization, 인앱 삭제, 제3자 AI 공유 명시·명시적 허가, 건강 연구 동의/IRB | 건강 주장 축소, AI 동의, 인앱 삭제, 실기기/연구 증거 | A; 제출 직전 갱신 확인 |
| O-12 | [OWASP MASVS](https://mas.owasp.org/MASVS/) | STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY 검증 범주 | Stage 1/2 release checklist에 최소 STORAGE/AUTH/NETWORK/PLATFORM/PRIVACY 매핑 | B(산업표준); 버전 고정 |
| O-13 | 국가법령정보센터 `개인정보 보호법` 제21·23·28조의8, 이전 감사에서 DRF 원문 확인 | 파기, 민감정보 처리, 국외이전 관련 법적 검토점 | 건강·인지 데이터 분류, 삭제, Gemini/Firebase 처리지역·고지/동의 검토 | A; 시행일/개정 및 구체 적용은 법률 검토 |
| O-14 | 국가법령정보센터 `디지털의료제품법` 제2·3조, 이전 감사에서 DRF 원문 확인 | 정의·적용범위는 제품의 사용목적/표방과 결합해 판단 필요 | 비의료 경계 유지. 진단·치료·예방/위험판정으로 사용목적을 확장하지 않음 | A; 하위법령·사례와 전문 자문 필요 |

> 정정 기록: 이전 중간 종합의 “한국 법 원문 미확보” 표현은 부정확하다. 개인정보보호법 제21·23·28조의8과 디지털의료제품법 제2·3조는 선행 감사에서 국가법령정보센터 DRF 원문을 확인했다. 다만 아래 공백은 여전히 남는다.

## 2. 연구 근거

| ID | 연구·설계 | 확인된 결과 | 적용 가능 범위와 한계 | 강도 |
|---|---|---|---|---|
| R-01 | Moon et al., 2025, SUPERBRAIN-MEET, 17개 병원 RCT, MCI 300명, 24주. [DOI](https://doi.org/10.1002/alz.14517), [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC11848216/) | mITT 277명. RBANS 24주 변화 MI 8.43 vs control 4.26, 차이 4.17(95% CI 1.92–6.43), p<.001. adherence 84.7%. 치매 전환 HR 0.46(0.14–1.52), p=.202로 유의하지 않음. 운동 관련 근골격 AE 4건 | 개입은 혈관위험 관리·인지훈련·전문가 지도 운동·영양·동기, 대면+Zoom+가족/코디네이터를 포함. **MemoryLink 앱 단독 효과나 치매 예방 효과의 근거가 아님**. 초기 교육/지원, adherence, 안전 모니터링 설계에 참고 | C |
| R-02 | Bea et al., 2025, 만성질환 스마트폰 보행 체계적 문헌고찰, 54개 연구. [DOI](https://doi.org/10.3390/jfmk10020133), [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC12015829/) | validity 연구 70%, correlation r=.42–.97; test-retest ICC .53–.95; feasibility 94%. 속도/케이던스가 step length/variability보다 대체로 강함. 위치·환경·질환·protocol 이질성 | 타 앱/기기 결과는 MemoryLink 성능이 아님. 위치·기기·표면·home/clinical을 고정·층화하고 step event→interval→CV를 별도 검증. 논문 내부 reliability 비율 서술(초록 27%, 본문 50%) 불일치가 있어 개별 표 확인 필요 | C |
| R-03 | Lampit et al., 2014, 건강한 고령자 CCT RCT 메타분석, 52 datasets/4,885명. [DOI](https://doi.org/10.1371/journal.pmed.1001756) | outlier 제거 후 전체 g=.22(95% CI .15–.29). attention/executive는 유의하지 않음. home-based g=.09, group-based g=.29; 지속성/실생활 전이/치매위험은 평가하지 않음 | 구 연구이며 healthy older adults 대상. 게임 점수 개선을 실제 인지건강·예방 효과로 표현하지 않게 하는 제한 근거. 빈도 제안은 최신 근거와 함께 재검토 | C |
| R-04 | Ngandu et al., 2015 FINGER RCT. [DOI](https://doi.org/10.1016/S0140-6736(15)60461-5) | 식이·운동·인지훈련·혈관위험 모니터링의 2년 다영역 개입 근거 | 단일 모바일 게임/앱의 독립 효과로 분해 불가. 다영역·장기·전문가 관리의 중요성 참고 | C |
| R-05 | SUPERBRAIN-MEET protocol, 2024. [DOI](https://doi.org/10.12779/dnd.2024.23.1.30) | 다기관 평가, 대면 outcome, adherence/AE, 구체 개입 구조 | MemoryLink 연구 protocol의 동의·평가자·adherence·AE 설계 참고. 제품 효과 근거 자체는 R-01 | C |

## 3. 사실·추정·결정 구분 규칙

- **확인된 사실:** 코드/manifest/test 출력 또는 위 원문의 직접 진술. 날짜와 범위를 함께 적는다.
- **추정:** 예: 특정 권한을 제거해도 기능이 유지될 것이라는 판단. 반드시 실기기 검증 패킷으로 전환한다.
- **의무:** 법령·스토어 정책상 제출/운영 조건. 법률 해석이 필요한 경우 “전문 검토 필요”를 붙인다.
- **권장:** 공식 기술문서·보안표준·연구가 제시하는 안전한 구현 방향.
- **프로젝트 결정:** 비의료 경계, 검증 전 CV 비공개, AI 미결 시 기능 off 등 위험수용 기준.

## 4. 미확인·재검증 대기

| 공백 | 현재 처리 | 해소 시점/소유자 |
|---|---|---|
| 보건복지부 비의료 건강관리서비스 가이드라인 최신 공식 원문·개정 이력 | 근거로 확정 인용하지 않음. 제품은 더 보수적인 비의료 경계를 적용 | 스토어 문구 확정 전 규제 담당자가 공식 원문 확보 |
| KWCAG 2.2 국가표준 전문과 최신 적용 상태 | “KWCAG 준수” 주장 금지. Flutter guideline+TalkBack/VoiceOver를 실제 Gate로 사용 | 접근성 적합성 주장 전 접근성 담당자 확인 |
| 디지털의료제품법 하위법령·MemoryLink 구체 분류 | 법률 자문 없이 비의료 여부를 확정적 법률 결론으로 표현하지 않음 | 사용목적/마케팅이 변경될 때 전문 자문 |
| Apple/Google/Firebase의 제출 시점 정책 변경 | 기준일 이후 변경 가능 | 각 RC/스토어 제출 직전 URL·갱신일 재검증 |
| MemoryLink CV threshold, 기기별 정확도, 장기 신뢰도 | 검증되지 않음. 외부 공유/위험 표시 금지 | Stage 4 통과 후 독립 심사 |

## 5. 인용 품질 주의

사용자가 제공한 웹 원문에는 복사 과정에서 일부 URL 공백·깨짐과 표 누락이 있다. 이 등록부는 제목·DOI·PMCID와 본문에서 일관되게 확인되는 핵심 결과만 사용했다. 세부 통계·표본수·정책 문구를 외부 제출물에 재사용할 때는 DOI/공식 URL 원문을 다시 열어 확인한다.
