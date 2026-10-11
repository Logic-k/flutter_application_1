# Topic Choice 검증계획 v2 - 독립 검토 반영

작성일: 2026-10-05  
성격: 기존 구현 보고서와 연구 보고서를 대체하지 않는 별도 검증계획.  
주의: 이 문서는 추가 독립 검토 결론을 반영한 계획 문서이며, 아래 추가 결론 전체가 실제 코드 대조까지 완료되었다는 뜻이 아니다. 코드 대조 완료 항목은 이전 감사 문서의 코드 라인 근거가 있는 항목으로 한정한다.

## 1. 독립 검토 결론

현재 자료가 지지하는 최대 범위는 다음이다.

- **지지 가능:** 인지자극 연구의 일부 원리, 예를 들어 생활 주제, 의미 있는 대화, 즐거운 자극, 도움 정도 관찰을 참고한 독자 활동 초안.
- **지지 불가:** 표준 CST 충실 구현, 치매안심센터 공식 프로그램 구현, 임상 효과, 인지 개선, 진단·선별 도구, 표준 검사 대체.
- **보류 원칙:** 전문가 시연 전에는 초안·미검증 표시를 유지하고, 가상자료/현재 구현/제안/미구현을 분리해야 한다.

원문 기준:

- UCL CST 설명은 CST를 5~8명 그룹, 14회, 회당 45분, 주 2회, 7주 프로그램으로 설명한다. 이 구조는 현재 `topic_choice` 단일 활동과 다르다. 출처: https://www.ucl.ac.uk/brain-sciences/individual-cognitive-stimulation-therapy-icst/evidence-base-cst-intervention
- iCST RCT는 25주 동안 75회, 회당 30분의 가정 기반 caregiver-led 프로그램이며, 인지/QoL 효과는 확인되지 않았다고 보고한다. 출처: https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1002269
- TIDieR는 개입 보고에 `why`, `what`, `who provided`, `where`, `when and how much`, `tailoring`, `how well` 등 재현 가능한 설명 항목을 요구한다. 출처: https://discovery.ucl.ac.uk/id/eprint/1425450/
- MRC-NIHR 복합중재 개발·실행가능성·평가 틀은 제공 URL을 기록한다. 현재 세션에서는 PMC 본문이 브라우저 확인 페이지로 막혀 본문 대조는 미완료다. 출처: https://pmc.ncbi.nlm.nih.gov/articles/PMC8482308/

## 2. 8축 분리 검증 프레임

| 축 | 현재 판정 | 통과 전 금지 | 통과조건 |
|---|---|---|---|
| 1. 근거추적성 | 일부 원리 참고 수준 | 연구 기반 기능, CST 기반 기능이라고 단정 | 원문 원리, 자체 설계가정, 생략요소, 버전 ID를 한 표로 연결 |
| 2. 매뉴얼충실도 | 표준 CST/iCST 충실 구현 아님 | 표준 CST 구현, 치매센터 프로토콜 구현 주장 | CST/iCST와 다른 점을 명시하고, 충실 구현을 목표로 할지 독자활동으로 둘지 결정 |
| 3. 콘텐츠타당성 | 전문가 검토 전 초안 | 적절한 인지활동이라고 확정 | 치매/인지/작업치료/센터 운영 전문가 검토와 수정 이력 |
| 4. 사용성·접근성 | 실사용 미검증 | 고령자에게 쉽게 쓸 수 있다고 주장 | 실기기, 큰 글씨, 터치, 스크린리더, 피로/불편 관찰 |
| 5. 운영측정타당성 | 완료건수는 가능, 참여율·이행률·충실도 불가 | 참여율, 이행률, fidelity 주장 | 배정분모, session assignment, 중단/불편/기술오류, manual log 정의 |
| 6. 임상효과 | 미검증 | 인지 개선, QoL 개선, 예방/치료 효과 주장 | 별도 연구 설계, outcome, 윤리/심의, 분석계획 |
| 7. 구현품질 | 기본 소프트웨어 동작 일부 확인 | 실서비스 안정성 주장 | 실기기 종료/중단/계정격리/오프라인/오류복구 확인 |
| 8. 사용권 | 보호 문항은 복제하지 않았으나 자산·명칭·프로토콜 권리 미확인 | 매뉴얼/센터자료/검사명 상업 활용 주장 | 자산 출처, 프로그램명, 이미지/아이콘/문구, 매뉴얼 사용권 확인 |

## 3. 단계별 게이트

### Gate A. 전문가 시연 전

전문가에게 보여주기 전 최소 조건:

