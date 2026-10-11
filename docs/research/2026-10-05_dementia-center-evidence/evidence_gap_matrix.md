# MemoryLink 센터 연계 근거 격차 매트릭스

- 작성일: 2026-10-05
- 성격: 읽기 전용 설계 검토 보조자료
- 범위: 현재 구현된 7개 훈련 게임, `daily_recall`, 온보딩 자가체크, 간단 인지과제의 근거 격차와 검증 방법
- 제외: 앱 코드 수정, 전체 테스트 실행, 임상 효과 추정, 외부 연락, 배포, Git commit/push

## 기준 문서

아래 문서를 현재 코드와 대조했다. 일부 기존 문서는 Windows 콘솔에서 한글이 깨져 보였으므로, 경로와 코드/문서 구조를 기준으로 의미를 재확인했다.

| 문서 제목 | 경로 | 이번 검토에서의 역할 |
|---|---|---|
| MemoryLink | `README.md` | 제품 소개, 7개 훈련/보행/리포트/보호자/면책 표현의 외부 노출 기준 확인 |
| MemoryLink 프로젝트 문서 | `PROJECT_DOCS.md` | 라우트, 기능, DB 테이블, 평가/훈련/리포트 설명의 현재 문서화 상태 확인 |
| DEVELOPMENT_ROADMAP | `DEVELOPMENT_ROADMAP.md` | MMSE/GDS 제거, `activityIndex` 전환, CIST 안내, 의료기기/효과 주장 제한 확인 |
| MemoryLink 실행 계획 README | `docs/plans/README.md` | 제품 범위가 비의료 생활습관/인지훈련/일기/자가 모니터링임을 확인 |
| Stage 4 보행 실기기 검증/연구 | `docs/plans/04_STAGE_4_GAIT_VALIDATION_RESEARCH.md` | 보행 CV와 보호자/리포트 표시의 검증 원칙을 인지훈련 쪽 검증 프레임에 참고 |
| 정책 및 연구 근거 등록부 | `docs/plans/05_RESEARCH_EVIDENCE_REGISTER.md` | SUPERBRAIN-MEET, Lampit CCT, FINGER, 앱스토어/의료기기/개인정보 제한 기준 확인 |
| ADR-001 첫 출시 범위 | `docs/release/ADR-001_first_release_scope.md` | 첫 출시에서 의료적 표현, AI, Health Connect, 보호자 공유를 제한한 결정 확인 |
| 연구 QA 베이스라인 | `docs/qa/2026-10-01-research-qa-baseline.md` | 음성 지표, 0점/미측정 구분, 임상 타당도 미확보 상태 확인 |
| 음성 지표 계약 | `docs/qa/2026-10-01-speech-metric-contract.md` | WPM/TTR/음성 입력 출처와 임상 해석 제한 확인 |
| 음성 지표 QA | `docs/qa/2026-10-01-speech-metric-qa.md` | 음성 지표 화면/DB/임계값의 검증 상태 확인 |
| 디자인/접근성 근거 등록 | `docs/design/MEMORYLINK_DESIGN_RESEARCH_EVIDENCE.md` | 고령 사용자용 UI 근거는 임상 근거가 아니라 UX/접근성 근거임을 확인 |
| 기존 HTML 초안 | `docs/research/2026-10-05_dementia-center-evidence/index.html` | 이후 최종 HTML 업데이트 대상 |

## 집중 점검 결과

