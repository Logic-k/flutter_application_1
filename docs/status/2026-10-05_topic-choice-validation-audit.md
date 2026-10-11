# Topic Choice 근거 추적 및 사용 보류 감사

작성일: 2026-10-05  
범위: 읽기 전용 감사. 코드 삭제, 롤백, 기능 추가, 새 설문 작성, 임상 효과 주장, 배포, commit/push 없음.

## 0. 핵심 감사 결론

`topic_choice`는 현재 코드상 "리서치 원문 프로토콜을 구현한 기능"이라고 말할 수 없다. 더 정확한 표현은 다음이다.

- **확인됨:** 기존 연구 보고서가 제안한 "첫 파일럿에서는 진단/치료/효과 주장보다 짧은 생활 주제 기반 활동과 운영 가능성 확인을 우선한다"는 방향에 맞춰, 아주 작은 참여형 활동 후보를 만든 상태다.
- **설계가정:** 음식/계절/취미 3개 주제와 짧은 떠올리기 문장은 CST/iCST/회상/생활 대화 원리를 제품 문구로 축약한 자체 설계다. 원문 매뉴얼의 특정 세션, 특정 문항, 특정 치료 dose를 일대일로 옮긴 것이 아니다.
- **미검증:** 대상 적합성, 진행자 필요성, dose, 피로/불편, 접근성, 실제 기기 사용성, 중단/기술오류 기록, 임상/인지 효과, 전문가 내용타당도, 파일럿 운영 가능성은 아직 검증되지 않았다.
- **기관·권리자 확인 필요:** CST/iCST 매뉴얼, 치매안심센터 자료, CIST/MMSE/MoCA/SMCQ/SGDS-K 등 표준 검사·척도·교육자료는 권리와 사용범위를 별도로 확인해야 한다. 현재 활동은 보호 검사문항을 복제하지 않지만, 외부 자료명·프로그램명·효과 근거를 제품 주장에 쓰려면 확인이 필요하다.

**사용 보류 게이트:** 이 기능은 "검증 전 내부 실험 후보"로만 취급한다. 기업 접촉, 센터 제안, 임상/인지 효과 주장, 치매안심센터 프로토콜 구현 주장, 앱 배포 기본 노출은 아래 검증계획의 Gate 0~6 통과 전 보류한다.

## 1. 현재 사용자가 실제로 하는 일

확인됨:

1. 화면은 `TopicChoicePage`이며 `contentVersion`은 `topic_choice_v1`이다. `lib/features/training/topic_choice_page.dart:17-18`
2. 사용자는 3개 주제 중 하나를 고른다: `meal`, `season`, `hobby`. `lib/features/training/topic_choice_page.dart:20-24`
3. 사용자는 도움 정도를 고른다: `independent`, `verbal_prompt`, `hands_on_help`. `lib/features/training/topic_choice_page.dart:26-30`
4. 주제를 고르지 않으면 저장하지 않고 스낵바만 표시한다. `lib/features/training/topic_choice_page.dart:46-52`, `test/widget/training/topic_choice_page_test.dart:130-138`
5. 완료 버튼을 누르면 `activityId=topic_choice`, `completionStatus=completed`, `sessionContext=self_practice`, `contentVersion=topic_choice_v1`, `responseCode=<선택 주제>`를 보낸다. `lib/features/training/topic_choice_page.dart:62-74`
6. UI에는 "대화 내용은 앱에 저장하지 않는다"는 안내가 있고 자유입력 TextField는 없다. `lib/features/training/topic_choice_page.dart:219-220`, `test/widget/training/topic_choice_page_test.dart:122-128`

인간 진행자/대화 여부:

