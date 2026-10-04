# 연구·개발 QA 첫 작업: 기준선과 음성 지표 정의

기준일: 2026-10-01 (Asia/Seoul)

## 범위와 결과

ChatGPT Pro 운영 계획의 첫 작업이다. 현재 작업 트리를 그대로 검사하고, 지표 정의와 다음 검증에 필요한 정보를 정리한다. 앱 로직·임계값·DB·UI를 변경하지 않는다. 문헌 cutoff 대조, 테스터 통계 분석, 음성 진단 재활성화는 이번 완료 범위가 아니다.

- 기준 HEAD: `27ca9d338351dfce2a3836ed03680b64309124d1`.
- 검사 대상에는 기존 미커밋/미추적 디자인·라우터·테스트 변경이 포함된다. HEAD만의 결과 또는 원격 main CI 결과로 해석하지 않는다.
- SDK: Flutter 3.41.5 / Dart 3.11.3. CI의 Flutter 지정 버전과 일치.
- 테스트 자산: test 아래 58개 `*_test.dart`, integration_test 아래 2개. 파일 수와 실행 사례 수는 다르다.
- 실행 결과: 정적 분석 성공(오류 0/경고 0/info 4), 기존 테스트 454 통과/2 skip, 별도 서비스 재현 2 통과. 실행 코드 보존 해시 196개 일치.
- 상세 증빙: `.omo/evidence/october-research-qa/2026-10-01-baseline/`. 이 경로는 기존 `.gitignore`에 의해 제외되므로 GitHub PR에는 자동 포함되지 않는다. 최종 보고서 제출 시 비식별 증빙을 별도로 첨부한다.

## 실행 기준선

| 검사 | 명령 | 결과 |
|---|---|---|
| 정적 분석 | `flutter analyze --no-fatal-infos` | exit 0; error 0, warning 0, info 4; 201.4초 |
| 기존 전체 단위·위젯 테스트 | `flutter test --coverage --reporter expanded` | exit 0; 454 pass, 2 skip; 테스트 출력 기준 1분 53초 |
| 실제 서비스 재현 | `flutter test --no-pub .omo/evidence/october-research-qa/2026-10-01-baseline/metric_probe_test.dart --reporter expanded` | exit 0; 2 pass. 최대 구성 점수 95, 빈 서비스 입력 risk_score=1 확인 |
| 소스 보존 | 작업 전후 SHA-256 비교 | lib/test/통합 테스트/pubspec/CLAUDE/DESIGN/CI의 Git 열거 대상 196파일 일치 |

첫 Git Bash MCP 분석 시도는 결과 없이 중단되어 성공/실패 진단으로 사용하지 않는다. Windows `flutter.bat`로 재시도했으며, 실행 경로 변경만으로 원인을 확정하지 않는다. 상세는 `execution-notes.md`에 남긴다.

### 커버리지와 기존 미해결 항목

- LCOV에 포함된 125파일의 라인 커버리지: **4,880 / 9,735 = 50.13%**. 전체 소스가 빠짐없이 포함되었음을 보장하는 비율은 아니다. 별도 두 재현 테스트는 이 수치에 합산하지 않았다.
- LocalAIService: **0/53라인**. AiChatScreen: **1/256라인**. 지표 분석 경로가 기존 테스트에서 거의 실행되지 않는다는 직접 증거다.
- StepAnomalyPolicy: 13/15라인, AnomalyMonitorService: 14/15라인. 라인 커버리지가 임상적 정확성이나 모든 경계 검증을 뜻하지는 않는다.
- info 4건은 ml_widgets.dart:197,248의 null-aware 권고, theme.dart:121의 nullable 선언 권고, shape_match_game.dart:223의 null-aware 권고다. 이번 범위에서는 수정하지 않았다.
- 기존 skip 2건: main_nav_shell_test.dart:216의 309dp 콘텐츠 오버플로, router_contract_test.dart:322의 미온보딩 사용자/admin 경로 리다이렉트. 테스트 주석에 알려진 결함으로 기록되어 있으며 이번에 활성화하거나 수정하지 않았다. 따라서 '알려진 결함 없음'이라고 보고하지 않는다.

### 사용량 기록 시작

2026-10-01 10:31:54 KST 계정 전체 Codex 7일 사용량 창에서 usedPercent=7을 확인했다. 이 작업만의 소비량이 아니며, 첫 실행 전 스냅샷이 없어 이번 작업의 증분 사용량은 산출하지 않는다. `usage-snapshot.json`에는 계정 식별자를 제거한 값만 보관했다. 5영업일 운영 판단은 후속 기록이 필요하다.

## 현재 코드의 지표 정의와 비교 조건