- 화면·문서에 **초안**, **미검증**, **인지자극 일부 원리 참고**, **표준 CST 아님**을 표시한다.
- 가상자료와 실제자료를 분리한다.
- 현재 구현, 제안, 미구현을 분리한다.
- 활동 주제, 문구, 아이콘, HTML 목업, 보고서 문장 등 자산 출처를 확인한다.
- 완료건수는 내부 운영 로그로 보고 가능하지만, 배정분모가 없으므로 참여율·이행률·충실도는 주장하지 않는다.
- 중단 UI가 미구현이라는 이유만으로 모든 전문가 시연을 금지하지는 않는다. 단, 시연 목적과 제한을 명확히 쓰고, 중단/불편/오류는 수기 로그로 보완한다.

### Gate B. 실제 참여자의 감독형 사용성 평가 전

기관 또는 운영 책임자가 먼저 판단해야 할 항목:

- 대상: 누구에게 시도할지, 제외해야 할 상태는 무엇인지.
- 진행자: 가족/직원/연구자 중 누가 옆에서 안내할지.
- 자발적 동의/철회: 시작 전 설명, 거부권, 중단권.
- 중단/불편 대응: 피로, 짜증, 울음, 혼란, 거부감 발생 시 절차.
- 개인정보: 저장되는 값, 저장하지 않는 값, 수기 로그 관리.
- 필요 심의 경로: 내부 QA인지, 사용성 평가인지, 연구인지, IRB/윤리검토가 필요한지.
- 실기기 핵심 확인: 시작, 완료, 뒤로가기, 앱 종료, 저장 실패, 계정 격리, 다른 사용자 데이터 미노출.

감독형 사용성 평가는 임상시험 완료를 전제로 하지 않는다. 다만 효과 주장은 별도 임상 검증 없이는 금지한다.

### Gate C. 가정/반복 운영 확대 전

반복 운영 또는 가정 사용 확대 전 추가 조건:

- 접근성: 글자 크기, 대비, 터치, 음성안내, 보호자 보조.
- 직원/가족 부담: 준비 시간, 설명 시간, 반복 수행 부담.
- 상태 기록: 누락/중복/오류/중단/불편 기록 정의.
- 지원 책임: 앱 오류, 불편 호소, 데이터 문의, 중단 요청을 누가 처리하는지.
- 지표 정의: 모든 지표는 수집 전에 이름, 분모, 분자, 시점, 해석 금지 범위를 정의한다.

## 4. 지표 정의 원칙

수집 전 정의가 필요한 지표:

- `assigned_sessions`: 배정된 활동 수. 없으면 참여율 산출 불가.
- `started_sessions`: 시작된 활동 수.
- `completed_sessions`: 완료 저장된 활동 수. 현재 코드의 완료건수와 가까운 지표.
- `stopped_sessions`: 사용자/진행자 중단 수. 현재 UI 미구현.
- `technical_issue_sessions`: 기술오류 수. 현재 UI 미구현.
- `manual_assistance_level`: 진행자가 관찰한 도움 정도.
- `discomfort_flag`: 피로/불편/거부감 발생 여부.
- `fidelity_check`: 진행자가 계획된 절차를 따랐는지. 현재 자동 산출 불가.

해석 제한:

- 완료건수는 보고 가능하다.
- 배정분모가 없으면 참여율, 이행률, 충실도는 보고하지 않는다.
- 도움 정도는 운영 관찰값이지 기능수준/임상척도가 아니다.
- `response_code`는 주제 선택 코드이지 기억력/언어능력 점수가 아니다.

## 5. 현 문서의 상태 표시

| 주장 | 표시 |
|---|---|
| 인지자극 일부 원리를 참고한 독자 활동 초안 | 가능 |
| 표준 CST 14회/7주/45분 충실 구현 | 금지 |
| iCST 75회/25주/30분 효과를 앱 활동에 적용 | 금지 |
| 감독형 사용성 평가 준비 | 조건부 가능 |
| 임상 효과 주장 | 별도 검증 전 금지 |
| 전문가 시연 | 초안·미검증·제한 표시와 수기 로그 조건부 가능 |
| 가정 반복 운영 | 접근성·부담·지원책임 검토 전 보류 |

## 6. 다음 작업 순서

1. 제안서/보고서/시연 화면의 금지 표현 점검.
2. `topic_choice_v1` 설계표 작성: 원리, 자체 설계, 생략, 위험, 지표.
3. 전문가 시연용 안내문 작성: 초안, 미검증, 표준 CST 아님, 효과 주장 없음.
4. 수기 로그 양식 작성: 중단, 불편, 기술오류, 도움 정도, 관찰 메모.
5. 기관 사용성 평가 여부 판단: 대상, 동의, 철회, 개인정보, 심의.
6. 실기기 핵심 흐름 확인: 완료, 뒤로가기, 앱 종료, 계정 격리.
7. 승인 후 감독형 사용성 평가.

