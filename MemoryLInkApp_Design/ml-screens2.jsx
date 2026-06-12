// ml-screens2.jsx — MemoryLink 방향 A 확장 화면 (첫 실행 플로우 + 부가 기능)
const { PhoneFrame, Icon, Mascot, Senior, Card, IconTile, Badge, Progress,
  SectionTitle, Body, AppBar, RoundBtn, AreaChart, Ring } = window;

/* 공통: 닫기/뒤로 헤더 */
function FlowHeader({ t, title, step, onClose }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:14, padding:'10px 20px' }}>
      <Icon name={onClose==='x'?'plus':'chevron'} c={t.text} size={22} sw={2.4}
        style={{ transform: onClose==='x'?'rotate(45deg)':'rotate(180deg)' }} />
      <span style={{ flex:1, textAlign:'center', fontSize:t.z(18), fontWeight:800 }}>{title}</span>
      {step ? <span style={{ fontSize:t.z(14.5), fontWeight:800, color:t.primary }}>{step}</span>
            : <span style={{ width:22 }} />}
    </div>
  );
}

/* ════════════ 09. 온보딩 · 사용 목적 ════════════ */
function ScreenOnboard({ t }) {
  const goals = [
    { ic:'shield', c:t.cat.mem, title:'예방 중심', desc:'현재 건강하지만 미리 예방하고 싶어요.', on:true },
    { ic:'sparkle', c:t.cat.calc, title:'관심 및 우려', desc:'최근 기억력이 걱정되어 확인하고 싶어요.' },
    { ic:'family', c:t.cat.care, title:'가족 관리', desc:'부모님이나 가족의 건강을 챙기고 싶어요.' },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="사용 목적" back />
      <Body pad={24} style={{ display:'flex', flexDirection:'column' }}>
        <div style={{ fontSize:t.z(26), fontWeight:900, lineHeight:1.35, letterSpacing:'-0.02em', marginTop:8 }}>
          앱을 어떻게<br/>활용하고 싶으신가요?</div>
        <div style={{ fontSize:t.z(15), color:t.textSoft, marginTop:10 }}>목적에 맞춰 훈련과 리포트를 맞춤 제안해 드려요.</div>
        <div style={{ display:'flex', flexDirection:'column', gap:14, marginTop:30 }}>
          {goals.map(g => (
            <div key={g.title} style={{ display:'flex', alignItems:'center', gap:16, padding:18,
              background: g.on ? g.c+'12' : t.surface, borderRadius:t.r(20),
              border:`2px solid ${g.on ? g.c : t.line}`, boxShadow: g.on?'none':t.cardShadow }}>
              <IconTile t={t} name={g.ic} color={g.c} size={54} />
              <div style={{ flex:1 }}>
                <div style={{ fontSize:t.z(17), fontWeight:800 }}>{g.title}</div>
                <div style={{ fontSize:t.z(13), color:t.textSoft, marginTop:3, lineHeight:1.4 }}>{g.desc}</div>
              </div>
              {g.on && <div style={{ width:26, height:26, borderRadius:13, background:g.c,
                display:'flex', alignItems:'center', justifyContent:'center' }}>
                <Icon name="check" c="#fff" size={16} sw={3} /></div>}
            </div>
          ))}
        </div>
        <div style={{ marginTop:'auto', background:t.primary, color:'#fff', borderRadius:t.r(18),
          padding:'18px', textAlign:'center', fontSize:t.z(18), fontWeight:800, boxShadow:t.shadow }}>시작하기</div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════════ 10. 회원가입 ════════════ */
function ScreenRegister({ t }) {
  const goals = ['예방','걱정','가족 관리'];
  return (
    <PhoneFrame t={t} nav={false} height={1180}>
      <AppBar t={t} title="회원가입" back />
      <Body pad={26}>
        <div style={{ fontSize:t.z(23), fontWeight:900, marginTop:6, letterSpacing:'-0.02em' }}>기본 정보 입력</div>
        <div style={{ fontSize:t.z(14), color:t.textSoft, marginTop:6 }}>맞춤 훈련을 위해 정보를 입력해 주세요.</div>

        <div style={{ display:'flex', flexDirection:'column', gap:13, marginTop:24 }}>
          <RegField t={t} label="아이디" />
          <RegField t={t} label="비밀번호" dot />
          <RegField t={t} label="비밀번호 확인" dot />
          <div style={{ display:'flex', gap:13 }}>
            <RegField t={t} label="나이 (세)" val="65" flex />
            <RegField t={t} label="체중 (kg)" val="68.5" flex />
          </div>
        </div>

        <div style={{ fontSize:t.z(16), fontWeight:800, marginTop:26, marginBottom:12 }}>관심 분야 선택</div>
        <div style={{ display:'flex', gap:10 }}>
          {goals.map((g,i)=>(
            <div key={g} style={{ flex:1, textAlign:'center', padding:'13px 0', borderRadius:t.r(13),
              fontSize:t.z(15), fontWeight: i===0?800:600,
              background: i===0?t.primary:t.surface, color: i===0?'#fff':t.text,
              border:`1.5px solid ${i===0?t.primary:t.line}` }}>{g}</div>
          ))}
        </div>

        <div style={{ marginTop:24, display:'flex', alignItems:'center', gap:8 }}>
          <span style={{ fontSize:t.z(16), fontWeight:800 }}>선택 정보</span>
          <Badge t={t} color={t.cat.mem}>나중에 입력해도 됩니다</Badge>
          <Icon name="chevron" c={t.textFaint} size={18} style={{ transform:'rotate(90deg)', marginLeft:'auto' }} />
        </div>
        <div style={{ marginTop:14, display:'flex', flexDirection:'column', gap:13 }}>
          <RegField t={t} label="혈액형" icon="blood" val="선택 안 함" faint />
          <RegField t={t} label="복용 약물" icon="pill" val="혈압약, 당뇨약 등" faint />
          <RegField t={t} label="비상 연락처" icon="bell" val="보호자 이름 및 연락처" faint />
        </div>

        <div style={{ marginTop:26, background:t.primary, color:'#fff', borderRadius:t.r(16), padding:'18px',
          textAlign:'center', fontSize:t.z(18), fontWeight:800, boxShadow:t.shadow }}>가입 완료</div>
      </Body>
    </PhoneFrame>
  );
}
function RegField({ t, label, val, dot, icon, faint, flex }) {
  return (
    <div style={{ flex: flex?1:undefined }}>
      <div style={{ fontSize:t.z(13), fontWeight:700, color:t.textSoft, marginBottom:7 }}>{label}</div>
      <div style={{ display:'flex', alignItems:'center', gap:10, background:t.surfaceAlt,
        border:`1px solid ${t.line}`, borderRadius:t.r(14), padding:'14px 14px' }}>
        {icon && <Icon name={icon} c={t.primary} size={19} />}
        <span style={{ fontSize:t.z(15), color: val && !faint ? t.text : t.textFaint,
          fontWeight: val && !faint ? 700:500, letterSpacing: dot?2:0 }}>
          {dot ? '••••••••' : (val || '입력하세요')}</span>
      </div>
    </div>
  );
}

/* ════════════ 11. 자가 체크 설문 ════════════ */
function ScreenSurvey({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <FlowHeader t={t} title="자가 체크 (3/10)" onClose="x" />
      <div style={{ padding:'0 20px' }}>
        <div style={{ height:8, borderRadius:8, background:t.primarySoft, overflow:'hidden' }}>
          <div style={{ width:'30%', height:'100%', background:t.primary, borderRadius:8 }} /></div>
      </div>
      <Body pad={28} style={{ display:'flex', flexDirection:'column', flex:1 }}>
        <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
          <div style={{ marginBottom:32 }}><Mascot t={t} size={80} mood="calm" /></div>
          <div style={{ fontSize:t.z(23), fontWeight:800, textAlign:'center', lineHeight:1.5, letterSpacing:'-0.01em' }}>
            당신의 기억력이<br/>10년 전보다<br/>나빠졌습니까?</div>
        </div>
        <div style={{ display:'flex', gap:14 }}>
          {[['예',true],['아니오',false]].map(([l,yes])=>(
            <div key={l} style={{ flex:1, textAlign:'center', padding:'24px 0', borderRadius:t.r(18),
              fontSize:t.z(19), fontWeight:800,
              background: yes ? t.primary : t.surface, color: yes ? '#fff' : t.text,
              border:`1.5px solid ${yes?t.primary:t.line}`, boxShadow: yes?t.shadow:t.cardShadow }}>{l}</div>
          ))}
        </div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════════ 12. 검사 결과 ════════════ */
function ScreenResult({ t }) {
  const score = 28; // 양호
  const c = t.good;
  return (
    <PhoneFrame t={t} nav={false} height={900}>
      <AppBar t={t} title="검사 결과" />
      <Body pad={28} style={{ display:'flex', flexDirection:'column', flex:1 }}>
        <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
          <div style={{ fontSize:t.z(18), color:t.textSoft, fontWeight:600 }}>현재 나의 인지 건강 상태</div>
          <div style={{ margin:'26px 0' }}>
            <Ring t={t} value={1-score/100} size={210} stroke={16} color={c}>
              <div style={{ fontSize:t.z(52), fontWeight:900, color:c, lineHeight:1 }}>{score}%</div>
              <div style={{ fontSize:t.z(15), fontWeight:800, color:c, marginTop:6 }}>양호</div>
            </Ring>
          </div>
          <div style={{ fontSize:t.z(18), fontWeight:700, textAlign:'center', lineHeight:1.5, padding:'0 6px' }}>
            인지 건강이 매우 양호합니다.<br/>꾸준한 루틴으로 유지해보세요!</div>
        </div>
        <div style={{ display:'flex', gap:11, background:t.warn+'14', border:`1px solid ${t.warn}33`,
          borderRadius:t.r(14), padding:'14px 16px', alignItems:'flex-start' }}>
          <Icon name="info" c={t.warn} size={20} />
          <span style={{ fontSize:t.z(12.5), color:t.textSoft, lineHeight:1.5 }}>
            이 결과는 "의학적 진단"이 아니며 관찰 지표일 뿐입니다. 자세한 진단은 전문의와 상담하세요.</span>
        </div>
        <div style={{ marginTop:16, background:t.primary, color:'#fff', borderRadius:t.r(16), padding:'17px',
          textAlign:'center', fontSize:t.z(17), fontWeight:800, boxShadow:t.shadow }}>홈 화면으로 이동</div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════════ 13. AI 대화 도우미 ════════════ */
function ScreenChat({ t }) {
  const msgs = [
    { ai:true, txt:'안녕하세요, 김민수님! 오늘 하루는 어떻게 보내고 계신가요?' },
    { ai:false, txt:'아침에 공원에 다녀왔어요. 벚꽃이 활짝 폈더라고요.' },
    { ai:true, txt:'산책 다녀오셨군요! 공원에서 어떤 것들이 기억에 남으셨어요?' },
    { ai:false, txt:'연못가에 오리도 있었고, 사람들이 사진을 많이 찍고 있었어요.' },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={900} bg={t.surface}>
      <div style={{ display:'flex', alignItems:'center', gap:12, padding:'10px 18px' }}>
        <Icon name="chevron" c={t.text} size={22} sw={2.4} style={{ transform:'rotate(180deg)' }} />
        <div style={{ width:34, height:34, borderRadius:17, background:t.primarySoft,
          display:'flex', alignItems:'center', justifyContent:'center' }}><Mascot t={t} size={30} /></div>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:t.z(16), fontWeight:800 }}>AI 대화 도우미</div>
          <div style={{ display:'flex', alignItems:'center', gap:5 }}>
            <span style={{ width:7, height:7, borderRadius:7, background:t.good }} />
            <span style={{ fontSize:t.z(11.5), color:t.good, fontWeight:700 }}>Gemini AI 연결됨</span></div>
        </div>
        <span style={{ fontSize:t.z(13.5), fontWeight:700, color:t.primary }}>대화 종료</span>
      </div>
      {/* progress */}
      <div style={{ padding:'4px 18px 10px' }}>
        <div style={{ display:'flex', justifyContent:'space-between', marginBottom:6 }}>
          <span style={{ fontSize:t.z(12), color:t.textSoft, fontWeight:600 }}>대화 진행</span>
          <span style={{ fontSize:t.z(12), color:t.primary, fontWeight:800 }}>4 / 10 턴</span></div>
        <div style={{ height:5, borderRadius:5, background:t.primarySoft, overflow:'hidden' }}>
          <div style={{ width:'40%', height:'100%', background:t.primary, borderRadius:5 }} /></div>
      </div>
      <div style={{ flex:1, overflow:'hidden', padding:'8px 18px', background:t.bg,
        display:'flex', flexDirection:'column', gap:12 }}>
        {msgs.map((m,i)=>(
          <div key={i} style={{ display:'flex', gap:8, alignItems:'flex-end',
            justifyContent: m.ai?'flex-start':'flex-end' }}>
            {m.ai && <div style={{ width:30, height:30, borderRadius:15, background:t.primarySoft, flex:'0 0 30px',
              display:'flex', alignItems:'center', justifyContent:'center' }}><Mascot t={t} size={26} /></div>}
            <div style={{ maxWidth:'74%', padding:'12px 15px', fontSize:t.z(14.5), lineHeight:1.5,
              background: m.ai ? t.surface : t.primary, color: m.ai ? t.text : '#fff',
              border: m.ai?`1px solid ${t.line}`:'none',
              borderRadius:18, borderBottomLeftRadius: m.ai?5:18, borderBottomRightRadius: m.ai?18:5,
              boxShadow: m.ai?t.cardShadow:t.shadow }}>{m.txt}</div>
          </div>
        ))}
      </div>
      {/* input */}
      <div style={{ display:'flex', alignItems:'center', gap:10, padding:'12px 16px', background:t.surface,
        borderTop:`1px solid ${t.line}` }}>
        <div style={{ width:42, height:42, borderRadius:21, background:t.primarySoft,
          display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="voice" c={t.primary} size={21} /></div>
        <div style={{ flex:1, background:t.surfaceAlt, border:`1px solid ${t.line}`, borderRadius:22,
          padding:'13px 16px', fontSize:t.z(14.5), color:t.textFaint }}>메시지를 입력하세요...</div>
        <div style={{ width:44, height:44, borderRadius:22, background:t.primary,
          display:'flex', alignItems:'center', justifyContent:'center', boxShadow:t.shadow }}>
          <Icon name="chevron" c="#fff" size={20} sw={2.6} style={{ transform:'rotate(-90deg)' }} /></div>
      </div>
    </PhoneFrame>
  );
}

/* ════════════ 14. 정밀 보행 분석 ════════════ */
function ScreenGait({ t }) {
  const wave = [0,6,-4,9,-7,5,-9,7,-3,8,-6,4,-8,6,-2,7];
  return (
    <PhoneFrame t={t} nav={false} height={1000}>
      <FlowHeader t={t} title="정밀 보행 분석" onClose="x" />
      <Body pad={24} style={{ display:'flex', flexDirection:'column', flex:1 }}>
        {/* timer header */}
        <Card t={t} pad={22} soft style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginTop:4 }}>
          <div>
            <div style={{ fontSize:t.z(13.5), fontWeight:800, color:t.primary }}>분석 중...</div>
            <div style={{ fontSize:t.z(34), fontWeight:900, marginTop:2, fontVariantNumeric:'tabular-nums' }}>02:14</div>
          </div>
          <div style={{ textAlign:'right' }}>
            <div style={{ fontSize:t.z(13), color:t.textSoft }}>감지된 걸음</div>
            <div style={{ fontSize:t.z(24), fontWeight:800, marginTop:2 }}>186보</div>
          </div>
        </Card>

        {/* dual task toggle */}
        <div style={{ marginTop:16, display:'flex', alignItems:'center', justifyContent:'space-between',
          background:t.cat.read+'12', border:`1px solid ${t.cat.read}30`, borderRadius:t.r(16), padding:'13px 16px' }}>
          <div style={{ display:'flex', alignItems:'center', gap:10 }}>
            <Icon name="sparkle" c={t.cat.read} size={20} />
            <span style={{ fontSize:t.z(14), fontWeight:700 }}>이중 과제 모드 (정밀 진단)</span></div>
          <div style={{ width:46, height:27, borderRadius:14, background:t.cat.read, position:'relative' }}>
            <div style={{ width:21, height:21, borderRadius:11, background:'#fff', position:'absolute', top:3, left:22 }} /></div>
        </div>

        {/* task banner */}
        <div style={{ marginTop:16, background:t.grad, borderRadius:t.r(18), padding:'18px', textAlign:'center', boxShadow:t.shadow }}>
          <div style={{ fontSize:t.z(12), fontWeight:800, color:'rgba(255,255,255,0.85)', letterSpacing:'0.04em' }}>지금 수행할 인지 미션</div>
          <div style={{ fontSize:t.z(19), fontWeight:800, color:'#fff', marginTop:8 }}>100에서 7씩 거꾸로 빼기</div>
        </div>

        {/* live waveform */}
        <Card t={t} pad={18} style={{ marginTop:16, flex:1, display:'flex', flexDirection:'column' }}>
          <div style={{ fontSize:t.z(13.5), fontWeight:800, color:t.primary }}>실시간 보행 파형</div>
          <div style={{ flex:1, display:'flex', alignItems:'center' }}>
            <Wave t={t} data={wave} color={t.primary} />
          </div>
        </Card>

        <div style={{ marginTop:16, background:t.bad, color:'#fff', borderRadius:t.r(16), padding:'17px',
          textAlign:'center', fontSize:t.z(17), fontWeight:800 }}>분석 중지</div>
      </Body>
    </PhoneFrame>
  );
}
function Wave({ t, data, color }) {
  const w=300, h=130, mid=h/2;
  const pts = data.map((v,i)=>[ (i/(data.length-1))*w, mid - v*7 ]);
  let d=`M ${pts[0][0]},${pts[0][1]}`;
  for(let i=0;i<pts.length-1;i++){const[x0,y0]=pts[i],[x1,y1]=pts[i+1];const cx=(x0+x1)/2;d+=` C ${cx},${y0} ${cx},${y1} ${x1},${y1}`;}
  return (<svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} style={{ width:'100%' }}>
    <line x1="0" y1={mid} x2={w} y2={mid} stroke={t.line} strokeWidth="1.5" strokeDasharray="4 4" />
    <path d={d} fill="none" stroke={color} strokeWidth="3.2" strokeLinecap="round" strokeLinejoin="round" />
  </svg>);
}

/* ════════════ 15. 보호자 안심 연결 ════════════ */
function ScreenGuardian({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={1180}>
      <AppBar t={t} title="보호자 안심 연결" back />
      <Body pad={24}>
        <div style={{ textAlign:'center', marginTop:8 }}>
          <div style={{ width:80, height:80, margin:'0 auto', borderRadius:26, background:t.primarySoft,
            display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="shield" c={t.primary} size={40} /></div>
          <div style={{ fontSize:t.z(20), fontWeight:800, marginTop:16 }}>보호자님께 안심을 선물하세요</div>
          <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:8, lineHeight:1.5 }}>
            QR 코드를 스캔하면 앱 설치 없이 어르신의<br/>활동 상태를 실시간으로 확인할 수 있습니다.</div>
        </div>

        {/* sync status */}
        <Card t={t} pad={16} soft style={{ marginTop:22 }}>
          <div style={{ display:'flex', alignItems:'center', gap:8 }}>
            <Icon name="check" c={t.good} size={17} sw={2.4} />
            <span style={{ fontSize:t.z(13), color:t.textSoft, fontWeight:600 }}>3분 전 동기화</span></div>
          <div style={{ marginTop:12, background:t.primary, color:'#fff', borderRadius:t.r(12), padding:'13px',
            textAlign:'center', fontSize:t.z(15), fontWeight:800, display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>
            <Icon name="reset" c="#fff" size={18} />지금 동기화</div>
        </Card>

        {/* QR */}
        <div style={{ marginTop:22, background:'#fff', borderRadius:t.r(24), padding:24, boxShadow:t.cardShadow,
          border:`1px solid ${t.line}`, display:'flex', flexDirection:'column', alignItems:'center' }}>
          <QR t={t} />
          <div style={{ fontSize:t.z(12.5), color:t.textFaint, marginTop:14 }}>보호자 스마트폰으로 스캔</div>
        </div>

        {/* what guardian sees */}
        <Card t={t} pad={20} soft style={{ marginTop:22 }}>
          {[['walk','오늘 걸음 수 및 주간 활동 추이'],['brain','인지 훈련 카테고리별 최신 점수'],
            ['bell','활동량 이상 감지 시 경고 알림'],['clock','마지막 동기화 시각']].map(([ic,tx])=>(
            <div key={tx} style={{ display:'flex', alignItems:'center', gap:12, padding:'8px 0' }}>
              <Icon name={ic} c={t.primary} size={19} />
              <span style={{ fontSize:t.z(14) }}>{tx}</span></div>
          ))}
        </Card>

        <div style={{ display:'flex', gap:12, marginTop:18 }}>
          <OutBtn t={t} icon="bell" label="보호자 전화" />
          <OutBtn t={t} icon="info" label="문자 알림" />
        </div>
        <div style={{ marginTop:12, background:t.primary, color:'#fff', borderRadius:t.r(14), padding:'16px',
          textAlign:'center', fontSize:t.z(16), fontWeight:800, boxShadow:t.shadow }}>링크 공유하기 (카톡 등)</div>
      </Body>
    </PhoneFrame>
  );
}
function OutBtn({ t, icon, label }) {
  return (<div style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center', gap:8,
    border:`1.5px solid ${t.primary}55`, color:t.primary, borderRadius:t.r(14), padding:'14px',
    fontSize:t.z(15), fontWeight:800 }}>
    <Icon name={icon} c={t.primary} size={18} />{label}</div>);
}
function QR({ t }) {
  // stylized QR with rounded modules
  const cells = [
    "1111111011101111111","1000001000101000001","1011101011101011101","1011101000001011101",
    "1011101110101011101","1000001010101000001","1111111010101111111","0000000011100000000",
    "1101011001011010110","0010110110100101001","1110011100111001110","0101100011010110010",
    "1011101110100110101","0000000101110100110","1111111010011011010","1000001011101010011",
    "1011101000111001110","1011101110010110101","1011101011101001011"];
  const n=19, s=190/n;
  return (<svg width="190" height="190" viewBox="0 0 190 190">
    {cells.map((row,y)=>row.split('').map((v,x)=> v==='1' &&
      <rect key={x+'-'+y} x={x*s+0.6} y={y*s+0.6} width={s-1.2} height={s-1.2} rx={s*0.35}
        fill={ (y<7&&x<7)||(y<7&&x>11)||(y>11&&x<7) ? t.primary : t.text } />))}
  </svg>);
}

/* ════════════ 16. 고객센터 ════════════ */
function ScreenCS({ t }) {
  const items = [
    { ic:'bell', c:t.cat.calc, title:'공지사항', desc:'서비스 업데이트 및 안내' },
    { ic:'info', c:t.cat.mem, title:'자주 묻는 질문', desc:'이용 중 궁금한 점 확인' },
    { ic:'text', c:t.cat.care, title:'1:1 문의하기', desc:'직접 문의 접수' },
    { ic:'doc', c:t.cat.read, title:'내 문의 내역', desc:'접수한 문의 및 답변 확인' },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="고객센터" back />
      <Body pad={22}>
        <div style={{ background:t.gradSoft, borderRadius:t.r(t.radius), padding:20, border:`1px solid ${t.line}`,
          display:'flex', alignItems:'center', gap:14, marginTop:4 }}>
          <div style={{ width:54, height:54, borderRadius:18, background:t.surface,
            display:'flex', alignItems:'center', justifyContent:'center', boxShadow:t.cardShadow }}>
            <Icon name="headset" c={t.primary} size={28} /></div>
          <div>
            <div style={{ fontSize:t.z(16.5), fontWeight:800 }}>무엇을 도와드릴까요?</div>
            <div style={{ fontSize:t.z(13), color:t.textSoft, marginTop:3 }}>평일 09:00–18:00 상담 가능</div>
          </div>
        </div>
        <div style={{ display:'flex', flexDirection:'column', gap:12, marginTop:20 }}>
          {items.map(it => (
            <Card t={t} key={it.title} pad={16} style={{ display:'flex', alignItems:'center', gap:14 }}>
              <IconTile t={t} name={it.ic} color={it.c} size={50} />
              <div style={{ flex:1 }}>
                <div style={{ fontSize:t.z(16), fontWeight:800 }}>{it.title}</div>
                <div style={{ fontSize:t.z(13), color:t.textSoft, marginTop:2 }}>{it.desc}</div>
              </div>
              <Icon name="chevron" c={t.textFaint} size={20} />
            </Card>
          ))}
        </div>
      </Body>
    </PhoneFrame>
  );
}

Object.assign(window, {
  ScreenOnboard, ScreenRegister, ScreenSurvey, ScreenResult,
  ScreenChat, ScreenGait, ScreenGuardian, ScreenCS,
});
