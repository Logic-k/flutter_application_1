# -*- coding: utf-8 -*-
from pptx import Presentation
from pptx.util import Pt, Cm, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.oxml.ns import qn
from lxml import etree
import copy

# Colors
DARK_BLUE    = RGBColor(0x1F, 0x3D, 0x79)
MID_BLUE     = RGBColor(0x2E, 0x74, 0xB5)
LIGHT_BLUE   = RGBColor(0xDE, 0xEB, 0xF7)
RED_TITLE    = RGBColor(0x8B, 0x00, 0x00)
WHITE        = RGBColor(0xFF, 0xFF, 0xFF)
BLACK        = RGBColor(0x00, 0x00, 0x00)
GRAY         = RGBColor(0x59, 0x59, 0x59)
LIGHT_GRAY   = RGBColor(0xF2, 0xF2, 0xF2)
CODE_BG      = RGBColor(0x1E, 0x1E, 0x1E)
CODE_FG      = RGBColor(0xD4, 0xD4, 0xD4)
TEAL         = RGBColor(0x00, 0x70, 0xC0)

FONT = '맑은 고딕'
W = Cm(33.87)
H = Cm(19.05)


def new_prs():
    prs = Presentation()
    prs.slide_width  = W
    prs.slide_height = H
    return prs


def blank_slide(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def txb(slide, text, x, y, w, h, size=11, bold=False, color=BLACK,
        align=PP_ALIGN.LEFT, wrap=True, font=FONT):
    box = slide.shapes.add_textbox(x, y, w, h)
    box.word_wrap = wrap
    tf = box.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.name = font
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    return box


def txb_multi(slide, lines, x, y, w, h, size=10, color=BLACK, font=FONT,
              line_spacing=None):
    """lines: list of (text, bold, size_override_or_None)"""
    box = slide.shapes.add_textbox(x, y, w, h)
    box.word_wrap = True
    tf = box.text_frame
    tf.word_wrap = True
    first = True
    for (text, bold, sz) in lines:
        if first:
            p = tf.paragraphs[0]
            first = False
        else:
            p = tf.add_paragraph()
        run = p.add_run()
        run.text = text
        run.font.name = font
        run.font.size = Pt(sz if sz else size)
        run.font.bold = bold
        run.font.color.rgb = color
    return box


def fill_shape(shape, color):
    shape.fill.solid()
    shape.fill.fore_color.rgb = color


def header_bar(slide, title, subtitle=None):
    """Blue bar at top-left with white title."""
    bar = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.RECTANGLE
        Cm(0), Cm(0.6), Cm(16), Cm(1.55)
    )
    fill_shape(bar, DARK_BLUE)
    bar.line.fill.background()
    tf = bar.text_frame
    tf.word_wrap = False
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.LEFT
    run = p.add_run()
    run.text = f"| {title}"
    run.font.name = FONT
    run.font.size = Pt(16)
    run.font.bold = True
    run.font.color.rgb = WHITE
    # small decorative line
    line = slide.shapes.add_shape(1, Cm(0), Cm(2.15), W, Cm(0.05))
    fill_shape(line, MID_BLUE)
    line.line.fill.background()
    if subtitle:
        txb(slide, subtitle, Cm(16.5), Cm(0.8), Cm(16), Cm(1.2),
            size=9, color=GRAY)


def rect(slide, x, y, w, h, color, line_color=None):
    s = slide.shapes.add_shape(1, x, y, w, h)
    fill_shape(s, color)
    if line_color:
        s.line.color.rgb = line_color
    else:
        s.line.fill.background()
    return s


def add_table(slide, headers, rows, x, y, w, col_widths=None,
              row_height=Cm(0.65), header_bg=DARK_BLUE, alt_bg=LIGHT_BLUE,
              font_size=9):
    ncols = len(headers)
    nrows = len(rows)
    tbl = slide.shapes.add_table(nrows + 1, ncols, x, y, w,
                                  row_height * (nrows + 1))
    table = tbl.table
    # column widths
    if col_widths:
        for i, cw in enumerate(col_widths):
            table.columns[i].width = cw
    # header row
    for ci, hdr in enumerate(headers):
        cell = table.cell(0, ci)
        cell.fill.solid()
        cell.fill.fore_color.rgb = header_bg
        tf = cell.text_frame
        tf.paragraphs[0].alignment = PP_ALIGN.CENTER
        run = tf.paragraphs[0].add_run()
        run.text = hdr
        run.font.name = FONT
        run.font.size = Pt(font_size)
        run.font.bold = True
        run.font.color.rgb = WHITE
    # data rows
    for ri, row_data in enumerate(rows):
        bg = alt_bg if ri % 2 == 1 else WHITE
        for ci, val in enumerate(row_data):
            cell = table.cell(ri + 1, ci)
            cell.fill.solid()
            cell.fill.fore_color.rgb = bg
            tf = cell.text_frame
            tf.word_wrap = True
            tf.paragraphs[0].alignment = PP_ALIGN.LEFT
            run = tf.paragraphs[0].add_run()
            run.text = str(val)
            run.font.name = FONT
            run.font.size = Pt(font_size)
            run.font.color.rgb = BLACK
    return tbl


def code_box(slide, code_text, x, y, w, h, size=7.5):
    box = rect(slide, x, y, w, h, CODE_BG)
    tf_box = slide.shapes.add_textbox(x + Cm(0.2), y + Cm(0.2),
                                       w - Cm(0.4), h - Cm(0.3))
    tf_box.word_wrap = True
    tf = tf_box.text_frame
    tf.word_wrap = True
    first = True
    for line in code_text.split('\n'):
        if first:
            p = tf.paragraphs[0]
            first = False
        else:
            p = tf.add_paragraph()
        run = p.add_run()
        run.text = line
        run.font.name = 'Consolas'
        run.font.size = Pt(size)
        run.font.color.rgb = CODE_FG
    return tf_box


# ─────────────────────────────────────────
# SLIDE 1 – 표지
# ─────────────────────────────────────────
def slide01(prs):
    sl = blank_slide(prs)
    # background gradient-like top bar
    rect(sl, Cm(0), Cm(0), W, Cm(3.5), DARK_BLUE)
    # logo area text
    txb(sl, "한이음드림업", Cm(28), Cm(0.3), Cm(5), Cm(0.8),
        size=12, bold=True, color=WHITE)
    # circuit decoration dots (simplified)
    for dx, dy in [(1,1),(1,2),(3,1),(3,2.5),(5,1.5),(5,2.8),
                   (7,1),(7,2),(9,1.5)]:
        r = slide_dot(sl, Cm(dx), Cm(dy))
    # Main title
    txb(sl, "SW개발/HW제작 설계서", Cm(3), Cm(4.5), Cm(27), Cm(2.5),
        size=40, bold=True, color=RED_TITLE, align=PP_ALIGN.LEFT)
    # Project name
    rect(sl, Cm(3), Cm(8), Cm(27), Cm(2.2), LIGHT_GRAY)
    txb(sl, "프로젝트 명 :", Cm(3.5), Cm(8.2), Cm(8), Cm(0.9),
        size=14, bold=True, color=DARK_BLUE)
    txb(sl,
        "MemoryLink\n- AI 기반 치매 예방 멀티 인터벤션 모바일 플랫폼",
        Cm(3.5), Cm(9.0), Cm(25), Cm(1.2),
        size=13, bold=True, color=BLACK)
    # date + team
    rect(sl, Cm(8), Cm(12), Cm(18), Cm(3.5), LIGHT_GRAY)
    txb(sl, "2025. 05. 22", Cm(9), Cm(12.5), Cm(16), Cm(1),
        size=13, color=GRAY, align=PP_ALIGN.CENTER)
    txb(sl, "(팀명)  *팀원 이름 및 소속 기입 불가",
        Cm(9), Cm(13.5), Cm(16), Cm(1),
        size=12, color=RED_TITLE, align=PP_ALIGN.CENTER)


def slide_dot(sl, x, y, r=Cm(0.18)):
    s = sl.shapes.add_shape(9, x, y, r, r)  # oval
    fill_shape(s, MID_BLUE)
    s.line.fill.background()
    return s


# ─────────────────────────────────────────
# SLIDE 2 – 수행 단계별 주요 산출물
# ─────────────────────────────────────────
def slide02(prs):
    sl = blank_slide(prs)
    header_bar(sl, "수행 단계별 주요 산출물")
    headers = ["단계", "산출물", "일반\n모바일APP·Web", "응용SW\n빅데이터·AI", "응용HW\nIoT·로봇"]
    rows = [
        ["환경 분석", "시장/기술 환경 분석서", "△", "△", "△"],
        ["",          "설문조사 결과서",        "△", "△", "△"],
        ["",          "인터뷰 결과서",          "△", "△", "△"],
        ["요구사항 분석","요구사항 정의서",      "○", "○", "○"],
        ["",          "유즈케이스 정의서",      "△", "△", "△"],
        ["아키텍처 설계","서비스 구성도(시스템 구성도)","○","○","○"],
        ["",          "서비스 흐름도(데이터 흐름도)","△","○","△"],
        ["",          "UI/UX 정의서",           "△", "△", "△"],
        ["",          "하드웨어/센서 구성도",   "-",  "-",  "○"],
        ["기능 설계", "메뉴 구성도",            "○", "○", "○"],
        ["",          "화면 설계서",            "○", "○", "△"],
        ["",          "엔티티 관계도",          "○", "○", "△"],
        ["",          "기능 처리도(기능 흐름도)","○","○","○"],
        ["",          "알고리즘 명세서/설명서", "△", "○", "○"],
        ["",          "데이터 수집처리 정의서", "-",  "○", "-"],
        ["",          "하드웨어 설계도",        "-",  "-",  "○"],
        ["개발/구현", "프로그램 목록",          "○", "○", "○"],
        ["",          "테이블 정의서",          "○", "○", "△"],
        ["",          "핵심 소스코드",          "○", "○", "○"],
    ]
    cw = [Cm(3.2), Cm(7.5), Cm(4.5), Cm(4.5), Cm(4.5)]
    add_table(sl, headers, rows, Cm(0.5), Cm(2.4), Cm(24.2),
              col_widths=cw, row_height=Cm(0.6), font_size=8)
    txb(sl, "※ ○ 필수, △ 선택", Cm(0.5), Cm(18.0), Cm(10), Cm(0.6),
        size=9, color=GRAY)
    # highlight our project type
    rect(sl, Cm(25.0), Cm(2.4), Cm(8.5), Cm(1.2), LIGHT_BLUE)
    txb(sl, "본 프로젝트: 일반 모바일 APP", Cm(25.2), Cm(2.6), Cm(8), Cm(0.8),
        size=10, bold=True, color=DARK_BLUE)
    txb(sl, "필수 산출물(○)을 모두 작성합니다.",
        Cm(25.2), Cm(3.7), Cm(8), Cm(0.6), size=9, color=GRAY)