- **확인됨:** 코드 기본 저장값은 `self_practice`다. `lib/features/training/topic_choice_page.dart:71`
- **확인됨:** UI 문구는 말하거나 마음속으로 고르라고 안내한다. 대화는 선택적 행동이지 앱이 검증하거나 필수로 요구하는 단계가 아니다. `lib/features/training/topic_choice_page.dart:228-233`
- **미검증:** CST/iCST처럼 진행자가 주제 전환, 격려, 반응 조절, 사회적 상호작용을 수행해야 하는지 검증하지 않았다.

## 2. 원문 원리와 현재 UI 단계의 추적성

| 원문/보고서에서 확인한 원리 | 현재 UI 대응 | 판정 |
|---|---|---|
| 첫 파일럿은 진단·치료 효과가 아니라 생활 주제 기반 짧은 활동과 운영 가능성 확인이 우선이라는 보고서 결론. `docs/research/2026-10-05_dementia-center-evidence/index.html:147-178`, `current_activity_mapping_and_protocols.md:7-9` | "인지 검사 아님", 주제 선택, 짧은 떠올리기, 도움 정도 기록. `topic_choice_page.dart:101-107`, `:228-233` | **확인됨 + 설계가정** |
| CST는 7주, 주 2회, 45분, 총 14회 RCT dose가 언급됨. `cognitive_intervention_evidence_2026-10-05.md:71-78`, source DOI `https://doi.org/10.1192/bjp.183.3.248` | 단일 2단계 활동. 시간·회기·진행자·집단요소 없음. | **미검증/생략** |
| iCST는 25주, 최대 75회, 회당 30분, 보호자/진행자 동반 모델이 언급됨. `cognitive_intervention_evidence_2026-10-05.md:92-99`, source DOI `https://doi.org/10.1371/journal.pmed.1002269` | 앱은 기본 `self_practice`; 보호자/센터 진행을 요구하지 않음. | **미검증/생략** |
| 인지자극은 의견 교환·사회적 상호작용·의미 있는 일상 대화가 핵심이라는 요약. `center_programs_source_matrix.md:58-59`, `cognitive_intervention_evidence_2026-10-05.md:32-38` | 음식/계절/취미 주제와 짧은 회상 프롬프트. | **설계가정** |
| 회상/일상 이야기 원리는 있으나 효과와 적절성은 맥락 의존. `cognitive_intervention_evidence_2026-10-05.md:153-161`, source DOI `https://doi.org/10.1002/14651858.CD001120.pub3` | 좋아하는 음식/계절/취미를 떠올림. | **설계가정, 효과 미검증** |
| 권리·검사 도구는 사용범위 확인 필요. `questionnaire_rights_validation_ko.md:7-15`, `:37-39`, `:221-228` | 보호 검사문항은 복제하지 않음. 표준 검사명/센터 프로토콜 구현 주장은 없음. | **확인됨 + 권리자 확인 필요** |

직접 요소:

- 짧은 생활 주제, 의미 있는 이야기, 회상/인지자극 방향성.
- 보호 검사문항·점수화 도구를 피하고 자체 활동으로 축소한다는 안전 원칙.

우리 설계가정:

- 음식/계절/취미 3개 주제가 적절하다는 판단.
- 한 화면에서 주제 선택과 도움 정도만 기록해도 파일럿 운영지표로 의미가 있다는 판단.
- `self_practice`에서 대화 없이 마음속 선택만 해도 활동 완료로 볼 수 있다는 판단.

생략 요소:

- 진행자 스크립트, 주제 전환 규칙, 격려/중단 기준.
- 대상자 조건, 제외 기준, 인지 수준별 난이도 조절.
- dose, 회기 수, 회당 시간, 반복 빈도.
- 피로/불편/거부 반응 기록.
- 실제 센터 운영 SOP, 보호자 동의, 개인정보 처리, IRB/윤리 검토.

## 3. source/protocol/version ID와 저장 변수 의미

현재 저장 변수:

