# 06 — 힉스필드(Higgsfield) 활용 시각 품질 고도화 계획

- **기준일:** 2026-09-13
- **구분:** 별도 트랙(Stage 1~4와 독립). 코드 변경은 Stage 1 CI 복구 이후 PR 단위로 병합
- **범위:** ① 앱 내 이미지·일러스트, ② 인지훈련 게임 7종의 체감 품질, ③ 랜딩 사이트, ④ 스토어·공모전 발표 시각물
- **원칙:** `DESIGN.md`가 상위 규범이다. 힉스필드는 *자산 생산 도구*이지 디자인 방향을 정하는 도구가 아니다

---

## 0. 한 줄 결론

힉스필드는 **CLI로 Claude Code 안에서 직접 호출**할 수 있고, 게임 에셋 전용 스킬(스프라이트 시트·타일·SFX·BGM)까지 공식 제공한다. 그러나 감사 결과 MemoryLink 게임의 가장 큰 결핍은 그림이 아니라 **피드백(눌림·정답/오답·햅틱·효과음)이 사실상 없는 것**이다. 따라서 순서는 **(1) 게임 피드백 기반 → (2) 힉스필드로 일러스트·아이콘 세트 교체 → (3) 웹·스토어 시각물**이며, 한 달 Plus 플랜(1,200cr) 안에서 전부 끝낼 수 있게 자산 수를 잠근다.

---

## 1. 힉스필드 조사 결과 (2026-09 기준)

### 1.1 제품 구성

| 영역 | 도구 | MemoryLink 용도 |
|---|---|---|
| 이미지 | **Soul 2.0 / Soul Cinema**(실사·시네마틱), **Nano Banana 2**(범용, ~2cr), **GPT Image 2**(UI·텍스트 정확), **Flux 2**(키포즈), Seedream | 일러스트·아이콘·배경은 Nano Banana 2, 텍스트가 들어가는 목업은 GPT Image 2 |
| 색·일관성 | **Soul HEX**(참조 이미지에서 팔레트 추출·고정), Soul ID(인물 동일성), Moodboard, Style Mixer | `DESIGN.md` 팔레트를 HEX로 잠가 톤 이탈 방지 |
| 편집 | 인페인팅·캔버스 확장, 4K 업스케일, 배경 제거(투명 PNG), 비율 리사이즈(1:1·16:9·9:16) | 스토어 규격 변환, 마스코트 투명 배경 |
| 영상 | **Cinema Studio 2.5**(4K, 최대 1분, 컬러그레이딩), Kling 3.0·Veo 3.1·Seedance 2.x·Sora 2 통합, Soul Cast(정지 이미지 → 3~5초) | 랜딩 히어로 클립, 발표용 리빌 영상 |
| 마케팅 | **Marketing Studio** — App 프리셋(UGC 15초), Hyper Motion(9:16 CGI 리빌), TV Spot(16:9), Wild Card | 앱 스크린샷 1장으로 프로모 영상 |
| 게임 | **AI Games**(프롬프트 → 브라우저 게임, 약 70cr), **game-generation 스킬**(AutoSprite 스프라이트 시트, 타일 텍스처, 3D, SFX·BGM·TTS) | 에셋 파이프라인만 채택. 브라우저 게임 생성은 Flutter와 무관하므로 제외 |
| 에이전트 연동 | `npm i -g @higgsfield/cli` → `higgsfield auth login`(브라우저 로그인, API 키 불필요) → `npx skills add higgsfield-ai/skills`. MCP 서버도 제공. Claude Code에서는 CLI 권장 | 이 저장소에서 바로 생성·다운로드·후처리 |

공식 스킬 9종: generate, soul-id, product-photoshoot, brandkit, marketplace-cards, websites, video-explainer, **youtube-thumbnail**, **game-generation**. 이 중 game-generation, generate, youtube-thumbnail, brandkit 4종을 쓴다.

### 1.2 게임 에셋 파이프라인 (game-generation 스킬 규약)