# ─────────────────────────────────────────
# SLIDE 3 – 요구사항 정의서
# ─────────────────────────────────────────
def slide03(prs):
    sl = blank_slide(prs)
    header_bar(sl, "요구사항 정의서")
    headers = ["요구사항ID", "요구사항명", "기능ID", "기능명", "세부사항", "예외사항"]
    rows = [
        ["A01","인지훈련 기능","A01_B01","비교 게임","두 수/식을 비교하여 큰 값을 선택한다","시간 초과 시 오답 처리"],
        ["",   "",            "A01_B02","구구단 맞추기","구구단 문제의 정답을 선택한다",""],
        ["",   "",            "A01_B03","순서 기억","제시된 순서를 기억 후 재현한다",""],
        ["",   "",            "A01_B04","도형 스도쿠","3×3 그리드의 빈칸 도형을 선택한다",""],
        ["",   "",            "A01_B05","도형 짝 맞추기","같은 도형 쌍을 찾아 선택한다",""],
        ["",   "",            "A01_B06","단어 분류","단어를 알맞은 카테고리로 분류한다",""],
        ["",   "",            "A01_B07","문장 읽기","문장 읽기 후 이해도 문항에 답한다",""],
        ["A02","보행 분석 기능","A02_B01","실시간 보행 측정","가속도 센서로 보행 변동성(CV%)을 측정한다","센서 권한 거부 시 안내"],
        ["",   "",            "A02_B02","백그라운드 만보기","앱 종료 후에도 걸음수를 지속 측정한다","배터리 최적화 예외 처리"],
        ["",   "",            "A02_B03","주간 통계","7일간 걸음수/칼로리/거리를 그래프로 제공한다",""],
        ["A03","음성 평가 기능","A03_B01","음성 녹음(STT)","마이크로 음성을 녹음하여 텍스트로 변환한다","마이크 권한 거부 시 안내"],
        ["",   "",            "A03_B02","어휘 분석(TTR)","TTR/발화속도로 위험도 점수(0~100)를 산출한다",""],
        ["A04","리포트 기능", "A04_B01","주간 점수 차트","4개 영역 인지 점수 시계열 차트를 표시한다","데이터 없을 시 안내"],
        ["",   "",            "A04_B02","뇌 나이 추정","인지 점수 평균으로 뇌 나이를 추정한다",""],
        ["",   "",            "A04_B03","PDF 내보내기","임상 리포트를 PDF로 저장·공유한다",""],
        ["A05","사용자 관리", "A05_B01","회원가입/로그인","SQLite 기반 로컬 인증을 지원한다","중복 ID 거부"],
        ["",   "",            "A05_B02","의료 정보 관리","혈액형·복용약·비상연락처를 등록한다",""],
        ["",   "",            "A05_B03","보호자 QR 연결","QR 코드로 보호자 모니터링 링크를 공유한다",""],
        ["A06","관리자 기능", "A06_B01","어드민 대시보드","전체 사용자 수/DAU/위험 사용자를 조회한다","관리자 코드 인증"],
        ["",   "",            "A06_B02","위험 사용자 감지","주간 점수 20% 이상 하락 사용자를 표시한다",""],
        ["A07","CS 기능",     "A07_B01","공지사항/FAQ","공지사항·FAQ를 등록·조회한다",""],
        ["",   "",            "A07_B02","1:1 문의","사용자 문의 제출 및 관리자 답변을 지원한다",""],
        ["",   "",            "A07_B03","치매안심센터 연결","전화·지도 앱으로 치매안심센터에 연결한다",""],
    ]
    cw = [Cm(2.2), Cm(3.8), Cm(2.8), Cm(3.5), Cm(10.0), Cm(4.5)]
    add_table(sl, headers, rows, Cm(0.3), Cm(2.4), Cm(32.8),
              col_widths=cw, row_height=Cm(0.58), font_size=7.5)


# ─────────────────────────────────────────
# SLIDE 4 – 서비스 구성도 (시스템 아키텍처)
# ─────────────────────────────────────────
def slide04(prs):
    sl = blank_slide(prs)
    header_bar(sl, "서비스 구성도 - 시스템 아키텍처")

    def box(x, y, w, h, label, bg=DARK_BLUE, fg=WHITE, sz=9):
        r = rect(sl, x, y, w, h, bg, MID_BLUE)
        txb(sl, label, x+Cm(0.1), y+Cm(0.1), w-Cm(0.2), h-Cm(0.1),
            size=sz, bold=True, color=fg, align=PP_ALIGN.CENTER)

    # User
    box(Cm(1), Cm(3.5), Cm(4), Cm(2.5), "사용자\n(노인/MCI 환자)",
        bg=RGBColor(0x70,0xAD,0x47), sz=10)
    # Arrow
    txb(sl, "→", Cm(5.2), Cm(4.4), Cm(1.5), Cm(0.8), size=18, bold=True, color=DARK_BLUE)

    # App core
    box(Cm(6.5), Cm(2.5), Cm(14), Cm(12), "",
        bg=LIGHT_BLUE, fg=BLACK)
    txb(sl, "Flutter 모바일 앱  (Android / iOS / Web)",
        Cm(7), Cm(2.6), Cm(13), Cm(0.8), size=11, bold=True, color=DARK_BLUE)

    sub = [
        (Cm(7.2), Cm(3.8), "인지훈련 엔진\n7 Game + 적응형 난이도"),
        (Cm(7.2), Cm(5.8), "보행 분석\naccelerometer + pedometer"),
        (Cm(7.2), Cm(7.8), "음성 평가\nSTT → TTR 어휘 분석"),
        (Cm(7.2), Cm(9.8), "리포트 생성\nfl_chart + PDF 내보내기"),
        (Cm(12.5), Cm(3.8), "백그라운드 만보기\nAndroid Foreground Service"),
        (Cm(12.5), Cm(5.8), "기억 정원\nLottie 애니메이션"),
        (Cm(12.5), Cm(7.8), "어드민 포털\n7개 관리화면"),
        (Cm(12.5), Cm(9.8), "CS 센터\n공지/FAQ/문의"),
    ]
    for (sx, sy, label) in sub:
        box(sx, sy, Cm(4.8), Cm(1.6), label, bg=MID_BLUE, sz=8)

    # Arrows down to DBs
    txb(sl, "↓", Cm(8), Cm(14.7), Cm(2), Cm(0.8), size=16, bold=True, color=DARK_BLUE)
    txb(sl, "↓", Cm(15.5), Cm(14.7), Cm(2), Cm(0.8), size=16, bold=True, color=DARK_BLUE)

    # DBs
    box(Cm(6), Cm(15.5), Cm(6), Cm(2), "SQLite 로컬 DB\n사용자/점수/걸음수/체크리스트",
        bg=RGBColor(0xC5,0x5A,0x11), sz=8)
    box(Cm(13.5), Cm(15.5), Cm(7), Cm(2), "Supabase 클라우드 DB\n훈련난이도/공지/문의/FAQ",
        bg=RGBColor(0x20,0x3864,0x7B) if False else RGBColor(0x00,0x70,0xC0), sz=8)

    # Provider / State layer label
    txb(sl, "State Management: Provider (ChangeNotifier)\nRouting: GoRouter 17.x  |  Font: 맑은 고딕",
        Cm(21.5), Cm(3.5), Cm(11.5), Cm(2), size=9, color=DARK_BLUE)

    # Legend
    txb(sl, "■ 인지훈련  ■ 보행  ■ 음성  ■ 리포트  ■ CS",
        Cm(1), Cm(17.5), Cm(25), Cm(0.8), size=8, color=GRAY)


# ─────────────────────────────────────────
# SLIDE 5 – 서비스 구성도 (서비스 시나리오)
# ─────────────────────────────────────────
def slide05(prs):
    sl = blank_slide(prs)
    header_bar(sl, "서비스 구성도 - 서비스 시나리오")

    scenarios = [
        ("① 인지훈련 시나리오",
         "앱 실행 → 인지훈련 탭 선택 → 게임 선택 (7종)\n→ 적응형 난이도로 문제 생성\n→ 사용자 응답 → 점수 저장 (SQLite)\n→ 난이도 자동 조정 (Supabase 동기화)\n→ 주간 리포트 반영",
         RGBColor(0x1F,0x3D,0x79)),
        ("② 보행 분석 시나리오",
         "걷기 시작 → 백그라운드 만보기 자동 측정\n→ 보행 탭 → '측정 시작' 버튼\n→ 가속도 3축 데이터 수집\n→ CV% 실시간 계산 및 파형 표시\n→ 세션 종료 → 결과 저장 → 리포트 반영",
         RGBColor(0x37,0x86,0x3C)),
        ("③ 보호자 알림 시나리오",
         "오후 6시 이후 걸음수 급감 감지\n(3일 평균의 30% 미만)\n→ 이상 감지 알림 생성\n→ 보호자 QR 코드 공유\n→ 보호자가 대시보드 접속\n→ 위험 지표 확인 및 조치",
         RGBColor(0xC5,0x5A,0x11)),
    ]

    for i, (title, steps, color) in enumerate(scenarios):
        x = Cm(0.5 + i * 11.1)
        rect(sl, x, Cm(2.4), Cm(10.7), Cm(1.1), color)
        txb(sl, title, x+Cm(0.2), Cm(2.5), Cm(10.3), Cm(0.9),
            size=11, bold=True, color=WHITE)
        rect(sl, x, Cm(3.5), Cm(10.7), Cm(13), LIGHT_GRAY)
        txb(sl, steps, x+Cm(0.3), Cm(3.7), Cm(10.2), Cm(12.5),
            size=10, color=BLACK)

    txb(sl,
        "○ 공통 서비스 흐름: 로그인 → 온보딩 (최초 1회) → 기저값 인지평가 → 일상 루틴 (훈련·보행·음성) → 주간 리포트",
        Cm(0.5), Cm(17.2), Cm(32.5), Cm(0.8), size=9, color=GRAY)


