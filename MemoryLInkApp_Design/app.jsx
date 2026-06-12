// app.jsx — assembles the MemoryLink redesign canvas + Tweaks panel.
const { useTweaks, TweaksPanel, TweakSection, TweakSlider, TweakToggle, TweakRadio, TweakColor } = window;
const { THEME_A, THEME_B, makeTheme } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "fontSize": 1.0,
  "roundness": 1.0,
  "mascot": true,
  "dark": false,
  "navStyle": "auto",
  "accentA": "#6C5CE7",
  "accentB": "#2E6BE6"
}/*EDITMODE-END*/;

// hex mix toward white (amt 0..1)
function lighten(hex, amt) {
  const n = parseInt(hex.slice(1), 16);
  let r = (n>>16)&255, g = (n>>8)&255, b = n&255;
  r = Math.round(r + (255-r)*amt); g = Math.round(g + (255-g)*amt); b = Math.round(b + (255-b)*amt);
  return '#' + ((1<<24)+(r<<16)+(g<<8)+b).toString(16).slice(1);
}
function applyAccent(t, hex, dark) {
  t.primary = hex;
  t.primaryDeep = lighten(hex, -0.0) ;
  t.primarySoft = dark ? hex+'2E' : hex+'18';
  t.grad = `linear-gradient(135deg, ${hex} 0%, ${lighten(hex,0.20)} 100%)`;
  t.gradSoft = dark ? `linear-gradient(135deg, ${hex}33, ${hex}22)` : `linear-gradient(135deg, ${hex}14, ${lighten(hex,0.12)}1A)`;
  t.shadow = `0 14px 36px -12px ${hex}4D`;
  t.cat = Object.assign({}, t.cat, { calc: hex });
  return t;
}

const SCREENS = [
  { id:'login',   h:832,  title:'01 · 로그인 / 시작',   sub:'첫 진입 — 브랜드 무드와 안심감', comp:'ScreenLogin' },
  { id:'home',    h:1080, title:'02 · 홈 대시보드',     sub:'인사 · 오늘 현황 · 추천 훈련 · 두뇌 건강', comp:'ScreenHome' },
  { id:'hub',     h:1360, title:'03 · 두뇌 트레이닝 센터', sub:'카테고리별 인지 훈련 게임 허브', comp:'ScreenHub' },
  { id:'game',    h:832,  title:'04 · 인지 훈련 (vs AI)', sub:'게임 플레이 — 동기부여 · 성취감', comp:'ScreenGame' },
  { id:'report',  h:1360, title:'05 · 주간 분석 리포트',  sub:'신호등 지표 · 점수 추이 · AI 요약', comp:'ScreenReport' },
  { id:'walk',    h:1300, title:'06 · 생활습관 (걷기)',  sub:'원형 게이지 · 정밀 분석 · 주간 추이', comp:'ScreenWalk' },
  { id:'profile', h:1360, title:'07 · 내 정보 / 설정',  sub:'건강 정보 · 보호자 연결 · 앱 설정', comp:'ScreenProfile' },
  { id:'garden',  h:900,  title:'08 · 기억의 정원',     sub:'성장 게이미피케이션 · 계절 정원', comp:'ScreenGarden' },
];

function themeFor(dir, tw) {
  const base = dir === 'A' ? THEME_A : THEME_B;
  const t = makeTheme(base, tw);
  applyAccent(t, dir === 'A' ? (tw.accentA||'#6C5CE7') : (tw.accentB||'#2E6BE6'), tw.dark);
  return t;
}

function Swatch({ c, label }) {
  return (<div style={{ textAlign:'center' }}>
    <div style={{ width:46, height:46, borderRadius:13, background:c, boxShadow:'0 2px 8px rgba(0,0,0,0.12)' }} />
    <div style={{ fontSize:11, color:'#8b8698', marginTop:6, fontWeight:600 }}>{label}</div></div>);
}
function DirSpec({ t, dir, traits }) {
  return (
    <div style={{ width:384, fontFamily:t.font, background:t.surface, borderRadius:28,
      padding:26, border:`1px solid ${t.line}`, boxShadow:t.cardShadow, color:t.text }}>
      <div style={{ display:'flex', alignItems:'center', gap:14 }}>
        <window.Mascot t={t} size={56} />
        <div>
          <div style={{ fontSize:13, fontWeight:700, color:t.primary }}>방향 {dir}</div>
          <div style={{ fontSize:24, fontWeight:900, letterSpacing:'-0.02em' }}>{t.name}</div>
        </div>
      </div>
      <div style={{ height:1, background:t.line, margin:'20px 0' }} />
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:20 }}>
        <Swatch c={t.primary} label="Primary" />
        <Swatch c={t.cat.mem} label="Mint/Teal" />
        <Swatch c={t.cat.read} label="Amber" />
        <Swatch c={t.good} label="양호" />
        <Swatch c={t.bad} label="주의" />
      </div>
      <div style={{ background:t.gradSoft, borderRadius:16, padding:16, marginBottom:16 }}>
        <div style={{ fontSize:22, fontWeight:900, letterSpacing:'-0.02em' }}>Pretendard</div>
        <div style={{ fontSize:14, color:t.textSoft, marginTop:4 }}>고령층 가독성을 위한 큰 본문 · 또렷한 굵기 대비</div>
      </div>
      <div style={{ display:'flex', flexDirection:'column', gap:9 }}>
        {traits.map(tr => (<div key={tr} style={{ display:'flex', gap:9, alignItems:'flex-start' }}>
          <window.Icon name="check" c={t.primary} size={17} sw={2.4} />
          <span style={{ fontSize:13.5, lineHeight:1.4, color:t.textSoft }}>{tr}</span></div>))}
      </div>
    </div>
  );
}