- `completion_status`, `assistance_level`, `session_context`, `content_version`, `response_code` 필드는 입력 모델에 있다. `lib/features/training/application/training_attempt_input.dart:1-30`
- 허용값은 코드 상수로 제한되어 있다. `TrainingCompletionStatus`, `TrainingAssistanceLevel`, `TrainingSessionContext`. `lib/features/training/application/training_attempt_input.dart:33-55`
- DB 스키마는 `completion_status`, `assistance_level`, `session_context`, `content_version`, `response_code`를 저장한다. `lib/core/database_helper.dart:520-539`
- v9→v10 마이그레이션은 기존 attempt를 보존하고 새 필드를 추가한다. `lib/core/database_helper.dart:741-768`, `test/unit/core/database_v9_migration_test.dart:175-283`
- 저장소는 해당 필드를 그대로 insert한다. `lib/features/training/data/sqlite_training_progress_repository.dart:100-120`

판정:

- **확인됨:** `content_version=topic_choice_v1`은 앱 내부 콘텐츠 버전이다. 원문 source/protocol ID가 아니다.
- **확인됨:** `response_code=meal|season|hobby`는 선택 주제 코드다. 인지 점수나 임상 결과가 아니다.
- **확인됨:** `assistance_level`은 도움 정도 운영지표다. 독립성/기능수준의 검증된 임상척도가 아니다.
- **미검증:** 원문 source ID, protocol ID, rights/license reference, facilitator ID, session plan ID, dose ID가 없다.
- **권리자 확인 필요:** 보고서가 제안한 `instrument_id`, `license_reference`, `permitted_site` 수준의 추적성은 아직 구현되지 않았다. `questionnaire_rights_validation_ko.md:206`

## 4. 소프트웨어 테스트가 검증하는 것과 못 하는 것

검증하는 것:

- `topic_choice` UI에서 주제와 도움 정도를 선택하면 score/correct/total 없이 metadata를 전달한다. `test/widget/training/topic_choice_page_test.dart:98-120`
- 안내 문구가 있고 TextField가 없다. `test/widget/training/topic_choice_page_test.dart:122-128`
- 주제를 고르지 않으면 저장하지 않는다. `test/widget/training/topic_choice_page_test.dart:130-138`
- 완료 서비스는 topic_choice를 점수 없이 저장하고 legacy score를 만들지 않는다. `test/unit/training/training_completion_service_test.dart:189-224`
- `stopped` 입력은 현재 완료 서비스에서 저장하지 않고 예외 처리된다. `test/unit/training/training_completion_service_test.dart:226-240`
- DB v10 컬럼과 v9→v10 보존을 확인한다. `test/unit/core/database_v9_migration_test.dart:87-100`, `:175-283`
- 라우터에 `/training/topic_choice`가 등록된다. `test/widget/core/router_contract_test.dart:110-112`, `:223-233`

전혀 검증하지 못하는 것:

- 음식/계절/취미가 특정 대상자에게 적절한지.
- 실제 사용자나 보호자가 문구를 이해하는지.
- 진행자 없이 수행해도 되는지.
- 대화가 없거나 마음속 선택만 했을 때 활동 완료로 볼 수 있는지.
- 피로, 불편, 거부감, 낙인감, 좌절감.
- 접근성: 큰 글씨, 스크린리더, 청각/시각/운동 제한, 고령자 터치 정확도.
- 실제 Android 기기, 저사양 기기, 오프라인/DB 오류/회전/백그라운드.
- 임상 효과, 인지 개선, 치매센터 프로그램 적합성.
- 외부 자료 저작권·상표·프로토콜 사용권.

## 5. 현재 빠진 위험요소

