# MemoryLink 설문·평가도구 도입 검토

검토일: 2026-10-05 · 대상: 한국 치매안심센터 연계형 참여자·보호자 앱 · 공개된 원저·정부 지침·권리자 정책 중심

## 1. 결론

**MVP는 독자적으로 작성한 비진단적 활동 체크인과 기관 평가결과의 출처 있는 기록 기능부터 설계하는 것이 적절하다. CIST·MMSE·MoCA 또는 기존 설문을 앱 화면에 그대로 넣는 작업은 지금 승인할 수 없다.** 공개 PDF, 논문의 Open Access 표시, 무료 환자검사, 기관의 기존 종이검사 사용권은 각각 상용 SaaS 내 복제·배포·자동채점·음성화 권한과 다르다.

추천 순서는 다음과 같다.

1. **즉시 설계 가능:** 활동 선택·중단·도움 요청·경험/불편감·만족도·기술적 사용성에 대한 독자 문항, 참여기록, 담당자 검토함. 진단명·위험군·인지나이·치매확률·임상 절단점은 생성하지 않는다.
2. **기관 평가와 연동:** 기관이 정당한 절차로 시행한 평가의 도구명/정확한 판본/시행일/시행자/응답자 유형/총점/기관 해석을 구분해 기록하는 구조. 실제 저장·공유 권한, 계약상 결과보고서/점수 처리 범위는 기관과 확인해야 한다. 검사지 이미지나 문항별 반응을 자동으로 반입하지 않는다.
3. **첫 표준화 설문 후보:** 기관 프로그램 연속성을 위해 SMCQ와 SGDS-K를 먼저 검토한다. 보호자 지원 목적이면 S-ZBI 12문항의 **정확한 한국어 판본**을 추가 검토한다. 모두 권리 확인·응답자 구분·담당자 대응체계가 전제다.
4. **선택 모듈:** 삶의 질이 주된 목표라면 KQOL-AD, 실제 생활기능 유지가 목표라면 기관이 사용하는 정확한 ADL/IADL 척도. 측정 부담 때문에 전부 일괄 탑재하지 않는다.
5. **전문가 검사:** CIST, K-MMSE~2, MoCA는 기관 주도 평가로 남긴다. 매일 앱 퀴즈로 반복하여 치료효과 지표로 사용하는 설계는 피한다.

이 문서는 제품·연구 설계 의사결정을 위한 자료이며, 특정 사람의 진단이나 개별 계약의 법률해석을 대신하지 않는다. 현재 확인되지 않은 이용권한은 '금지로 확정'이 아니라 **도입 보류 후 권리자 확인**으로 표시했다.

## 2. 실제 치매안심센터 운영과의 연결

2026년 보건복지부 지침 원문에서 확인된 운영상의 구분은 다음과 같다. [S01]

- 인쇄 68쪽(PDF 124쪽): 치매선별검사 시행자는 치매전문교육을 받은 센터·보건지소·보건진료소 직원이며, 국가치매교육의 CIST 수행 교육 이수가 필수다. 기본 도구는 CIST다. 등록 장애인 중 CIST를 시행할 수 없는 경우에 한해 SMCQ 또는 KDSQ 설문을 이용하는 예외가 제시된다
- 인쇄 71쪽(PDF 127쪽): 외부 CIST 사용가능 기관의 결과를 연계할 수 있다. 이 운영상 인정이 MemoryLink에 대한 전자복제 허락을 뜻하지는 않는다
- 인쇄 113~114쪽(PDF 169~170쪽): 예방·인지강화교실의 사전·사후 평가는 SGDS-K, SMCQ와 연결된다
- 인쇄 118쪽(PDF 174쪽): 쉼터 사전·사후 평가에도 SGDS-K, SMCQ가 있고 CIST는 선택 사항이다
- 인쇄 149쪽(PDF 205쪽): 가족교실 사전·사후 평가에 PHQ-9, S-ZBI, 치매태도척도(DAS)가 제시된다

공식 2025년 별지서식에는 CIST(60쪽), SGDS-K(105쪽), SMCQ(106쪽), KDSQ-C(107쪽), 단축형 자릿 부양부담평가(127쪽)가 있다. **현재 운영 내용은 2026년을 우선하고, 2025년 서식은 판본 확인용으로만 사용한다.** 게시물의 공공누리 제4유형 표시는 상업적 이용과 변경을 허용하는 근거가 아니다. 간행물 사용서약서도 특정 신청자료와 용도에 묶여 있으며, 모든 검사도구를 포괄 허락하는 계약으로 읽어서는 안 된다. [S02]

## 3. 권리·실행 결정표

표의 '보류'는 표준화 도구의 문항, 자극, 채점규준을 앱에 탑재하는 경우를 말한다. 기관의 기존 합법적 시행을 중단하라는 의미가 아니다.

