// app-a.jsx — MemoryLink 리디자인 · 방향 A (라벤더 캄) 확정본
// A 전용 캔버스: 디자인 토큰 스펙 + 컴포넌트 시트 + 8화면 플로우 + Tweaks.
const { useTweaks, TweaksPanel, TweakSection, TweakSlider, TweakToggle, TweakRadio, TweakColor } = window;
const { THEME_A, makeTheme } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "fontSize": 1.0,
  "roundness": 1.0,
  "mascot": true,
  "dark": false,
  "navStyle": "auto",
  "accent": "#6C5CE7"
}/*EDITMODE-END*/;

function lighten(hex, amt) {
  const n = parseInt(hex.slice(1), 16);
  let r=(n>>16)&255, g=(n>>8)&255, b=n&255;
  if (amt>=0){ r=Math.round(r+(255-r)*amt); g=Math.round(g+(255-g)*amt); b=Math.round(b+(255-b)*amt);}
  else { const k=1+amt; r=Math.round(r*k); g=Math.round(g*k); b=Math.round(b*k);}
  return '#' + ((1<<24)+(r<<16)+(g<<8)+b).toString(16).slice(1);
}
function applyAccent(t, hex, dark) {
  t.primary = hex; t.primaryDeep = lighten(hex,-0.12);
  t.primarySoft = dark ? hex+'2E' : hex+'18';
  t.grad = `linear-gradient(135deg, ${hex} 0%, ${lighten(hex,0.20)} 100%)`;
  t.gradSoft = dark ? `linear-gradient(135deg, ${hex}33, ${hex}22)` : `linear-gradient(135deg, ${hex}14, ${lighten(hex,0.12)}1A)`;
  t.shadow = `0 14px 36px -12px ${hex}4D`;
  t.cat = Object.assign({}, t.cat, { calc: hex });
  return t;
}
function themeA(tw) {
  const t = makeTheme(THEME_A, tw);
  return applyAccent(t, tw.accent || '#6C5CE7', tw.dark);
}

// 첫 실행 플로우 (앱 진입 → 맞춤 설정)
const FLOW_ONBOARD = [
  { id:'login',    h:832,  comp:'ScreenLogin',    label:'로그인' },
  { id:'register', h:1180, comp:'ScreenRegister', label:'회원가입' },
  { id:'onboard',  h:832,  comp:'ScreenOnboard',  label:'사용 목적' },
  { id:'survey',   h:832,  comp:'ScreenSurvey',   label:'자가 체크' },
  { id:'result',   h:900,  comp:'ScreenResult',   label:'검사 결과' },
];
// 메인 탭 (플로팅 네비 5탭)
const FLOW_MAIN = [
  { id:'home',    h:1080, comp:'ScreenHome',   label:'홈' },
  { id:'hub',     h:1360, comp:'ScreenHub',    label:'인지훈련 · 센터' },
  { id:'walk',    h:1300, comp:'ScreenWalk',   label:'생활습관' },
  { id:'report',  h:1360, comp:'ScreenReport', label:'리포트' },
  { id:'profile', h:1360, comp:'ScreenProfile',label:'내 정보' },
];
// 세부 · 부가 기능
const FLOW_FEATURE = [
  { id:'chat',     h:900,  comp:'ScreenChat',     label:'AI 대화 도우미' },
  { id:'gait',     h:1000, comp:'ScreenGait',     label:'정밀 보행 분석' },
  { id:'garden',   h:900,  comp:'ScreenGarden',   label:'기억의 정원' },
  { id:'guardian', h:1180, comp:'ScreenGuardian', label:'보호자 안심 연결' },
  { id:'referral', h:1000, comp:'ScreenReferral', label:'기관 · 서비스 연계' },
  { id:'cs',       h:832,  comp:'ScreenCS',       label:'고객센터' },
];
// 인지 훈련 게임 (개별 플레이)
const FLOW_GAMES = [
  { id:'g-comp',   h:832, comp:'GameComparison',  label:'누가 큰가요? (비교)' },
  { id:'g-mult',   h:900, comp:'GameMultiply',    label:'구구단 맞추기' },
  { id:'g-cat',    h:880, comp:'GameCategorize',  label:'범주화 훈련' },
  { id:'g-seq',    h:880, comp:'GameSequence',    label:'규칙 찾아보기' },
  { id:'g-sudoku', h:920, comp:'GameSudoku',      label:'그림 스도쿠' },
  { id:'g-shape',  h:920, comp:'GameShapeMatch',  label:'같은 모양 찾기' },
  { id:'g-sentence',h:900,comp:'GameSentence',    label:'문장 읽기' },
  { id:'voice',    h:900, comp:'ScreenVoice',     label:'음성 평가' },
  { id:'g-done',   h:832, comp:'GameDone',        label:'훈련 완료' },
];
// CS · 설정 · 기타
const FLOW_CS = [
  { id:'consent', h:832,  comp:'ScreenConsent',     label:'개인정보 동의' },
  { id:'edit',    h:1180, comp:'ScreenEditProfile', label:'정보 수정' },
  { id:'faq',     h:1000, comp:'ScreenFAQ',         label:'자주 묻는 질문' },
  { id:'inquiry', h:832,  comp:'ScreenInquiry',     label:'1:1 문의하기' },
  { id:'myinq',   h:832,  comp:'ScreenMyInquiries', label:'내 문의 내역' },
  { id:'notices', h:832,  comp:'ScreenNotices',     label:'공지사항' },
];
// 관리자 (내부용)
const FLOW_ADMIN = [
  { id:'admin-login', h:832,  comp:'ScreenAdminLogin', label:'관리자 로그인' },
  { id:'admin-dash',  h:1240, comp:'ScreenAdmin',      label:'관리자 대시보드' },
];