| 점검 항목 | 확인 결과 | 근거 |
|---|---|---|
| `shape_sudoku`의 memory 분류 | 카탈로그에서 `adaptiveCategory`와 `scoreCategory`가 모두 `memory`이다. 실제 과제는 Latin Square 기반의 도형/기호 규칙 추론과 빈칸 선택이며, 지연회상이나 기억부하 조작은 확인되지 않았다. 따라서 "기억력 훈련" 주장에는 별도 근거 또는 분류 조정이 필요하다. | `lib/features/training/domain/training_catalog.dart:41-45`, `lib/features/training/games/shape_sudoku_game.dart:91-132`, `lib/features/training/games/shape_sudoku_game.dart:137-143` |
| 서로 다른 과제 점수 혼합 | `activityIndex`는 domain 값의 단순 평균이다. `calculation`과 `logic`은 `executive`로 평균되고, `memory`, `attention`, `language`와 다시 같은 가중으로 섞인다. 과제별 신뢰도, 난이도, 반복 횟수, 센터 프로그램 도메인 매핑은 반영되지 않는다. | `lib/features/reports/models/clinical_report_data.dart:219-247`, `lib/features/reports/models/clinical_report_data.dart:257-261` |
| 점수 스케일 혼합 위험 | 게임들은 대부분 0-100 점수를 저장한다. 그런데 리포트 정규화 로직은 `calculation/logic/attention`을 0-10으로 가정해 10배 후 clamp한다. 최신 0-100 점수가 들어오면 80점도 100점으로 포화될 수 있다. | `lib/features/training/games/shape_sudoku_game.dart:187-196`, `lib/features/training/application/training_completion_service.dart:87-92`, `lib/features/reports/models/clinical_report_data.dart:206-215` |
| 자가체크 결과의 보고서 전파 | 온보딩 10문항은 `UserProvider._surveyAnswers`에만 저장되고 DB 저장 경로가 보이지 않는다. 결과 화면은 `totalAssessmentScore`를 사용하지만, 보고서 생성은 별도 `RiskFactors` 체크리스트를 받는다. 따라서 자가체크 결과가 임상/보호자 보고서에 직접 전파된다고 보기 어렵다. | `lib/features/assessment/assessment_screen.dart:34-48`, `lib/core/user_provider.dart:290-332`, `lib/features/assessment/result_screen.dart:14-30`, `lib/features/reports/clinical_report_options_screen.dart:27-29`, `lib/features/reports/clinical_report_options_screen.dart:74-78` |
| 자가체크 결과의 보호자 화면 전파 | 보호자 공유 view는 걸음, 주간 걸음, 최신 점수 이력, 이상활동 메시지 중심이다. 자가체크 설문 답변 또는 `totalAssessmentScore`는 포함되지 않는다. | `lib/core/services/guardian_sync_service.dart:80-115`, `lib/core/services/guardian_sync_service.dart:136-160` |
| 미응답과 0점 구별 | DB의 `training_attempts.score`는 null 가능하고 `daily_recall`은 score 없이 완료된다. 반면 `UserProvider`는 로컬 점수 초기값을 모두 0으로 두고 `s > 0`만 measured로 취급한다. 실제 0점과 미측정을 구분하기 어렵다. | `lib/core/database_helper.dart:456-468`, `lib/features/training/daily_recall_page.dart:79-86`, `lib/core/user_provider.dart:202-212`, `lib/core/user_provider.dart:321-328` |
| 음성/인지 점수의 질병 추정 표현 | 면책 문구는 존재한다. 다만 결과 화면과 PDF 추천 문구는 활동지수/점수 band에 따라 센터 방문, 재평가, 보호자 동반 상담을 권한다. 이는 진단이라고 단정하지는 않지만, 질병 추정처럼 읽히지 않도록 문구 검수와 근거 연결이 필요하다. | `lib/features/reports/models/clinical_report_data.dart:47-59`, `lib/features/assessment/result_screen.dart:23-30`, `lib/features/reports/clinical_report_generator.dart:816-856`, `lib/features/reports/clinical_report_generator.dart:973-980`, `lib/features/reports/clinical_report_generator.dart:1054-1060` |

## 활동별 근거 격차 표