- **STYLE FORMULA**: 게임당 60~90단어 영어 한 문단을 *한 번* 확정하고, 모든 시각 프롬프트에 **바이트 단위로 동일하게** 삽입한다. 구성: 렌더링 스타일 → 형태·선 언어 → 역할별 팔레트 → 빛·분위기 → 게임 가독성(대비·시점).
- **모델 배정**: 스프라이트·타일·배경 `nano_banana_2`(1k, 1:1/16:9), UI 요소·애니메이션 시트 `gpt_image_2`(1k, 1:1), 키포즈 `flux_2`.
- **투명 배경**: 모델은 알파를 출력하지 못한다. **단색 키 컬러(`#FF00FF` 기본, 보라 계열 자산은 `#00FF00`)** 배경으로 생성한 뒤 후처리에서 키잉하고, 갇힌 영역(도넛 구멍)도 지운다. 또는 `image_background_remover` 잡을 프레임 단위로 돌린다.
- **스프라이트 시트**: `autosprite` 잡(`--kind idle|walk|…`, `--frame_count`, `--frame_size`, `--remove_bg default`). 픽셀아트는 8~16프레임, HD는 16~24. 파일명 규약 `{asset}_{action}_f{count}_{w}x{h}_g{cols}x{rows}_fps{n}_{loop|once}.png`.
- **오디오**: SFX `seed_audio`, BGM `sonilo_music --duration 30`, 음성 `inworld_text_to_speech`.
- **크기 규약**: 스프라이트 128px, 타일 256px(2의 거듭제곱), 배경 1280×720. 픽셀아트는 NEAREST, 나머지는 LANCZOS로 축소.

### 1.3 요금·권리

| 항목 | 확인 내용 |
|---|---|
| 플랜 | Free 0cr(상업 이용 불가), Starter $19/월 270cr, Plus $59/월(연 $47) 1,200cr, Ultra $129/월(연 $99) 3,000cr |
| 단가 | Nano Banana 2 이미지 ~2cr(4K ~4cr), Soul 이미지 ~5cr, 기본 영상 25~50cr, Kling/Sora 급 50~80cr, AI Games 1회 ~70cr |
| 만료 | 구독 크레딧은 **결제 주기 말 소멸, 이월 없음**. 추가 팩(약 $5/100cr)은 90일 |
| 권리 | 2026-08 개정 약관: 입력·출력 소유권 주장 없음, 상업 이용 무제한, 구독 해지 후에도 출력물 권리 유지. 유료 플랜은 워터마크 없음 |
| 유의 | 약관은 플랫폼 운영 목적의 라이선스를 회사에 부여한다. 사용자 개인정보(얼굴·일기 내용)를 프롬프트나 참조 이미지로 올리지 않는다 |

### 1.4 MemoryLink에 맞춰 걸러낸 것

- **채택**: Nano Banana 2 일러스트, Soul HEX 팔레트 잠금, 배경 제거·리사이즈, AutoSprite(마스코트 1~2동작), seed_audio SFX, Marketing Studio 리빌 영상 1~2편, youtube-thumbnail.
- **제외**: AI Games 브라우저 게임 생성(Flutter 앱과 무관), Soul 2.0 실사 인물(65+ 사용자에게 불쾌한 골짜기·초상권 리스크, 앱 안에는 실사 얼굴을 넣지 않는다), Cinema Studio 1분 4K(비용 대비 용도 없음), 무한 루프 애니메이션(`DESIGN.md` §4 KWCAG 3초 규칙 위반), 보라 그라데이션 배경(§5 "AI 생성물의 지문").
- **표시 의무**: 2026-01 시행 인공지능 기본법의 생성형 AI 산출물 표시 의무 적용 여부를 랜딩·스토어·발표자료 기준으로 확인한다(§9 결정 4). 공모전은 각 요강의 AI 생성물 허용·표기 조항을 제출 전 대조한다.

---

## 2. 현재 기준선 (2026-09-13 감사)

