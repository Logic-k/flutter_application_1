// ml-kit.jsx — MemoryLink redesign kit
// Shared tokens, phone shell, floating pill nav, charts, icon tiles, mascot/illustrations.
// Two cohesive directions: A "라벤더 캄" (Lavender Calm), B "클리니컬 트러스트" (Clinical Trust).
// Exports to window so screen files can use them.

const { useState, useEffect, useRef } = React;

/* ─────────────────────────  THEME TOKENS  ───────────────────────── */
const THEME_A = {
  id: 'A',
  name: '라벤더 캄',
  bg: '#F1F0FB',
  surface: '#FFFFFF',
  surfaceAlt: '#F6F5FD',
  primary: '#6C5CE7',
  primaryDeep: '#5847D6',
  primarySoft: '#ECE9FC',
  onPrimary: '#FFFFFF',
  grad: 'linear-gradient(135deg,#7C6FF0 0%,#9E7DF6 100%)',
  gradSoft: 'linear-gradient(135deg,#EFEBFD 0%,#F6EEFB 100%)',
  text: '#241F3D',
  textSoft: '#716C8C',
  textFaint: '#A6A2BC',
  line: '#ECEAF4',
  radius: 26,
  radiusSm: 18,
  nav: 'iconActive',          // pill nav: icons, label only on active
  chart: 'area',              // soft area/curve charts
  shadow: '0 14px 36px -12px rgba(108,92,231,0.30)',
  cardShadow: '0 8px 24px -14px rgba(60,40,120,0.28)',
  cat: { calc:'#6C5CE7', mult:'#FF8E72', logic:'#A66BE8', mem:'#38C9A6', cat2:'#5AA9F0', perc:'#F2789F', care:'#FF7AA2', read:'#FFB74D' },
  good:'#3FBF8F', warn:'#FFB020', bad:'#FF6B6B',
  font: "'Pretendard', -apple-system, sans-serif",
};
const THEME_B = {
  id: 'B',
  name: '클리니컬 트러스트',
  bg: '#EBF1FA',
  surface: '#FFFFFF',
  surfaceAlt: '#F3F8FE',
  primary: '#2E6BE6',
  primaryDeep: '#1F57CC',
  primarySoft: '#E2ECFD',
  onPrimary: '#FFFFFF',
  grad: 'linear-gradient(135deg,#2E6BE6 0%,#27A0E0 100%)',
  gradSoft: 'linear-gradient(135deg,#E6EFFE 0%,#E6F6FB 100%)',
  text: '#15243C',
  textSoft: '#56688A',
  textFaint: '#9DAAC2',
  line: '#E4EBF6',
  radius: 18,
  radiusSm: 14,
  nav: 'allLabels',           // pill nav: all labels visible
  chart: 'bars',              // crisp bar charts
  shadow: '0 14px 34px -12px rgba(46,107,230,0.30)',
  cardShadow: '0 8px 22px -14px rgba(20,50,110,0.26)',
  cat: { calc:'#2E6BE6', mult:'#F6A609', logic:'#5566E0', mem:'#0FB5AE', cat2:'#3F8AE0', perc:'#EB5B6B', care:'#E5709A', read:'#F2A23C' },
  good:'#2FAE6B', warn:'#F2A600', bad:'#E5484D',
  font: "'Pretendard', -apple-system, sans-serif",
};