| 활동 | 현재 구현 | 근거가 필요한 주장 | 센터 연계에 부족한 데이터/기능 | 최소 변경 제안 | 검증 방법 |
|---|---|---|---|---|---|
| `comparison` | 두 항목/숫자를 비교해 정답률 기반 0-100 점수를 저장한다. 카탈로그상 `calculation`이다. | 숫자 비교 과제가 실제 치매안심센터 인지활동 또는 특정 인지영역 향상과 연결된다는 주장. | 난이도, 문항 유형, 반응시간, 오답 유형, 반복 노출, 감독 여부, 센터 프로그램명/회기 매핑이 없다. | "계산/비교 활동"으로만 표기하고, 센터 매뉴얼에서 유사 활동을 확보할 때까지 효과 표현을 금지한다. 점수에는 activity_id, level, item template version을 함께 설명하도록 문서화한다. | 단위 검증: score=correct/total*100 보존. 문서 검증: 센터 근거가 없으면 "효과"가 아니라 "활동 수행 기록"으로 표시되는지 문구 리뷰. |
| `multiplication` | 곱셈 객관식 게임. `comparison` 이후 잠금해제되며 `calculation` 점수로 저장된다. | 곱셈 과제가 노년층/인지저하군에 적합한 난이도이며 계산 능력 훈련으로 타당하다는 주장. | 문항 난이도 적응 근거, 교육 수준 보정, 숫자 친숙도, 오류 유형, 중도 포기 사유가 없다. | 센터용 설명에서는 "산술 연습"으로 제한하고, 난이도/교육수준/오답 유형 로그 요구사항을 추가한다. | 난이도별 정답률 분포를 샘플 데이터로 점검. 고령 사용자 usability 테스트에서 글자 크기/시간 부담/포기율 확인. |
| `sequence` | 수열의 빠진 값을 고르는 게임. 카탈로그상 `logic` 점수다. | 수열 추론이 센터의 실행기능/추론 활동과 연결된다는 주장. | 어떤 수열 규칙인지, 난이도 산정, 풀이 시간, 힌트 사용, 추론 실패 유형이 저장되지 않는다. | "논리/규칙 찾기 활동"으로 표기하고, 규칙 유형과 난이도 version을 기록해야 한다는 요구사항을 문서화한다. | 시나리오 검증: 산술/기하/차분 유형별 문항 생성이 섞이는지 코드 리뷰. 리포트 검증: `logic` 점수가 임상 실행기능으로 단정되지 않는지 확인. |
| `categorization` | 항목을 범주로 분류한다. `sequence` 이후 잠금해제되며 `logic` 점수로 저장된다. | 범주화 과제가 의미기억/언어/집행 기능 중 무엇을 대표하는지에 대한 주장. | 문항 corpus 출처, 문화/교육 편향, 카테고리 난이도, 의미적 근접 오답 구분이 없다. | 도메인을 "논리"로 고정 주장하지 말고 "분류 활동"으로 설명한다. 문항 출처와 사용권, 문항 검수자를 별도 필드로 관리하도록 제안한다. | 문항 목록 검수표 작성. 센터/전문가가 카테고리 분류 타당성을 확인하기 전까지 리포트 도메인 매핑 보류. |
| `shape_sudoku` | Latin Square 형태의 도형 빈칸 맞추기. 카탈로그는 `memory`로 분류한다. | 이 과제가 기억력 점수라는 주장. 현재 구현만 보면 시공간/규칙 추론 성격이 강하다. | 지연회상, 작업기억 부하, 기억 유지시간, distractor 여부가 없다. 센터 프로그램과 연결하려면 어떤 인지영역인지 재분류 근거가 필요하다. | 최소 변경은 문서/표기에서 "기억력" 단정을 보류하고 "도형 규칙/시공간 패턴 활동"으로 설명하는 것이다. 코드 변경 시에는 `scoreCategory` 재분류 또는 별도 `visuospatial` 도메인 추가 검토. | 코드 검증: `training_catalog.dart:41-45`와 report domain 설명이 일치하는지 확인. 전문가 검증: memory vs visuospatial/executive 분류 리뷰. |
| `shape_match` | 목표 도형을 옵션에서 찾는다. adaptive는 `perception`, score는 `attention`이다. | 단순 도형 매칭 정답률이 주의력 점수라는 주장. | 반응시간, 시각장애/색각/화면크기 보정, distractor 유사도, trial 수가 부족하다. | "주의/시지각 활동"으로 중립 표기. 반응시간과 시각 접근성 조건을 센터 검증 필수 데이터로 추가한다. | 접근성 검증: 작은 화면/고대비/스크린리더에서 조작 가능성 확인. 데이터 검증: 정답률만으로 주의력 저하를 해석하지 않는지 문구 검수. |
| `sentence_reading` | 사용자가 문장을 읽고 STT 결과와 목표문을 Levenshtein 기반으로 비교한다. 평균 점수와 70점 초과 정답수를 저장한다. | STT 문자열 유사도가 언어능력, 발화능력, 치매 위험과 연결된다는 주장. | 음성 원신호, 실제 발화시간, 잡음, STT 모델/locale, 교정 여부, 발음 오류 유형, 독해/시력/마이크 실패 구분이 없다. | "문장 읽기/음성 인식 활동"으로만 표기. 질병 추정이나 언어기능 점수로 쓰지 말고, STT 실패와 사용자 오류를 분리하는 validity_status 요구사항을 추가한다. | QA 문서 기준으로 voice 지표가 임상 해석으로 표시되지 않는지 점검. 샘플 STT 실패/무음/부분인식 케이스별 score와 메시지 검토. |
| `daily_recall` | 자유서술 답변을 모아 완료 기록을 남긴다. `TrainingAttemptInput`에는 score/correct/total이 없다. | 회상치료 또는 회상훈련 효과가 있다는 주장. | 답변 텍스트가 훈련 완료 레코드에 저장되지 않고, 주제, 정서, 회상 길이, 도움 여부, 보호자/진행자 피드백이 없다. 개인정보 포함 가능성 관리도 필요하다. | "일일 회상 프롬프트/참여 기록"으로 제한. 센터 연계 전에는 텍스트 저장 여부, 민감정보 필터, 보호자 공유 여부, 삭제 정책을 먼저 결정한다. | DB 검증: `daily_recall` 완료가 null score로 남고 legacy score가 생기지 않는지 확인. 개인정보 검증: 보고서/보호자 화면에 답변 원문이 노출되지 않는지 확인. |
| 온보딩 10문항 자가체크 | 10개 예/아니오 답변을 provider 메모리에 저장하고 결과 화면에서 0-100% 위험 형태로 보여준다. | 문항이 검증된 선별검사 또는 치매 위험 평가라는 주장. | 문항 출처/사용권/민감도/특이도/절단점/미응답 처리/DB 보존 정책이 없다. 결과가 DB와 보호자 view에 직접 저장되지 않는다. | "자가점검"으로 제한하고, 검증 도구명처럼 보이는 표현을 피한다. 미응답과 0점 구분을 위해 null 기반 응답 모델을 설계 문서에 추가한다. | 검색 검증: `_surveyAnswers`, `setSurveyAnswer`, `totalAssessmentScore` 사용처가 assessment 화면에 한정되는지 확인. 문구 검증: 결과 화면이 진단/질병확률처럼 보이지 않는지 리뷰. |
| 간단 인지과제 | 3단어 기억, 방해 계산, 재인, 5단계 주의 과제로 `memory`와 `attention` 점수를 저장한다. | 3단어/5단계 과제가 표준 인지검사와 동등하거나 질병 위험을 추정한다는 주장. | 단어 목록 출처, 학습효과, 반복 노출, 교육/언어 보정, 미응답, 반응시간, 오답 패턴, 검사 환경이 없다. 계산 방해 과제의 점수 반영도 제한적이다. | "간단 활동" 또는 "앱 내부 점수"로 제한한다. 표준 검사와 동등하지 않다는 면책을 결과 화면과 리포트에 유지한다. | 단위 검증: memory=정답/3*100, attention=정답/5*100. 설계 검증: 점수 저장 전후에 null/0/미응답 상태가 구분되는지 확인. |