| 영역 | 확인된 사실 | 계획상 의미 |
|---|---|---|
| 앱 이미지 | `assets/`에 일러스트는 `brain_buddy.svg`(829B, 선 몇 개) 1개뿐이고 **`lib/`에서 미사용**. `Image.asset` 호출 1곳(로그인 아이콘), `Icon(` 141곳. `lottie`·`audioplayers`·`vibration`·`flutter_svg`는 pubspec에 있으나 import 0 | 자산은 "없다"가 아니라 "슬롯만 있다". 의존성 추가 없이 시작 가능 |
| 빈 상태 | admin·cs·gait 카드가 `Text('…없습니다.')`로 끝남 | `DESIGN.md` §6.1 위반. 일러스트 4종 필요 |
| 게임 렌더링 | 7종 전부 일반 위젯. `AnimationController` 0, `Transform.scale` 0, `CustomPaint` 0(PDF 제외). `GameTemplate`가 공통 뼈대 | 파이프라인 도입보다 **공통 템플릿 한 곳**에 피드백을 넣는 것이 지렛대 |
| 게임 피드백 | 햅틱은 categorization·shape_sudoku 2종만. comparison·multiplication은 정답/오답 표시 자체가 없음(`comparison_game.dart:34` 주석). SFX 0, TTS만 | "고퀄리티"의 1순위는 그림이 아니라 반응 |
| 게임 그림 | shape_match 16종·shape_sudoku 4종이 Material 아이콘. categorization은 단어만 | 힉스필드로 교체할 **정확한 슬롯**이 확정돼 있다 |
| 보상 | `training_result_sheet.dart`가 아이콘 5개 나열. 코스맵은 카드+2px 선 | 1회성(≤3초) 축하 스프라이트 자리 |
| 랜딩 | `site/index.html` 히어로는 `shots/home.webp` + CSS 폰 프레임 + 글로우 3개. **영상 없음, `og:image` 없음**. GSAP는 이미 동작 | 소셜 미리보기 1장이 가장 싼 개선. 히어로 클립은 선택 |
| 스토어 | `PLAY_CONSOLE.md`에 이미지 규격 없음. 피처 그래픽·프레임 스크린샷 없음 | 규격을 이 문서에 고정한다(§6) |
| 공모전 | 충북 ICT 발표평가 9월 대기, 한이음·TTA 제출 완료. 정지 이미지는 6월 기기 캡처 4장 재사용 | 발표 덱용 시각물이 당장 쓰이는 첫 산출물 |
| 로컬 도구 | Node 22.14, ffmpeg 8.1.2, Python 3.13 있음. `@higgsfield/cli` 미설치 | 설치 10분 |

---

## 3. 트랙 A — 게임 체감 품질 기반 (힉스필드 이전에 끝낸다)

### A-01 `GameTemplate` 공통 피드백 레이어
- **구분/목표:** 필수; 7종 게임이 한 번에 눌림·정답·오답·완료 피드백을 얻는다.
- **근거/현재 사실:** `DESIGN.md` §4 "눌림 피드백 필수 scale(0.98)"이 어디에도 구현돼 있지 않다. 고령 사용자는 눌렸는지 몰라 두 번 누른다. 정답/오답을 색으로만 주지 않는다(§5).
- **영향 파일:** `lib/features/training/widgets/game_template.dart`, `adaptive_answer_grid.dart`, 게임 7종의 `onAnswer` 콜백, `lib/core/theme.dart`(모션 상수).
- **선행/구현:** `PressableScale`(100ms, 0.98) 래퍼; 정답은 색+아이콘+짧은 문구 3겹, 오답은 흔들림 150ms+문구; `HapticFeedback.lightImpact/mediumImpact`를 템플릿에서 일괄 호출; comparison·multiplication의 "표시 없음" 정책은 제품 판단으로 폐기하고 동일 규칙 적용; 애니메이션은 모두 1회성 ≤300ms.
- **제외:** Flame·Rive·flutter_animate 도입(표준 `AnimatedScale`/`TweenAnimationBuilder`로 충분), 파티클.
- **완료/검증:** 위젯 테스트로 정답·오답 상태 3겹 렌더 확인; `flutter analyze` error·warning 0 유지; 테스트 307/307 유지; Maestro 게이팅 20 플로우 통과.
- **비용/위험/롤백:** 2~3인일. 위험은 오답 흔들림이 어지러움을 유발하는 것 → 진폭 4px 이하, `MediaQuery.disableAnimations` 존중. 롤백은 템플릿 플래그 한 곳.