function App() {
  const [tw, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const tA = themeFor('A', tw);
  const tB = themeFor('B', tw);

  return (
    <>
      <window.DesignCanvas>
        {/* Overview */}
        <window.DCSection id="overview" title="방향성 · 두 갈래" subtitle="둘 다 라이트 기반 · 코드 기능 유지 · 외피만 교체 · 고령층 가독성 우선">
          <window.DCArtboard id="specA" label="방향 A · 라벤더 캄" width={384} height={520}>
            <DirSpec t={tA} dir="A" traits={[
              'Reflectly·팀 목업 기반 — 부드러운 라벤더, 넉넉한 여백',
              '브레인 버디 마스코트로 정서적 친근함',
              'TIDE식 곡선 그래프 · 감성적 카피',
              '플로팅 알약 네비 (활성 탭만 라벨)',
            ]} />
          </window.DCArtboard>
          <window.DCArtboard id="specB" label="방향 B · 클리니컬 트러스트" width={384} height={520}>
            <DirSpec t={tB} dir="B" traits={[
              'NeuroNation 기반 — 신뢰감 있는 블루, 의료앱 무드',
              '정보 밀도 ↑ · 신호등 상태 · 또렷한 구조',
              '둥근 막대 그래프 · 수치 중심',
              '플로팅 알약 네비 (전체 라벨 노출)',
            ]} />
          </window.DCArtboard>
        </window.DCSection>

        {/* One section per screen, A & B side by side */}
        {SCREENS.map(s => {
          const Comp = window[s.comp];
          return (
            <window.DCSection key={s.id} id={s.id} title={s.title} subtitle={s.sub}>
              <window.DCArtboard id={s.id+'-A'} label="A · 라벤더 캄" width={384} height={s.h}>
                <Comp t={tA} variant="A" />
              </window.DCArtboard>
              <window.DCArtboard id={s.id+'-B'} label="B · 클리니컬 트러스트" width={384} height={s.h}>
                <Comp t={tB} variant="B" />
              </window.DCArtboard>
            </window.DCSection>
          );
        })}
      </window.DesignCanvas>

      <TweaksPanel>
        <TweakSection label="타이포그래피" />
        <TweakSlider label="글자 크기" value={tw.fontSize} min={0.9} max={1.3} step={0.05}
          onChange={(v)=>setTweak('fontSize', v)} />
        <TweakSection label="형태" />
        <TweakSlider label="모서리 둥글기" value={tw.roundness} min={0.6} max={1.4} step={0.1}
          onChange={(v)=>setTweak('roundness', v)} />
        <TweakRadio label="하단 네비" value={tw.navStyle}
          options={['auto','iconActive','allLabels']}
          onChange={(v)=>setTweak('navStyle', v)} />
        <TweakToggle label="캐릭터 마스코트" value={tw.mascot} onChange={(v)=>setTweak('mascot', v)} />
        <TweakToggle label="다크 모드" value={tw.dark} onChange={(v)=>setTweak('dark', v)} />
        <TweakSection label="강조색" />
        <TweakColor label="A · 라벤더 계열" value={tw.accentA}
          options={['#6C5CE7','#7C5CFF','#8A5CD6','#5C6BE7','#3FA796']}
          onChange={(v)=>setTweak('accentA', v)} />
        <TweakColor label="B · 블루 계열" value={tw.accentB}
          options={['#2E6BE6','#1E88E5','#0FB5AE','#3949D6','#2F8F6B']}
          onChange={(v)=>setTweak('accentB', v)} />
      </TweaksPanel>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