| 도구 | 용도·응답/시행 주체 | 권리자·공식 문의 경로 | 공개 정책으로 확인된 범위 | MemoryLink 판단 |
|---|---|---|---|---|
| **CIST** | 수행 기반 인지선별; 교육 이수한 기관 인력이 1:1 시행 | 보건복지부·중앙치매센터 개발. 중앙치매센터 자료실/국가치매교육을 통한 공식 자료·허락 확인 | 2026 지침은 교육 요건을 확인해준다. 현재 외부 상용 앱·자동채점·음성/영상·재배포 허락 원문은 확보하지 못했다. 공식 자료실의 개별 자료 링크는 도구에서 열리지 않았다 | **전자 탑재 보류.** 기관 종이검사/공식 경로 유지. 소유권·허락범위는 중앙치매센터에서 서면 재확인 [S01,S03,S04] |
| **MMSE / K-MMSE / K-MMSE~2** | 수행 기반 인지기능 검사; 적격·훈련된 시행자 | PAR는 국제 출판/라이선싱 경로. 한국판 K-MMSE~2는 인싸이트의 공식 상품·라이선스 경로 확인 | PAR는 복제·부분사용·번역·형식 변경·온라인 사용에 사전 허락을 요구한다. 인싸이트 2021 공식 공문은 기관별 EMR 탑재 연간계약을 별도로 안내한다. 종이 구매는 SaaS 재판매·다기관 제공 허가가 아니다 | **상용 앱/자동채점 보류.** 한국판·온라인·다기관·보고서·규준 권리를 각각 요청. 2021 가격을 현행 견적으로 사용하지 않는다 [S05–S08] |
| **MoCA-K / K-MoCA** | MCI/인지저하 선별; 보건의료 전문가가 표준 시행 | 저작권자 Ziad Nasreddine; MoCA Test Inc. / MoCA Cognition | 상업기관 또는 상업적 지원을 받는 사용은 서면 허락·라이선스 필요. 공식 Permissions는 제3자 웹 게시·전자버전 개발을 금지한다고 명시한다. 공식 디지털 제품의 존재는 제3자 앱 권한이 아니다 | **서면 계약 전 보류.** 정확한 한국어판·모드·훈련정책 확인. 아래 '인증정책 불일치' 참조 [S09–S11] |
| **SMCQ** | 주관적 기억불편; 원형은 참여자 자기보고 | Youn 등 개발진·소속기관이 확인 가능한 문의 출발점. **실제 저작권 귀속·상업 라이선스 관리자는 공개자료만으로 확정 못함** | 논문과 정부서식 존재. 상업적 전자복제·자동채점·수정·음성화·원격 대리응답의 일반 허락은 확인 못함 | **우선 협의 후보, 탑재 보류.** 기관 시행 결과 연동부터. 진단·객관적 인지향상 지표로 표시하지 않음 [S02,S12] |
| **KDSQ-C** | 인지·생활기능 변화에 대한 설문; 신뢰할 수 있는 정보제공자 보고가 기본. 자기보고와 별도 취급 | Yang 등 개발진/대한신경과학회 논문·관련 연구기관으로 권리자 확인. **앱 이용권을 줄 수 있는 권리자는 미확정** | 정부검진·원저 사용과 상용 SaaS 허락은 별개. 논문 CC BY-NC만으로 상업 도구 탑재권을 얻는 것은 아님 | **탑재 보류.** 참여자와 보호자 응답을 한 점수 추세로 연결하지 않음. 15문항과 연구용 단축형을 혼합하지 않음 [S13,S14] |
| **AD8 / K-AD8** | 짧은 인지변화 선별; 주로 정보제공자. 공식 설명상 직접 자기보고 연구도 있음 | Washington University in St. Louis, Office of Technology Management | 모든 사용에 라이선스 절차가 필요. 무료 조건부 허락은 변형 없는 개별 환자진료/비상업 학술연구이며 임상시험·제품홍보·EMR/EHR를 제외. 수정·파생물 금지 | **상용/전자 통합 보류.** WU에서 명시적으로 앱·한국어판·점수처리를 허락받을 것. 전문 공식교육은 요구하지 않지만 임상 후속평가는 별도 [S15,S16] |
| **K-ADL / K-IADL(Won)** | 기본/도구적 일상생활 기능; 기관 평가자 인터뷰·필요시 신뢰할 수 있는 보호자 정보 | Won 등/대한노인병학회 개발. 현재 권리관리·전자사용 허락자는 공개자료만으로 미확정 | 7문항 K-ADL과 10문항 K-IADL에 검증 근거가 있으나 전자·상업 허락을 확인하지 못함 | **특정 기능 목표일 때만 선택, 권리 확인 후.** 신체장애·환경·기존 생활역할 영향을 분리 [S20,S21] |
| **K-IADL(Kang/Chin)** | 치매 관련 복합 일상기능; 11문항, 정보제공자 보고 | Kang 등 및 Korean Dementia Research Group 원저; 현재 권리관리자는 별도 확인 필요 | 원저·재표준화 논문 확인. 논문 공개와 상업 구현 허락은 다름 | **기관의 정확한 판본을 고정한 후 협의.** 위 Won 척도와 이름이 같아도 다른 도구 [S18,S19] |
| **SGDS-K** | 우울증상 선별/프로그램 평가; 참여자 자기보고, 읽기 지원과 대리응답을 구분 | 영어 GDS는 Yesavage 공식 페이지에서 public domain 확인. 한국어 Bae/Cho판·Kee판·Jang판 등 판본은 별도 확인 | 원 영어척도 권리상태가 모든 한국어 번역에 자동 적용된다고 볼 수 없음. 공식 페이지도 번역의 정확성을 일괄 보증하지 않음 | **기관 연계 우선 후보.** 사용할 한국어판의 문구·전자권리 확인과 우울/위기 대응 책임자 지정 후 [S22,S23] |
| **S-ZBI / ZBI** | 보호자가 느끼는 돌봄부담; 보호자 자기보고 | Steven H. Zarit/Judy M. Zarit 명의 권리 고지; Mapi Research Trust 라이선싱 경로 | 단축형 여러 종류가 존재. 전자 구현 자료는 화면·표현 변경의 승인과 권리표시를 요구. 특정 기관·연구 허락이 앱 전체로 확대되지 않음 | **보호자 기능의 1순위 표준화 후보, 서면 허락 필요.** 12문항 종류·한국어 번역·기간·상업성·시행수를 특정 [S24–S27] |
| **KQOL-AD** | 참여자 삶의 질; 참여자 인터뷰와 보호자 proxy가 별도 | Rebecca Logsdon; Mapi가 QOL-AD 및 파생물 라이선스/배포 담당으로 발표 | 전자버전·번역도 권리관리 대상. 한국어판의 해당 앱 사용 조건은 개별 확인 필요 | **삶의 질이 핵심 목표인 파일럿의 선택 후보.** 참여자와 보호자 결과를 분리; 인지점수 대체 금지 [S28,S29] |
| **SUS** | 시스템의 지각된 사용성; 실제 앱을 쓴 사용자 자기보고 | John Brooke가 자유로운 사용·전달을 허용한 경위 직접 기술 | 척도 사용 가능성과 논문 전체 재배포권은 별개. 한국어 번역의 출처·권리와 대상집단 적합성을 확인해야 함 | **직원/보호자 사용성 측정에 상대적으로 용이.** 인지저하 참여자에게는 관찰 중심; 임의 단축 점수를 SUS로 부르지 않음 [S30] |

### MoCA 인증정책의 중요한 현행 차이

2026-10-05 확인한 공식 FAQ는 **2025년 12월부터 총점만 이용한 선별·triage·의뢰 목적의 보건의료 전문가에게 인증을 선택사항**으로 안내하며 Paper 페이지도 같은 방침을 설명한다. 개별 과제·하위점수·인지영역 손상 해석에는 인증을 계속 요구한다. 공식 FAQ는 결과 해석에 인지 분야 전문성을 갖춘 보건의료 전문가가 필요하다고 명시한다. Permissions 페이지에는 2019년부터 모든 시행·채점에 필수라는 이전 문구가 남아 있다. 따라서 “MoCA는 항상 인증 필수” 또는 “인증이 완전히 폐지됐다”라고 쓰면 부정확하다. 연구자/직원/앱 제공자의 구체적 사용에 적용되는 최신 조건은 권리자에게 확인해야 한다. **인증 완화가 상업적 전자복제 허락을 확대하지는 않는다.** [S09,S10,S36]