### A-02 효과음 4종과 음소거
- **구분/목표:** 필수; 정답·오답·레벨업·완료 SFX. 이미 선언된 `audioplayers`를 처음 사용한다.
- **근거:** 청각 피드백은 시각 저하 사용자에게 두 번째 채널이다. `flutter_tts`가 제목을 읽는 기존 흐름과 충돌하지 않게 볼륨 덕킹.
- **영향 파일:** `pubspec.yaml`(assets/sfx), 신규 `lib/core/services/sfx_service.dart`, 설정 화면 토글, `voice_service.dart`.
- **선행/구현:** 힉스필드 `seed_audio`로 생성(§7 명령), 각 ≤1초, mp3 96kbps, 총 200KB 이하. 기본 ON, 설정에서 OFF, 시스템 무음 모드 존중.
- **제외:** BGM(집중 방해·KWCAG 자동재생), 음성 캐릭터.
- **완료/검증:** 실기기에서 TTS와 동시 재생 시 끊김 없음; 설정 OFF 시 재생 0회(테스트).
- **비용/위험/롤백:** 1인일 + 약 20cr. 위험은 생성 SFX가 "게임스러워" 고령 사용자에게 유치하게 들리는 것 → 프롬프트에 "soft, wooden, short, no reverb" 고정. 롤백은 서비스 no-op.

### A-03 축하 스프라이트(1회성)
- **구분/목표:** 권장; 결과 시트와 코스 노드 해금에 마스코트 축하 동작 1개(≤2.5초, 1회 재생).
- **근거:** §4 자동 반복 금지 → 루프가 아니라 one-shot. 아이콘 5개 나열보다 한 동작이 낫다.
- **영향 파일:** `training_result_sheet.dart`, `course_node.dart`, 신규 `lib/core/widgets/sprite_sheet_player.dart`(`AnimationController` + `Image` 소스 rect, 의존성 없음).
- **선행/구현:** B-01 마스코트 확정 후 `autosprite --kind <celebrate>` 12프레임·256px·fps 12·once. 시트 1장(3×4) PNG ≤150KB.
- **제외:** Lottie 변환(힉스필드는 Lottie를 만들지 않음), 상시 idle 애니메이션.
- **완료/검증:** 재생 후 정지 프레임 유지, `disableAnimations` 시 마지막 프레임 정지 표시.
- **비용/위험/롤백:** 1인일 + 약 30cr. 롤백은 정적 마스코트 이미지.

---

## 4. 트랙 B — 앱 이미지·일러스트 (힉스필드 본 작업)

### B-00 스타일 공식 확정 (모든 생성의 선행 조건)
- **구분/목표:** 필수; MemoryLink STYLE FORMULA 1개를 승인받고 `docs/design/style_formula.md`에 동결한다.
- **근거:** game-generation 스킬 규약 — 공식이 바뀌면 자산 세트가 갈라진다. `DESIGN.md` §5(강조 1색, 화면당 카테고리색 3개, 그라데이션 금지, 색조 그림자).
- **초안(승인 대상):**
  > Flat vector illustration with soft rounded shapes and no outlines, gentle two-tone shading, matte paper texture-free surfaces. Friendly, calm and dignified — never childish. Palette by role: background always off-white #F1F0FB, primary accent lavender #6C5CE7 used sparingly, category tints mint #38C9A6, peach #FF7AA2, amber #FFB74D, sky #5AA9F0 — at most two tints per image, no purple gradients. Soft single light source from upper-left, shadows tinted lavender not black. High contrast, large simple silhouettes readable at 48px, front or three-quarter view, generous margin around subject.
- **선행/구현:** Soul HEX에 `lib/core/theme.dart` 팔레트 6색을 참조로 등록; 후보 3장(Nano Banana 2)으로 톤 비교 → 1개 승인 → 이후 바이트 동일 삽입. 압축형 STYLE TOKEN(≤120자)도 함께 동결.
- **완료/검증:** 승인된 공식·토큰·참조 이미지 3장이 문서에 있고, 이후 모든 프롬프트 로그(§7)가 이를 인용.
- **비용:** 0.5인일 + ~20cr.

### B-01 마스코트 "브레인 버디" 세트
- **구분/목표:** 필수; 현재 SVG의 선 스타일을 계승한 마스코트 정면·측면·표정 6종(기본·기쁨·응원·생각·휴식·축하)을 투명 PNG로.
- **근거:** `PORTING_GUIDE.md` STEP 7이 지정한 슬롯(로그인 히어로, 홈 헤더, vs AI 아바타, 메모리 가든 빈 상태)이 비어 있다. 하나의 캐릭터가 앱·웹·발표를 관통하면 정체성이 생긴다.
- **영향 파일:** `assets/illustrations/mascot/*.png`(1x·2x·3x), `login_screen.dart:45`, `home_screen.dart`, 결과 시트, 빈 상태 위젯.
- **선행/구현:** B-00 공식 + "sprite" 템플릿 + 키 컬러 `#00FF00`(보라 계열이므로 마젠타 회피) → 후처리 키잉 → 512px 원본에서 1x(96px)·2x·3x 생성. 실사 얼굴 금지, 브레인 형태는 기존 SVG 실루엣 유지.
- **제외:** Soul ID 학습(인물용, 마스코트에는 불필요·과금), 3D.
- **완료/검증:** 6종 실루엣이 48px에서도 식별; 합계 ≤400KB; golden test 1건(로그인 화면).
- **비용/위험/롤백:** 1인일 + ~60cr(후보 포함). 위험은 표정 간 스타일 드리프트 → 첫 승인 이미지를 `@image_1` 참조로 넘겨 생성. 롤백은 기존 SVG.