# ─────────────────────────────────────────
# SLIDE 6 – 메뉴 구성도
# ─────────────────────────────────────────
def slide06(prs):
    sl = blank_slide(prs)
    header_bar(sl, "메뉴 구성도")

    def node(x, y, w, h, label, bg=MID_BLUE, fg=WHITE, sz=8):
        r = rect(sl, x, y, w, h, bg, DARK_BLUE)
        txb(sl, label, x+Cm(0.1), y+Cm(0.05), w-Cm(0.2), h-Cm(0.1),
            size=sz, bold=True, color=fg, align=PP_ALIGN.CENTER)

    def arrow_h(x1, y, x2):
        line = sl.shapes.add_connector(1, x1, y, x2, y)
        line.line.color.rgb = DARK_BLUE
        line.line.width = Pt(1)

    def arrow_v(x, y1, y2):
        line = sl.shapes.add_connector(1, x, y1, x, y2)
        line.line.color.rgb = DARK_BLUE
        line.line.width = Pt(1)

    # Root
    node(Cm(1), Cm(2.5), Cm(3.5), Cm(1), "스플래시 화면", bg=DARK_BLUE, sz=9)
    arrow_h(Cm(4.5), Cm(3.0), Cm(6))
    node(Cm(6), Cm(2.5), Cm(3.5), Cm(1), "로그인", bg=DARK_BLUE, sz=9)
    node(Cm(6), Cm(4.0), Cm(3.5), Cm(1), "회원가입", bg=DARK_BLUE, sz=9)
    arrow_h(Cm(9.5), Cm(3.0), Cm(11))
    node(Cm(11), Cm(2.5), Cm(4), Cm(1), "온보딩\n(최초1회)", bg=DARK_BLUE, sz=8)
    arrow_h(Cm(15), Cm(3.0), Cm(16.5))

    # Main nav
    node(Cm(16.5), Cm(2.5), Cm(4.5), Cm(1), "메인 내비게이션\n(하단 탭 5개)", bg=RED_TITLE, sz=9)

    tabs = [
        ("홈", Cm(0.5), ["오늘의 걸음 목표", "기억 정원", "MIND 식단 추천", "일일 체크리스트", "일상 회상 (Daily Recall)"]),
        ("인지훈련", Cm(7), ["비교 게임", "구구단 맞추기", "순서 기억", "도형 스도쿠", "도형 짝 맞추기", "단어 분류", "문장 읽기"]),
        ("보행", Cm(13.5), ["실시간 만보기", "보행 변동성(CV%) 측정", "주간 걸음 통계", "정밀 분석"]),
        ("리포트", Cm(20), ["주간 인지 점수 차트", "뇌 나이 추정", "임상 리포트", "PDF 내보내기"]),
        ("프로필", Cm(26.5), ["내 정보 수정", "의료 정보", "보호자 QR 연결", "접근성 설정\n(글자 크기/음성/진동)", "고객센터", "치매안심센터 연결", "로그아웃"]),
    ]
    for (tab_name, tx, items) in tabs:
        node(tx, Cm(5.0), Cm(6.0), Cm(0.9), tab_name, bg=MID_BLUE, sz=9)
        for ii, item in enumerate(items):
            iy = Cm(6.3 + ii * 1.4)
            node(tx + Cm(0.5), iy, Cm(5.0), Cm(1.1), item,
                 bg=LIGHT_GRAY, fg=BLACK, sz=7.5)
            arrow_v(tx + Cm(3.0), Cm(6.3 + ii * 1.4) if ii == 0 else iy - Cm(0.3), iy)


# ─────────────────────────────────────────
# SLIDE 7 – 화면 설계서: 홈 화면
# ─────────────────────────────────────────
def slide07(prs):
    sl = blank_slide(prs)
    header_bar(sl, "화면 설계서 - 홈 화면")

    # Feature table
    headers = ["기능번호", "기능명", "기능설명", "처리내용"]
    rows = [
        ["HOME-001", "실시간 걸음수", "오늘의 걸음수·목표 달성률을 표시한다",
         "PedometerManager에서 steps 수신, 목표 6000보 대비 %"],
        ["HOME-002", "기억 정원",    "계절·훈련 달성에 따라 꽃이 자라는 가드닝 화면",
         "Lottie 애니메이션 + 훈련 완료 카운트로 꽃 단계 갱신"],
        ["HOME-003", "MIND 식단 추천","치매 예방 MIND 식단 카드 슬라이드를 제공한다",
         "정적 콘텐츠 카드(12개 식품군) 랜덤 표시"],
        ["HOME-004", "일일 체크리스트","오늘의 활동 목표 체크 기능(운동·훈련·복약 등)",
         "SQLite checklist 테이블 upsert (date 기준)"],
        ["HOME-005", "일상 회상",    "오늘 있었던 일을 짧게 기록하는 회상 훈련",
         "Daily recall 페이지 이동; 저장 후 훈련 점수 반영"],
    ]
    cw = [Cm(3.0), Cm(3.5), Cm(10.5), Cm(12.0)]
    add_table(sl, headers, rows, Cm(0.3), Cm(2.4), Cm(29.0),
              col_widths=cw, row_height=Cm(0.85), font_size=8)

    # Mockup phone frame
    rx, ry, rw, rh = Cm(30.0), Cm(2.4), Cm(3.3), Cm(16)
    rect(sl, rx, ry, rw, rh, LIGHT_GRAY, DARK_BLUE)
    screen_items = [
        "┌─────────────┐",
        "│  MemoryLink │",
        "│   🏠 홈     │",
        "│─────────────│",
        "│ 오늘 걸음수  │",
        "│  3,254 / 6,000│",
        "│ [████░░░░] 54%│",
        "│─────────────│",
        "│ [기억 정원 🌸]│",
        "│ [MIND 식단  ]│",
        "│ [체크리스트 ]│",
        "│─────────────│",
        "│홈 훈련 보행  │",
        "│리포트 프로필 │",
        "└─────────────┘",
    ]
    for ii, item in enumerate(screen_items):
        txb(sl, item, rx+Cm(0.05), ry+Cm(0.3+ii*0.98), rw-Cm(0.1), Cm(0.9),
            size=6, color=BLACK, font='Consolas')


# ─────────────────────────────────────────
# SLIDE 8 – 화면 설계서: 인지훈련 허브
# ─────────────────────────────────────────
def slide08(prs):
    sl = blank_slide(prs)
    header_bar(sl, "화면 설계서 - 인지훈련 허브")

    info = [
        ("기능번호", "GAME-001 ~ GAME-007"),
        ("기능명",   "인지훈련 허브 (7종 게임)"),
        ("기능설명", "사용자의 현재 난이도(1~10)에 맞게 7종의 인지훈련 게임을 제공한다.\n"
                     "적응형 난이도 엔진(DifficultyProvider)이 성과에 따라 레벨을 자동 조정한다."),
        ("처리내용", "① DifficultyProvider.loadLevels() 로 현재 레벨 조회\n"
                     "② 게임 선택 → 레벨 기반 문제 생성\n"
                     "③ 응답 수집 → updatePerformance(category, isCorrect, time)\n"
                     "④ 3연속 정답 + 목표시간 이하 → level UP (max 10)\n"
                     "⑤ 2연속 오답 → level DOWN (min 1)\n"
                     "⑥ setCognitiveScore() → SQLite 저장 → Supabase 동기화"),
        ("비고",     "게임 공통 템플릿: GameTemplate 위젯\n"
                     "카테고리: 계산·논리·기억·지각 (4개 영역)"),
        ("요구사항명", "인지훈련 기능 (A01)"),
    ]

    for ii, (key, val) in enumerate(info):
        iy = Cm(2.5 + ii * 1.5)
        rect(sl, Cm(0.3), iy, Cm(4.0), Cm(1.3), DARK_BLUE)
        txb(sl, key, Cm(0.4), iy+Cm(0.2), Cm(3.8), Cm(1.0),
            size=9, bold=True, color=WHITE)
        rect(sl, Cm(4.3), iy, Cm(22.5), Cm(1.3), LIGHT_GRAY)
        txb(sl, val, Cm(4.5), iy+Cm(0.1), Cm(22.1), Cm(1.3),
            size=8.5, color=BLACK)

    # 7 game cards
    games = [
        ("GAME-001\n비교 게임\n(계산)",   MID_BLUE),
        ("GAME-002\n구구단\n(계산)",      MID_BLUE),
        ("GAME-003\n순서 기억\n(기억)",   RGBColor(0x37,0x86,0x3C)),
        ("GAME-004\n도형 스도쿠\n(기억)", RGBColor(0x37,0x86,0x3C)),
        ("GAME-005\n도형 짝 맞추기\n(지각)", RGBColor(0xC5,0x5A,0x11)),
        ("GAME-006\n단어 분류\n(논리)",   RGBColor(0x75,0x30,0x0D)),
        ("GAME-007\n문장 읽기\n(지각)",   RGBColor(0xC5,0x5A,0x11)),
    ]
    for gi, (label, color) in enumerate(games):
        gx = Cm(27.5 + (gi % 2) * 2.8)
        gy = Cm(2.5 + gi * 1.55)
        if gi == 6:
            gx = Cm(28.5)
        rect(sl, gx, gy, Cm(2.5), Cm(1.35), color)
        txb(sl, label, gx+Cm(0.1), gy+Cm(0.05), Cm(2.3), Cm(1.25),
            size=7, color=WHITE, align=PP_ALIGN.CENTER)

    txb(sl, "난이도: Lv.1 ~ Lv.10 (자동 조정)", Cm(27), Cm(13.5),
        Cm(6), Cm(0.7), size=8, bold=True, color=RED_TITLE)


# ─────────────────────────────────────────
# SLIDE 9 – 화면 설계서: 보행 분석
# ─────────────────────────────────────────
def slide09(prs):
    sl = blank_slide(prs)
    header_bar(sl, "화면 설계서 - 보행 분석")

    headers = ["기능번호", "기능명", "기능설명", "처리내용"]
    rows = [
        ["GAIT-001","실시간 보행 측정",
         "가속도 센서로 보행 변동성(CV%)을 실시간 측정한다",
         "GaitProvider.startMeasurement() → sensors_plus 스트리밍"],
        ["GAIT-002","걸음 감지 알고리즘",
         "3축 가속도 크기(magnitude)로 걸음을 감지한다",
         "magnitude=√(x²+y²+z²) > 1.0, 시간간격 300~2000ms"],
        ["GAIT-003","보행 변동성(CV%) 계산",
         "stride_time의 표준편차/평균으로 CV%를 산출한다",
         "CV%=(σ/μ)×100; 높을수록 불규칙 보행 위험"],
        ["GAIT-004","실시간 파형 시각화",
         "최근 50샘플의 가속도 파형을 그래프로 표시한다",
         "fl_chart LineChart; 0.1초 간격 업데이트"],
        ["GAIT-005","백그라운드 만보기",
         "앱 종료 후에도 Android 포그라운드 서비스로 걸음 수 측정",
         "flutter_background_service + pedometer 패키지"],
        ["GAIT-006","일간 보행 저장",
         "걸음수·칼로리·거리를 일 단위로 SQLite에 저장한다",
         "daily_steps 테이블 upsert; 칼로리=steps×0.04×(weight/60)×((100-age)/100)"],
    ]
    cw = [Cm(2.8), Cm(3.8), Cm(9.5), Cm(12.0)]
    add_table(sl, headers, rows, Cm(0.3), Cm(2.4), Cm(28.4),
              col_widths=cw, row_height=Cm(1.0), font_size=8)

    # CV formula box
    rect(sl, Cm(29.2), Cm(2.4), Cm(4.3), Cm(4.5), LIGHT_BLUE, DARK_BLUE)
    txb(sl, "보행 변동성 공식",
        Cm(29.4), Cm(2.6), Cm(4.0), Cm(0.7), size=9, bold=True, color=DARK_BLUE)
    txb(sl, "CV(%) =\n  (σ / μ) × 100\n\nσ: stride_time 표준편차\nμ: stride_time 평균\n\n정상: CV < 3%\n경계: 3~5%\n위험: CV ≥ 5%",
        Cm(29.4), Cm(3.4), Cm(4.0), Cm(3.3), size=8.5, color=BLACK)

    rect(sl, Cm(29.2), Cm(7.2), Cm(4.3), Cm(4.0), LIGHT_GRAY, DARK_BLUE)
    txb(sl, "칼로리 계산식",
        Cm(29.4), Cm(7.3), Cm(4.0), Cm(0.7), size=9, bold=True, color=DARK_BLUE)
    txb(sl, "kcal = steps × 0.04\n  × (weight / 60)\n  × ((100 - age) / 100)\n\n거리(km)\n = steps × 0.7 / 1000",
        Cm(29.4), Cm(8.0), Cm(4.0), Cm(3.0), size=8.5, color=BLACK)