/* ── design-token spec card ── */
function Swatch({ c, label, hex }) {
  return (<div style={{ textAlign:'center' }}>
    <div style={{ width:52, height:52, borderRadius:14, background:c, boxShadow:'0 2px 8px rgba(0,0,0,0.12)' }} />
    <div style={{ fontSize:11.5, color:'#8b8698', marginTop:6, fontWeight:700 }}>{label}</div>
    {hex && <div style={{ fontSize:10, color:'#b3aec2', fontFamily:'monospace' }}>{hex}</div>}</div>);
}
function DirSpec({ t }) {
  return (
    <div style={{ width:420, fontFamily:t.font, background:t.surface, borderRadius:28,
      padding:28, border:`1px solid ${t.line}`, boxShadow:t.cardShadow, color:t.text }}>
      <div style={{ display:'flex', alignItems:'center', gap:14 }}>
        <window.Mascot t={t} size={60} />
        <div>
          <div style={{ fontSize:13, fontWeight:800, color:t.primary }}>확정 방향</div>
          <div style={{ fontSize:26, fontWeight:900, letterSpacing:'-0.02em' }}>라벤더 캄</div>
        </div>
      </div>
      <div style={{ height:1, background:t.line, margin:'22px 0' }} />
      <div style={{ fontSize:13, fontWeight:800, color:t.textSoft, marginBottom:12 }}>COLOR</div>
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:22 }}>
        <Swatch c={t.primary} label="Primary" hex={t.primary} />
        <Swatch c={t.cat.mem} label="Mint" hex="#38C9A6" />
        <Swatch c={t.cat.read} label="Amber" hex="#FFB74D" />
        <Swatch c={t.good} label="양호" hex="#3FBF8F" />
        <Swatch c={t.warn} label="보통" hex="#FFB020" />
        <Swatch c={t.bad} label="주의" hex="#FF6B6B" />
      </div>
      <div style={{ fontSize:13, fontWeight:800, color:t.textSoft, marginBottom:10 }}>SURFACE</div>
      <div style={{ display:'flex', gap:10, marginBottom:22 }}>
        {[['배경','#F1F0FB'],['카드','#FFFFFF'],['보조','#F6F5FD'],['라인','#ECEAF4']].map(([l,c])=>(
          <div key={l} style={{ flex:1, textAlign:'center' }}>
            <div style={{ height:38, borderRadius:11, background:c, border:`1px solid ${t.line}` }} />
            <div style={{ fontSize:10.5, color:'#8b8698', marginTop:5, fontWeight:700 }}>{l}</div>
            <div style={{ fontSize:9.5, color:'#b3aec2', fontFamily:'monospace' }}>{c}</div></div>))}
      </div>
      <div style={{ fontSize:13, fontWeight:800, color:t.textSoft, marginBottom:10 }}>TYPE · Pretendard</div>
      <div style={{ background:t.gradSoft, borderRadius:16, padding:18 }}>
        <div style={{ fontSize:28, fontWeight:900, letterSpacing:'-0.02em' }}>안녕하세요, 김민수님</div>
        <div style={{ fontSize:18, fontWeight:800, marginTop:8 }}>타이틀 · 18–27px / 800</div>
        <div style={{ fontSize:15, color:t.textSoft, marginTop:4 }}>본문 · 14–16px / 600 · 고령층 가독성 우선</div>
      </div>
    </div>
  );
}