## 리포트/보호자/DB 관점의 설계 메모

1. `training_attempts`는 null score를 지원하므로 참여형 활동과 점수형 활동을 구분할 수 있다. 이 장점은 리포트/보호자 view에서도 유지해야 한다.
2. `training_scores`는 legacy 호환용 카테고리 점수로 계속 쓰인다. 새 게임이 0-100을 저장하는 현재 구조에서는 리포트 정규화가 0-10 전제와 충돌할 수 있다.
3. `UserProvider`의 로컬 점수는 double 0 초기값이라 "아직 없음"과 "실제 0점"이 섞인다. 설문도 메모리 map이라 앱 재시작/로그인 전환 후 추적성이 약하다.
4. 보호자 view는 `scores` 최대 4개와 걸음/이상활동 중심이다. 자가체크 답변, `totalAssessmentScore`, `activityIndex` 자체는 공유 payload에 포함되지 않는다.
5. 리포트는 면책 문구를 포함하지만, `activityIndex` band로 후속 행동을 추천한다. 기업/센터 접촉용 자료에서는 "진단 도구"와 "앱 내부 활동지표"를 시각적으로 분리해야 한다.

## 문헌/센터 자료가 들어오면 확인할 질문

| 질문 | 필요한 외부 자료 | 코드상 연결 지점 |
|---|---|---|
| 실제 치매안심센터에서 유사한 숫자비교/계산/수열/분류/도형매칭/문장읽기/회상 활동을 쓰는가? | 센터 프로그램 매뉴얼, 회기 자료, 교육자료 사용 허가 | `lib/features/training/domain/training_catalog.dart` |
| 각 활동을 어떤 인지영역으로 분류해야 하는가? | 작업치료/임상심리/인지재활 전문가 검토, 관련 논문 | `scoreCategory`, `ClinicalReportData._extractDomains` |
| 활동 점수를 보고서에 평균내도 되는가? | 도메인별 신뢰도, 반복측정 자료, 최소 trial 수, 센터 파일럿 결과 | `ClinicalReportData.computeActivityIndex` |
| 자가체크 10문항을 계속 유지해도 되는가? | 문항 출처, 사용권, 선별도구 여부, cutoff 근거 | `AssessmentScreen`, `UserProvider.totalAssessmentScore` |
| 보호자에게 어떤 데이터까지 공유해야 하는가? | 동의서, 개인정보 처리방침, 센터 운영 시나리오 | `GuardianSyncService.buildView` |
| 음성/인지 점수 문구가 의료기기/진단 주장으로 읽히는가? | 법무/RA 검토, 앱스토어 정책 검토, 의료기기 해당성 검토 | `AssessmentResultScreen`, `ClinicalReportGenerator` |

## 이번 단계에서 실행하지 않은 것

- 앱 코드 수정 없음
- 전체 테스트 실행 없음
- 외부 계정/배포/연락 없음
- 개인정보 또는 비밀키 열람 없음
- 기존 HTML 최종 업데이트 없음. 이 파일은 부모가 검증 문헌을 전달한 뒤 `index.html`을 업데이트하기 위한 보조자료다.