### B-02 빈 상태·온보딩 일러스트
- **구분/목표:** 필수; 빈 상태 5종(훈련 기록 없음·일기 없음·보행 세션 없음·보호자 미연결·문의 없음) + 온보딩 3장(훈련·기록·보호자).
- **근거:** `DESIGN.md` §6.1 "첫 걸음을 알려주는 화면". `DESIGN.md` §7 결정 4(무가입 즉시 체험)가 확정되면 온보딩 3장이 그 화면이 된다.
- **영향 파일:** `lib/features/{training,diary,gait_analysis,guardian,cs}` 빈 상태 위젯, 신규 `lib/core/widgets/empty_state.dart`(그림+제목+행동 버튼 1개).
- **선행/구현:** "background" 템플릿 변형, 16:9가 아닌 4:3, 텍스트 절대 삽입 금지(한글 렌더링 실패 회피, 문구는 Flutter가 그림 위가 아닌 아래에 그린다). 마스코트 등장은 8장 중 4장 이하로 절제.
- **완료/검증:** 5개 화면의 빈 상태가 그림+문구+행동 3요소; 명도 대비 AA; 위젯 테스트.
- **비용:** 1.5인일 + ~50cr.

### B-03 도형 게임 아이콘 세트 교체
- **구분/목표:** 필수; `shape_match_game.dart` 16종, `shape_sudoku_game.dart` 4종 심볼을 일관된 일러스트 아이콘으로.
- **근거:** Material outline 아이콘은 64세 이상 사용자에게 선이 얇고, 16종 간 시각적 무게가 제각각이라 "같은 모양 찾기"의 난이도가 도형이 아닌 아이콘 두께에 좌우된다. 한 세트로 그리면 난이도가 의도대로 돌아온다.
- **영향 파일:** 두 게임의 `_shapeNames`/아이콘 맵 → `assets/illustrations/shapes/{name}.png`, `training_catalog.dart`(썸네일), 테스트.
- **선행/구현:** "UI" 템플릿("single element, centered, crisp edges, no drop shadow"), 1:1, 배경 키 컬러, 128px 최종. **식별성 규칙**: 20종 모두 실루엣이 서로 다르고 좌우 대칭 여부를 섞는다(스도쿠 4종은 회전해도 구분). 색은 카테고리 3색 이내, 색만으로 구분하지 않는다.
- **제외:** 게임 규칙 변경, 난이도 곡선 변경.
- **완료/검증:** 색맹 시뮬레이션에서 20종 구분 가능; 기존 게임 테스트 통과(아이콘 → 이미지 위젯 교체 후 골든 갱신).
- **비용:** 1인일 + ~60cr.

### B-04 범주화 게임 그림 카드
- **구분/목표:** 권장; `categorization_game.dart`의 단어 문항에 그림 카드를 붙여 이중 부호화(단어+그림).
- **근거:** 제품 판단. 단어만 있는 문항은 읽기 부담이 크고, 그림은 회상 단서가 된다. 단, 그림이 답을 노출하면 훈련 효과가 사라지므로 **범주가 아닌 대상 자체**만 그린다.
- **영향 파일:** 문항 데이터(단어 → 이미지 키 매핑), 게임 위젯, `assets/illustrations/cards/`.
- **선행/구현:** 문항 어휘 수 확정 후 진행(수십~백 단위면 크레딧 ~2cr×N). 우선 상위 빈도 40개만.
- **제외:** 전체 어휘 그림화, 사진(실사) 사용.
- **완료/검증:** 그림 있는 문항과 없는 문항의 정답률 차이를 SQLite 기록으로 관찰(Stage 3 타임라인과 연결).
- **비용:** 1인일 + ~100cr.