### 소유권이 미확정인 도구의 처리

논문 저자, 출판사, 정부서식 제공기관, 원척도 권리자, 번역자, 한국 배포자가 서로 다를 수 있다. 이 표에서 저자를 적은 것은 그 사람이 라이선스를 줄 권한이 있다는 확정이 아니다. 연락 시 권리 양도/대표권과 해당 한국어판·전자판을 허락할 권한부터 확인한다. 답변이 없으면 독자 체크인과 승인된 기관 평가결과 기록만으로 파일럿을 진행하는 방안을 검토한다.

## 4. 한국어 타당화 근거와 적용 한계

아래 수치는 해당 연구 표본과 기준검사에서 얻은 값이다. 서로 다른 연구의 민감도/특이도로 도구 순위를 단정하거나, 앱에 진단 기준으로 복사하지 않는다. 신뢰도 α/ICC가 높다는 사실만으로 디지털 동등성·변화 민감도·치료효과가 입증되지는 않는다.

| 도구·원저 | 한국 검증 집단/방법 | 확인한 주요 수치 | MemoryLink에 주는 의미 |
|---|---|---|---|
| CIST, Kwon 등 2026 | 전국 256센터 ANSYS 선별검사 자료 7,492,613건 중 CIST 3,195,129건. 원문은 individuals로도 표현하나 동일인의 시기별 두 검사 포함 가능. CIST 후 진단검사 자료 144,379건 | 진단검사 기준 AUC .790; 민감도 83.02%, 특이도 44.76%. 진단검사가 주로 의심자에게 선택적으로 시행된 구조 | 큰 표본이어도 검증편향·시기 차이가 있다. 일반 앱 자가검사 정확도로 내세우면 안 됨. 보고된 점수 등가변환도 개인별 변환 공식으로 채택하지 않음 [S03] |
| K-MMSE, Kang 등 1997 | AD 84명, 혈관성 치매 64명, 당시 연구에서 pseudo-dementia로 분류한 23명 | 치매 탐지 민감도 .70~.83; Blessed 지표와 r=.78; 초기 치매 둔감성 지적 | 원판·번역·K-MMSE~2를 같은 검사로 취급 금지. 2020 한국판 2판은 별도 매뉴얼·규준 확인 [S07,S17] |
| MoCA-K, Lee 등 2008 | 노인 외래 196명: 경도 AD 44, MCI 37, 정상 115 | 해당 연구 MCI 선별 민감도 89%, 특이도 84% | 외래·대면 시행 연구를 무감독 스마트폰 자기시행에 일반화할 수 없음 [S31] |
| K-MoCA, Kang 등 2009 | 백질병변을 동반한 뇌졸중군 82명과 정상 81명 | α=.84, 재검사 ICC=.85; 전체 VCI AUC=.80, VCI-ND=.67, 혈관성치매=.90 | Lee의 MoCA-K와 타당화 집단·판본을 구분해야 함 [S32] |
| SMCQ, Youn 등 2009 | 지역사회 한국인 65세 이상 1,651명: 무작위 692명, 자원 959명; 치매 187명. 재검사 20명, 4주 | 총점 α=.864, 재검사 ICC=.828; 초록과 본문 Table 4의 AUC 표기가 달라 단일 정확도 수치를 채택하지 않음 | 주관적 불편을 측정하는 자기보고로 사용. 기분과 인지에 모두 영향받을 수 있어 '기억력 회복 %'로 표시 금지. 작고 선택된 재검사 표본도 고려 [S12] |
| KDSQ, Yang 등 2002 | 치매 72명(AD39/혈관성33), 병원 대조66명의 정보제공자; CDR .5~1.0 | AUC .889, 재검사 r=.81; 해당 연구 민감도79%, 특이도80% | 정보제공자 검증 기반. 보호자가 모르는 내용까지 추측하게 하지 않음 [S13] |
| KDSQ-C, Kim 등 2020 | 11개 병원/지역센터, 420명과 정보제공자: 정상200/MCI50/치매170. 대부분 65세 이상 모집 | 15문항 치매판별 AUC: 자기보고 .75, 정보제공자 .92. 단축형 KDSQ-C-II .76/.92 | 응답자 변경만으로 결과 의미가 달라질 수 있다. 기본척도·단축척도·자기/보호자를 다른 계열로 저장 [S14] |
| K-AD8, Ryu 등 2009 | 환자·정보제공자 155쌍, CDR/신경심리검사와 비교 | α=.88; 재검사 weighted κ=.81; 평가자간 ICC=.89; AUC .88. CDR .5 대 0 비교 민감도68%, 특이도90% | 미국 자료의 전체 정확도를 한국 앱 사용자에게 그대로 인용하지 않음. 한국 직접 자기보고 동등성은 이 논문으로 입증되지 않음 [S16] |
| K-IADL(Kang), 2002/2018 | 2002 치매114/대조106 정보제공자. 2018 병원6곳 MCI/치매2,347명+지역 정상254명 | 2002 α=.96, 재검사 r=.94. 2018 α=.968; 연구에서 선정한 기준 민감도90.1%, 특이도91.6% | 기능적 어려움 추적 후보. 인지 때문인지 운동/시청각/역할 경험 때문인지 기관 해석 필요 [S18,S19] |
| K-ADL/K-IADL(Won), 2002; 후속 2020 | 일반 노인 기능평가용. 2020 KLoSA 65세 이상 4,164명 분석 | K-ADL 원저 초록 α=.937. 2020 합본 ADL/IADL α=.96이지만 IADL 일부에 성별·연령·교육 관련 DIF 확인 | 동일 점수가 동일 기능을 뜻한다고 가정하지 않음. K-ADL 원저 웹 초록의 재검사 숫자 오탈자로 보이는 값은 이 보고서에 사용하지 않음 [S20,S21] |
| SGDS-K, Bae/Cho 2004 | 노인 정신과 환자154명, 독립적 DIS-III-R 및 다른 우울척도 비교 | GDS-K와 SGDS-K r=.9522; 신뢰도·동시/변별타당도 양호 보고 | 일반 고령자·중등도 이상 치매·대리응답에서 동일 성능을 보장하지 않음. 인지저하 정도에 따라 임상의가 다른 우울평가를 선택 [S23] |
| S-ZBI 한국 활용, Kim 등 2022 | 인지저하 노인을 돌보는 60세 미만 보호자 27명 분석, 6주 로봇 RCT | 총점 α=.90, 개인부담 .93, 역할부담 .77 | 사용사례이지 대규모 한국어 디지털 타당화 연구가 아님. 총 부담 변화는 유의하지 않았음. 여러 한국 번역/단축판의 증거를 서로 대체하면 안 됨 [S26] |
| K-ZBI, Yoon/Robinson 2005 | 한국 근로자/배우자에서 얻은 가족돌봄자943명, 학회 원발표 | α=.94; 21문항과 8문항 구조 분석 | 치매안심센터 12문항 S-ZBI의 검증으로 인용하면 부정확. 정확한 12문항 한국판의 원번역·허락·타당화 확인을 별도 gate로 둠 [S27] |
| KQOL-AD, Shin 2006 | 지역사회 치매24명+치매 아닌 인지저하72명; 본인·보호자 평가 | 내적 일관성·반분·재검사 신뢰도 양호; NPI와 상관, MMSE-K/CDR/ADL과 비유의 | 삶의 질과 인지는 별개 성과다. 소규모 예비연구이므로 전국 앱 기준값·임상 최소중요차이를 만들 근거가 아님 [S28] |
| SUS, Brooke 원저/회고 | 범용 시스템 사용성; 본 검토에서는 한국 치매 참가자 전용 표준화 근거를 확정 못함 | 0~100 점수는 백분율이 아니다 | 직원·보호자에 먼저 사용. 인지저하 참여자는 문항 이해/역문항 혼동을 사전 확인. 임의 간소화 시 기존 SUS 규준 비교 금지 [S30] |