/* ── component sheet (Flutter 포팅 레퍼런스) ── */
function Row({ children, gap=12, style }) { return <div style={{ display:'flex', gap, alignItems:'center', flexWrap:'wrap', ...style }}>{children}</div>; }
function SheetBlock({ t, title, children }) {
  return (<div style={{ marginBottom:22 }}>
    <div style={{ fontSize:12.5, fontWeight:800, color:t.textFaint, letterSpacing:'0.04em', marginBottom:11 }}>{title}</div>
    {children}</div>);
}
function StatusPill({ t, label, c }) {
  return (<div style={{ display:'flex', alignItems:'center', gap:6, background:c+'1F',
    border:`1px solid ${c}40`, borderRadius:11, padding:'5px 11px' }}>
    <span style={{ width:8, height:8, borderRadius:8, background:c }} />
    <span style={{ fontSize:13, fontWeight:800, color:c }}>{label}</span></div>);
}
function NavSample({ t }) {
  const items=[['home','홈'],['brain','인지훈련'],['walk','생활습관'],['chart','리포트'],['user','내정보']];
  return (<div style={{ display:'flex', alignItems:'center', gap:6, background:t.surface, borderRadius:30,
    padding:'9px 12px', boxShadow:t.shadow, border:`1px solid ${t.line}` }}>
    {items.map(([ic,l],i)=>{ const on=i===0; return (
      <div key={l} style={{ display:'flex', alignItems:'center', gap:7, background:on?t.primary:'transparent',
        padding:on?'9px 14px':'9px 9px', borderRadius:22 }}>
        <window.NavIcon name={ic} c={on?'#fff':t.textFaint} on={on} />
        {on && <span style={{ fontSize:13, fontWeight:800, color:'#fff' }}>{l}</span>}</div>); })}
  </div>);
}
function ComponentSheet({ t }) {
  return (
    <div style={{ width:420, fontFamily:t.font, background:t.surface, borderRadius:28,
      padding:28, border:`1px solid ${t.line}`, boxShadow:t.cardShadow, color:t.text }}>
      <div style={{ fontSize:22, fontWeight:900, letterSpacing:'-0.02em', marginBottom:22 }}>컴포넌트</div>

      <SheetBlock t={t} title="BUTTONS">
        <Row>
          <div style={{ background:t.primary, color:'#fff', fontWeight:800, fontSize:15, padding:'11px 22px', borderRadius:t.r(14), boxShadow:t.shadow }}>시작</div>
          <div style={{ background:t.primarySoft, color:t.primary, fontWeight:800, fontSize:15, padding:'11px 20px', borderRadius:t.r(14) }}>전체보기</div>
          <div style={{ border:`1.5px solid ${t.primary}66`, color:t.primary, fontWeight:800, fontSize:14, padding:'9px 16px', borderRadius:t.r(12) }}>프로필 수정</div>
        </Row>
      </SheetBlock>

      <SheetBlock t={t} title="ICON TILES">
        <Row gap={14}>
          <window.IconTile t={t} name="calc" color={t.cat.calc} size={52} />
          <window.IconTile t={t} name="logic" color={t.cat.logic} size={52} />
          <window.IconTile t={t} name="puzzle" color={t.cat.mem} size={52} />
          <window.IconTile t={t} name="heart" color={t.cat.care} size={52} />
          <window.IconTile t={t} name="voice" color={t.cat.read} size={52} />
        </Row>
      </SheetBlock>

      <SheetBlock t={t} title="BADGES & STATUS">
        <Row>
          <window.Badge t={t} color={t.textSoft}>Lv.3</window.Badge>
          <div style={{ display:'flex', alignItems:'center', gap:6, background:t.cat.read+'1A', border:`1px solid ${t.cat.read}33`, borderRadius:20, padding:'6px 12px' }}>
            <window.Icon name="flower" c={t.cat.read} size={16} /><span style={{ fontSize:12.5, fontWeight:800, color:t.cat.read }}>제철 꽃: 벚꽃</span></div>
          <StatusPill t={t} label="양호" c={t.good} />
          <StatusPill t={t} label="보통" c={t.warn} />
          <StatusPill t={t} label="주의" c={t.bad} />
        </Row>
      </SheetBlock>

      <SheetBlock t={t} title="PROGRESS & RING">
        <Row gap={18} style={{ flexWrap:'nowrap' }}>
          <div style={{ flex:1, minWidth:0 }}>
            <window.Progress t={t} value={0.62} color={t.primary} h={10} />
            <div style={{ height:10 }} />
            <window.Progress t={t} value={0.84} color={t.cat.mem} h={10} />
          </div>
          <window.Ring t={t} value={0.74} size={72} stroke={9} color={t.primary}>
            <span style={{ fontSize:16, fontWeight:900 }}>74%</span></window.Ring>
        </Row>
      </SheetBlock>

      <SheetBlock t={t} title="CARDS">
        <div style={{ background:t.grad, borderRadius:t.r(18), padding:16, color:'#fff', boxShadow:t.shadow, marginBottom:12 }}>
          <div style={{ fontSize:13, opacity:0.85 }}>오늘 걸음</div>
          <div style={{ fontSize:22, fontWeight:900 }}>7,372보</div>
        </div>
        <div style={{ background:t.surface, border:`1px solid ${t.line}`, borderRadius:t.r(18), padding:16, boxShadow:t.cardShadow, display:'flex', gap:12, alignItems:'center' }}>
          <window.IconTile t={t} name="calc" color={t.cat.calc} size={46} />
          <div style={{ flex:1 }}><div style={{ fontWeight:800, fontSize:15 }}>누가 큰가요?</div>
            <div style={{ fontSize:12.5, color:t.textSoft }}>수식 비교로 판단력 향상</div></div>
          <div style={{ background:t.primary, color:'#fff', fontWeight:800, fontSize:14, padding:'9px 16px', borderRadius:t.r(12) }}>시작</div>
        </div>
      </SheetBlock>

      <SheetBlock t={t} title="FLOATING PILL NAV">
        <NavSample t={t} />
      </SheetBlock>
    </div>
  );
}