### B-05 앱 아이콘·스플래시 최적화
- **구분/목표:** 권장; `app_icon.png` 757KB, `adaptive_background.png` 856KB를 규격(512px, 무손실 100KB대)으로 재출력. 힉스필드는 필요 시 배경 재생성만.
- **완료/검증:** APK 자산 크기 -1.5MB, 아이콘 시각 동일.
- **비용:** 0.5인일, 0cr.

---

## 5. 트랙 C — 랜딩 사이트(`site/`)

### C-01 `og:image` 1장
- **구분/목표:** 필수; 1200×630 소셜 미리보기. 현재 없어서 공유 링크가 빈 카드로 뜬다.
- **선행/구현:** GPT Image 2로 "폰 목업 + 마스코트 + 여백" 구도 생성 → 앱 캡처 `shots/home.webp`를 목업 화면 영역에 로컬 합성(생성 이미지 안의 가짜 UI를 쓰지 않는다) → 문구는 HTML/로컬 합성으로 삽입. `landing/og.png`도 같은 파일로 교체.
- **완료/검증:** Facebook·카카오 링크 디버거에서 미리보기 확인; `index.html` head에 `og:image`·`twitter:card` 추가.
- **비용:** 0.5인일 + ~10cr.

### C-02 히어로 클립(선택)
- **구분/목표:** 권장; 6~8초 무음 9:16 클립을 `.phone` 프레임 안에서 재생.
- **근거:** Marketing Studio Hyper Motion은 스크린샷 1장으로 리빌 영상을 만든다. 단 랜딩은 공공 접근성 기준(KWCAG)을 지키기 위해 **자동재생 시 3초 내 정지 또는 일시정지 버튼**, `prefers-reduced-motion`이면 정적 이미지.
- **선행/구현:** 프롬프트 골격은 힉스필드 공식 예시를 따르되 "pitch-black void" 대신 `#F1F0FB` 배경과 라벤더 색조 그림자로 교체(브랜드 정합). 출력 mp4 → ffmpeg로 720×1560 webm/mp4 각 ≤1.5MB, 포스터 프레임 webp.
- **제외:** 전체 화면 배경 영상, 사운드.
- **완료/검증:** LCP 2.5초 이내 유지(현재 Lighthouse 기준선 측정 후 비교), 모바일에서 데이터 절약 모드 시 미재생.
- **비용:** 1인일 + ~100cr(재생성 2회 포함).

### C-03 섹션 일러스트·갤러리 정비
- **구분/목표:** 권장; 기능 3~4개 섹션에 B-02 온보딩 일러스트 재사용, 갤러리 10장은 실제 캡처 유지(생성물 사용 금지 — 스토어 정책과 동일하게 실제 UI만).
- **비용:** 0.5인일, 추가 크레딧 0.

---

## 6. 트랙 D — 스토어·공모전 발표 시각물

규격은 이 표를 정본으로 `PLAY_CONSOLE.md`에 링크한다.

| 산출물 | 규격 | 생성 방식 |
|---|---|---|
| Play 아이콘 | 512×512 32bit PNG | 기존 아이콘 재출력(B-05) |
| 피처 그래픽 | 1024×500 JPG/PNG(알파 없음), 텍스트 최소 | GPT Image 2 배경+마스코트 → 로고·문구 로컬 합성 |
| 폰 스크린샷 | 2~8장, 9:16, 1080×1920 권장, 320~3840px | **실제 캡처만**(Maestro 캡처 재사용) + 로컬 프레임·캡션 합성. 생성 UI 금지(정책 위반·심사 탈락 위험) |
| 프로모 영상 | YouTube 공개/미등록 URL, 30초 내외 16:9 | Marketing Studio TV Spot 또는 Hyper Motion 클립 + 실제 화면 녹화를 ffmpeg로 편집 |
| 발표 덱(충북 ICT 발표평가) | 표지·문제 정의·해결 장면 3장 | Soul Cinema 아닌 Nano Banana 2 일러스트(공식 동일), 인물은 실루엣·뒷모습만 |
| 유튜브 썸네일(한이음 등) | 1280×720 | `higgsfield-youtube-thumbnail` 스킬, 한글 문구는 로컬 합성 |

- **완료/검증:** 각 파일이 규격 검사 스크립트(`scripts/check_store_assets.py`, 신규)를 통과; 스크린샷 원본과 합성본의 UI 픽셀이 동일(생성물 미포함 증빙).
- **비용:** 1.5인일 + ~150cr.