**우선순위에 없는 추가 설문:** PHQ-9와 DAS는 가족교실 지침의 실제 측정항목이지만, 단순 활동지원 MVP에 우울 선별·태도척도를 모두 넣을 필요는 없다. 가족교육/우울 지원이 핵심 목적으로 확정될 때 각각 한국판 타당도·권리·기관 위기대응 절차를 추가 검토한다. NPI-Q처럼 증상·부담을 함께 다루는 도구도 별도 임상 목적과 라이선스 검토 없이 편의상 추가하지 않는다.

## 4-1. 기존 MemoryLink 구현의 교체 경로

현재 코드 검토에서 확인된 구성은 출처가 확립되지 않은 예/아니오 10문항 자기점검, 3단어 재인·방해과제 계산·5단계 주의 과제, 0~100 정규화 결과다. 문서에는 이미 비의료 자기관찰 취지가 있으나, **그 설명만으로 문항·합산 점수에 표준화 검사 타당성이 생기는 것은 아니다.**

### 경로 A: 독자 활동기록으로 유지·재설계

- 10문항을 SMCQ/KDSQ-C/AD8로 이름만 바꾸거나, 점수를 비례환산해 이들 척도 점수로 표시하지 않는다
- 현재 문항의 실제 문구·출처·유사성을 항목별로 검토한 후 독립 창작 여부를 확인한다. 10문항 전체를 보지 않은 상태에서 표절/비표절 또는 임상 적합성을 단정하지 않는다
- 정해진 활동에서의 성공/시도 횟수·도움 수준·중단 이유는 활동 수행기록으로만 보여준다. 임의 0~100을 인지건강 백분율·진단·위험등급·정상/비정상 판단에 사용하지 않는다
- 3단어·계산·주의 과제가 일반적인 과제 유형이라는 이유만으로 특정 검사 자극·지시문·순서·채점의 복제를 허용한다고 가정하지 않는다. 동일 자극 반복의 학습효과도 별도 고려한다
- 기존 이력은 출처·구버전 표시와 함께 보존할 수 있지만, 이후 검증척도 결과와 같은 그래프 축에서 연결하거나 '임상적으로 개선됨'으로 소급 재해석하지 않는다

### 경로 B: 기관이 시행한 정식 평가결과 연결

권리·기관 데이터 처리범위가 확인된 경우, 검사 자체는 교육·자격을 갖춘 기관에서 공식 방식으로 시행하고 앱에는 승인된 결과만 연결한다. 최소 출처는 **도구명, 한국어판/버전, 시행일, 시행자와 자격/역할, 기관, 시행모드, 응답자, 지원·환경/컨텍스트, 동의/공유범위, 입력·검수일**이다. 결과는 '기관 평가결과'로 표기하고 **앱이 자체 절단점으로 자가진단/치매확률/중증도를 새로 생성하지 않는다.**

원본 PDF 업로드·문항별 반응·규준표·채점엔진은 총점 기록과 별도 권한이다. 기관이 이미 종이검사를 사용할 수 있다는 사실만으로 결과보고서 전체를 고객 앱에 배포할 수 있다고 단정하지 않는다.

### 경로 C: 정식 한국판 전자 도구를 별도로 도입

권리자 허락, 정확한 한국어판, 시행자/응답자 요건, 전자화 변경 검토, 임상책임자·후속 대응을 확보한 후 별도 모듈로 제공한다. 기존 10문항과 새 도구 간 점수변환은 실제 교차검증/동등성 근거 없이는 만들지 않는다. 새 모듈을 켜도 과거 독자 점수를 공식척도로 변환하지 않는다.

## 5. 즉시 설계할 수 있는 독자 체크인

다음은 표준화 검사 문항을 옮기거나 축약한 것이 아닌 제품 설계 예시다. 점수를 합쳐 임상척도로 부르지 않는다.

| 시점 | 독자 문구 예시 | 처리 |
|---|---|---|
| 활동 전 | '오늘은 어떤 활동을 해보고 싶으세요?' | 취향 선택; 추천 순서만 조절 |
| 활동 중 | '지금 계속할까요, 잠깐 쉴까요?' | 언제든 중단·쉬기; 오답 처리 없음 |
| 활동 뒤 | '다음에 이 활동을 또 해보고 싶으세요?' | 개인 취향 기록; 인지효과로 해석하지 않음 |
| 활동 뒤 | '진행하면서 불편했던 점이 있었나요?' | 자유입력/건너뛰기; 담당자 검토 경로 |
| 보호자 | '앱을 함께 사용하는 동안 어떤 도움이 필요했나요?' | 기술·진행 지원 요청; 돌봄부담 점수 없음 |
| 직원 | '오늘 기록에서 다시 확인할 내용이 있나요?' | 확인 필요 목록; 진단/위험등급 자동 생성 없음 |

원칙:

- 쉬운 말, 큰 글자, 한 화면 한 목적, 충분한 응답시간, '모르겠어요/건너뛰기/그만하기' 제공
- 미응답·접속 중단·활동 거절을 기능저하나 실패로 자동 분류하지 않음
- 보호자가 대신 조작했는지, 문구만 읽어줬는지, 본인이 응답했는지 구분
- 만족·활동참여·자기표현을 원래 범주대로 보고. '치매 예방효과', '치료효과', '인지기능 개선'으로 바꾸지 않음
- 기기 오류, 난청, 시력, 손 운동, 피로, 낮은 디지털 숙련도를 인지저하와 혼동하지 않음
- 개인에게 갑작스러운 상태 변화/불편이 있으면 앱 점수와 무관하게 기관의 기존 상담·의료 연결 절차를 이용할 수 있게 함

## 6. 전자도입 go/no-go gates

### Gate A. 정확한 권리와 계약

다음이 문서로 정리되지 않으면 표준화 도구의 프로덕션 탑재를 보류한다.

- 정확한 도구명, 저자/권리자, 한국어 번역자, 판/버전/문항수, 언어·국가
- 해당 권리자가 원형·번역·전자화·채점/규준에 대한 허락 권한을 갖는지
- 사용주체: 기관 자체, 외주 운영사, MemoryLink, 고객기관 수, 사용자/시행량
- 목적: 비상업 학술 파일럿, 상업 후원 연구, 상용 서비스, 임상/비임상
- 제공방식: 휴대전화·태블릿·웹·기관 단말·오프라인, 자기/면접/보호자, 음성 읽기/응답
- 문항/지시문/그림 복제, 페이지 분할, 글자 확대, 접근성 변경, 문항 순서, 답변방식
- 총점/하위점수 계산, 규준표 구현, 결과 저장, 보고서·PDF·CSV 내보내기, 고객기관 공유
- 고객기관/개발사에 대한 재허락 또는 sublicense, 개발·QA 중 테스트 자산 노출, 백업/보관/삭제
- AI에 문항·반응을 보내는지, LLM 채점·설명·요약·번역을 허용하는지. 허락이 없으면 제외
- 비용·계약기간·재평가·감사·만료 시 비활성화·권리표시·공개 스크린샷 제한

**공공기관 협력, IRB 승인, 논문 인용, 교육 이수 중 어느 하나도 나머지 권한을 대신하지 않는다.** 계약을 얻었다는 것과 해당 모드가 임상적으로 유효하다는 것도 별개다.

### Gate B. 임상 책임과 대상 적합성

기관 임상책임자가 도구/응답자/시행 조건/반복 간격/결과 해석/의뢰 절차를 확정해야 한다. 인지검사와 실제 교육·게임 자극을 분리해 사전 노출을 피한다. 자가/보호자/전문가 기록을 명확하게 나누고, 판본이 다른 점수의 전후 비교를 차단한다.

### Gate C. 디지털 동등성·채점 QA

문항 의미·회상기간·반응선택지·순서·채점 규칙·누락 처리를 보존하고 권리자가 요구하는 화면 검토를 받는다. ISPOR의 최신 권고는 충분한 기존 동등성 근거와 faithful migration이 있으면 항상 새 대규모 동등성시험이 필요한 것은 아니라고 한다. 그러나 **종이 면접을 AI 음성대화, 무감독 자기검사, 임의 단축형으로 바꾸는 일은 단순 매체이동으로 가정할 수 없다.** 필요한 검증 수준은 변경 내용·기존 근거·권리자·임상팀이 결정한다. [S33,S34]

구현 QA는 경계값·역채점·누락·중단/재개·중복제출·시각장애 설정·응답자 변경·네트워크 장애·시간대·버전갱신 사례를 포함한다. 검증용 예상 점수는 권리자가 승인한 예제/매뉴얼로 만들고 이중 검산한다. 허락 없이 규준표나 검사지를 공개 저장소/프롬프트/데모 화면에 넣지 않는다.

### Gate D. 데이터·동의

누가 본인·보호자·직원인지, 누가 무엇을 볼 수 있는지, 동의·철회·보존/삭제·수탁처리·사고대응을 기관과 정한다. 보호자 자신의 우울/부담 응답을 환자나 다른 가족에게 자동 공개하지 않는다. 실제 민감정보 수집 전에 필요한 개인정보·연구윤리 검토를 완료한다. 단순 '비진단용' 문구만으로 제품의 실제 기능·홍보·위험을 정리할 수는 없다.

## 7. 기관 파일럿 평가안

다음은 **제안 설계**이며 임상 기준값이나 공식 의무 인원수가 아니다. 최종 일정·표본수·도구는 협력기관의 대상자와 운영자원을 보고 확정한다.

### 1단계: 실행가능성·사용성

- 목적: 참여자가 존중받으며 사용할 수 있는지, 직원 업무가 늘지 않는지, 활동과 가정 연결이 실행가능한지 확인
- 대상: 한 프로그램 유형부터 시작. 예방교실·MCI·치매쉼터를 한 작은 표본으로 합쳐 '인지효과' 분석하지 않음
- 초기 사용자 관찰: 참여자 8~12명 정도를 출발점으로, 보호자/직원도 각각 별도 관찰. 다양한 나이·교육·시청각/운동조건·디지털 숙련도를 포함하고 새로운 주요 사용성 문제가 더 이상 나타나지 않는지 보며 확대
- 첫 현장시험 예시: 1~2개 기관, 30~50쌍 또는 프로그램 규모에 맞춘 참여자, 6~8주. 이는 모집·유지·업무부담을 추정하기 위한 운영 예시이며 효과 검정에 충분하다는 주장이 아님
- 1차 지표: 가입/동의 이해, 핵심 과업 완료, 도움 필요 수준, 탈락 이유, 사용 가능한 기록 비율, 활동 중 불편, 직원 처리시간
- 주 단위 지표: 실제 활동 횟수/기회 대비 참여율, 미응답 원인, 기술적 실패, 도움 요청과 기관 처리 완료. 빈도 자체를 임상적 성공으로 간주하지 않음
- 사용성: 직원/보호자 SUS가 적합하고 권리가 정리되면 보조 측정. 참여자 본인의 경험은 관찰·쉬운 독자 질문·짧은 인터뷰를 우선

### 2단계: 최소 성과측정 세트

**첫 실증을 정상군 예방교실로 한정한다면 SGDS-K·SMCQ의 기존 기관 운영평가 연계만 우선한다.** S-ZBI·KQOL-AD·ADL/IADL은 보호자 지원·치매 프로그램·생활기능 목표로 범위를 확장할 때의 별도 선택지이며, 첫 파일럿 필수세트가 아니다.