아래의 '비교 전 계약'은 다음 구현·연구를 위한 작업 기준이다. 특정 논문의 정의나 임상 임계값을 이번에 검증했다는 뜻이 아니다. 실제 문헌 대조표의 출처·표·페이지·언어·대상·과제 칸은 T3에서 채운다.

| 지표 | 현재 코드 정의 | 비교 전 계약 | 현재 부족한 정보 |
|---|---|---|---|
| WPM | 사용자 텍스트의 공백 토큰 수 ×60 / 첫 AI 인사 메시지부터 종료까지 정수 초. 0초이면 0 | 언어·토큰 단위와 시간 분모를 논문에 맞춤. 사용자 발화 구간의 휴지를 포함하는 속도와 유성/조음 구간만의 속도를 구분. 전체 대화 추정값과 별도 이름/버전 사용 | 음성 입력 여부, 사용자 음성 시작/종료, AI 대기 제외, 구간별 시간축 |
| TTR | 소문자화한 고유 공백 토큰 수 / 전체 공백 토큰 수 | 공백 어절/형태소 등 단위를 고정하고 문장부호·숫자·정규화·최소 길이·전사 오류 처리 기록. 다른 길이 자료를 단순 비교하지 않음 | 전사 원문/정규화 버전/토큰 수/지표값의 지속 저장 |
| 휴지 비율 | 계산 없음. STT의 `pauseFor: 3초` 설정만 존재 | 무음 구간의 합 / 정의한 사용자 응답 구간 길이. 최소 휴지 길이, 경계 포함 여부, 잡음 처리와 분모를 연구 프로토콜에서 고정 | 음성 시간축·무음 구간·탐지 방식. 텍스트만으로 복원 불가 |

근거 파일:

- [AI 대화의 계산](../../lib/features/ai_chat/ai_chat_screen.dart): 129~150행.
- [텍스트·음성 입력 공유 경로](../../lib/features/ai_chat/ai_chat_screen.dart): 91~99, 198~210, 377~401행.
- [메시지 모델](../../lib/features/ai_chat/models/chat_message.dart): text, isUser, timestamp만 존재.
- [LocalAIService](../../lib/core/local_ai_service.dart): durationSeconds를 받지만 특성 계산에 사용하지 않음.
- [VoiceService](../../lib/core/services/voice_service.dart): TTS 출력 서비스이며 음성 입력/휴지 분석기가 아님.

### 비교 예시와 측정 불가 규칙

- 같은 60토큰을 30초에 말하면 해당 시간 정의의 속도는 120 WPM이다. 이후 AI 응답 대기가 30초 늘어도 사용자 발화 자체의 속도는 바뀌지 않아야 한다. 현재 세션 분모 방식으로는 60 WPM으로 낮아질 수 있다. 이는 산식 예시이며 실제 녹음 측정 결과가 아니다.
- 고유 토큰 30/전체 60이면 TTR=.5이다. 현재 방식에서 `사과`와 `사과,`는 서로 다른 토큰이므로 구두점 차이만으로 고유 토큰 수가 달라질 수 있다.
- 정의한 응답 구간 30초 중 적격 무음 6초면 휴지 비율=.2이다. 무음의 적격 조건과 응답 구간은 문헌/수집 계약이 먼저 정해져야 한다.
- 음성 출처·시간이 없거나 타이핑이면 음성 WPM은 미측정으로 구분한다. 0초·빈 전사·STT 실패를 임상적 저점수 또는 높은 위험으로 자동 대체하지 않는 계약이 필요하다.
- 기존 기록의 누락 시간이나 입력 출처를 추정해 채우지 않는다. 별도 자료가 없다면 과거 최종 점수에서 세 지표를 복원할 수 없다.

## 점수·표시·저장의 현재 상태