function App() {
  const [tw, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const t = themeA(tw);
  return (
    <>
      <window.DesignCanvas>
        <window.DCSection id="system" title="방향 A · 라벤더 캄 — 디자인 시스템"
          subtitle="확정 방향 · 토큰과 컴포넌트는 Flutter 포팅 레퍼런스로 사용하세요">
          <window.DCArtboard id="tokens" label="디자인 토큰" width={420} height={620}>
            <DirSpec t={t} />
          </window.DCArtboard>
          <window.DCArtboard id="components" label="컴포넌트 시트" width={420} height={760}>
            <ComponentSheet t={t} />
          </window.DCArtboard>
        </window.DCSection>

        <window.DCSection id="flow-onboard" title="플로우 1 · 첫 실행 (온보딩)"
          subtitle="로그인 → 회원가입 → 사용 목적 → 자가 체크(10문항) → 검사 결과">
          {FLOW_ONBOARD.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>

        <window.DCSection id="flow-main" title="플로우 2 · 메인 5개 탭"
          subtitle="플로팅 알약 네비 — 홈 · 인지훈련 · 생활습관 · 리포트 · 내 정보">
          {FLOW_MAIN.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>

        <window.DCSection id="flow-feature" title="플로우 3 · 세부 · 부가 기능"
          subtitle="인지 훈련 게임 · AI 대화 · 정밀 보행 분석 · 기억의 정원 · 보호자 연결 · 고객센터">
          {FLOW_FEATURE.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>

        <window.DCSection id="flow-games" title="플로우 4 · 인지 훈련 게임 (개별 플레이)"
          subtitle="공통 게임 셸 위 · 비교(누가 큰가요?) · 구구단 · 범주화 · 수열 · 스도쿠 · 모양찾기 · 문장읽기 · 음성평가 · 완료">
          {FLOW_GAMES.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>

        <window.DCSection id="flow-cs" title="플로우 5 · 설정 · 고객지원 · 기타"
          subtitle="개인정보 동의 · 정보 수정 · FAQ · 1:1 문의 · 내 문의 내역 · 공지사항">
          {FLOW_CS.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>

        <window.DCSection id="flow-admin" title="플로우 6 · 관리자 콘솔 (내부용)"
          subtitle="운영자 대상 · 어두운 톤으로 사용자 앱과 구분 · 통계 · 위험 사용자 · 회원 관리">
          {FLOW_ADMIN.map((s,i) => {
            const Comp = window[s.comp];
            return (
              <window.DCArtboard key={s.id} id={s.id} label={`${String(i+1).padStart(2,'0')} · ${s.label}`} width={384} height={s.h}>
                <Comp t={t} variant="A" />
              </window.DCArtboard>
            );
          })}
        </window.DCSection>
      </window.DesignCanvas>

      <TweaksPanel>
        <TweakSection label="타이포그래피" />
        <TweakSlider label="글자 크기" value={tw.fontSize} min={0.9} max={1.3} step={0.05} onChange={(v)=>setTweak('fontSize', v)} />
        <TweakSection label="형태" />
        <TweakSlider label="모서리 둥글기" value={tw.roundness} min={0.6} max={1.4} step={0.1} onChange={(v)=>setTweak('roundness', v)} />
        <TweakRadio label="하단 네비" value={tw.navStyle} options={['auto','iconActive','allLabels']} onChange={(v)=>setTweak('navStyle', v)} />
        <TweakToggle label="캐릭터 마스코트" value={tw.mascot} onChange={(v)=>setTweak('mascot', v)} />
        <TweakToggle label="다크 모드" value={tw.dark} onChange={(v)=>setTweak('dark', v)} />
        <TweakSection label="강조색" />
        <TweakColor label="라벤더 계열" value={tw.accent}
          options={['#6C5CE7','#7C5CFF','#8A5CD6','#5C6BE7','#3FA796']}
          onChange={(v)=>setTweak('accent', v)} />
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