- 예방/인지강화 프로그램: 기관이 이미 사용하는 SMCQ·SGDS-K를 기존 시행방식으로 시작/종료 시 수집. 먼저 완료 가능성·응답부담·자료 누락·점수 분포를 평가
- 보호자 지원 모듈: 허가받은 정확한 한국판 S-ZBI 12문항을 시작/종료 시 선택. 자가 보고는 보호자가 직접 하고 별도 비공개 영역에 저장
- 삶의 질이 중심인 치매 프로그램: 권리 정리 후 KQOL-AD 선택. 본인과 proxy를 별도로 분석
- 생활기능이 실제 중재 목표인 경우: 기관이 쓰는 정확한 ADL/IADL 한 종류를 선택. 단기 활동 앱의 일반적 효과 지표로 기본 탑재하지 않음
- CIST/MMSE/MoCA: 임상책임자가 필요하다고 정한 표준화 평가로만 선택. 매주 반복하거나 게임 성적과 더해 복합 인지지수를 만들지 않음

### 분석과 보고

- 사전에 주목적·측정시점·책임자·변경규칙·누락처리·중단조건을 확정
- 원점수 변화와 신뢰구간, 완료율, 탈락·불편·도움 요청을 함께 보고. 유의한 항목만 골라 홍보하지 않음
- 일관된 같은 응답자/판본/모드 유지. 모드나 보호자가 바뀌면 표식을 남기고 민감도 분석
- 단일군 전후점수의 변화는 학습효과·평균회귀·동시 치료·기관활동·선택적 탈락 때문에 앱 인과효과를 입증하지 못함
- α는 내적 일관성일 뿐 유효성 전체가 아님. 작은 파일럿에서 새 절단점이나 진단분류 모델을 만들지 않음
- 비교효과가 필요하면 이후 적절히 규모 산정한 무작위 비교연구를 계획. 사전 등록/연구윤리/통계계획 여부는 연구기관이 검토
- 파일럿의 중심은 실행가능성이라는 원칙과 사전 progression criteria는 CONSORT 파일럿 확장 지침에 부합한다. [S35]

### 운영상 진행/수정/중단 기준의 예시

수치 기준은 협력기관과 사전에 정할 **운영 목표**이며 임상 절단점이 아니다.

- **중단/보류:** 도구 권한 불명확, 정답·검사지 노출, 안전상 오해, 동의/접근권한 문제, 중요한 도움 요청을 담당자가 처리할 수 없음
- **수정 후 재시험:** 높은 미완료·특정 집단의 접근성 실패·과도한 직원 지원시간·참여자 피로 또는 보호자 대리응답 혼입
- **확대 고려:** 핵심 과업 수행·참여자 수용·기관 운영부담·기록의 정확성에서 사전에 합의한 목표를 충족하고 중대한 안전/개인정보 문제가 없음

## 8. 데이터 사전의 최소 구조

실제 코드 구현 전 기관과 합의할 설계 필드:

- 평가기록 종류: 독자 체크인 / 표준화 자기보고 / 정보제공자 보고 / 전문가 수행평가 / 기관의 외부 결과 요약
- 도구 식별: instrument_id, full_name, author/version/language, item_count, scoring_version, license_reference, permitted_site
- 시행 출처: 기관, 시행자 역할/자격확인 상태, 시행일시, 대면/종이/전자/전화, 필요 지원 내용
- 응답 출처: 본인/보호자/전문가, 보호자의 관계·관찰가능성, 읽어주기와 대리답변 여부
- 결과: 원점수와 기관 해석을 분리, 누락/중단 사유, 공식 매뉴얼 외 재계산 금지, 판본 변경 이력
- 권한: 각 정보주체의 동의/공유범위, 담당자만 보는 내용, 정정·철회·내보내기·보존정책

구분별 실제 개인정보 항목은 최소화한다. 이름·주민등록번호·정밀 위치·검사지 원본을 '있으면 유용하다'는 이유로 수집하지 않는다.

## 9. 출처와 확인 수준

서지 페이지 범위는 논문의 출판 면수다. 개별 표/본문 위치를 별도로 적지 않은 경우 그 면 전체를 확인했다는 뜻은 아니다. 공개 HTML/초록만 확인한 자료는 그렇게 표시한다. 모든 링크는 이번 조사에서 발견·확인한 주소다.