# ─────────────────────────────────────────
# SLIDE 10 – 화면 설계서: 리포트
# ─────────────────────────────────────────
def slide10(prs):
    sl = blank_slide(prs)
    header_bar(sl, "화면 설계서 - 리포트")

    headers = ["기능번호", "기능명", "기능설명", "처리내용"]
    rows = [
        ["REPORT-001","주간 인지 점수 차트",
         "최근 7일간 4개 영역(계산/논리/기억/지각) 점수 추이를 시계열 차트로 표시",
         "SQLite training_scores → fl_chart LineChart; 영역별 색상 구분"],
        ["REPORT-002","뇌 나이 추정",
         "인지 점수 평균(0~10)을 기반으로 추정 뇌 나이를 계산하여 표시한다",
         "brainAge = realAge + (5.0 - avgScore) × 2; ReportAnalyzer.analyze()"],
        ["REPORT-003","임상 리포트 생성",
         "주간 인지·보행·음성 점수를 종합한 임상 텍스트 리포트를 생성한다",
         "ClinicalReportGenerator.generate(); 강점·약점·권고사항 포함"],
        ["REPORT-004","개인화 권장사항",
         "점수가 낮은 영역에 맞춤 활동 권장사항 카드를 제공한다",
         "ReportAnalyzer.getRecommendations(); 4개 영역별 권장 운동 매핑"],
        ["REPORT-005","PDF 내보내기·공유",
         "임상 리포트를 PDF로 변환하여 저장하거나 타 앱으로 공유한다",
         "pdf + printing 패키지; share_plus로 외부 공유"],
    ]
    cw = [Cm(3.0), Cm(4.0), Cm(11.0), Cm(11.5)]
    add_table(sl, headers, rows, Cm(0.3), Cm(2.4), Cm(29.8),
              col_widths=cw, row_height=Cm(1.1), font_size=8)

    # Right panel: chart mockup
    rect(sl, Cm(30.2), Cm(2.4), Cm(3.3), Cm(10), LIGHT_GRAY, DARK_BLUE)
    txb(sl, "주간 점수 차트 (예시)",
        Cm(30.3), Cm(2.6), Cm(3.1), Cm(0.6), size=7.5, bold=True, color=DARK_BLUE)
    chart_data = "10│  ●─●\n 8│●     ●\n 6│        ●\n 4│\n 2│\n  └─────────\n   월 화 수 목 금"
    txb(sl, chart_data, Cm(30.3), Cm(3.3), Cm(3.0), Cm(3.5),
        size=7, color=BLACK, font='Consolas')

    txb(sl, "뇌 나이 추정 카드 (예시)",
        Cm(30.3), Cm(7.2), Cm(3.0), Cm(0.6), size=7.5, bold=True, color=DARK_BLUE)
    rect(sl, Cm(30.3), Cm(7.9), Cm(3.0), Cm(2.0), MID_BLUE)
    txb(sl, "추정 뇌 나이\n\n65세",
        Cm(30.4), Cm(8.0), Cm(2.8), Cm(1.8), size=10, bold=True,
        color=WHITE, align=PP_ALIGN.CENTER)
    txb(sl, "실제 나이 대비 +2세\n→ 인지훈련 강화 권장",
        Cm(30.3), Cm(10.1), Cm(3.1), Cm(1.0), size=7.5, color=RED_TITLE)


# ─────────────────────────────────────────
# SLIDE 11 – 엔티티 관계도 (ERD)
# ─────────────────────────────────────────
def slide11(prs):
    sl = blank_slide(prs)
    header_bar(sl, "엔티티 관계도 - ERD")

    txb(sl, "○ SQLite 로컬 데이터베이스 (sqflite)",
        Cm(0.5), Cm(2.4), Cm(20), Cm(0.7), size=10, bold=True, color=DARK_BLUE)

    tables = [
        ("users (사용자)",
         ["id INT PK", "username VARCHAR(50) UNIQUE",
          "password VARCHAR(100)", "goal VARCHAR(20)",
          "age INT", "weight REAL", "blood_type VARCHAR(5)",
          "medications TEXT", "emergency_contact VARCHAR(20)",
          "pedometer_enabled BOOLEAN",
          "has_completed_onboarding BOOLEAN"],
         Cm(0.3), Cm(3.2)),
        ("training_scores (훈련점수)",
         ["id INT PK", "user_id INT FK → users.id",
          "category VARCHAR(20)", "score REAL (0~10)",
          "created_at TIMESTAMP"],
         Cm(9.0), Cm(3.2)),
        ("daily_steps (일간 걸음)",
         ["user_id INT FK → users.id",
          "date DATE", "steps INT",
          "calories REAL", "distance REAL"],
         Cm(17.0), Cm(3.2)),
        ("checklist (일일 체크)",
         ["id INT PK", "user_id INT FK → users.id",
          "task_title VARCHAR(100)",
          "is_checked BOOLEAN", "date DATE"],
         Cm(24.5), Cm(3.2)),
    ]

    for (title, fields, tx, ty) in tables:
        tw = Cm(8.2)
        rect(sl, tx, ty, tw, Cm(0.7), DARK_BLUE)
        txb(sl, title, tx+Cm(0.1), ty+Cm(0.05), tw-Cm(0.2), Cm(0.6),
            size=8.5, bold=True, color=WHITE)
        rect(sl, tx, ty+Cm(0.7), tw, Cm(len(fields)*0.55+0.1), LIGHT_GRAY, DARK_BLUE)
        for fi, f in enumerate(fields):
            c = MID_BLUE if 'PK' in f else (RGBColor(0xC5,0x5A,0x11) if 'FK' in f else BLACK)
            txb(sl, f, tx+Cm(0.15), ty+Cm(0.8+fi*0.55), tw-Cm(0.3), Cm(0.52),
                size=7.5, color=c)

    # FK arrows (text)
    txb(sl, "1 ─── N", Cm(8.2), Cm(5.5), Cm(1.0), Cm(0.6), size=7, color=MID_BLUE)
    txb(sl, "1 ─── N", Cm(16.0), Cm(6.5), Cm(1.0), Cm(0.6), size=7, color=MID_BLUE)
    txb(sl, "1 ─── N", Cm(23.5), Cm(6.5), Cm(1.0), Cm(0.6), size=7, color=MID_BLUE)

    # Supabase section
    txb(sl, "○ Supabase 클라우드 데이터베이스 (PostgreSQL)",
        Cm(0.5), Cm(11.5), Cm(25), Cm(0.7), size=10, bold=True, color=TEAL)

    sup_tables = [
        ("training_difficulty",
         ["username VARCHAR PK","calculation_level INT","logic_level INT",
          "memory_level INT","perception_level INT","updated_at TIMESTAMP"],
         Cm(0.3)),
        ("notices",
         ["id UUID PK","title TEXT","content TEXT",
          "is_pinned BOOLEAN","created_at TIMESTAMP"],
         Cm(9.0)),
        ("inquiries",
         ["id UUID PK","user_id TEXT","title TEXT",
          "content TEXT","status VARCHAR","admin_response TEXT","created_at"],
         Cm(17.0)),
        ("faqs",
         ["id UUID PK","category VARCHAR",
          "question TEXT","answer TEXT","order_num INT"],
         Cm(25.2)),
    ]
    for (title, fields, tx) in sup_tables:
        ty = Cm(12.3)
        tw = Cm(8.3)
        rect(sl, tx, ty, tw, Cm(0.65), TEAL)
        txb(sl, title, tx+Cm(0.1), ty+Cm(0.05), tw-Cm(0.2), Cm(0.58),
            size=8, bold=True, color=WHITE)
        rect(sl, tx, ty+Cm(0.65), tw, Cm(len(fields)*0.52+0.1),
             RGBColor(0xE2,0xF0,0xF9), TEAL)
        for fi, f in enumerate(fields):
            txb(sl, f, tx+Cm(0.15), ty+Cm(0.75+fi*0.52), tw-Cm(0.3),
                Cm(0.5), size=7.5, color=BLACK)