---

## 7. 기술 파이프라인 (재현 가능하게)

### 7.1 설치·인증

```bash
npm i -g @higgsfield/cli
higgsfield auth login            # 브라우저 로그인, API 키 없음
npx skills add higgsfield-ai/skills
higgsfield model list --json > docs/design/higgsfield_models.json   # 잡 타입·파라미터 스냅샷
```

### 7.2 생성 명령 예시 (STYLE FORMULA는 `docs/design/style_formula.md`에서 그대로 붙여넣는다)

```bash
# 마스코트 표정 1장 (투명화용 키 컬러 배경)
higgsfield generate create nano_banana_2 \
  --prompt "game sprite of a friendly lavender brain mascot smiling, single character, full body visible, centered, <STYLE FORMULA> on a solid uniform bright #00FF00 background, no shadows cast on the background" \
  --aspect_ratio 1:1 --resolution 1k --wait --json > docs/design/jobs/mascot_happy.json

# 도형 아이콘 1장
higgsfield generate create nano_banana_2 \
  --prompt "game UI element: a simple house shape icon, single element, centered, <STYLE FORMULA> on a solid uniform bright #00FF00 background, crisp edges, no drop shadow" \
  --aspect_ratio 1:1 --resolution 1k --wait --json

# 축하 스프라이트 시트 (승인된 마스코트 이미지를 입력으로)
higgsfield generate create autosprite \
  --image_url "<승인 마스코트 URL 또는 잡 ID>" --kind celebrate \
  --frame_count 12 --frame_size 256 --remove_bg default --with_sound false \
  --is_humanoid false --wait --json

# 효과음
higgsfield generate create seed_audio \
  --prompt "short soft wooden tap, correct answer chime, warm, dry, no reverb, no music, under 0.6 seconds" \
  --wait --json

# 랜딩 히어로 클립 (Marketing Studio는 웹 UI에서 App/Hyper Motion 프리셋 사용)
```

### 7.3 후처리 (`scripts/hf_postprocess.py`, 신규 — Python 3.13 + Pillow)

1. 키 컬러 키잉: 허용 오차 내 `#00FF00` → 알파 0, 갇힌 영역은 flood-fill 반전으로 함께 제거, 가장자리 1px 페더.
2. 트림 + 여백 8%; 스프라이트 시트는 전 프레임 **합집합 바운딩 박스**로 동일 크롭, 루프면 마지막 프레임 제거.
3. LANCZOS 축소 → `assets/illustrations/<set>/1.0x|2.0x|3.0x/<name>.png`, `pngquant`급 무손실 근접 압축, 세트 합계 예산 준수.
4. 웹용은 `cwebp -q 82`로 `site/`에 별도 출력.
5. `docs/design/assets.csv`에 `id,role,type,description,size,style_ref,source_job_id,credits` 한 줄 추가. **모든 프롬프트와 잡 JSON을 커밋**한다(재현·저작 증빙).

### 7.4 Flutter 적용 규칙

- 래스터 PNG는 `Image.asset(..., cacheWidth:)`로 디코드 크기 제한. SVG 변환은 하지 않는다(생성물 벡터화 품질 불량).
- 이미지에는 글자를 넣지 않는다. 모든 문구는 위젯이 그린다(다국어·글자 크기·접근성).
- 애니메이션은 `AnimationController` 1회 재생, `MediaQuery.disableAnimations` 존중, 3초 이내.
- 새 의존성 0. `lottie`·`vibration`·`flutter_svg`는 이번 트랙에서도 쓰지 않으면 pubspec에서 제거(별도 정리 PR).

---

## 8. 실행 순서·일정·예산

```text
주차 0 (0.5일)  CLI 설치 · 모델 스냅샷 · B-00 스타일 공식 승인 (~20cr)
주차 1         A-01 피드백 레이어 → A-02 SFX(20cr) → B-01 마스코트(60cr) → B-03 도형 세트(60cr)
주차 2         B-02 빈 상태·온보딩(50cr) → A-03 축하 스프라이트(30cr) → C-01 og:image(10cr) → B-05
주차 3         D 스토어·발표 시각물(150cr) → C-02 히어로 클립(100cr, 선택) → B-04 그림 카드(100cr, 선택)
```