// Build a working theme by merging a base direction with live tweaks.
function makeTheme(base, tw) {
  const t = Object.assign({}, base);
  if (tw) {
    if (tw.dark) {
      const darkBg = base.id === 'A' ? '#15131F' : '#0F1626';
      const darkSurf = base.id === 'A' ? '#211D30' : '#172234';
      t.bg = darkBg; t.surface = darkSurf; t.surfaceAlt = base.id==='A' ? '#1A1726' : '#131d2e';
      t.text = '#F3F1FA'; t.textSoft = '#A9A4C2'; t.textFaint='#6F6A86';
      t.line = base.id==='A' ? '#2E2A3D' : '#243349';
      t.primarySoft = base.id==='A' ? '#2C2647' : '#1B2F50';
      t.gradSoft = base.id==='A' ? 'linear-gradient(135deg,#2A2447,#2D2640)' : 'linear-gradient(135deg,#172A4A,#163243)';
      t.cardShadow = '0 10px 26px -16px rgba(0,0,0,0.6)';
    }
    t.fs = tw.fontSize || 1;          // font scale multiplier
    t.radiusMul = tw.roundness != null ? tw.roundness : 1;
    t.mascot = tw.mascot !== false;
    t.density = tw.density || 'regular';
    if (tw.navStyle && tw.navStyle !== 'auto') t.nav = tw.navStyle;
  } else {
    t.fs = 1; t.radiusMul = 1; t.mascot = true; t.density = 'regular';
  }
  t.r = (v) => Math.round(v * t.radiusMul);
  t.z = (v) => Math.round(v * t.fs);   // scale a font size
  return t;
}

/* ─────────────────────────  PHONE SHELL  ───────────────────────── */
const PW = 384;  // phone content width

function StatusBar({ t, light }) {
  const c = light ? 'rgba(255,255,255,0.96)' : t.text;
  return (
    <div style={{ height: 44, display:'flex', alignItems:'center', justifyContent:'space-between',
      padding:'0 26px', flex:'0 0 auto' }}>
      <span style={{ fontSize:15, fontWeight:700, color:c, letterSpacing:0.2 }}>9:41</span>
      <div style={{ display:'flex', alignItems:'center', gap:6 }}>
        <Glyph d="signal" c={c} />
        <Glyph d="wifi" c={c} />
        <Glyph d="battery" c={c} />
      </div>
    </div>
  );
}
function Glyph({ d, c }) {
  if (d === 'signal') return (<svg width="17" height="11" viewBox="0 0 17 11"><g fill={c}>
    <rect x="0" y="7" width="3" height="4" rx="1"/><rect x="4.5" y="5" width="3" height="6" rx="1"/>
    <rect x="9" y="2.5" width="3" height="8.5" rx="1"/><rect x="13.5" y="0" width="3" height="11" rx="1"/></g></svg>);
  if (d === 'wifi') return (<svg width="16" height="11" viewBox="0 0 16 11"><path fill={c} d="M8 11l2.4-3c-1.4-1-3.4-1-4.8 0L8 11zM3 5.2C6 2.6 10 2.6 13 5.2l1.6-2C10.7-.2 5.3-.2 1.4 3.2L3 5.2z"/></svg>);
  return (<svg width="26" height="13" viewBox="0 0 26 13"><rect x="0.5" y="0.5" width="22" height="12" rx="3.5" fill="none" stroke={c} strokeOpacity="0.5"/><rect x="2" y="2" width="18" height="9" rx="2" fill={c}/><rect x="23.5" y="4" width="2" height="5" rx="1" fill={c} fillOpacity="0.5"/></svg>);
}

// PhoneFrame: full screen design frame for the canvas. Children fill the body.
// `bg` optional custom background; `light` => status bar uses white.
function PhoneFrame({ t, children, bg, light, height = 832, nav, navActive }) {
  return (
    <div style={{ width: PW, height, position:'relative', background: bg || t.bg,
      borderRadius: 40, overflow:'hidden', fontFamily: t.font, color: t.text,
      display:'flex', flexDirection:'column', boxShadow:'inset 0 0 0 1px rgba(0,0,0,0.04)' }}>
      <StatusBar t={t} light={light} />
      <div style={{ flex:'1 1 auto', overflow:'hidden', position:'relative', display:'flex', flexDirection:'column' }}>
        {children}
      </div>
      {nav && <PillNav t={t} active={navActive} />}
    </div>
  );
}