| 항목 | 코드에서 확인한 동작 | QA 의미 |
|---|---|---|
| TTR 점수 | `clamp(ttr/0.6*40,0,40)`; 라벨 .6 이상 양호/.4 이상 보통/그 외 부족 | 수학적 동작과 cutoff 근거를 각각 검증 |
| WPM 점수 | 80~160:25점; 50~80 미만 또는 160 초과~200:18점; 나머지 양수:10점; 0 이하:5점 | 입력 방식·시간 정의 미확보 시 임상적 해석 불가 |
| 합계 | TTR 40 + 속도 25 + 분량 20 + 완결성 10 - 반복 감점 최대 5 | clamp 상한은 100이지만 성분 합계 최대는 95. 의도/표시 기준을 다음 QA에서 검토 |
| 빈 서비스 입력 | 인지점수 0, risk_score 1 반환 | 현재 UI는 빈 전송/사용자 발화 없는 종료를 차단. 서비스 동작과 화면 재현 가능성을 구분 |
| 키워드 위험 점수 | 일치한 키워드 종류당 .15, 최대 .6; 인지점수와 별도 | 이 값의 임상적 위험률 의미를 부여하지 않음 |
| 입력 출처 | STT 결과가 텍스트 컨트롤러에 들어감. 직접 입력과 같은 전송·분석 경로 | 타입/음성별 분리 통계를 현재 메시지 모델만으로 만들 수 없음 |
| 저장 | 저장 버튼에서 최종 점수만 `voice` category로 저장 | WPM/TTR/휴지/시간/버전/전사/입력 출처가 이 저장 경로에 남지 않음 |
| 저장 완료 | `setCognitiveScore`가 DB insert를 await하지 않고 화면은 성공 메시지를 표시 | 실제 실패/성공 전달은 다음 표적 QA. 이번에 장애를 주입해 재현한 것은 아님 |
| 미측정 | Provider voice 초기값/재로딩 값 0 | 미측정과 실제 0점의 분리 필요성 검토 |
| 보고서 | 임상 보고서 language 영역은 `voice`가 아닌 `perception` | 채팅 음성 점수가 임상 보고서 언어 영역으로 연결된다고 보고하지 않음 |

저장 근거: [UserProvider](../../lib/core/user_provider.dart) 295~307행, [DatabaseHelper](../../lib/core/database_helper.dart) 120~126 및 946~953행. 보고서 근거: [ClinicalReportData](../../lib/features/reports/models/clinical_report_data.dart) 219~246행.

## 기존 테스트가 확인하는 범위

- StepAnomalyPolicy 경계와 기준선 제외는 기존 테스트에 있다. 세 호출자가 공유하는 정책을 다시 통합할 필요는 없다.
- UserProvider voice 로딩/계정 변경 초기화, 일반 점수 DB 저장, 보고서 평균·결측, 중지된 음성 진단 화면/라우트 테스트가 있다.
- 이번 test 검색에서 LocalAIService 산식·WPM/TTR 계산·입력 출처·휴지·채팅 저장 완료 전달을 직접 검증하는 테스트는 찾지 못했다.
- 이번 증빙용 재현 두 건은 test 디렉터리 밖에 두어 기존 전체 테스트 수와 구분한다. 현재 동작 관찰이며 그 동작의 타당성 승인이나 앞으로 유지해야 할 요구사항이 아니다.
- 재현 스크립트 자체의 `dart analyze`도 `No issues found!`로 확인했다. 전체 앱의 기존 info 4건과 별개다.

## 다음 작업에 필요한 최소 데이터 사전

아래는 제안 스키마이며 현재 DB에 구현되어 있지 않다.

| 필드 | 의미와 제약 |
|---|---|
| participant_id / session_id | 가명 참여자/세션 식별자. 반복 측정 그룹 구분 |
| input_origin | voice / typed / mixed / unknown. 기존 기록에 근거 없이 voice 대입 금지 |
| task_id / language / device / stt_version | 동일 과제·언어·측정 조건 확인 |
| metric_version / tokenizer_version | 지표 및 전처리 변경 추적 |
| total_tokens / unique_tokens / ttr | 같은 토큰 정의에서 계산. 결측은 null |
| response_duration_ms / voiced_duration_ms / pause_duration_ms | 분모/구간 정의가 있는 실제 측정값만. 결측은 null |
| wpm / pause_ratio | 자료와 프로토콜이 모두 있을 때만 계산 |
| validity_status / exclusion_reason | valid / insufficient / unavailable 등의 상태와 이유 |
| independent_label / label_source | 확보된 독립 평가만. 앱 점수로 만든 라벨로 자체 타당성 검증 금지 |

테스터 자료의 위치·수집 동의·접근 범위는 미확인이다. 실제 자료는 읽거나 업로드하지 않았다. 현재 앱 저장 정보만으로 세 지표의 분포/그룹 구분 검증에 착수할 수 있다고 가정하지 않는다.

## 다음 우선순위

1. 이번 기준선 결과를 바탕으로 기존 실패와 신규 QA 대상을 분리한다.
2. 음성/타이핑 출처·유효 시간·결측 계약을 확정하고, 현재 데이터로 검증 가능한 항목을 표시한다.
3. WPM/TTR 산식과 저장 완료 전달에 표적 회귀 테스트를 붙인다. cutoff는 문헌 대조 전 변경하지 않는다.
4. 기존 FINGER·SUPERBRAIN 등록부를 출발점으로 음성 지표 연구를 별도로 대조한다.

## 미실행·미검증

이번은 로컬 단위·위젯/분석 기준선 작업이다. 원격 CI, APK 빌드, Android 실기기 음성/STT, 임상 타당성, 실제 테스터 데이터 분석은 완료했다고 표시하지 않는다. 앱 코드나 임계값에 대한 수정 PR은 만들지 않았다.
