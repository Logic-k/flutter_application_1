// ml-screens3.jsx — MemoryLink 방향 A · 인지 훈련 게임 6종 + 음성 평가
const { PhoneFrame, Icon, Mascot, Card, IconTile, Body } = window;

/* 공통 게임 셸 (GameTemplate 대응) */
function GameShell({ t, title, objective, step, total, target, children, height = 880 }) {
  return (
    <PhoneFrame t={t} nav={false} height={height} bg={t.surface}>
      {/* appbar */}
      <div style={{ display:'flex', alignItems:'center', gap:12, padding:'10px 18px' }}>
        <Icon name="plus" c={t.text} size={22} sw={2.4} style={{ transform:'rotate(45deg)' }} />
        <span style={{ flex:1, textAlign:'center', fontSize:t.z(17), fontWeight:800 }}>{title}</span>
        {target && <span style={{ fontSize:t.z(12.5), fontWeight:800, color:t.primary,
          background:t.primarySoft, padding:'4px 9px', borderRadius:9 }}>목표 {target}초</span>}
        <span style={{ fontSize:t.z(15), fontWeight:800, color:t.text }}>{step}/{total}</span>
      </div>
      {/* progress */}
      <div style={{ height:6, background:t.primarySoft }}>
        <div style={{ width:`${step/total*100}%`, height:'100%', background:t.primary }} /></div>
      {/* objective + body */}
      <div style={{ flex:1, overflow:'hidden', padding:'24px 22px', display:'flex', flexDirection:'column' }}>
        <div style={{ background:t.primarySoft, borderRadius:t.r(16), padding:18, textAlign:'center',
          fontSize:t.z(15.5), fontWeight:600, color:t.text, lineHeight:1.5 }}>{objective}</div>
        <div style={{ flex:1, display:'flex', flexDirection:'column', marginTop:26 }}>{children}</div>
      </div>
    </PhoneFrame>
  );
}

/* ════════ 17. 범주화 훈련 ════════ */
function GameCategorize({ t }) {
  return (
    <GameShell t={t} title="범주화 훈련" objective="다음 단어는 어느 분류에 속하나요?" step={3} total={5} height={880}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center' }}>
        <div style={{ padding:'26px 44px', background:t.primarySoft, borderRadius:t.r(24),
          border:`2px solid ${t.primary}33`, marginBottom:48 }}>
          <span style={{ fontSize:t.z(44), fontWeight:900, color:t.primary }}>고등어</span></div>
        <div style={{ width:'100%', display:'flex', flexDirection:'column', gap:16 }}>
          {[['육류',false],['어류',true],['곡류',false]].map(([l,on])=>(
            <div key={l} style={{ height:72, display:'flex', alignItems:'center', justifyContent:'center',
              fontSize:t.z(21), fontWeight:800, borderRadius:t.r(16),
              background: on?t.good+'18':t.surface, color: on?t.good:t.text,
              border:`2px solid ${on?t.good:t.line}` }}>{l}{on && <Icon name="check" c={t.good} size={22} sw={3} style={{ marginLeft:10 }} />}</div>
          ))}
        </div>
      </div>
    </GameShell>
  );
}

/* ════════ 18. 규칙 찾아보기 (수열) ════════ */
function GameSequence({ t }) {
  const seq = [3,7,'?',15,19];
  return (
    <GameShell t={t} title="규칙 찾아보기" objective="물음표(?)에 들어갈 알맞은 숫자를 고르세요." step={2} total={5} target="8.0" height={880}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', flex:1 }}>
        <div style={{ display:'flex', gap:10, justifyContent:'center' }}>
          {seq.map((n,i)=>{ const q=n==='?'; return (
            <div key={i} style={{ width:60, height:60, display:'flex', alignItems:'center', justifyContent:'center',
              fontSize:t.z(24), fontWeight:900, borderRadius:t.r(13),
              background: q?t.primarySoft:t.surface, color: q?t.primary:t.text,
              border:`2px solid ${q?t.primary:t.line}` }}>{n}</div>); })}
        </div>
        <Icon name="chevron" c={t.textFaint} size={34} style={{ transform:'rotate(90deg)', margin:'18px 0 30px' }} />
        <div style={{ width:'100%', display:'grid', gridTemplateColumns:'1fr 1fr', gap:16 }}>
          {[11,9,13,8].map((o,i)=>(
            <div key={i} style={{ height:64, display:'flex', alignItems:'center', justifyContent:'center',
              fontSize:t.z(22), fontWeight:800, borderRadius:t.r(13),
              background: i===0?t.primary:t.surface, color: i===0?'#fff':t.text,
              border:`1.5px solid ${i===0?t.primary:t.line}`, boxShadow: i===0?t.shadow:t.cardShadow }}>{o}</div>
          ))}
        </div>
      </div>
    </GameShell>
  );
}