- **S01.** 보건복지부, 2026년 치매정책 사업안내. 청주복지재단 정부기관 지침 게시물과 첨부 원문 확인. 인쇄 68,71,113,114,118,149쪽. [게시물](https://www.cjwf.or.kr/home/sub.php?listCnt=10&menukey=204&mod=view&no=653315&page=8&scode=00000004). PDF 원문을 내려받아 텍스트 확인; 원문 PDF와 추출본은 연구자료 폴더에 보존
- **S02.** 보건복지부, 2025년 치매정책 사업안내 공식 게시물·별지서식. [게시물](https://www.mohw.go.kr/board.es?act=view&bid=0019&list_no=1485015&mid=a10411010300&tag=), [별지 PDF](https://www.mohw.go.kr/boardDownload.es?bid=0019&list_no=1485015&seq=4). 서식 인쇄60,105~107,127쪽, 중앙치매센터 간행물 사용서약서 인쇄159쪽(PDF161쪽) 원문 확인
- **S03.** Kwon HS et al. Verification of Efficacy of Cognitive Function Test Using the Cognitive Impairment Screening Test. J Clin Neurol. 2026;22(1):59–65. DOI [10.3988/jcn.2025.0383](https://doi.org/10.3988/jcn.2025.0383). [원저 전체 HTML](https://pmc.ncbi.nlm.nih.gov/articles/PMC12802069/), Methods, Results, Discussion
- **S04.** 중앙치매센터 공식 [홈페이지](https://www.nid.or.kr/main/main.aspx), [국가치매교육](https://edu.nid.or.kr/). CIST 개별 자료의 발견된 공식 주소 https://www.nid.or.kr/info/dataroom_view.aspx?BID=216 는 이번 도구에서 접근 불가. 따라서 현행 사용서약서 원문·상용 앱 허락은 미확인
- **S05.** PAR [Licensing Team](https://www.parinc.com/about/connect-with-us/licensing-team), 현행 복제/변형/번역/온라인 자료 통제 정책
- **S06.** PAR [Product Information FAQ](https://www.parinc.com/customer-support/product-information), 온라인 시행·부분사용·번역/변형에 관한 허락 절차
- **S07.** 인싸이트 [K-MMSE~2 공식 출시 안내](https://inpsyt.co.kr/main/board/0000/0002/view/1/12808), 한국판 표준화자·연령·판형 확인. 2020-03-31 게시
- **S08.** 인싸이트 2021-02-01, 문서21-0010 'K-MMSE~2 EMR 시스템 탑재 및 사용권 안내'. [공식 발행 공문 PDF](https://ssproxy.ucloudbiz.olleh.com/v1/AUTH_be6ec959-1c37-4a8c-948a-ef2ae7ddfb1a/mailImg/inpsyt-img/download/2021/210526_K-MMSE_2_K-MMSE2_license_3.pdf). 역사적 정책 증거이며 현행 요금·다기관 앱 허락은 아님
- **S09.** MoCA Cognition [Permissions](https://www.mocacognition.com/permission), clinical/research/commercial/web/development 조건
- **S10.** MoCA Cognition [Paper](https://www.mocacognition.com/paper), Important Update to MoCA Certification Policy
- **S11.** MoCA Cognition [Contact](https://www.mocacognition.com/contact), Nasreddine의 copyright owner 표시 및 MoCA Test Inc. 경로
- **S12.** Youn JC et al. Development of the Subjective Memory Complaints Questionnaire. Dement Geriatr Cogn Disord. 2009;27:310–317. DOI [10.1159/000205512](https://doi.org/10.1159/000205512); [PubMed](https://pubmed.ncbi.nlm.nih.gov/19252402/); [공저자가 올린 원문](https://www.researchgate.net/publication/24146938_Development_of_the_Subjective_Memory_Complaints_Questionnaire). 모집·방법 인쇄311~312쪽, 신뢰도/상관313쪽, ROC Table4 315쪽 확인. 논문 권리는 도구 상용 허락으로 간주하지 않음
- **S13.** Yang DW et al. The Development and Validation of Korean Dementia Screening Questionnaire (KDSQ). J Korean Neurol Assoc. 2002;20(2):135–141. [학회 원저 PDF](https://www.jkna.org/upload/pdf/200202006.pdf), [국립의과학지식센터 초록](https://library.nih.go.kr/ncmiklib/elib/kom/articleDtl.do?pk_pb_seq=PB08298690). DOI 미확인
- **S14.** Kim A et al. Reliability and Validity of a Short Form of the Korean Dementia Screening Questionnaire-Cognition. J Clin Neurol. 2020;16(1):145–153. DOI [10.3988/jcn.2020.16.1.145](https://doi.org/10.3988/jcn.2020.16.1.145); [원문 HTML](https://pmc.ncbi.nlm.nih.gov/articles/PMC6974816/), Methods와 Results
- **S15.** Washington University [AD8 Terms Agreement](https://otm.wustl.edu/ad8-terms-agreement/); [Knight ADRC 공식 설명](https://knightadrc.wustl.edu/professionals-clinicians/ad8-instrument/). 용도별 라이선스·변형 금지·비용면제 범위·교육요건 확인. 약관 수락이나 신청은 하지 않음
- **S16.** Ryu HJ, Kim HJ, Han SH. Validity and reliability of the Korean version of the AD8 informant interview (K-AD8) in dementia. Alzheimer Dis Assoc Disord. 2009;23(4):371–376. DOI [10.1097/WAD.0b013e31819e6881](https://doi.org/10.1097/WAD.0b013e31819e6881). [원저 초록](https://pubmed.ncbi.nlm.nih.gov/19561437/)
- **S17.** Kang YW, Na DL, Hahn SH. A validity study on the Korean Mini-Mental State Examination (K-MMSE) in dementia patients. J Korean Neurol Assoc. 1997;15(2):300–308. [학회 원저 초록](https://jkna.org/journal/view.php?number=4088). DOI 미확인
- **S18.** Kang SJ et al. The Reliability and Validity of the Korean Instrumental Activities of Daily Living (K-IADL). J Korean Neurol Assoc. 2002;20(1):8–14. [원저 PDF](https://www.jkna.org/upload/pdf/200201002.pdf), 8쪽 초록 확인. DOI 미확인
- **S19.** Chin J et al. Re-standardization of the Korean-Instrumental Activities of Daily Living (K-IADL): Clinical Usefulness for Various Neurodegenerative Diseases. Dement Neurocogn Disord. 2018;17:11–22. DOI [10.12779/dnd.2018.17.1.11](https://doi.org/10.12779/dnd.2018.17.1.11). [원저 HTML](https://pmc.ncbi.nlm.nih.gov/articles/PMC6427997/). 초록·Reliability·Validity 검색/열람 결과 확인; 재열람 일부에서 CAPTCHA 응답, 수행하지 않음
- **S20.** Won CW et al. The Validity and Reliability of Korean Activities of Daily Living (K-ADL) Scale. J Korean Geriatr Soc. 2002;6(2):98–106. [원저 초록 색인](https://komci.org/GSResult.php?DT=6&ITEMNO=2&RID=0111JKGS%2F2002.6.2.98&TITEM=9). Won CW et al. K-IADL validity and reliability. 2002;6(4):273–280. [학회 PDF 주소](https://www.e-agmr.org/upload/pdf/Kgs-006-04-04.pdf). 전문 재열람 실패, 샘플 크기/숫자 불확실 부분은 채택하지 않음
- **S21.** Why Do Older Korean Adults Respond Differently to Activities of Daily Living and Instrumental Activities of Daily Living? A Differential Item Functioning Analysis. [원저](https://pmc.ncbi.nlm.nih.gov/articles/PMC7370754/). 2020; KLoSA 4,164명 분석의 Methods/Results
- **S22.** Jerome Yesavage [GDS 공식 페이지](https://web.stanford.edu/~yesavage/GDS), 원척도 public domain 및 번역 검증 한계. 한국어 단축형 링크가 Bae/Cho판과 동일하다고 확인하지 않음
- **S23.** Bae JN, Cho MJ. Development of the Korean version of the Geriatric Depression Scale and its short form among elderly psychiatric patients. J Psychosom Res. 2004;57:297–305. DOI [10.1016/j.jpsychores.2004.01.004](https://doi.org/10.1016/j.jpsychores.2004.01.004). [PubMed 초록](https://pubmed.ncbi.nlm.nih.gov/15507257/); [출판사 원문 정보](https://www.sciencedirect.com/science/article/pii/S0022399904000285)
- **S24.** Mapi [ZBI 공식 안내](https://eprovide.mapi-trust.org/zbi-zarit-burden-interview/), 판본 구분·licensing team 안내; [개발자 testimonial](https://www.mapi-trust.org/author-collaboration/author-testimonials). 일부 'not currently distributed' 표시는 특정 단축판 항목에 붙은 것으로 ZBI 전체 배포 중단으로 해석하지 않음
- **S25.** Mapi Research Trust, e-Booklet E-ZBI-12, 2018, 23쪽 §6.2: 화면내용 변경 승인·저작권표시. [전자 구현 지침 PDF](https://jira.mdsol.com/secure/attachment/377052/ZBI-12_AU1.0_e-Booklet_1.0.pdf). 제3자 호스팅의 발행자 문서이며 현행 MemoryLink 계약 대신 사용할 수 없음
- **S26.** Kim SK et al. Evaluation of the Effectiveness of Social Robot by Family Caregivers Nursing for the Older Adult with Cognitive Impairment: A Randomized Controlled Trial. J Korean Gerontol Nurs. 2022;24:142–150. DOI [10.17079/jkgn.2022.24.2.142](https://doi.org/10.17079/jkgn.2022.24.2.142); [학회 원저 PDF](https://www.jkgn.org/upload/pdf/jkgn-24-2-142.pdf), 144쪽 표본/탈락, 146쪽 측정도구, 147쪽 결과
- **S27.** Yoon E, Robinson M. Psychometric Properties of the Korean Version of the Zarit Burden Interview. [SSWR 2005 저자 발표 초록](https://sswr.confex.com/sswr/2005/techprogram/P263.HTM). 논문 서지 J Social Work Res Eval. 2005;6(1):75–86, 논문 전문 미확보. 학회 수치와 최종논문 동일성을 단정하지 않음
- **S28.** Shin HY. A preliminary study on the Korean version of QOL-AD in community-dwelling elderly with dementia. J Prev Med Public Health. 2006;39(3):243–248. [PubMed 원저 초록](https://pubmed.ncbi.nlm.nih.gov/16764499/). DOI 미확인
- **S29.** Mapi Research Trust 발행 2017-05-23 [QOL-AD 독점 라이선스/배포/번역 발표](https://www.prnewswire.com/news-releases/mapi-research-trust-appointed-as-exclusive-distributor-and-mapi-language-services-as-exclusive-translator-of-the-quality-of-life--alzheimers-disease-measure-qol-ad-300462249.html); [현행 신청경로](https://eprovide.mapi-trust.org/instruments/quality-of-life-in-alzheimer-s-disease). 현행 개별 전자약관 본문은 도구에서 표시되지 않아 미확인
- **S30.** Brooke J. SUS: A Retrospective. J Usability Studies. 2013;8(2):29–40. 29쪽 자유 사용·전달 경위, 점수 해석 논의. [저자 업로드 원문](https://www.researchgate.net/profile/John-Brooke-6/publication/285811057_SUS_a_retrospective/links/5ee5c4a792851ce9e7e38a75/SUS-a-retrospective.pdf). 최초 척도: Brooke 1996, Usability Evaluation in Industry, 189–194쪽. 한국 치매 앱 전용 규준 아님
- **S31.** Lee JY et al. Brief screening for mild cognitive impairment in elderly outpatient clinic: validation of the Korean version of the Montreal Cognitive Assessment. J Geriatr Psychiatry Neurol. 2008;21(2):104–110. DOI [10.1177/0891988708316855](https://doi.org/10.1177/0891988708316855); [PubMed](https://pubmed.ncbi.nlm.nih.gov/18474719/)
- **S32.** Kang Y et al. A Reliability, Validity, and Normative Study of the Korean-Montreal Cognitive Assessment as an Instrument for Screening of VCI. Korean J Clin Psychol. 2009;28(2):549–562. DOI [10.15842/kjcp.2009.28.2.013](https://doi.org/10.15842/kjcp.2009.28.2.013); [학회 원문](https://www.accesson.kr/kjcp/assets/pdf/16582/journal-28-2-549.pdf), 561쪽 영문초록
- **S33.** ISPOR, Updated Recommendations on Evidence Needed to Support Measurement Comparability Among Modes of Data Collection for PROMs. [공식 good-practices 안내](https://www.ispor.org/heor-resources/good-practices/article/updated-recommendations-on-evidence-needed-to-support-measurement-comparability-among-modes-of-data-collection-for-patient-reported-outcome-measures)
- **S34.** Mowlem FD et al. Best Practices for the Electronic Implementation and Migration of Patient-Reported Outcome Measures. Value Health. 2024;27(1). [ISPOR 공식 초록](https://www.ispor.org/publications/journals/value-in-health/abstract/Volume-27--Issue-1/Best-Practices-for-the-Electronic-Implementation-and-Migration-of-Patient-Reported-Outcome-Measures)
- **S35.** Eldridge SM et al. CONSORT 2010 statement: extension to randomised pilot and feasibility trials. BMJ. 2016;355:i5239. DOI [10.1136/bmj.i5239](https://doi.org/10.1136/bmj.i5239), Box1 및 progression criteria. 파일럿에 대한 특별 지침으로 인용하며 전체 임상시험 보고지침의 최신 판이라는 뜻은 아님

- **S36.** MoCA Cognition [공식 FAQ](https://mocacognition.com/faq/), Administration / Training and certification / Interpretation 섹션. 2025년 12월 인증정책 변경과 결과 해석 전문성 요건 확인

## 10. 미확인 사항과 다음 판단

- CIST 현행 자료사용 서약서 원문 및 MemoryLink 상용/전자/다기관 허락
- SMCQ, KDSQ-C, Won/Kang 계열 ADL/IADL의 실제 현재 권리자와 앱 라이선스
- 기관이 쓰는 SGDS-K의 번역판·원문·전자권리. 영어 GDS public domain만으로 한국판을 일괄 승인하지 않음
- S-ZBI 한국어 12문항의 정확한 번역/단축판 lineage, 저작권·전자판 및 해당 집단의 변화 민감도
- MoCA 최신 인증정책의 연구/상업 앱 운영자에 대한 적용 확인
- 각 척도의 한국어 고령자 스마트폰·음성 시행 동등성, 반복평가 변화 민감도, 최소중요차이
- 기관/제품의 실제 의도된 사용에 따른 규제·윤리·개인정보 검토

이번 조사에서는 도구 신청·약관 수락·유료구매·권리자 연락·회원가입을 하지 않았다. 위 미확인은 허락을 가정하지 않고 유지한다.