| 항목 | 현재 상태 | 판정 |
|---|---|---|
| 대상 | MCI/치매/일반 고령자 중 누구에게 적합한지 정의 없음 | **미검증** |
| dose | 회기 수·빈도·시간 기준 없음. CST/iCST dose와 다름 | **미검증** |
| 진행자 | self practice로 저장. 인간 진행자 필수 여부 미정 | **미검증** |
| 대화 | 말하기 또는 마음속 선택으로 안내. 실제 대화 발생 여부 미측정 | **설계가정** |
| 중단 | DB enum은 있으나 완료 서비스가 stopped 저장을 거부 | **확인됨, 기능 부족** |
| 기술오류 | DB enum은 있으나 UI/서비스 기록 경로 없음 | **기능 부족** |
| 동의 | 활동별 동의/철회/보호자 동의 없음 | **미검증** |
| 접근성 | 테스트 없음 | **미검증** |
| 피로/불편 | 기록 필드/UX 없음 | **미검증** |
| 저작권 | 보호 검사문항은 복제하지 않았지만 원문 프로그램명·매뉴얼 활용권은 미확인 | **기관·권리자 확인 필요** |
| 전문가 내용타당도 | 작업치료/임상심리/치매센터 전문가 검토 없음 | **미검증** |
| 파일럿 | 사용자 관찰/사용성/운영 가능성 파일럿 없음 | **미검증** |
| 실기기 | 현재 감사에서 실기기 검증 없음 | **미검증** |

## 6. 검증 계획과 사용 보류 게이트

| 순서 | Gate | 통과조건 | 필요 증거 | 담당자 |
|---|---|---|---|---|
| 0 | 기능 주장 제한 | 제품/제안서에서 "CST 구현", "치매센터 검증", "인지 개선" 표현 제거. "내부 파일럿 후보"로만 표기 | 문구 리뷰 diff, 금지 표현 체크리스트 | 제품/법무 |
| 1 | 근거 추적성 | `topic_choice_v1` 설계표에 원문 원리, 자체 설계가정, 생략요소를 분리 기록 | 본 문서 + source/protocol traceability 표 | 리서치 담당 |
| 2 | 권리 확인 | CST/iCST/센터 자료/검사도구 명칭·문항·이미지·매뉴얼의 사용범위 확인 | 권리자 또는 기관 답변, 라이선스 기록 | 법무/사업 |
| 3 | 전문가 내용타당도 | 주제 3개, 문구, 도움 정도, 중단 기준에 대해 전문가 2인 이상 검토 | 검토자 이름/역할, 수정 이력, 승인 범위 | 임상자문/작업치료 |
| 4 | 안전·동의 UX | 중단, 불편, 도움 필요, 기술오류, 동의/철회 흐름을 UX로 분리 | 화면 설계, 개인정보 영향 검토 | 제품/개발/개인정보 |
| 5 | 접근성·실기기 | 실제 Android 기기 3종 이상, 글자크기/스크린리더/터치/회전/오프라인 확인 | 테스트 로그, 기기 목록, 실패/수정 이력 | QA |
| 6 | 소규모 사용성 파일럿 | 비임상 사용성 목적의 관찰 파일럿. 완료율, 중단율, 도움 정도, 이해도, 피로/불편 수집 | 프로토콜, 동의서, 관찰기록, 중단 사례 | 리서치/운영 |
| 7 | 외부 제안 가능 | Gate 0~6 증거가 한 폴더에 있고, 주장 범위가 "운영 가능성/사용성"으로 제한됨 | 검증 패키지, 승인 체크리스트 | 총괄 |

Gate 7 전까지 금지:

- 기업·센터에 "검증된 인지 활동"으로 제안.
- 치매 예방/개선/진단/선별 효과 주장.
- CST/iCST/치매안심센터 공식 프로그램 구현 주장.
- 표준 검사·척도 문항, 채점, 컷오프 추가.
- 기본 사용자에게 배포 노출.

## 7. 현재 보류 판정

현재 상태는 **"사용 보류: 내부 검증 후보"**다.

소프트웨어 테스트와 APK 빌드는 앱이 실행 가능한지, 저장값이 기대대로 흐르는지를 확인할 뿐이다. 그것은 기능 효과, 대상 적합성, 센터 적용 승인, 임상 타당성, 저작권 허가를 의미하지 않는다.