| 항목 | 값 |
|---|---|
| 인력 | 약 12~14인일(선택 항목 포함 16) |
| 크레딧 | 필수 ~350cr, 선택 포함 ~600cr, 재생성 여유 2배 → **~1,000cr** |
| 플랜 | **Plus 1개월($59)** 1회 구독으로 종결. Starter(270cr)로는 필수 항목만 가능하고 재생성 여유가 없다. 크레딧이 월말 소멸하므로 **생성 작업은 결제 후 30일 안에 몰아서** 한다 |
| 병합 조건 | Stage 1 CI 복구 이후, PR당 `flutter analyze` 0/0, 테스트 전수 통과, 자산 크기 예산(앱 +3MB 이내) 명시 |

---

## 9. 사용자 결정이 필요한 것

1. **플랜**: Plus 1개월 구독 승인 여부(§8). 미승인 시 A트랙만 진행(크레딧 0으로 가능한 A-01·B-05 포함).
2. **마스코트 방향**: 현재 `brain_buddy.svg` 실루엣 계승(권장) vs 새 캐릭터. 후보 3장은 B-00에서 제시.
3. **히어로 클립(C-02)**: 도입 여부. 미도입 시 정적 og:image와 캡처만으로 진행.
4. **AI 생성물 표시 문구**: 랜딩 푸터·스토어 설명·발표 덱에 "일러스트는 생성형 AI로 제작 후 검수"를 넣을지. 인공지능 기본법 표시 의무 해당 여부는 근거 등록부(05)에 확인 항목으로 추가한다.

---

## 10. 위험과 대응

| 위험 | 대응 |
|---|---|
| 생성 이미지에 한글·문자 오류 | 이미지에 글자 금지, 위젯이 문구를 그린다 |
| 세트 간 스타일 드리프트 | STYLE FORMULA 바이트 동일 + 첫 승인 이미지 참조 + Soul HEX 팔레트 잠금 |
| "AI 티" 나는 보라 그라데이션·과한 광택 | 공식에 "no gradients, matte" 고정, `DESIGN.md` §5 사전 점검 |
| 스토어 심사에서 생성 UI 스크린샷 문제 | 스크린샷·갤러리는 실제 캡처만, 합성 스크립트로 증빙 |
| 고령 사용자에게 유치한 인상 | "dignified, never childish" 공식 문구, 후보 검토 시 65+ 사용자 1~2명 의견 |
| 크레딧 소멸·재생성 남발 | 자산 수 잠금(§4~6 표), 잡 JSON 커밋으로 중복 생성 방지 |
| 공모전 AI 생성물 규정 | 제출 전 요강 대조, 필요 시 표기 |

---

## 11. 참고 자료

- Higgsfield CLI: https://higgsfield.ai/cli · Skills: https://higgsfield.ai/skills · MCP: https://higgsfield.ai/mcp
- 공식 스킬 저장소: https://github.com/higgsfield-ai/skills
- game-generation 스킬 규약(STYLE FORMULA·AutoSprite·오디오): https://github.com/kaveone/higgsfield-skills/tree/main/higgsfield-game-generation
- AI Games 소개: https://higgsfield.ai/blog/higgsfield-ai-games
- 앱 마케팅 스택 워크플로(프롬프트 원문): https://higgsfield.ai/blog/marketing-studio-video-2
- AI Design Generator(인페인팅·배경 제거·리사이즈): https://higgsfield.ai/ai-design-generator
- Soul HEX 색 제어: https://higgsfield.ai/blog/hex-codes-ai-image-generation-color-control-soul
- Cinema Studio 2.5: https://higgsfield.ai/blog/cinema-studio-2-5-ai-video-generator
- 요금(2026-09-10 기준 정리): https://creatify.ai/blog/higgsfield-pricing-(2026)-plans-and-what-you-ll-actually-pay · 공식: https://higgsfield.ai/pricing
- 소유권·상업 이용: https://higgsfield.ai/creator-hub/help-center/account/who-owns-my-generations-and-can-i-use-them-commercially · 약관 개정 안내: https://higgsfield.ai/blog/terms-of-use-privacy-policy-update
- 국내 가이드(크레딧 체감 단가): https://carat.im/blog/higgsfield-ai-guide
- Flutter 게임 도구 참고(도입하지 않음, 판단 근거): https://flutter.dev/games · https://pub.dev/packages/flame