/* ─────────────────────────  FLOATING PILL NAV  ───────────────────────── */
const NAV_ITEMS = [
  { id:'home',  label:'홈',     icon:'home' },
  { id:'brain', label:'인지훈련', icon:'brain' },
  { id:'walk',  label:'생활습관', icon:'walk' },
  { id:'report',label:'리포트',  icon:'chart' },
  { id:'me',    label:'내정보',  icon:'user' },
];
function PillNav({ t, active = 'home' }) {
  const allLabels = t.nav === 'allLabels';
  return (
    <div style={{ position:'absolute', left:0, right:0, bottom:18, display:'flex', justifyContent:'center', zIndex:5, pointerEvents:'none' }}>
      <div style={{ display:'flex', alignItems:'center', gap: allLabels ? 2 : 6,
        background: t.surface, borderRadius: 30, padding: allLabels ? '8px 10px' : '9px 12px',
        boxShadow: t.shadow + ', 0 2px 8px rgba(0,0,0,0.05)', border:`1px solid ${t.line}` }}>
        {NAV_ITEMS.map(it => {
          const on = it.id === active;
          return (
            <div key={it.id} style={{ display:'flex', alignItems:'center', gap:7,
              background: on ? t.primary : 'transparent', color: on ? t.onPrimary : t.textFaint,
              padding: on ? '9px 14px' : '9px 11px', borderRadius: 22, transition:'all .2s' }}>
              <NavIcon name={it.icon} c={on ? t.onPrimary : t.textFaint} on={on} />
              {(on || allLabels) && <span style={{ fontSize: t.z(allLabels?12:13.5), fontWeight: on?800:600,
                color: on ? t.onPrimary : t.textFaint, whiteSpace:'nowrap' }}>{it.label}</span>}
            </div>
          );
        })}
      </div>
    </div>
  );
}
function NavIcon({ name, c, on }) {
  const sw = on ? 2.4 : 2.1; const s = 21;
  const P = { fill:'none', stroke:c, strokeWidth:sw, strokeLinecap:'round', strokeLinejoin:'round' };
  const paths = {
    home: <path {...P} d="M4 11l8-6 8 6v8a1 1 0 0 1-1 1h-4v-5h-6v5H5a1 1 0 0 1-1-1z"/>,
    brain: <path {...P} d="M8.5 4.5A3 3 0 0 0 6 9a3 3 0 0 0-1 5.5A3 3 0 0 0 8.5 19 2.5 2.5 0 0 0 12 17.2V5.6A2.4 2.4 0 0 0 8.5 4.5zM15.5 4.5A3 3 0 0 1 18 9a3 3 0 0 1 1 5.5A3 3 0 0 1 15.5 19 2.5 2.5 0 0 1 12 17.2"/>,
    walk: <g {...P}><circle cx="13" cy="4.5" r="1.8"/><path d="M11 9l-2 4 2 1.5V20M11 9l3 1 2 3M11 9l-3 2"/></g>,
    chart: <g {...P}><path d="M4 20h16"/><rect x="6" y="11" width="3" height="6" rx="1"/><rect x="11" y="7" width="3" height="10" rx="1"/><rect x="16" y="13" width="3" height="4" rx="1"/></g>,
    user: <g {...P}><circle cx="12" cy="8" r="3.4"/><path d="M5.5 20a6.5 6.5 0 0 1 13 0"/></g>,
  };
  return <svg width={s} height={s} viewBox="0 0 24 24">{paths[name]}</svg>;
}