/* ════════ 19. 그림 스도쿠 ════════ */
function Weather({ kind, c, size = 40 }) {
  const P = { fill:'none', stroke:c, strokeWidth:2.2, strokeLinecap:'round', strokeLinejoin:'round' };
  const m = {
    sun: <g {...P}><circle cx="12" cy="12" r="4.5"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/></g>,
    cloud: <path {...P} d="M7 18h9a4 4 0 0 0 0-8 5 5 0 0 0-9.7-1.5A3.5 3.5 0 0 0 7 18z"/>,
    umbrella: <g {...P}><path d="M12 3a9 9 0 0 1 9 9H3a9 9 0 0 1 9-9z"/><path d="M12 12v7a2 2 0 0 0 4 0"/></g>,
    waves: <g {...P}><path d="M2 8c2-2 4-2 6 0s4 2 6 0 4-2 6 0M2 14c2-2 4-2 6 0s4 2 6 0 4-2 6 0"/></g>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24">{m[kind]}</svg>;
}
function GameSudoku({ t }) {
  // 3x3, ? at [1][2]
  const grid = [['sun','cloud','umbrella'],['cloud','umbrella','?'],['umbrella','sun','cloud']];
  return (
    <GameShell t={t} title="그림 스도쿠" objective={"가로, 세로에 겹치지 않게\n물음표(?)에 들어올 알맞은 그림을 찾으세요."} step={3} total={5} height={920}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', flex:1 }}>
        <div style={{ display:'inline-flex', alignItems:'center', gap:7, background:t.primarySoft,
          padding:'6px 14px', borderRadius:20, marginBottom:22 }}>
          <Icon name="clock" c={t.primary} size={15} />
          <span style={{ fontSize:t.z(12.5), fontWeight:800, color:t.primary }}>권장 시간: 6.0초</span></div>
        {/* grid */}
        <div style={{ background:t.surface, borderRadius:t.r(18), padding:10, boxShadow:t.cardShadow,
          border:`1px solid ${t.line}` }}>
          <div style={{ display:'grid', gridTemplateColumns:'repeat(3,72px)', gridTemplateRows:'repeat(3,72px)',
            border:`2px solid ${t.line}` }}>
            {grid.flat().map((cell,i)=>{ const q=cell==='?'; return (
              <div key={i} style={{ display:'flex', alignItems:'center', justifyContent:'center',
                borderRight: (i%3!==2)?`2px solid ${t.line}`:'none', borderBottom:(i<6)?`2px solid ${t.line}`:'none',
                background: q?t.primarySoft:'transparent' }}>
                {q ? <span style={{ fontSize:t.z(34), fontWeight:900, color:t.primary }}>?</span>
                   : <Weather kind={cell} c={t.text} size={40} />}</div>); })}
          </div>
        </div>
        <div style={{ flex:1 }} />
        <div style={{ fontSize:t.z(14.5), fontWeight:800, marginBottom:18 }}>알맞은 그림을 선택하세요</div>
        <div style={{ display:'flex', gap:14, justifyContent:'center' }}>
          {['sun','cloud','umbrella'].map((k,i)=>(
            <div key={k} style={{ width:78, height:78, borderRadius:t.r(16), display:'flex',
              alignItems:'center', justifyContent:'center', background:t.surface,
              border:`2px solid ${i===1?t.primary:t.line}`, boxShadow:i===1?t.shadow:t.cardShadow }}>
              <Weather kind={k} c={t.primary} size={38} /></div>
          ))}
        </div>
      </div>
    </GameShell>
  );
}

/* ════════ 20. 같은 모양 찾기 ════════ */
function ShapeGlyph({ name, c, size = 36, fill }) {
  const P = { fill: fill?c:'none', stroke:c, strokeWidth:2, strokeLinecap:'round', strokeLinejoin:'round' };
  const m = {
    heart: <path {...P} d="M12 20s-7-4.3-7-9.3A3.7 3.7 0 0 1 12 8a3.7 3.7 0 0 1 7 2.7C19 15.7 12 20 12 20z"/>,
    star: <path {...P} d="M12 3l2.6 6.3L21 10l-5 4.3L17.5 21 12 17.3 6.5 21 8 14.3 3 10l6.4-.7z"/>,
    circle: <circle {...P} cx="12" cy="12" r="8"/>,
    square: <rect {...P} x="5" y="5" width="14" height="14" rx="3"/>,
    triangle: <path {...P} d="M12 4l8 15H4z"/>,
    diamond: <path {...P} d="M12 3l8 9-8 9-8-9z"/>,
    hexagon: <path {...P} d="M7 4h10l4 8-4 8H7l-4-8z" transform="scale(0.86) translate(2 2)"/>,
    bolt: <path {...P} d="M13 3L5 13h5l-1 8 8-11h-5z"/>,
    cloud: <path {...P} d="M7 18h9a4 4 0 0 0 0-8 5 5 0 0 0-9.7-1.5A3.5 3.5 0 0 0 7 18z"/>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24">{m[name]}</svg>;
}
function GameShapeMatch({ t }) {
  const opts = ['cloud','star','heart','square','diamond','triangle','bolt','circle','hexagon'];
  const target = 'star';
  return (
    <GameShell t={t} title="같은 모양 찾기" objective="상단에 제시된 도형과 똑같은 모양을 아래에서 찾으세요." step={5} total={10} target="4.0" height={920}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', flex:1, justifyContent:'center' }}>
        <div style={{ padding:34, background:t.surfaceAlt, borderRadius:t.r(28), marginBottom:40 }}>
          <ShapeGlyph name={target} c={t.primary} size={80} /></div>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(3,1fr)', gap:14, width:'100%' }}>
          {opts.map((o,i)=>(
            <div key={i} style={{ aspectRatio:'1', display:'flex', alignItems:'center', justifyContent:'center',
              background:t.surface, borderRadius:t.r(18), border:`1px solid ${t.line}`,
              boxShadow: o===target?t.shadow:t.cardShadow,
              ...(o===target?{outline:`2.5px solid ${t.primary}`, outlineOffset:'-1px'}:{}) }}>
              <ShapeGlyph name={o} c={o===target?t.primary:t.text} size={38} /></div>
          ))}
        </div>
      </div>
    </GameShell>
  );
}

/* ════════ 21. 게임 완료 (결과) ════════ */
function GameDone({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={832} bg={t.surface}>
      <Body pad={32} style={{ display:'flex', flexDirection:'column', flex:1, alignItems:'center', justifyContent:'center' }}>
        <div style={{ position:'relative', marginBottom:14 }}>
          {/* confetti */}
          {[['#FF8E72',-70,-30],['#38C9A6',70,-20],['#FFB74D',-50,40],['#6C5CE7',60,50],['#F2789F',0,-70]].map(([c,x,y],i)=>(
            <span key={i} style={{ position:'absolute', left:'50%', top:'50%', width:11, height:11, borderRadius:3,
              background:c, transform:`translate(${x}px,${y}px) rotate(${i*40}deg)` }} />))}
          <div style={{ width:130, height:130, borderRadius:42, background:t.cat.read+'1F',
            display:'flex', alignItems:'center', justifyContent:'center' }}>
            <Trophy t={t} /></div>
        </div>
        <div style={{ fontSize:t.z(28), fontWeight:900, marginTop:18 }}>훈련 완료!</div>
        <div style={{ fontSize:t.z(16), color:t.textSoft, marginTop:8 }}>참 잘하셨습니다 👏</div>
        <div style={{ marginTop:28, background:t.gradSoft, borderRadius:t.r(20), padding:'22px 40px',
          textAlign:'center', border:`1px solid ${t.line}` }}>
          <div style={{ fontSize:t.z(13.5), color:t.textSoft, fontWeight:700 }}>최종 점수</div>
          <div style={{ fontSize:t.z(46), fontWeight:900, color:t.primary, lineHeight:1.1 }}>80<span style={{ fontSize:t.z(22) }}>점</span></div>
          <div style={{ fontSize:t.z(14), color:t.textSoft, marginTop:4 }}>5문제 중 4문제 정답</div>
        </div>
        <div style={{ display:'flex', gap:12, marginTop:30, width:'100%' }}>
          <div style={{ flex:1, textAlign:'center', padding:'16px', borderRadius:t.r(14),
            border:`1.5px solid ${t.primary}55`, color:t.primary, fontSize:t.z(16), fontWeight:800 }}>다시 풀기</div>
          <div style={{ flex:1.4, textAlign:'center', padding:'16px', borderRadius:t.r(14),
            background:t.primary, color:'#fff', fontSize:t.z(16), fontWeight:800, boxShadow:t.shadow }}>돌아가기</div>
        </div>
      </Body>
    </PhoneFrame>
  );
}
function Trophy({ t }) {
  const c = t.cat.read;
  return (<svg width="66" height="66" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M7 4h10v5a5 5 0 0 1-10 0z" fill={c} fillOpacity="0.18"/>
    <path d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3"/>
    <path d="M12 14v3M9 21h6M10 17h4l-.5 4h-3z" fill={c} fillOpacity="0.18"/>
  </svg>);
}

/* ════════ 22. 음성 평가 ════════ */
function ScreenVoice({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={900} bg={t.surface}>
      <div style={{ display:'flex', alignItems:'center', gap:12, padding:'10px 18px' }}>
        <Icon name="chevron" c={t.text} size={22} sw={2.4} style={{ transform:'rotate(180deg)' }} />
        <span style={{ flex:1, textAlign:'center', fontSize:t.z(17), fontWeight:800 }}>초기 음성 진단</span>
        <span style={{ width:22 }} />
      </div>
      <Body pad={32} style={{ display:'flex', flexDirection:'column', flex:1, alignItems:'center' }}>
        <div style={{ marginTop:18, textAlign:'center' }}>
          <div style={{ fontSize:t.z(22), fontWeight:800, lineHeight:1.5, letterSpacing:'-0.01em' }}>
            최근 가장 행복했던 기억에 대해<br/>1분간 자유롭게 이야기해주세요.</div>
          <div style={{ fontSize:t.z(14), color:t.textSoft, marginTop:14, lineHeight:1.5 }}>
            AI가 발화 속도와 어휘 다양성을 분석하여<br/>인지 건강 상태를 체크합니다.</div>
        </div>

        {/* mic visualizer */}
        <div style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center' }}>
          <div style={{ position:'relative', width:220, height:220, display:'flex', alignItems:'center', justifyContent:'center' }}>
            <div style={{ position:'absolute', width:200, height:200, borderRadius:'50%', background:t.primary+'10' }} />
            <div style={{ position:'absolute', width:160, height:160, borderRadius:'50%', background:t.primary+'14' }} />
            <div style={{ width:130, height:130, borderRadius:'50%', background:t.primarySoft,
              border:`2px solid ${t.primary}33`, display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Icon name="voice" c={t.primary} size={56} /></div>
          </div>
        </div>

        {/* live transcript */}
        <div style={{ width:'100%', background:t.surfaceAlt, borderRadius:t.r(14), padding:'14px 16px',
          textAlign:'center', fontSize:t.z(13.5), color:t.textSoft, marginBottom:18, lineHeight:1.5 }}>
          "작년 봄에 가족들과 제주도로 여행을 갔던 게 가장 행복했어요…"</div>

        {/* record button */}
        <div style={{ width:'100%', height:68, borderRadius:t.r(20), background:t.primary, color:'#fff',
          display:'flex', alignItems:'center', justifyContent:'center', gap:12, fontSize:t.z(18), fontWeight:800, boxShadow:t.shadow }}>
          <Icon name="play" c="#fff" size={22} fill />녹음 시작하기</div>
        <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:14 }}>아래 버튼을 눌러 시작하세요</div>
      </Body>
    </PhoneFrame>
  );
}

Object.assign(window, {
  GameCategorize, GameSequence, GameSudoku, GameShapeMatch, GameDone, ScreenVoice,
});