이 문서는 계획 문서이며, 위 1~7을 완료했다는 증거가 아니다.

## 7. 실제 코드 감사 통합 대조표

이 절은 최초 코드 감사 내용을 v2 안에 통합한 것이다. 아래 항목은 실제 소스와 테스트에서 확인한 사실이며, 연구 원문 충실도나 임상 효과가 확인되었다는 뜻이 아니다.

### 7.1 실제 사용자 흐름

| 단계 | 실제 구현 | 소스 근거 | 판정 |
|---|---|---|---|
| 1. 주제 선택 | 사용자는 `meal`, `season`, `hobby` 중 하나를 고른다. 주제를 고르지 않으면 완료 저장을 호출하지 않는다. | `lib/features/training/topic_choice_page.dart:20-24`, `:46-52`; 테스트 `주제를 고르지 않으면 저장하지 않는다` (`test/widget/training/topic_choice_page_test.dart:130-138`) | 확인됨 |
| 2. 짧은 프롬프트 읽기 | 선택 주제에 따라 음식/계절/취미를 떠올리는 짧은 문구를 보여준다. | `lib/features/training/topic_choice_page.dart:185-233`; 테스트 `활동은 안내 질문을 보여주되 자유 대화 내용 입력란을 만들지 않는다` (`test/widget/training/topic_choice_page_test.dart:122-128`) | 확인됨 |
| 3. 도움 정도 선택 | `independent`, `verbal_prompt`, `hands_on_help` 중 하나를 선택한다. 기본값은 `independent`다. | `lib/features/training/topic_choice_page.dart:26-35`, `:131-149`; 테스트 `주제 선택은 점수 없이 도움 정도와 메타데이터를 저장한다` (`test/widget/training/topic_choice_page_test.dart:98-120`) | 확인됨 |
| 4. 완료 저장 | 완료 시 `TrainingAttemptInput`에 `activityId=topic_choice`, `completionStatus=completed`, `sessionContext=self_practice`, `contentVersion=topic_choice_v1`, `responseCode=<선택 주제>`를 넣어 저장한다. | `lib/features/training/topic_choice_page.dart:62-74`; `lib/features/training/application/training_completion_service.dart:56-72` | 확인됨 |
| 5. 화면 종료 | 저장 성공 후 완료 결과 UI를 보여주고 화면을 닫는다. | `lib/features/training/topic_choice_page.dart:76-85` | 확인됨 |

### 7.2 인간 진행자와 대화의 구현 상태

| 항목 | 현재 구현 | 판정 |
|---|---|---|
| 인간 진행자 필수 여부 | 코드에는 진행자 역할, 진행자 ID, 진행자 스크립트, 진행자 확인 단계가 없다. 기본 `sessionContext`는 `self_practice`다. 근거: `topic_choice_page.dart:71`, `training_attempt_input.dart:49-55` | 확인됨 |
| 대화 필수 여부 | UI는 "말하거나 마음속으로 골라보세요" 취지의 프롬프트를 보여주며, 대화 내용을 입력하거나 저장하지 않는다. `TextField`가 없음을 테스트한다. 근거: `topic_choice_page.dart:219-233`, `topic_choice_page_test.dart:122-128` | 확인됨 |
| CST/iCST 사회적 상호작용 충실도 | 원문 CST/iCST의 진행자 조율, 집단 상호작용, caregiver training/support, 회기 운영은 구현되어 있지 않다. | 원문 대비 생략 |
| 감독형 사용성 평가 | 중단 UI가 아직 없어도, 승인된 감독형 사용성 평가는 수기 로그로 중단/불편/기술오류를 보완할 수 있다. 이는 계획상 조건이며 코드 구현 완료가 아니다. | 계획 조건 |

### 7.3 저장 변수의 의미