/* ─────────────────────────  ICONS (line, for tiles & rows)  ───────────────────────── */
function Icon({ name, c = 'currentColor', size = 24, sw = 2, style }) {
  const P = { fill:'none', stroke:c, strokeWidth:sw, strokeLinecap:'round', strokeLinejoin:'round' };
  const m = {
    calc: <g {...P}><rect x="5" y="3" width="14" height="18" rx="2.5"/><path d="M8 7h8M8 11h2M12 11h0M8 15h2M12 15h0M16 11v4"/></g>,
    mult: <g {...P}><rect x="4" y="4" width="16" height="16" rx="3"/><path d="M9 9l6 6M15 9l-6 6"/></g>,
    logic: <g {...P}><path d="M12 3v3M5 8l2 2M19 8l-2 2"/><circle cx="12" cy="13" r="5"/><path d="M12 18v3"/></g>,
    puzzle: <g {...P}><path d="M10 5a1.5 1.5 0 0 1 3 0c0 .8 1 1 1.5 1H17a1 1 0 0 1 1 1v2.5c0 .5.2 1.5 1 1.5a1.5 1.5 0 0 1 0 3c-.8 0-1 .9-1 1.5V17a1 1 0 0 1-1 1h-2.5c-.6 0-1.5.2-1.5 1a1.5 1.5 0 0 1-3 0c0-.8-.9-1-1.5-1H6a1 1 0 0 1-1-1v-2.5C5 13.9 4.8 13 4 13a1.5 1.5 0 0 1 0-3c.8 0 1-1 1-1.5V7a1 1 0 0 1 1-1h2.5c.6 0 1.5-.2 1.5-1z"/></g>,
    grid: <g {...P}><rect x="4" y="4" width="7" height="7" rx="1.5"/><rect x="13" y="4" width="7" height="7" rx="1.5"/><rect x="4" y="13" width="7" height="7" rx="1.5"/><rect x="13" y="13" width="7" height="7" rx="1.5"/></g>,
    shapes: <g {...P}><circle cx="8" cy="8" r="4"/><rect x="13" y="12" width="7" height="7" rx="1.5"/></g>,
    heart: <path {...P} d="M12 20s-7-4.3-7-9.3A3.7 3.7 0 0 1 12 8a3.7 3.7 0 0 1 7 2.7C19 15.7 12 20 12 20z"/>,
    voice: <g {...P}><path d="M4 9v6h3l5 4V5L7 9z"/><path d="M16 9a3 3 0 0 1 0 6M18.5 7a6 6 0 0 1 0 10"/></g>,
    walk: <g {...P}><circle cx="13" cy="4.5" r="1.8"/><path d="M11 9l-2 4 2 1.5V20M11 9l3 1 2 3M11 9l-3 2"/></g>,
    fire: <path {...P} d="M12 3c1 3-1 4-1 6a3 3 0 0 0 5 1c1 2 1 3 1 4a5 5 0 0 1-10 0c0-3 2-4 2-6 1 1 2 1 3-1 0-2 0-3-1-4z"/>,
    map: <g {...P}><path d="M9 4L4 6v14l5-2 6 2 5-2V4l-5 2-6-2z"/><path d="M9 4v14M15 6v14"/></g>,
    clock: <g {...P}><circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/></g>,
    bell: <g {...P}><path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6z"/><path d="M10.5 19a1.5 1.5 0 0 0 3 0"/></g>,
    gear: <g {...P}><circle cx="12" cy="12" r="3"/><path d="M12 3v2M12 19v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M3 12h2M19 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"/></g>,
    info: <g {...P}><circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8h0"/></g>,
    flower: <g {...P}><circle cx="12" cy="12" r="2.5"/><path d="M12 9.5C12 6 10 5 12 3c2 2 0 3 0 6.5M14.5 12c3.5 0 4.5-2 6.5 0-2 2-3 0-6.5 0M12 14.5c0 3.5 2 4.5 0 6.5-2-2 0-3 0-6.5M9.5 12C6 12 5 14 3 12c2-2 3 0 6.5 0"/></g>,
    sparkle: <path {...P} d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>,
    shield: <g {...P}><path d="M12 3l7 3v5c0 5-3 8-7 10-4-2-7-5-7-10V6z"/><path d="M9 12l2 2 4-4"/></g>,
    family: <g {...P}><circle cx="8" cy="8" r="2.5"/><circle cx="16" cy="8" r="2.5"/><path d="M3.5 19a4.5 4.5 0 0 1 9 0M11.5 19a4.5 4.5 0 0 1 9 0"/></g>,
    headset: <g {...P}><path d="M5 13v-1a7 7 0 0 1 14 0v1"/><rect x="3.5" y="13" width="3.5" height="6" rx="1.5"/><rect x="17" y="13" width="3.5" height="6" rx="1.5"/><path d="M19 19a3 3 0 0 1-3 3h-2"/></g>,
    text: <g {...P}><path d="M4 7V5h16v2M9 19h6M12 5v14"/></g>,
    vibrate: <g {...P}><rect x="9" y="5" width="6" height="14" rx="1.5"/><path d="M5 9v6M19 9v6"/></g>,
    reset: <g {...P}><path d="M4 12a8 8 0 1 1 2.3 5.6M4 17v-4h4"/></g>,
    logout: <g {...P}><path d="M14 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4M9 12h11M16 8l4 4-4 4"/></g>,
    chevron: <path {...P} d="M9 6l6 6-6 6"/>,
    plus: <path {...P} d="M12 5v14M5 12h14"/>,
    weight: <g {...P}><circle cx="12" cy="12" r="8"/><path d="M12 12l3-3"/></g>,
    blood: <path {...P} d="M12 3s6 7 6 11a6 6 0 0 1-12 0c0-4 6-11 6-11z"/>,
    pill: <g {...P}><rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(45 12 12)"/><path d="M9 9l6 6"/></g>,
    cal: <g {...P}><rect x="4" y="5" width="16" height="16" rx="2.5"/><path d="M4 9h16M8 3v4M16 3v4"/></g>,
    play: <path {...P} d="M8 5l11 7-11 7z"/>,
    check: <path {...P} d="M5 13l4 4L19 7"/>,
    moon: <path {...P} d="M20 14a8 8 0 1 1-9-10 6 6 0 0 0 9 10z"/>,
    utensils: <g {...P}><path d="M6 3v8a2 2 0 0 0 4 0V3M8 11v10M16 3c-1.5 0-2 2-2 5s.5 4 2 4v9"/></g>,
    doc: <g {...P}><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h6"/></g>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" style={{ display:'block', ...style }}>{m[name] || m.info}</svg>;
}

/* ─────────────────────────  CHARACTER MASCOT + ILLUSTRATION  ───────────────────────── */
// Friendly "brain buddy" mascot — soft squircle brain w/ a calm face.
function Mascot({ t, size = 64, mood = 'happy' }) {
  const c = t.primary, lc = t.primarySoft;
  return (
    <svg width={size} height={size} viewBox="0 0 80 80">
      <rect x="8" y="10" width="64" height="60" rx="26" fill={lc}/>
      <path d="M26 24c-6 0-10 5-9 10-4 2-4 8 0 10 0 5 5 8 9 6M54 24c6 0 10 5 9 10 4 2 4 8 0 10 0 5-5 8-9 6"
        fill="none" stroke={c} strokeWidth="3.4" strokeLinecap="round"/>
      <path d="M40 22v36" stroke={c} strokeWidth="3" strokeLinecap="round" opacity="0.55"/>
      <circle cx="32" cy="42" r="3.4" fill={c}/><circle cx="48" cy="42" r="3.4" fill={c}/>
      {mood === 'happy'
        ? <path d="M33 51c3 3 11 3 14 0" fill="none" stroke={c} strokeWidth="3.2" strokeLinecap="round"/>
        : <path d="M34 52h12" fill="none" stroke={c} strokeWidth="3.2" strokeLinecap="round"/>}
      <circle cx="26" cy="49" r="3.2" fill={c} opacity="0.18"/><circle cx="54" cy="49" r="3.2" fill={c} opacity="0.18"/>
    </svg>
  );
}
// Small flat senior figure — geometric, calm. Used in login / profile / garden.
function Senior({ t, size = 96 }) {
  const skin = '#F2C9A8', hair = '#C9C4D6', top = t.primary, topl = t.primarySoft;
  return (
    <svg width={size} height={size} viewBox="0 0 120 120">
      <circle cx="60" cy="60" r="56" fill={topl} opacity="0.6"/>
      <path d="M30 116a30 30 0 0 1 60 0z" fill={top}/>
      <rect x="44" y="70" width="32" height="22" rx="10" fill={skin}/>
      <circle cx="60" cy="52" r="22" fill={skin}/>
      <path d="M38 50c0-14 10-22 22-22s22 8 22 22c-6-2-9-6-9-6-3 5-9 7-16 7-5 0-8 1-10 4-2-3-5-5-9-5z" fill={hair}/>
      <circle cx="52" cy="52" r="2.6" fill="#5b5470"/><circle cx="68" cy="52" r="2.6" fill="#5b5470"/>
      <path d="M54 60c2 2 10 2 12 0" fill="none" stroke="#b98c66" strokeWidth="2.4" strokeLinecap="round"/>
      <rect x="46" y="46" width="11" height="8" rx="4" fill="none" stroke="#5b5470" strokeWidth="1.6"/>
      <rect x="63" y="46" width="11" height="8" rx="4" fill="none" stroke="#5b5470" strokeWidth="1.6"/>
      <path d="M57 50h6" stroke="#5b5470" strokeWidth="1.6"/>
    </svg>
  );
}

/* ─────────────────────────  PRIMITIVES  ───────────────────────── */
function Card({ t, children, style, soft, pad = 18, onAccent }) {
  return (
    <div style={{ background: soft ? t.surfaceAlt : t.surface, borderRadius: t.r(t.radius),
      padding: pad, border:`1px solid ${t.line}`, boxShadow: soft ? 'none' : t.cardShadow,
      ...style }}>{children}</div>
  );
}
function IconTile({ t, name, color, size = 52, r }) {
  const rad = r != null ? r : t.r(16);
  return (
    <div style={{ width:size, height:size, borderRadius:rad, flex:`0 0 ${size}px`,
      background: color+'1A', display:'flex', alignItems:'center', justifyContent:'center' }}>
      <Icon name={name} c={color} size={size*0.52} sw={2.1} />
    </div>
  );
}
function Badge({ t, children, color, soft = true }) {
  return (
    <span style={{ fontSize: t.z(12), fontWeight:800, padding:'4px 10px', borderRadius:11,
      background: soft ? color+'1F' : color, color: soft ? color : '#fff', whiteSpace:'nowrap' }}>{children}</span>
  );
}
function Progress({ t, value, color, h = 9, track }) {
  return (
    <div style={{ height:h, borderRadius:h, background: track || (color+'22'), overflow:'hidden' }}>
      <div style={{ width:`${Math.max(3,value*100)}%`, height:'100%', borderRadius:h,
        background: color }} />
    </div>
  );
}
function SectionTitle({ t, children, right }) {
  return (
    <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', margin:'2px 0 12px' }}>
      <span style={{ fontSize:t.z(18.5), fontWeight:800, color:t.text, letterSpacing:'-0.01em' }}>{children}</span>
      {right}
    </div>
  );
}
function Body({ children, pad = 22, style }) {
  return <div style={{ padding:`6px ${pad}px 120px`, overflow:'hidden', ...style }}>{children}</div>;
}
function AppBar({ t, title, light, right, big, back }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12,
      padding:'8px 22px 6px' }}>
      {back && <Icon name="chevron" c={light?'#fff':t.text} size={24} sw={2.4} style={{ transform:'rotate(180deg)', marginLeft:-4 }} />}
      <span style={{ flex:1, fontSize: big? t.z(27): t.z(21), fontWeight:800, letterSpacing:'-0.02em',
        color: light ? '#fff' : t.text }}>{title}</span>
      <div style={{ display:'flex', gap:10 }}>{right}</div>
    </div>
  );
}
function RoundBtn({ t, name, light, onAccent }) {
  const c = light ? '#fff' : t.textSoft;
  const bg = light ? 'rgba(255,255,255,0.18)' : t.surface;
  return (
    <div style={{ width:40, height:40, borderRadius:13, background:bg, border: light?'none':`1px solid ${t.line}`,
      display:'flex', alignItems:'center', justifyContent:'center', boxShadow: light?'none':t.cardShadow }}>
      <Icon name={name} c={c} size={21} sw={2} />
    </div>
  );
}