# ─────────────────────────────────────────
# SLIDE 12 – 기능 처리도: 인지훈련 플로우
# ─────────────────────────────────────────
def slide12(prs):
    sl = blank_slide(prs)
    header_bar(sl, "기능 처리도(기능 흐름도) - 인지훈련 플로우")

    txb(sl, "프로그램 ID", Cm(0.3), Cm(2.3), Cm(2.5), Cm(0.55), size=8, bold=True, color=WHITE)
    rect(sl, Cm(0.3), Cm(2.3), Cm(2.5), Cm(0.55), DARK_BLUE)
    txb(sl, "GAME_DiffEngine_M", Cm(2.8), Cm(2.3), Cm(5), Cm(0.55), size=8, color=BLACK)
    txb(sl, "프로그램 명", Cm(7.8), Cm(2.3), Cm(2.5), Cm(0.55), size=8, bold=True, color=WHITE)
    rect(sl, Cm(7.8), Cm(2.3), Cm(2.5), Cm(0.55), DARK_BLUE)
    txb(sl, "인지훈련 적응형 난이도 엔진", Cm(10.3), Cm(2.3), Cm(7), Cm(0.55), size=8, color=BLACK)
    txb(sl, "작성일", Cm(17.3), Cm(2.3), Cm(1.5), Cm(0.55), size=8, bold=True, color=WHITE)
    rect(sl, Cm(17.3), Cm(2.3), Cm(1.5), Cm(0.55), DARK_BLUE)
    txb(sl, "2025.05", Cm(18.8), Cm(2.3), Cm(2.5), Cm(0.55), size=8, color=BLACK)

    txb(sl,
        "개요: 사용자의 응답 정확도와 반응 시간을 바탕으로 인지훈련 게임의 난이도(1~10)를 자동 조정하는 폐루프 엔진."
        " DifficultyProvider가 Provider 패턴으로 전역 관리하며, Supabase에 실시간 동기화한다.",
        Cm(0.3), Cm(3.0), Cm(32), Cm(0.8), size=8.5, color=BLACK)

    # Flow diagram boxes
    def fbox(x, y, w, h, label, bg=MID_BLUE, fg=WHITE, shape=1):
        r = rect(sl, x, y, w, h, bg)
        txb(sl, label, x+Cm(0.1), y+Cm(0.05), w-Cm(0.2), h-Cm(0.1),
            size=8, bold=True, color=fg, align=PP_ALIGN.CENTER)
    def diamond(x, y, w, h, label):
        r = rect(sl, x, y, w, h, RGBColor(0xFF,0xD9,0x66))
        txb(sl, label, x+Cm(0.1), y+Cm(0.1), w-Cm(0.2), h-Cm(0.1),
            size=7.5, color=BLACK, align=PP_ALIGN.CENTER)

    cx = Cm(6)
    fbox(cx, Cm(4.0), Cm(7), Cm(0.8), "앱 실행", DARK_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(4.8), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(5.3), Cm(7), Cm(0.8), "DifficultyProvider.loadLevels()", MID_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(6.1), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(6.6), Cm(7), Cm(0.8), "게임 선택 (7종)", MID_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(7.4), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(7.9), Cm(7), Cm(0.8), "레벨 기반 문제 생성", MID_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(8.7), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(9.2), Cm(7), Cm(0.8), "사용자 응답 수집", MID_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(10.0), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    diamond(cx, Cm(10.5), Cm(7), Cm(1.2), "updatePerformance\n(category, isCorrect, time)")
    # branches
    fbox(Cm(0.3), Cm(10.7), Cm(5.3), Cm(1.0),
         "3연속 정답 +\n목표시간 이하\n→ level UP (max 10)",
         RGBColor(0x37,0x86,0x3C))
    fbox(Cm(13.8), Cm(10.7), Cm(5.3), Cm(1.0),
         "2연속 오답\n→ level DOWN (min 1)",
         RED_TITLE)
    txb(sl, "↓", cx+Cm(3), Cm(11.7), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(12.2), Cm(7), Cm(0.8), "setCognitiveScore() → SQLite 저장", MID_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(13.0), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(13.5), Cm(7), Cm(0.8), "Supabase 동기화 (_syncToSupabase)", DARK_BLUE)
    txb(sl, "↓", cx+Cm(3), Cm(14.3), Cm(1), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    fbox(cx, Cm(14.8), Cm(7), Cm(0.8), "리포트 차트 반영", MID_BLUE)

    # Annotations
    txb(sl, "targetTime(level) = max(2.0, 5.0 − level × 0.3) 초",
        Cm(20.5), Cm(10.5), Cm(12), Cm(0.7), size=9, bold=True, color=RED_TITLE)
    txb(sl, "파일 위치: lib/features/training/difficulty_provider.dart",
        Cm(20.5), Cm(11.4), Cm(12), Cm(0.6), size=8.5, color=GRAY)
    txb(sl, "카테고리별 독립 관리:\ncalculation / logic / memory / perception",
        Cm(20.5), Cm(12.2), Cm(12), Cm(1.0), size=8.5, color=BLACK)


# ─────────────────────────────────────────
# SLIDE 13 – 기능 처리도: 보행 분석 플로우
# ─────────────────────────────────────────
def slide13(prs):
    sl = blank_slide(prs)
    header_bar(sl, "기능 처리도(기능 흐름도) - 보행 분석 플로우")

    txb(sl, "프로그램 ID", Cm(0.3), Cm(2.3), Cm(2.5), Cm(0.55), size=8, bold=True, color=WHITE)
    rect(sl, Cm(0.3), Cm(2.3), Cm(2.5), Cm(0.55), DARK_BLUE)
    txb(sl, "GAIT_Analyzer_M", Cm(2.8), Cm(2.3), Cm(5), Cm(0.55), size=8, color=BLACK)
    txb(sl, "개요: 가속도 센서 3축 데이터에서 걸음을 감지하고 보행 변동성(CV%)을 계산하여 인지 위험도 지표로 활용한다.",
        Cm(0.3), Cm(3.0), Cm(32), Cm(0.7), size=8.5, color=BLACK)

    def fbox(x, y, w, h, label, bg=MID_BLUE, fg=WHITE):
        rect(sl, x, y, w, h, bg)
        txb(sl, label, x+Cm(0.1), y+Cm(0.08), w-Cm(0.2), h-Cm(0.1),
            size=8, bold=True, color=fg, align=PP_ALIGN.CENTER)

    def diamond(x, y, w, h, label):
        rect(sl, x, y, w, h, RGBColor(0xFF,0xD9,0x66))
        txb(sl, label, x+Cm(0.1), y+Cm(0.1), w-Cm(0.2), h-Cm(0.1),
            size=7.5, color=BLACK, align=PP_ALIGN.CENTER)

    cx = Cm(6.5)
    steps_flow = [
        ("GaitProvider.startMeasurement()", MID_BLUE),
        ("sensors_plus: 가속도 3축 (x,y,z) 스트리밍", MID_BLUE),
        ("magnitude = √(x²+y²+z²)", MID_BLUE),
    ]
    y = Cm(4.0)
    for (label, bg) in steps_flow:
        fbox(cx, y, Cm(8), Cm(0.8), label, bg)
        txb(sl, "↓", cx+Cm(3.8), y+Cm(0.8), Cm(0.5), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
        y += Cm(1.3)

    diamond(cx, y, Cm(8), Cm(1.1), "magnitude > 1.0\nAND 시간간격 300~2000ms?")
    txb(sl, "YES↓", cx+Cm(3.5), y+Cm(1.1), Cm(1.5), Cm(0.5), size=9, color=MID_BLUE, align=PP_ALIGN.CENTER)
    txb(sl, "NO →", cx+Cm(8.2), y+Cm(0.3), Cm(1.5), Cm(0.5), size=9, color=RED_TITLE)
    fbox(Cm(16), y, Cm(5), Cm(0.8), "무시 (다음 샘플 대기)", RED_TITLE)

    y += Cm(1.6)
    more = [
        ("stride_time 기록 (걸음 간격 ms)", MID_BLUE),
        ("stride_time 목록 누적 (최근 30개)", MID_BLUE),
        ("CV% = (σ / μ) × 100 계산", RGBColor(0x37,0x86,0x3C)),
        ("실시간 파형 시각화 (최근 50샘플)", MID_BLUE),
    ]
    for (label, bg) in more:
        fbox(cx, y, Cm(8), Cm(0.8), label, bg)
        txb(sl, "↓", cx+Cm(3.8), y+Cm(0.8), Cm(0.5), Cm(0.5), size=14, color=DARK_BLUE, align=PP_ALIGN.CENTER)
        y += Cm(1.3)

    diamond(cx, y, Cm(8), Cm(1.0), "세션 종료?")
    txb(sl, "YES↓", cx+Cm(3.5), y+Cm(1.0), Cm(1.5), Cm(0.5), size=9, color=MID_BLUE, align=PP_ALIGN.CENTER)
    txb(sl, "NO → 계속 스트리밍", cx+Cm(8.2), y+Cm(0.2), Cm(5), Cm(0.5), size=9, color=GRAY)
    y += Cm(1.5)
    fbox(cx, y, Cm(8), Cm(0.8), "Supabase cognitive_scores 저장", DARK_BLUE)

    # right annotation
    txb(sl, "정상 보행 기준\n\nCV < 3%: 정상\n3~5%: 경계\nCV ≥ 5%: 불규칙 (위험)",
        Cm(22), Cm(4.0), Cm(10.5), Cm(3.5), size=9.5, color=BLACK)
    rect(sl, Cm(22), Cm(4.0), Cm(10.5), Cm(3.5), LIGHT_BLUE, DARK_BLUE)
    txb(sl, "정상 보행 기준\n\nCV < 3%:  정상\n3 ~ 5%:  경계\nCV ≥ 5%:  불규칙 (위험)",
        Cm(22.2), Cm(4.1), Cm(10), Cm(3.3), size=9.5, color=BLACK)

    txb(sl, "파일: lib/features/gait_analysis/gait_analyzer.dart\n"
            "     lib/features/gait_analysis/gait_provider.dart",
        Cm(22), Cm(8.0), Cm(11), Cm(1.0), size=8.5, color=GRAY)


# ─────────────────────────────────────────
# SLIDE 14 – 프로그램 목록
# ─────────────────────────────────────────
def slide14(prs):
    sl = blank_slide(prs)
    header_bar(sl, "프로그램 목록")

    rows = [
        ["AUTH","AUTH-001","회원가입 및 로그인"],
        ["AUTH","AUTH-002","자동 로그인 (SharedPreferences)"],
        ["AUTH","AUTH-003","로그아웃 및 세션 초기화"],
        ["ONBD","ONBD-001","온보딩 플로우 (목표 선택·동의)"],
        ["ASMT","ASMT-001","기저값 인지 평가 (10문항 설문)"],
        ["ASMT","ASMT-002","인지 과제 평가 (시각·언어)"],
        ["GAME","GAME-001","비교 게임 (누가 큰가요?)"],
        ["GAME","GAME-002","구구단 맞추기"],
        ["GAME","GAME-003","순서 기억"],
        ["GAME","GAME-004","도형 스도쿠"],
        ["GAME","GAME-005","도형 짝 맞추기"],
        ["GAME","GAME-006","단어 분류"],
        ["GAME","GAME-007","문장 읽기"],
        ["GAIT","GAIT-001","실시간 보행 측정"],
        ["GAIT","GAIT-002","걸음 감지 알고리즘 (magnitude 임계값)"],
        ["GAIT","GAIT-003","보행 변동성 (CV%) 계산"],
        ["GAIT","GAIT-004","실시간 파형 시각화"],
        ["GAIT","GAIT-005","백그라운드 만보기 서비스"],
        ["GAIT","GAIT-006","일간 보행 데이터 저장"],
        ["VOICE","VOICE-001","음성 녹음 (STT)"],
        ["VOICE","VOICE-002","어휘 다양도 (TTR) 계산"],
        ["VOICE","VOICE-003","발화 속도 분석"],
        ["VOICE","VOICE-004","음성 위험도 점수 (0~100) 출력"],
        ["HOME","HOME-001","실시간 걸음수 표시"],
        ["HOME","HOME-002","기억 정원 (Lottie 애니메이션)"],
        ["HOME","HOME-003","MIND 식단 추천 카드"],
        ["HOME","HOME-004","일일 체크리스트"],
        ["REPORT","REPORT-001","주간 인지 점수 시계열 차트"],
        ["REPORT","REPORT-002","뇌 나이 추정"],
        ["REPORT","REPORT-003","임상 리포트 생성"],
        ["REPORT","REPORT-005","PDF 내보내기·공유"],
        ["GUARD","GUARD-001","보호자 QR 코드 생성·공유"],
        ["GUARD","GUARD-002","이상 감지 알림 (걸음수 급감)"],
        ["CS","CS-001","공지사항 목록·상세"],
        ["CS","CS-002","FAQ 목록"],
        ["CS","CS-003","1:1 문의 제출"],
        ["CS","CS-004","내 문의 이력 조회"],
        ["INST","INST-001","치매안심센터 전화·지도 연결"],
        ["ADMIN","ADMIN-001","관리자 로그인"],
        ["ADMIN","ADMIN-002","어드민 대시보드 통계"],
        ["ADMIN","ADMIN-003","위험 사용자 감지·조회"],
        ["ADMIN","ADMIN-004","CS 문의 관리 및 답변"],
        ["ACC","ACC-001","텍스트 크기 조절 (3단계)"],
        ["ACC","ACC-002","음성 안내 (TTS, 한국어)"],
        ["ACC","ACC-003","진동(햅틱) 피드백"],
    ]
    # split into 2 columns
    mid = len(rows) // 2 + 1
    headers = ["분류", "기능번호", "기능명"]
    cw1 = [Cm(2.0), Cm(3.5), Cm(10.0)]
    add_table(sl, headers, rows[:mid], Cm(0.3), Cm(2.4), Cm(15.5),
              col_widths=cw1, row_height=Cm(0.53), font_size=7.5)
    add_table(sl, headers, rows[mid:], Cm(17.0), Cm(2.4), Cm(15.5),
              col_widths=cw1, row_height=Cm(0.53), font_size=7.5)


# ─────────────────────────────────────────
# SLIDE 15 – 테이블 정의서 (users & training_scores)
# ─────────────────────────────────────────
def slide15(prs):
    sl = blank_slide(prs)
    header_bar(sl, "테이블 정의서")

    txb(sl, "< users 테이블 >",
        Cm(0.3), Cm(2.4), Cm(16), Cm(0.6), size=10, bold=True, color=DARK_BLUE)
    headers = ["항목명", "타입", "필수/선택", "발생여부", "설명"]
    users_rows = [
        ["id",                      "INTEGER PK",    "필수", "발생", "기본키 (자동증가)"],
        ["username",                "VARCHAR(50)",   "필수", "발생", "로그인 ID (unique)"],
        ["password",                "VARCHAR(100)",  "필수", "발생", "해시 비밀번호"],
        ["goal",                    "VARCHAR(20)",   "필수", "발생", "prevention / concern / family"],
        ["age",                     "INTEGER",       "선택", "발생", "나이"],
        ["weight",                  "REAL",          "선택", "발생", "체중 (kg)"],
        ["blood_type",              "VARCHAR(5)",    "선택", "발생", "혈액형"],
        ["medications",             "TEXT",          "선택", "발생", "복용약 목록 (쉼표 구분)"],
        ["emergency_contact",       "VARCHAR(20)",   "선택", "발생", "비상 연락처"],
        ["pedometer_enabled",       "BOOLEAN",       "필수", "발생", "만보기 활성 여부 (기본값: false)"],
        ["has_completed_onboarding","BOOLEAN",       "필수", "발생", "온보딩 완료 여부 (기본값: false)"],
    ]
    cw = [Cm(5.5), Cm(3.5), Cm(2.5), Cm(2.5), Cm(9.0)]
    add_table(sl, headers, users_rows, Cm(0.3), Cm(3.1), Cm(23.0),
              col_widths=cw, row_height=Cm(0.6), font_size=8)

    txb(sl, "< training_scores 테이블 >",
        Cm(0.3), Cm(11.2), Cm(16), Cm(0.6), size=10, bold=True, color=DARK_BLUE)
    ts_rows = [
        ["id",         "INTEGER PK",  "필수","발생","기본키"],
        ["user_id",    "INTEGER FK",  "필수","발생","users.id 참조"],
        ["category",   "VARCHAR(20)", "필수","발생","calculation / logic / memory / perception"],
        ["score",      "REAL",        "필수","발생","0.0 ~ 10.0 점수"],
        ["created_at", "TIMESTAMP",   "필수","발생","기록 일시"],
    ]
    add_table(sl, headers, ts_rows, Cm(0.3), Cm(11.9), Cm(23.0),
              col_widths=cw, row_height=Cm(0.6), font_size=8)

    # right column: daily_steps + checklist
    txb(sl, "< daily_steps 테이블 >",
        Cm(24.0), Cm(2.4), Cm(9), Cm(0.6), size=10, bold=True, color=DARK_BLUE)
    ds_rows = [
        ["user_id","INTEGER FK","필수","발생","users.id 참조"],
        ["date",   "DATE",      "필수","발생","기록 날짜 (YYYY-MM-DD)"],
        ["steps",  "INTEGER",   "필수","발생","당일 걸음수"],
        ["calories","REAL",     "필수","발생","소모 칼로리 (kcal)"],
        ["distance","REAL",     "필수","발생","이동 거리 (km)"],
    ]
    cw2 = [Cm(2.5), Cm(2.5), Cm(1.5), Cm(1.5), Cm(5.0)]
    add_table(sl, headers, ds_rows, Cm(24.0), Cm(3.1), Cm(9.3),
              col_widths=cw2, row_height=Cm(0.6), font_size=7.5)

    txb(sl, "< checklist 테이블 >",
        Cm(24.0), Cm(7.5), Cm(9), Cm(0.6), size=10, bold=True, color=DARK_BLUE)
    cl_rows = [
        ["id",         "INTEGER PK", "필수","발생","기본키"],
        ["user_id",    "INTEGER FK", "필수","발생","users.id 참조"],
        ["task_title", "VARCHAR(100)","필수","발생","체크리스트 항목명"],
        ["is_checked", "BOOLEAN",    "필수","발생","완료 여부"],
        ["date",       "DATE",       "필수","발생","해당 날짜"],
    ]
    add_table(sl, headers, cl_rows, Cm(24.0), Cm(8.2), Cm(9.3),
              col_widths=cw2, row_height=Cm(0.6), font_size=7.5)

    txb(sl, "< daily_active_users 테이블 >",
        Cm(24.0), Cm(12.0), Cm(9), Cm(0.6), size=10, bold=True, color=DARK_BLUE)
    dau_rows = [
        ["date",    "DATE",    "필수","발생","기록 날짜"],
        ["user_id", "INT FK",  "필수","발생","users.id 참조"],
    ]
    add_table(sl, headers, dau_rows, Cm(24.0), Cm(12.7), Cm(9.3),
              col_widths=cw2, row_height=Cm(0.6), font_size=7.5)


# ─────────────────────────────────────────
# SLIDE 16 – 테이블 정의서 (Supabase)
# ─────────────────────────────────────────
def slide16(prs):
    sl = blank_slide(prs)
    header_bar(sl, "테이블 정의서 - Supabase 클라우드 DB")

    headers = ["항목명", "타입", "필수/선택", "설명"]

    tables_def = [
        ("training_difficulty", [
            ["username",          "VARCHAR PK",  "필수","사용자 ID (users.username 참조)"],
            ["calculation_level", "INTEGER",     "필수","계산 영역 난이도 (1~10)"],
            ["logic_level",       "INTEGER",     "필수","논리 영역 난이도 (1~10)"],
            ["memory_level",      "INTEGER",     "필수","기억 영역 난이도 (1~10)"],
            ["perception_level",  "INTEGER",     "필수","지각 영역 난이도 (1~10)"],
            ["updated_at",        "TIMESTAMP",   "필수","마지막 업데이트 일시"],
        ], Cm(0.3), Cm(2.4)),
        ("notices (공지사항)", [
            ["id",         "UUID PK",   "필수","공지사항 ID (자동생성)"],
            ["title",      "TEXT",      "필수","공지 제목"],
            ["content",    "TEXT",      "필수","공지 내용"],
            ["is_pinned",  "BOOLEAN",   "필수","상단 고정 여부"],
            ["created_at", "TIMESTAMP", "필수","작성 일시"],
        ], Cm(0.3), Cm(7.5)),
        ("faqs", [
            ["id",        "UUID PK",  "필수","FAQ ID"],
            ["category",  "VARCHAR",  "필수","카테고리 (사용방법/계정/기능/기타)"],
            ["question",  "TEXT",     "필수","질문 내용"],
            ["answer",    "TEXT",     "필수","답변 내용"],
            ["order_num", "INTEGER",  "선택","표시 순서"],
        ], Cm(0.3), Cm(12.5)),
        ("inquiries (1:1문의)", [
            ["id",             "UUID PK",  "필수","문의 ID"],
            ["user_id",        "TEXT",     "필수","사용자 ID"],
            ["title",          "TEXT",     "필수","문의 제목"],
            ["content",        "TEXT",     "필수","문의 내용"],
            ["status",         "VARCHAR",  "필수","pending / resolved"],
            ["admin_response", "TEXT",     "선택","관리자 답변"],
            ["created_at",     "TIMESTAMP","필수","제출 일시"],
        ], Cm(17.0), Cm(2.4)),
        ("inquiry_replies (답변)", [
            ["id",          "UUID PK",   "필수","답변 ID"],
            ["inquiry_id",  "UUID FK",   "필수","inquiries.id 참조"],
            ["content",     "TEXT",      "필수","답변 내용"],
            ["is_admin",    "BOOLEAN",   "필수","관리자 답변 여부"],
            ["created_at",  "TIMESTAMP", "필수","작성 일시"],
        ], Cm(17.0), Cm(8.5)),
        ("cognitive_scores (인지/보행 점수)", [
            ["id",         "UUID PK",  "필수","점수 ID"],
            ["user_id",    "TEXT",     "필수","사용자 ID"],
            ["type",       "VARCHAR",  "필수","gait / voice / training"],
            ["score",      "REAL",     "필수","점수 값"],
            ["metadata",   "JSONB",    "선택","추가 데이터 (CV%, TTR 등)"],
            ["created_at", "TIMESTAMP","필수","기록 일시"],
        ], Cm(17.0), Cm(13.5)),
    ]

    cw = [Cm(5.0), Cm(3.0), Cm(2.5), Cm(5.5)]
    for (tname, trows, tx, ty) in tables_def:
        txb(sl, f"< {tname} >", tx, ty, Cm(16), Cm(0.55),
            size=9.5, bold=True, color=TEAL)
        add_table(sl, headers, trows, tx, ty+Cm(0.6), Cm(16.0),
                  col_widths=cw, row_height=Cm(0.55), font_size=7.5,
                  header_bg=TEAL)


# ─────────────────────────────────────────
# SLIDE 17 – 핵심 소스코드 (1): 보행 변동성
# ─────────────────────────────────────────
def slide17(prs):
    sl = blank_slide(prs)
    header_bar(sl, "핵심 소스코드 (1) - 보행 변동성 알고리즘")

    rect(sl, Cm(0.3), Cm(2.4), Cm(32.8), Cm(0.65), DARK_BLUE)
    txb(sl, "• GaitAnalyzer  |  파일: lib/features/gait_analysis/gait_analyzer.dart",
        Cm(0.5), Cm(2.45), Cm(32), Cm(0.58), size=9, bold=True, color=WHITE)

    code1 = """\
import 'dart:math';

class GaitAnalyzer {
  final List<int> _strideTimes = [];
  int? _lastStepTime;

  // 걸음 감지: 가속도 크기 임계값 기반
  bool detectStep(double x, double y, double z) {
    double magnitude = sqrt(x * x + y * y + z * z);
    int now = DateTime.now().millisecondsSinceEpoch;

    if (magnitude > 1.0 && _lastStepTime != null) {
      int interval = now - _lastStepTime!;
      if (interval >= 300 && interval <= 2000) {   // 생물학적 보행 범위
        _strideTimes.add(interval);
        if (_strideTimes.length > 30) _strideTimes.removeAt(0);
        _lastStepTime = now;
        return true;
      }
    }
    if (magnitude > 1.0) _lastStepTime = now;
    return false;
  }

  // 보행 변동성 CV% = (표준편차 / 평균) × 100
  double calculateCV() {
    if (_strideTimes.length < 2) return 0.0;
    double mean = _strideTimes.reduce((a, b) => a + b) / _strideTimes.length;
    double variance = _strideTimes
        .map((t) => pow(t - mean, 2).toDouble())
        .reduce((a, b) => a + b) / _strideTimes.length;
    return (sqrt(variance) / mean) * 100;   // CV%
  }

  // 위험도 판정
  String getRiskLevel() {
    double cv = calculateCV();
    if (cv < 3.0) return '정상';
    if (cv < 5.0) return '경계';
    return '위험';
  }
}"""
    code_box(sl, code1, Cm(0.3), Cm(3.15), Cm(20.5), Cm(15.2), size=8)

    # annotation
    txb(sl, "알고리즘 설명", Cm(21.3), Cm(3.2), Cm(11.5), Cm(0.65),
        size=10, bold=True, color=DARK_BLUE)
    rect(sl, Cm(21.3), Cm(3.2), Cm(11.5), Cm(0.65), LIGHT_BLUE)
    txb(sl, "알고리즘 설명", Cm(21.5), Cm(3.3), Cm(11), Cm(0.55),
        size=10, bold=True, color=DARK_BLUE)

    annots = [
        ("① 걸음 감지", "가속도 크기(magnitude)가 임계값(1.0 m/s²)을 초과하고,\n직전 걸음과의 시간 간격이 300~2,000 ms 범위인 경우에만\n걸음으로 인정 (생물학적 보행 주기 기반 필터링)"),
        ("② 변동성 계산", "최근 30개 stride_time의 표준편차를 평균으로 나눈\n값에 100을 곱해 CV%를 구함.\nCV%가 높을수록 보행이 불규칙 → 치매 조기 지표"),
        ("③ 위험도 판정", "CV < 3%: 정상\n3% ≤ CV < 5%: 경계\nCV ≥ 5%: 불규칙 (위험, 가이드라인 기준)"),
        ("④ 데이터 활용", "GaitProvider → GaitScreen\n→ Supabase cognitive_scores 저장\n→ ReportsScreen 주간 차트에 반영"),
    ]
    ay = Cm(4.0)
    for (title, body) in annots:
        rect(sl, Cm(21.3), ay, Cm(11.5), Cm(0.55), MID_BLUE)
        txb(sl, title, Cm(21.5), ay+Cm(0.08), Cm(11), Cm(0.45),
            size=9, bold=True, color=WHITE)
        rect(sl, Cm(21.3), ay+Cm(0.55), Cm(11.5), Cm(2.0), LIGHT_GRAY)
        txb(sl, body, Cm(21.5), ay+Cm(0.65), Cm(11.0), Cm(1.8),
            size=8.5, color=BLACK)
        ay += Cm(2.65)


# ─────────────────────────────────────────
# SLIDE 18 – 핵심 소스코드 (2): 적응형 난이도
# ─────────────────────────────────────────
def slide18(prs):
    sl = blank_slide(prs)
    header_bar(sl, "핵심 소스코드 (2) - 적응형 난이도 엔진")

    rect(sl, Cm(0.3), Cm(2.4), Cm(32.8), Cm(0.65), DARK_BLUE)
    txb(sl, "• DifficultyProvider  |  파일: lib/features/training/difficulty_provider.dart",
        Cm(0.5), Cm(2.45), Cm(32), Cm(0.58), size=9, bold=True, color=WHITE)

    code2 = """\
class DifficultyProvider extends ChangeNotifier {
  Map<String, int> _levels = {
    'calculation': 1, 'logic': 1, 'memory': 1, 'perception': 1
  };
  // 카테고리별 최근 결과 기록 (최대 5개)
  final Map<String, List<Map<String, dynamic>>> _history = {};

  // 게임 결과 반영 → 난이도 자동 조정
  void updatePerformance(String category, bool isCorrect,
                          double responseTime) {
    _addResult(category, isCorrect, responseTime);
    int level = _levels[category] ?? 1;

    // 목표 반응시간: 레벨이 높을수록 짧아짐
    double targetTime = max(2.0, 5.0 - (level * 0.3));

    if (_lastThreeCorrect(category) &&
        _avgTime(category) <= targetTime) {
      _levels[category] = min(10, level + 1);  // 레벨 UP
    } else if (_lastTwoWrong(category)) {
      _levels[category] = max(1, level - 1);   // 레벨 DOWN
    }
    _syncToSupabase(category);
    notifyListeners();
  }

  bool _lastThreeCorrect(String cat) {
    var h = _history[cat] ?? [];
    if (h.length < 3) return false;
    return h.reversed.take(3).every((r) => r['correct'] == true);
  }

  bool _lastTwoWrong(String cat) {
    var h = _history[cat] ?? [];
    if (h.length < 2) return false;
    return h.reversed.take(2).every((r) => r['correct'] == false);
  }

  double _avgTime(String cat) {
    var h = _history[cat] ?? [];
    if (h.isEmpty) return 999.0;
    return h.map((r) => r['time'] as double).reduce((a,b)=>a+b) / h.length;
  }
}"""
    code_box(sl, code2, Cm(0.3), Cm(3.15), Cm(20.5), Cm(15.2), size=7.8)

    # Annotations
    annots = [
        ("레벨 범위", "1 (최저) ~ 10 (최고)\n4개 영역 독립 관리\n(계산/논리/기억/지각)"),
        ("목표 시간 공식", "targetTime = max(2.0, 5.0 − level × 0.3)\n\nLv.1: 4.7초 / Lv.5: 3.5초\nLv.10: 2.0초 (최소값)"),
        ("UP 조건", "최근 3회 연속 정답\nAND 평균 응답시간 ≤ targetTime"),
        ("DOWN 조건", "최근 2회 연속 오답"),
        ("동기화", "변경 시 Supabase\ntraining_difficulty 테이블\n실시간 업데이트"),
    ]
    ay = Cm(3.2)
    for (title, body) in annots:
        rect(sl, Cm(21.3), ay, Cm(11.5), Cm(0.55), MID_BLUE)
        txb(sl, title, Cm(21.5), ay+Cm(0.08), Cm(11), Cm(0.45),
            size=9, bold=True, color=WHITE)
        rect(sl, Cm(21.3), ay+Cm(0.55), Cm(11.5), Cm(1.8), LIGHT_GRAY)
        txb(sl, body, Cm(21.5), ay+Cm(0.65), Cm(11.0), Cm(1.6),
            size=8.5, color=BLACK)
        ay += Cm(2.45)


# ─────────────────────────────────────────
# SLIDE 19 – 핵심 소스코드 (3): 음성 평가
# ─────────────────────────────────────────
def slide19(prs):
    sl = blank_slide(prs)
    header_bar(sl, "핵심 소스코드 (3) - 음성 평가 (TTR 분석)")

    rect(sl, Cm(0.3), Cm(2.4), Cm(32.8), Cm(0.65), DARK_BLUE)
    txb(sl, "• VoiceAssessmentScreen._analyzeText()  |  파일: lib/features/voice_assessment/voice_assessment_screen.dart",
        Cm(0.5), Cm(2.45), Cm(32), Cm(0.58), size=8.5, bold=True, color=WHITE)

    code3 = """\
// 음성 텍스트 분석: TTR + 발화속도 + 발화량 → 위험도 점수
Map<String, dynamic> _analyzeText(String text) {
  // 1. TTR (Type-Token Ratio): 어휘 다양도
  List<String> words = text
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  int uniqueWords = words.toSet().length;
  double ttr = words.isEmpty ? 0.0 : uniqueWords / words.length;
  double ttrScore = (ttr * 40).clamp(0, 40);      // max 40점

  // 2. 발화 속도 (WPM: Words Per Minute)
  double minutes = _recordingSeconds / 60.0;
  double wpm = minutes > 0 ? words.length / minutes : 0;
  // 정상 발화속도: 60~180 WPM
  double speedScore = (wpm >= 60 && wpm <= 180) ? 30.0 : 0.0;  // max 30점

  // 3. 발화량 (총 단어 수)
  double volumeScore = words.length.clamp(0, 30).toDouble();    // max 30점

  // 4. 종합 위험도 점수 (0~100)
  double total = (ttrScore + speedScore + volumeScore).clamp(0, 100);

  // 5. 위험 등급 판정
  String level;
  if (total >= 75)      level = '양호';   // 정상 범위
  else if (total >= 50) level = '보통';   // 주의 관찰
  else                  level = '주의';   // 전문가 상담 권고

  return {
    'score': total,
    'level': level,
    'ttr': ttr,
    'wpm': wpm,
    'wordCount': words.length,
    'uniqueWords': uniqueWords,
  };
}"""
    code_box(sl, code3, Cm(0.3), Cm(3.15), Cm(20.5), Cm(14.5), size=8)

    annots = [
        ("TTR (어휘 다양도)", "TTR = 고유 단어 수 / 전체 단어 수\n\n• TTR ≈ 1.0: 매우 다양한 어휘 사용\n• TTR 저하: 어휘 반복 증가 → 인지 기능 저하 징후\n• 배점: TTR × 40 (최대 40점)"),
        ("발화 속도 (WPM)", "정상 발화속도: 60 ~ 180 WPM\n범위 내 → 30점\n범위 외 → 0점\n\n너무 느리거나 빠른 경우 모두 비정상 처리"),
        ("발화량", "30단어 이상 발화 시 만점 (30점)\n단어 수가 적을수록 발화 억제 경향"),
        ("위험 등급", "≥ 75점: 양호\n50 ~ 74점: 보통 (관찰 권고)\n< 50점: 주의 (전문가 상담 권고)"),
    ]
    ay = Cm(3.2)
    for (title, body) in annots:
        rect(sl, Cm(21.3), ay, Cm(11.5), Cm(0.55), MID_BLUE)
        txb(sl, title, Cm(21.5), ay+Cm(0.08), Cm(11), Cm(0.45),
            size=9, bold=True, color=WHITE)
        rect(sl, Cm(21.3), ay+Cm(0.55), Cm(11.5), Cm(2.7), LIGHT_GRAY)
        txb(sl, body, Cm(21.5), ay+Cm(0.65), Cm(11.0), Cm(2.5),
            size=8.5, color=BLACK)
        ay += Cm(3.35)


# ─────────────────────────────────────────
# SLIDE 20 – 참조: 개발 환경
# ─────────────────────────────────────────
def slide20(prs):
    sl = blank_slide(prs)
    header_bar(sl, "참조 - 개발 환경 및 기술 스택")

    headers = ["구분", "항목", "적용내역"]
    rows = [
        ["S/W\n개발환경", "Flutter 3.11.3+ / Dart 3.x", "크로스플랫폼 모바일 앱 개발 (Android/iOS/Web)"],
        ["",            "Provider 6.x",               "상태관리 패턴 (ChangeNotifier, ProxyProvider)"],
        ["",            "GoRouter 17.1.0",             "선언형 라우팅 및 인증 가드"],
        ["",            "sqflite 2.4.2",               "로컬 SQLite 데이터베이스"],
        ["",            "supabase_flutter 2.8.1",      "클라우드 DB 동기화 (PostgreSQL)"],
        ["",            "sensors_plus",                "가속도계·자이로스코프 스트리밍"],
        ["",            "pedometer 4.0.1",             "시스템 만보기 걸음수 측정"],
        ["",            "speech_to_text 7.3.0",        "온디바이스 STT (Google Speech Recognition)"],
        ["",            "flutter_tts 4.2.5",           "TTS 음성 안내 (한국어, 노인 접근성)"],
        ["",            "fl_chart 1.2.0",              "인지 점수 시계열·막대 차트"],
        ["",            "flutter_background_service",  "Android 포그라운드 서비스 (백그라운드 만보기)"],
        ["",            "flutter_local_notifications", "이상 감지 로컬 푸시 알림"],
        ["",            "pdf 3.11.1 + printing 5.13.2","임상 리포트 PDF 생성·인쇄·공유"],
        ["",            "qr_flutter 4.1.0",            "보호자 연결 QR 코드 생성"],
        ["",            "Lottie 3.1.2",                "기억 정원 인터랙티브 애니메이션"],
        ["",            "NanumGothic / 맑은 고딕",     "한국어 노인 가독성 폰트"],
        ["H/W\n구성장비","Android 스마트폰",           "주 타겟 디바이스 (Android 6.0+)"],
        ["",            "iOS 아이폰",                  "보조 타겟 (iOS 12+)"],
        ["",            "내장 가속도/자이로 센서",     "보행 변동성 분석용"],
        ["",            "마이크",                      "음성 평가 STT 입력"],
        ["서버",        "Supabase (PostgreSQL)",        "클라우드 DB 및 REST API (무료 플랜)"],
        ["테스트",      "flutter_test",                "단위·위젯 테스트 (7 unit + 3 widget)"],
        ["",            "mocktail 1.0.4",              "Mock 기반 단위 테스트"],
        ["",            "integration_test",            "엔드투엔드 통합 테스트 (2개)"],
        ["CI/CD",       "GitHub Actions",              ".github/ 워크플로우 구성"],
    ]
    cw = [Cm(2.8), Cm(7.5), Cm(22.5)]
    add_table(sl, headers, rows, Cm(0.3), Cm(2.4), Cm(32.8),
              col_widths=cw, row_height=Cm(0.57), font_size=8)


# ─────────────────────────────────────────
# SLIDE 21 – S/W 기능 실사 화면 설명
# ─────────────────────────────────────────
def slide21(prs):
    sl = blank_slide(prs)
    header_bar(sl, "참조 - S/W 기능 실사 화면")

    screens = [
        ("홈 화면",
         "• 오늘의 걸음수 / 목표 달성률 표시\n"
         "• 기억 정원 (Lottie 꽃 성장 애니메이션)\n"
         "• MIND 식단 카드 슬라이드\n"
         "• 일일 체크리스트\n"
         "• 하단 탭 내비게이션 (5개 메뉴)",
         MID_BLUE),
        ("인지훈련 허브",
         "• 7종 게임 카드 그리드 레이아웃\n"
         "• 현재 난이도 레벨 배지 표시\n"
         "• 주간 훈련 완료율 프로그레스 바\n"
         "• 게임 시작 시 음성 안내(TTS)\n"
         "• 정답/오답 시 햅틱 피드백",
         RGBColor(0x37,0x86,0x3C)),
        ("보행 분석 화면",
         "• 실시간 가속도 파형 그래프\n"
         "• CV% 수치 및 위험도 색상 표시\n"
         "  (녹색: 정상 / 노랑: 경계 / 빨강: 위험)\n"
         "• 오늘 걸음수 / 칼로리 / 거리\n"
         "• 주간 막대 그래프\n"
         "• '정밀 분석' 상세 보기 탭",
         RGBColor(0xC5,0x5A,0x11)),
        ("리포트 화면",
         "• 4개 영역 인지 점수 시계열 차트\n"
         "• 추정 뇌 나이 카드\n"
         "• 영역별 강점/약점 텍스트 요약\n"
         "• 개인화 권장 활동 카드\n"
         "• PDF 내보내기 버튼",
         DARK_BLUE),
        ("프로필 & 어드민",
         "• 사용자 의료 정보 (혈액형/복용약)\n"
         "• 보호자 QR 코드 생성\n"
         "• 접근성: 글자 크기 3단계 조절\n"
         "• 관리자 대시보드: DAU/위험사용자\n"
         "• CS 문의 관리 및 답변 시스템",
         RGBColor(0x75,0x30,0x0D)),
    ]

    for i, (title, desc, color) in enumerate(screens):
        x = Cm(0.5 + i * 6.6)
        rect(sl, x, Cm(2.4), Cm(6.3), Cm(1.0), color)
        txb(sl, title, x+Cm(0.1), Cm(2.5), Cm(6.1), Cm(0.85),
            size=10, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
        # phone frame
        rect(sl, x+Cm(1.5), Cm(3.5), Cm(3.2), Cm(5.5), WHITE, DARK_BLUE)
        txb(sl, "[화면\n이미지]", x+Cm(2.1), Cm(4.5), Cm(2.0), Cm(3.0),
            size=9, color=GRAY, align=PP_ALIGN.CENTER)
        rect(sl, x, Cm(9.2), Cm(6.3), Cm(8.5), LIGHT_GRAY, color)
        txb(sl, desc, x+Cm(0.15), Cm(9.4), Cm(6.0), Cm(8.0),
            size=8.5, color=BLACK)

    txb(sl, "※ 실제 앱 스크린샷을 각 화면 이미지 영역에 삽입하여 제출하십시오.",
        Cm(0.5), Cm(18.0), Cm(32), Cm(0.7), size=9, color=RED_TITLE)


# ─────────────────────────────────────────
# SLIDE 22 – Thank You
# ─────────────────────────────────────────
def slide22(prs):
    sl = blank_slide(prs)
    rect(sl, Cm(0), Cm(0), W, H, WHITE)
    # decorative dots bottom-right
    positions = [(25,14),(26,15),(27,14),(28,15),(29,14),(30,15),
                 (27,16),(28,17),(29,16),(30,17),(31,16),
                 (25,16),(24,15),(24,17)]
    colors = [MID_BLUE, LIGHT_BLUE, RGBColor(0x9D,0xC3,0xE6)]
    for ii, (dx, dy) in enumerate(positions):
        s = sl.shapes.add_shape(9, Cm(dx), Cm(dy), Cm(0.4), Cm(0.4))
        fill_shape(s, colors[ii % 3])
        s.line.fill.background()
    # logo
    txb(sl, "한이음드림업", Cm(28), Cm(0.3), Cm(5.5), Cm(0.9),
        size=13, bold=True, color=DARK_BLUE)
    # Thank you
    txb(sl, "Thank you", Cm(8), Cm(7), Cm(18), Cm(3.5),
        size=54, bold=True, color=DARK_BLUE, align=PP_ALIGN.CENTER)
    txb(sl, "MemoryLink - AI 기반 치매 예방 멀티 인터벤션 모바일 플랫폼",
        Cm(5), Cm(11.5), Cm(24), Cm(1),
        size=13, color=GRAY, align=PP_ALIGN.CENTER)


# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────
def main():
    prs = new_prs()
    print("슬라이드 생성 중...")
    slide01(prs); print("  1/22 표지")
    slide02(prs); print("  2/22 수행 단계별 주요 산출물")
    slide03(prs); print("  3/22 요구사항 정의서")
    slide04(prs); print("  4/22 서비스 구성도 - 시스템 아키텍처")
    slide05(prs); print("  5/22 서비스 구성도 - 서비스 시나리오")
    slide06(prs); print("  6/22 메뉴 구성도")
    slide07(prs); print("  7/22 화면 설계서 - 홈")
    slide08(prs); print("  8/22 화면 설계서 - 인지훈련")
    slide09(prs); print("  9/22 화면 설계서 - 보행 분석")
    slide10(prs); print(" 10/22 화면 설계서 - 리포트")
    slide11(prs); print(" 11/22 엔티티 관계도 (ERD)")
    slide12(prs); print(" 12/22 기능 처리도 - 인지훈련 플로우")
    slide13(prs); print(" 13/22 기능 처리도 - 보행 분석 플로우")
    slide14(prs); print(" 14/22 프로그램 목록")
    slide15(prs); print(" 15/22 테이블 정의서 (SQLite)")
    slide16(prs); print(" 16/22 테이블 정의서 (Supabase)")
    slide17(prs); print(" 17/22 핵심 소스코드 (1) - 보행 변동성")
    slide18(prs); print(" 18/22 핵심 소스코드 (2) - 적응형 난이도")
    slide19(prs); print(" 19/22 핵심 소스코드 (3) - 음성 평가")
    slide20(prs); print(" 20/22 개발 환경")
    slide21(prs); print(" 21/22 기능 실사 화면")
    slide22(prs); print(" 22/22 Thank You")

    out = r"d:\Test_Android\flutter_application_1\MemoryLink_SW개발설계서.pptx"
    prs.save(out)
    print(f"\n완료! 파일 저장: {out}")


if __name__ == "__main__":
    main()