| 변수 | 실제 의미 | 임상/인지 점수 여부 | 근거 |
|---|---|---|---|
| `activity_id=topic_choice` | 새 참여형 활동 식별자 | 아님 | `training_catalog.dart:77-84` |
| `completion_status=completed` | 완료 저장 경로에서만 기록되는 완료 상태 | 아님 | `topic_choice_page.dart:69`; 완료 서비스는 `stopped` 저장을 거부함 `training_completion_service.dart:267-278` |
| `assistance_level` | 사용자가 선택한 도움 정도 운영값 | 검증된 기능수준 척도 아님 | `training_attempt_input.dart:41-47`; 테스트 `training_completion_service_test.dart:189-224` |
| `session_context=self_practice` | 현재 활동이 자기 연습 맥락으로 저장됨 | 센터/가정 진행 증거 아님 | `topic_choice_page.dart:71`; `training_attempt_input.dart:49-55` |
| `content_version=topic_choice_v1` | 앱 내부 콘텐츠 버전 | 원문 프로토콜 ID 아님 | `topic_choice_page.dart:18`, `:72` |
| `response_code=meal|season|hobby` | 선택한 주제 코드 | 기억력/언어능력/인지 점수 아님 | `topic_choice_page.dart:20-24`, `:73`; 테스트 `topic_choice_page_test.dart:117-118` |
| `score/correct/total=null` | 점수형 게임이 아님 | 점수 없음 | 테스트 `topic_choice_page_test.dart:110-113`, `training_completion_service_test.dart:207-223` |

현재 DB는 위 운영값을 저장할 수 있다. 스키마 근거는 `lib/core/database_helper.dart:520-539`, v9에서 v10으로 기존 attempt를 보존하면서 새 컬럼을 추가하는 테스트는 `test/unit/core/database_v9_migration_test.dart:175-283`이다.

### 7.4 원문 프로토콜과 생략·변형된 부분

| 원문/틀 | 원문 핵심 | 현재 `topic_choice` 상태 | 판정 |
|---|---|---|---|
| UCL CST | 5~8명 그룹, 14회, 회당 45분, 주 2회, 7주 프로그램. 출처: https://www.ucl.ac.uk/brain-sciences/individual-cognitive-stimulation-therapy-icst/evidence-base-cst-intervention | 단일 앱 활동, 2단계 화면, 그룹·진행자·14회 dose 없음 | 표준 CST 충실 구현 아님 |
| iCST RCT | 25주, 75회, 회당 30분, caregiver-led, 훈련·지원 포함. 인지/QoL 효과는 확인되지 않음. 출처: https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1002269 | caregiver training/support, 회기 배정, adherence, dyad 단위 기록 없음 | iCST 효과/충실도 주장 금지 |
| TIDieR | why, materials, procedure, provider, mode, location, dose, tailoring, fidelity 보고 필요. 출처: https://discovery.ucl.ac.uk/id/eprint/1425450/ | `content_version`과 일부 운영값만 있음. provider, where, when/how much, tailoring, fidelity는 없음 | 보고 요건 미충족 |
| MRC-NIHR 복합중재 틀 | 개발·실행가능성·평가를 단계적으로 다루는 틀로 제공됨. 출처: https://pmc.ncbi.nlm.nih.gov/articles/PMC8482308/ | 현재 문서는 URL만 기록. 이 세션에서 PMC 본문 대조는 미완료 | 추가 원문 대조 필요 |

### 7.5 소프트웨어 테스트가 확인한 것과 확인하지 못한 것

확인한 것:

- 주제 선택, 도움 정도 선택, 완료 저장 호출의 데이터 모양.
- 자유 대화 TextField가 없고 대화 내용이 저장되지 않는 구조.
- 주제 미선택 시 저장하지 않는 UI guard.
- `topic_choice`가 legacy cognitive score를 만들지 않는 완료 서비스 동작.
- DB 컬럼 추가와 기존 attempt 보존.
- 라우터 등록.

확인하지 못한 것:

- 주제 3개가 대상자에게 적절한지.
- 인간 진행자가 없어도 되는지.
- 사용자가 실제로 대화를 했는지.
- 피로, 불편, 혼란, 거부감.
- 실기기 접근성, 스크린리더, 큰 글자, 터치 정확도.
- 센터 운영 SOP, 동의·철회, 개인정보, 심의 필요성.
- 참여율, 이행률, fidelity. 현재 완료건수는 보고 가능하지만 배정분모가 없어 참여율/이행률/충실도 주장은 불가하다.
- 임상 효과, 인지 개선, QoL 개선.

### 7.6 최종 보류 문구

사용자·기업·기관에 전달할 때의 안전한 문구:

> 현재 `topic_choice_v1`은 인지자극 연구의 일부 원리를 참고해 만든 독자 활동 초안입니다. 실제 구현은 주제 선택, 짧은 프롬프트 읽기, 도움 정도 선택, 완료 저장까지이며, 인간 진행자 대화는 필수 흐름으로 구현되어 있지 않습니다. 선택 코드는 인지 점수가 아니고, 표준 CST/iCST 프로토콜이나 임상 효과는 입증되지 않았습니다.