/* ─────────────────────────  CHARTS  ───────────────────────── */
// Curved area sparkline (Direction A / TIDE-ish).
function AreaChart({ t, data, color, w = 320, h = 120, labels }) {
  const max = Math.max(...data) * 1.15 || 1;
  const min = Math.min(...data) * 0.6;
  const span = max - min || 1;
  const n = data.length;
  const pts = data.map((v,i) => [ (i/(n-1))*w, h - ((v-min)/span)*(h-10) - 5 ]);
  const path = smooth(pts);
  const area = `${path} L ${w},${h} L 0,${h} Z`;
  const gid = 'ag'+color.replace('#','')+w;
  return (
    <div>
      <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ display:'block' }}>
        <defs><linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={color} stopOpacity="0.28"/><stop offset="1" stopColor={color} stopOpacity="0"/>
        </linearGradient></defs>
        <path d={area} fill={`url(#${gid})`} />
        <path d={path} fill="none" stroke={color} strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/>
        {pts.map((p,i) => i===n-1 && <g key={i}>
          <circle cx={p[0]} cy={p[1]} r="9" fill={color} opacity="0.18"/>
          <circle cx={p[0]} cy={p[1]} r="5" fill={color} stroke="#fff" strokeWidth="2.5"/></g>)}
      </svg>
      {labels && <Labels t={t} labels={labels} w={w} active={n-1} />}
    </div>
  );
}
function smooth(pts) {
  if (pts.length < 2) return '';
  let d = `M ${pts[0][0]},${pts[0][1]}`;
  for (let i=0;i<pts.length-1;i++){
    const [x0,y0]=pts[i], [x1,y1]=pts[i+1];
    const cx=(x0+x1)/2;
    d += ` C ${cx},${y0} ${cx},${y1} ${x1},${y1}`;
  }
  return d;
}
// Rounded bar chart (Direction B / team mockup).
function BarChart({ t, data, color, w = 320, h = 120, labels, goal }) {
  const max = (goal || Math.max(...data)) * 1.05 || 1;
  const n = data.length;
  const bw = Math.min(22, (w/n)*0.5);
  const gap = (w - bw*n)/(n);
  return (
    <div>
      <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ display:'block' }}>
        {data.map((v,i)=>{
          const x = gap/2 + i*(bw+gap);
          const bh = Math.max(4,(v/max)*(h-8));
          const on = i===n-1;
          return (<g key={i}>
            <rect x={x} y={3} width={bw} height={h-8} rx={bw/2} fill={color} opacity="0.10"/>
            <rect x={x} y={h-bh-5} width={bw} height={bh} rx={bw/2} fill={on?color:color} opacity={on?1:0.45}/>
          </g>);
        })}
      </svg>
      {labels && <Labels t={t} labels={labels} w={w} active={n-1} />}
    </div>
  );
}
function Labels({ t, labels, w, active }) {
  return (
    <div style={{ display:'flex', justifyContent:'space-between', marginTop:8 }}>
      {labels.map((l,i)=>(<span key={i} style={{ fontSize:t.z(12.5), fontWeight: i===active?800:600,
        color: i===active? t.primary : t.textFaint, flex:1, textAlign:'center' }}>{l}</span>))}
    </div>
  );
}
// Circular ring gauge.
function Ring({ t, value, size = 200, stroke = 16, color, children }) {
  const r = (size-stroke)/2, c0 = 2*Math.PI*r;
  return (
    <div style={{ position:'relative', width:size, height:size }}>
      <svg width={size} height={size} style={{ transform:'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={(color||t.primary)+'1F'} strokeWidth={stroke}/>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color||t.primary} strokeWidth={stroke}
          strokeLinecap="round" strokeDasharray={c0} strokeDashoffset={c0*(1-value)}/>
      </svg>
      <div style={{ position:'absolute', inset:0, display:'flex', flexDirection:'column',
        alignItems:'center', justifyContent:'center' }}>{children}</div>
    </div>
  );
}

Object.assign(window, {
  THEME_A, THEME_B, makeTheme, PW,
  PhoneFrame, StatusBar, PillNav, Icon, NavIcon, Mascot, Senior,
  Card, IconTile, Badge, Progress, SectionTitle, Body, AppBar, RoundBtn,
  AreaChart, BarChart, Ring, Labels,
});
