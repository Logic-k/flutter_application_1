// ml-screens.jsx — MemoryLink redesigned screens (both directions via theme `t`).
// Each screen is a full PhoneFrame. `variant` is 'A' (Lavender Calm) or 'B' (Clinical Trust).
const { PhoneFrame, Icon, Mascot, Senior, Card, IconTile, Badge, Progress,
  SectionTitle, Body, AppBar, RoundBtn, AreaChart, BarChart, Ring } = window;

const won = (n) => n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');

/* ════════════════════════  1. HOME / 홈  ════════════════════════ */
function ScreenHome({ t, variant }) {
  const A = variant === 'A';
  return (
    <PhoneFrame t={t} nav navActive="home" height={1080}>
      <AppBar t={t} title="MemoryLink" right={<>
        <RoundBtn t={t} name="bell" /><RoundBtn t={t} name="gear" /></>} />
      <Body>
        {/* Greeting hero */}
        <div style={{ background:t.grad, borderRadius:t.r(t.radius+2), padding:'22px 22px 20px',
          color:'#fff', boxShadow:t.shadow, position:'relative', overflow:'hidden', marginTop:4 }}>
          {t.mascot && <div style={{ position:'absolute', right:14, top:14, opacity:0.95 }}>
            <Mascot t={{...t, primary:'#fff', primarySoft:'rgba(255,255,255,0.22)'}} size={58} /></div>}
          <div style={{ fontSize:t.z(13.5), fontWeight:600, opacity:0.85 }}>5월 21일 수요일</div>
          <div style={{ fontSize:t.z(23), fontWeight:800, lineHeight:1.3, marginTop:6 }}>안녕하세요,<br/>김민수님!</div>
          <div style={{ height:1, background:'rgba(255,255,255,0.22)', margin:'16px 0 14px' }} />
          <div style={{ display:'flex', gap:14 }}>
            <HeroStat t={t} icon="walk" label="오늘 걸음" value="7,372보" prog={0.73} />
            <div style={{ width:1, background:'rgba(255,255,255,0.22)' }} />
            <HeroStat t={t} icon="brain" label="훈련 현황" value="오늘 2개" />
          </div>
        </div>

        {/* Memory garden link */}
        <div style={{ marginTop:16, background:t.gradSoft, borderRadius:t.r(t.radius), padding:16,
          border:`1px solid ${t.line}`, display:'flex', alignItems:'center', gap:16 }}>
          <Ring t={t} value={0.62} size={62} stroke={7} color={t.cat.mem}>
            <Icon name="flower" c={t.cat.mem} size={24} />
          </Ring>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:t.z(16.5), fontWeight:800 }}>나의 기억의 정원</div>
            <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:3 }}>정성과 노력으로 정원을 가꾸어보세요</div>
          </div>
          <Icon name="chevron" c={t.textFaint} size={20} />
        </div>

        {/* Recommended training */}
        <div style={{ marginTop:24 }}>
          <SectionTitle t={t} right={<span style={{ fontSize:t.z(13.5), fontWeight:700, color:t.primary }}>전체보기</span>}>오늘의 추천 훈련</SectionTitle>
          <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
            <TrainRow t={t} name="calc" color={t.cat.calc} title="누가 큰가요?" desc="수식 비교로 판단력 향상" />
            <TrainRow t={t} name="logic" color={t.cat.logic} title="규칙 찾아보기" desc="수열 패턴으로 논리력 강화" />
          </div>
        </div>

        {/* Brain health */}
        <div style={{ marginTop:24 }}>
          <Card t={t} pad={20}>
            <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:16 }}>
              <Icon name="sparkle" c={t.primary} size={20} />
              <span style={{ fontSize:t.z(16.5), fontWeight:800, color:t.primary }}>두뇌 건강 분석</span>
            </div>
            {[['기억력',82,t.cat.mem],['집중력',64,t.cat.calc],['계산력',73,t.cat.read],['논리력',58,t.cat.logic]].map(([l,v,c])=>(
              <div key={l} style={{ marginBottom:13 }}>
                <div style={{ display:'flex', justifyContent:'space-between', marginBottom:7 }}>
                  <span style={{ fontSize:t.z(14.5), fontWeight:700 }}>{l}</span>
                  <span style={{ fontSize:t.z(13.5), fontWeight:800, color:c }}>{v}점</span>
                </div>
                <Progress t={t} value={v/100} color={c} h={9} />
              </div>
            ))}
            <div style={{ fontSize:t.z(13), color:t.primary, marginTop:4 }}>꾸준한 훈련으로 뇌 건강이 유지되고 있습니다!</div>
          </Card>
        </div>
      </Body>
    </PhoneFrame>
  );
}
function HeroStat({ t, icon, label, value, prog }) {
  return (
    <div style={{ flex:1 }}>
      <div style={{ display:'flex', alignItems:'center', gap:6, opacity:0.85 }}>
        <Icon name={icon} c="#fff" size={15} /><span style={{ fontSize:t.z(12.5) }}>{label}</span>
      </div>
      <div style={{ fontSize:t.z(17), fontWeight:800, marginTop:4 }}>{value}</div>
      {prog!=null && <div style={{ height:4, borderRadius:4, background:'rgba(255,255,255,0.3)', marginTop:7, overflow:'hidden' }}>
        <div style={{ width:`${prog*100}%`, height:'100%', background:'#fff', borderRadius:4 }} /></div>}
    </div>
  );
}
function TrainRow({ t, name, color, title, desc }) {
  return (
    <Card t={t} pad={14} style={{ display:'flex', alignItems:'center', gap:14 }}>
      <IconTile t={t} name={name} color={color} size={50} />
      <div style={{ flex:1 }}>
        <div style={{ fontSize:t.z(16), fontWeight:800 }}>{title}</div>
        <div style={{ fontSize:t.z(13), color:t.textSoft, marginTop:2 }}>{desc}</div>
      </div>
      <div style={{ background:color, color:'#fff', fontSize:t.z(15), fontWeight:800,
        padding:'10px 18px', borderRadius:t.r(13) }}>시작</div>
    </Card>
  );
}

/* ════════════════════════  2. TRAINING HUB / 인지훈련  ════════════════════════ */
const HUB_CATS = [
  { title:'계산 및 판단력', key:'calc', games:[
    { n:'calc', t:'누가 큰가요?', d:'빠른 수식 비교', lv:3, k:'calc' },
    { n:'mult', t:'구구단 맞추기', d:'기초 연산 훈련', lv:2, k:'mult' }]},
  { title:'논리 및 추론', key:'logic', games:[
    { n:'logic', t:'규칙 찾아보기', d:'수열 패턴 파악', lv:4, k:'logic' }]},
  { title:'기억 및 지각', key:'mem', games:[
    { n:'puzzle', t:'그림 스도쿠', d:'위치 기억 및 배치', lv:3, k:'mem' },
    { n:'grid', t:'범주화 훈련', d:'기억 구조화 연습', lv:2, k:'cat2' },
    { n:'shapes', t:'같은 모양 찾기', d:'순간 포착 능력', lv:4, k:'perc' }]},
  { title:'스마트 케어', key:'care', games:[
    { n:'heart', t:'일상 회상 훈련', d:'오늘의 기억 떠올리기', lv:1, k:'care' },
    { n:'voice', t:'문장 읽기 훈련', d:'소리 내어 정확히 읽기', lv:2, k:'read' }]},
];
function ScreenHub({ t, variant }) {
  return (
    <PhoneFrame t={t} nav navActive="brain" height={1360}>
      <AppBar t={t} title="두뇌 트레이닝 센터" right={<RoundBtn t={t} name="info" />} />
      <Body>
        {/* progress banner */}
        <div style={{ background:t.grad, borderRadius:t.r(t.radius), padding:20, color:'#fff', boxShadow:t.shadow, marginTop:4 }}>
          <div style={{ display:'flex', alignItems:'center', gap:8 }}>
            <Icon name="brain" c="#fff" size={20} />
            <span style={{ fontSize:t.z(17.5), fontWeight:800 }}>오늘의 인지훈련</span>
          </div>
          <div style={{ fontSize:t.z(13.5), opacity:0.85, marginTop:6 }}>매일 3가지 게임으로 뇌 건강을 지키세요.</div>
          <div style={{ display:'flex', alignItems:'center', gap:12, marginTop:16 }}>
            <div style={{ flex:1, height:8, borderRadius:8, background:'rgba(255,255,255,0.28)', overflow:'hidden' }}>
              <div style={{ width:'62%', height:'100%', background:'#fff', borderRadius:8 }} /></div>
            <span style={{ fontSize:t.z(13), fontWeight:800 }}>종합 62%</span>
          </div>
        </div>
        {HUB_CATS.map(cat => (
          <div key={cat.key} style={{ marginTop:24 }}>
            <div style={{ display:'flex', alignItems:'center', gap:9, marginBottom:13,
              padding:'7px 12px', borderRadius:t.r(10), background:t.cat[cat.key]+'14',
              borderLeft:`4px solid ${t.cat[cat.key]}` }}>
              <span style={{ fontSize:t.z(16.5), fontWeight:800, color:t.cat[cat.key] }}>{cat.title}</span>
            </div>
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
              {cat.games.map(g => <GameCard key={g.t} t={t} g={g} />)}
            </div>
          </div>
        ))}
      </Body>
    </PhoneFrame>
  );
}
function GameCard({ t, g }) {
  const c = t.cat[g.k];
  return (
    <Card t={t} pad={16} style={{ display:'flex', flexDirection:'column' }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start' }}>
        <IconTile t={t} name={g.n} color={c} size={48} />
        <Badge t={t} color={t.textSoft}>Lv.{g.lv}</Badge>
      </div>
      <div style={{ fontSize:t.z(15.5), fontWeight:800, marginTop:12 }}>{g.t}</div>
      <div style={{ fontSize:t.z(12.5), color:t.textSoft, marginTop:3, minHeight:t.z(17) }}>{g.d}</div>
      <div style={{ display:'flex', alignItems:'center', gap:8, marginTop:12 }}>
        <div style={{ flex:1 }}><Progress t={t} value={g.lv/10} color={c} h={6} /></div>
        <span style={{ fontSize:t.z(11.5), fontWeight:800, color:c }}>{g.lv*10}%</span>
      </div>
    </Card>
  );
}

/* ════════════════════════  3. GAME / 인지 훈련 게임 (vs AI)  ════════════════════════ */
function ScreenGame({ t, variant }) {
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <div style={{ display:'flex', alignItems:'center', gap:14, padding:'10px 22px' }}>
        <Icon name="chevron" c={t.textSoft} size={22} sw={2.4} style={{ transform:'rotate(180deg)' }} />
        <span style={{ flex:1, textAlign:'center', fontSize:t.z(18), fontWeight:800 }}>누가 더 강할까?</span>
        <span style={{ fontSize:t.z(15), fontWeight:800, color:t.primary }}>1/5</span>
      </div>
      <Body pad={22}>
        <div style={{ background:t.primarySoft, borderRadius:t.r(t.radius), padding:'16px 18px',
          display:'flex', gap:12, alignItems:'center', marginTop:4 }}>
          <Icon name="sparkle" c={t.primary} size={22} />
          <span style={{ fontSize:t.z(14.5), fontWeight:600, color:t.primary, lineHeight:1.4 }}>
            오늘 AI와 점수를 비교해보세요.<br/>더 높은 점수를 목표로 도전해요!</span>
        </div>

        <Card t={t} pad={24} style={{ marginTop:18 }}>
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-around' }}>
            <VsSide t={t} who="나의 점수" score={19} mascot />
            <span style={{ fontSize:t.z(20), fontWeight:900, color:t.textFaint }}>VS</span>
            <VsSide t={t} who="AI 점수" score={17} />
          </div>
          <div style={{ textAlign:'center', marginTop:22, padding:'12px', background:t.surfaceAlt,
            borderRadius:t.r(14), fontSize:t.z(14.5), fontWeight:700, color:t.textSoft }}>
            ✦ ✦ ✦  좋은 시작이에요!  ✦ ✦ ✦</div>
        </Card>

        {/* a sample question to make it feel like a real game */}
        <div style={{ marginTop:18 }}>
          <div style={{ textAlign:'center', fontSize:t.z(15), fontWeight:700, color:t.textSoft, marginBottom:14 }}>다음 중 더 큰 값은?</div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:14 }}>
            {['37 + 48','9 × 9'].map((q,i)=>(
              <div key={q} style={{ background: i===0? t.primary : t.surface, color: i===0?'#fff':t.text,
                border:`1px solid ${i===0?t.primary:t.line}`, borderRadius:t.r(20), padding:'26px 0',
                textAlign:'center', fontSize:t.z(28), fontWeight:800, boxShadow:i===0?t.shadow:t.cardShadow }}>{q}</div>
            ))}
          </div>
        </div>

        <div style={{ marginTop:24, background:t.primary, color:'#fff', borderRadius:t.r(18),
          padding:'17px', textAlign:'center', fontSize:t.z(17), fontWeight:800, boxShadow:t.shadow }}>다음 훈련</div>
      </Body>
    </PhoneFrame>
  );
}
function VsSide({ t, who, score, mascot }) {
  return (
    <div style={{ textAlign:'center' }}>
      <div style={{ width:62, height:62, borderRadius:20, background:t.primarySoft, margin:'0 auto',
        display:'flex', alignItems:'center', justifyContent:'center' }}>
        {mascot ? <Senior t={t} size={54} /> : <Icon name="sparkle" c={t.primary} size={30} />}
      </div>
      <div style={{ fontSize:t.z(13.5), color:t.textSoft, fontWeight:700, marginTop:8 }}>{who}</div>
      <div style={{ fontSize:t.z(34), fontWeight:900, color: mascot?t.primary:t.text, marginTop:2 }}>{score}</div>
    </div>
  );
}

/* ════════════════════════  4. REPORTS / 리포트  ════════════════════════ */
function ScreenReport({ t, variant }) {
  const A = variant === 'A';
  const inds = [
    { l:'계산력', v:0.42, s:'주의', c:t.bad },
    { l:'논리 추론', v:0.66, s:'보통', c:t.warn },
    { l:'시각 기억', v:0.84, s:'양호', c:t.good },
    { l:'집중력', v:0.40, s:'주의', c:t.bad },
  ];
  const trend = [62,58,66,61,70,68,76];
  return (
    <PhoneFrame t={t} nav navActive="report" height={1360}>
      <AppBar t={t} title="주간 분석 리포트" />
      <Body>
        <div style={{ fontSize:t.z(22), fontWeight:800, marginTop:2, marginBottom:16, letterSpacing:'-0.02em' }}>나의 인지 건강 일기</div>

        {/* brain age hero */}
        <div style={{ background:t.grad, borderRadius:t.r(t.radius), padding:22, color:'#fff', boxShadow:t.shadow,
          display:'flex', alignItems:'center', gap:18 }}>
          <Ring t={t} value={0.74} size={92} stroke={9} color="#fff">
            <span style={{ fontSize:t.z(26), fontWeight:900, color:'#fff' }}>85</span>
          </Ring>
          <div>
            <div style={{ fontSize:t.z(13.5), opacity:0.85 }}>나의 기억력 점수</div>
            <div style={{ fontSize:t.z(20), fontWeight:800, marginTop:3 }}>안정 단계</div>
            <div style={{ fontSize:t.z(13.5), opacity:0.9, marginTop:4 }}>지난 주보다 <b>+5점</b> 향상했어요 🎉</div>
          </div>
        </div>

        {/* indicators */}
        <Card t={t} pad={20} style={{ marginTop:18 }}>
          <div style={{ fontSize:t.z(17), fontWeight:800 }}>영역별 인지 지표</div>
          <div style={{ fontSize:t.z(12.5), color:t.textSoft, marginTop:4, marginBottom:18 }}>각 게임을 통해 측정된 현재의 건강 상태입니다.</div>
          {inds.map(ind => (
            <div key={ind.l} style={{ marginBottom:18 }}>
              <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:9 }}>
                <span style={{ fontSize:t.z(14.5), fontWeight:700 }}>{ind.l}</span>
                <div style={{ display:'flex', alignItems:'center', gap:6, background:ind.c+'1F',
                  border:`1px solid ${ind.c}40`, borderRadius:11, padding:'3px 10px' }}>
                  <span style={{ width:8, height:8, borderRadius:8, background:ind.c }} />
                  <span style={{ fontSize:t.z(12.5), fontWeight:800, color:ind.c }}>{ind.s}</span>
                </div>
              </div>
              <Progress t={t} value={ind.v} color={ind.c} h={12} />
            </div>
          ))}
        </Card>

        {/* trend chart */}
        <Card t={t} pad={20} style={{ marginTop:18 }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:18 }}>
            <span style={{ fontSize:t.z(16), fontWeight:800 }}>인지 훈련 점수 추이</span>
            <Icon name="info" c={t.textFaint} size={17} />
          </div>
          {t.chart === 'area'
            ? <AreaChart t={t} data={trend} color={t.primary} w={300} h={130} labels={['월','화','수','목','금','토','일']} />
            : <BarChart t={t} data={trend} color={t.primary} w={300} h={130} goal={100} labels={['월','화','수','목','금','토','일']} />}
        </Card>

        {/* AI summary */}
        <div style={{ marginTop:18, background:t.gradSoft, borderRadius:t.r(t.radius), padding:20, border:`1px solid ${t.line}` }}>
          <div style={{ display:'flex', alignItems:'center', gap:10 }}>
            <Icon name="sparkle" c={t.primary} size={20} />
            <span style={{ fontSize:t.z(16.5), fontWeight:800, color:t.primary }}>AI 분석 요약</span>
          </div>
          <div style={{ fontSize:t.z(14), lineHeight:1.7, marginTop:12, color:t.text }}>
            이번 주 시각 기억 영역이 꾸준히 향상되었어요. 다만 계산력과 집중력은 조금 주의가 필요합니다. 가벼운 연산 게임을 매일 5분씩 해보세요.</div>
          <div style={{ height:1, background:t.line, margin:'16px 0' }} />
          <div style={{ fontSize:t.z(14), fontWeight:800, marginBottom:10 }}>다음 주 권고 사항</div>
          {['누가 큰가요? 매일 1회 진행','하루 6,000보 이상 걷기','충분한 수면 (7시간 이상)'].map(r=>(
            <div key={r} style={{ display:'flex', alignItems:'center', gap:9, marginBottom:9 }}>
              <Icon name="check" c={t.good} size={17} sw={2.4} />
              <span style={{ fontSize:t.z(13.5) }}>{r}</span>
            </div>
          ))}
        </div>

        <div style={{ marginTop:18, background:t.primary, color:'#fff', borderRadius:t.r(16), padding:'16px',
          display:'flex', alignItems:'center', justifyContent:'center', gap:9, fontSize:t.z(16), fontWeight:800, boxShadow:t.shadow }}>
          <Icon name="doc" c="#fff" size={20} />임상 리포트 생성하기</div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════════════════════  5. WALKING / 생활습관  ════════════════════════ */
function ScreenWalk({ t, variant }) {
  const week = [5200,7100,4800,9300,6400,8100,7372];
  return (
    <PhoneFrame t={t} nav navActive="walk" height={1300}>
      <AppBar t={t} title="생활습관" right={<RoundBtn t={t} name="clock" />} />
      <Body>
        {/* big gauge */}
        <Card t={t} pad={28} style={{ textAlign:'center', marginTop:4 }}>
          <div style={{ display:'flex', justifyContent:'center' }}>
            <Ring t={t} value={0.74} size={194} stroke={17} color={t.primary}>
              <div style={{ fontSize:t.z(42), fontWeight:900, lineHeight:1 }}>7,372</div>
              <div style={{ fontSize:t.z(14), color:t.textSoft, fontWeight:700, marginTop:6 }}>/ 10,000 보</div>
            </Ring>
          </div>
          <div style={{ display:'inline-block', marginTop:18, background:t.primarySoft, color:t.primary,
            fontSize:t.z(14), fontWeight:800, padding:'9px 18px', borderRadius:13 }}>목표 달성이 코앞이에요! 🎉</div>
        </Card>

        {/* precise analysis CTA */}
        <div style={{ marginTop:18, background:t.grad, borderRadius:t.r(t.radius), padding:22, color:'#fff',
          boxShadow:t.shadow, display:'flex', alignItems:'center', gap:14 }}>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:t.z(17.5), fontWeight:800 }}>보행 정밀 분석</div>
            <div style={{ fontSize:t.z(13), opacity:0.88, marginTop:5, lineHeight:1.45 }}>3분간의 걸음으로 당신의 뇌 건강 패턴을 분석합니다.</div>
          </div>
          <div style={{ width:42, height:42, borderRadius:21, background:'rgba(255,255,255,0.18)',
            display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="chevron" c="#fff" size={18} /></div>
        </div>

        {/* today metrics */}
        <div style={{ marginTop:24 }}>
          <SectionTitle t={t}>오늘의 성과</SectionTitle>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
            <MetricCard t={t} label="걸음 수" value="7,372" unit="걸음" color={t.cat.read} icon="walk" />
            <MetricCard t={t} label="이동 거리" value="5.12" unit="km" color={t.cat.calc} icon="map" />
            <MetricCard t={t} label="소모 칼로리" value="242" unit="kcal" color={t.bad} icon="fire" />
            <MetricCard t={t} label="활동 시간" value="64" unit="분" color={t.good} icon="clock" />
          </div>
        </div>

        {/* weekly chart */}
        <div style={{ marginTop:24 }}>
          <SectionTitle t={t} right={<span style={{ fontSize:t.z(13.5), fontWeight:700, color:t.primary }}>상세보기</span>}>주간 활동 추이</SectionTitle>
          <Card t={t} pad={20} soft>
            {t.chart === 'area'
              ? <AreaChart t={t} data={week} color={t.primary} w={300} h={140} labels={['월','화','수','목','금','토','일']} />
              : <BarChart t={t} data={week} color={t.primary} w={300} h={140} goal={10000} labels={['월','화','수','목','금','토','일']} />}
          </Card>
        </div>
      </Body>
    </PhoneFrame>
  );
}
function MetricCard({ t, label, value, unit, color, icon }) {
  return (
    <div style={{ background:color+'10', border:`1px solid ${color}22`, borderRadius:t.r(16), padding:16 }}>
      <div style={{ display:'flex', alignItems:'center', gap:7 }}>
        <Icon name={icon} c={color} size={18} />
        <span style={{ fontSize:t.z(13), fontWeight:800, color:color }}>{label}</span>
      </div>
      <div style={{ display:'flex', alignItems:'baseline', gap:4, marginTop:10 }}>
        <span style={{ fontSize:t.z(22), fontWeight:900 }}>{value}</span>
        <span style={{ fontSize:t.z(12.5), color:t.textSoft }}>{unit}</span>
      </div>
    </div>
  );
}

/* ════════════════════════  6. PROFILE / 내정보  ════════════════════════ */
function ScreenProfile({ t, variant }) {
  return (
    <PhoneFrame t={t} nav navActive="me" height={1360}>
      <AppBar t={t} title="내 정보" right={<RoundBtn t={t} name="gear" />} />
      <Body>
        {/* header card */}
        <Card t={t} pad={20} style={{ display:'flex', alignItems:'center', gap:16, marginTop:4 }}>
          <div style={{ width:72, height:72, borderRadius:24, background:t.primarySoft, overflow:'hidden',
            display:'flex', alignItems:'flex-end', justifyContent:'center' }}><Senior t={t} size={68} /></div>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:t.z(21), fontWeight:800 }}>김민수님</div>
            <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:3 }}>65세 · 남성</div>
            <div style={{ display:'inline-block', marginTop:9, fontSize:t.z(12.5), fontWeight:700, color:t.primary,
              border:`1.5px solid ${t.primary}55`, borderRadius:11, padding:'5px 12px' }}>프로필 수정</div>
          </div>
        </Card>

        <Group t={t} title="건강 정보">
          <Card t={t} pad={4}>
            <InfoRow t={t} icon="cal" label="나이" value="65 세" />
            <InfoRow t={t} icon="weight" label="몸무게" value="68.5 kg" line />
            <InfoRow t={t} icon="blood" label="혈액형" value="A형" line />
            <InfoRow t={t} icon="pill" label="복용 약물" value="1종" line />
            <InfoRow t={t} icon="bell" label="비상 연락처" value="등록됨" line />
          </Card>
        </Group>

        <Group t={t} title="가족 및 연결">
          <Card t={t} pad={0}>
            <LinkRow t={t} icon="family" color={t.cat.calc} title="보호자 안심 연결" sub="보호자가 활동 상태를 확인할 수 있습니다." />
          </Card>
        </Group>

        <Group t={t} title="앱 설정">
          <Card t={t} pad={0}>
            <LinkRow t={t} icon="text" color={t.primary} title="글자 크기 설정" right="보통" />
            <LinkRow t={t} icon="voice" color={t.primary} title="음성 안내" sub="핵심 정보를 읽어줍니다." toggle line />
            <LinkRow t={t} icon="vibrate" color={t.primary} title="진동 피드백" sub="버튼 클릭 시 진동 반응." toggle on line />
            <LinkRow t={t} icon="moon" color={t.primary} title="다크 모드" toggle line />
          </Card>
        </Group>

        <Group t={t} title="데이터 관리">
          <Card t={t} pad={0}>
            <LinkRow t={t} icon="reset" color={t.warn} title="측정 데이터 초기화" sub="인지 점수 및 기록만 삭제됩니다." titleColor={t.warn} />
            <LinkRow t={t} icon="logout" color={t.bad} title="로그아웃" titleColor={t.bad} line />
          </Card>
        </Group>
        <div style={{ textAlign:'center', fontSize:t.z(12.5), color:t.textFaint, marginTop:18 }}>MemoryLink v1.0.0</div>
      </Body>
    </PhoneFrame>
  );
}
function Group({ t, title, children }) {
  return <div style={{ marginTop:22 }}>
    <div style={{ fontSize:t.z(15), fontWeight:800, marginBottom:11, color:t.text }}>{title}</div>{children}</div>;
}
function InfoRow({ t, icon, label, value, line }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, padding:'13px 14px',
      borderTop: line?`1px solid ${t.line}`:'none' }}>
      <Icon name={icon} c={t.textSoft} size={20} />
      <span style={{ fontSize:t.z(15), color:t.text }}>{label}</span>
      <span style={{ marginLeft:'auto', fontSize:t.z(15), fontWeight:700 }}>{value}</span>
    </div>
  );
}
function LinkRow({ t, icon, color, title, sub, right, toggle, on, line, titleColor }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:13, padding:'14px 16px',
      borderTop: line?`1px solid ${t.line}`:'none' }}>
      <IconTile t={t} name={icon} color={color} size={40} r={t.r(12)} />
      <div style={{ flex:1 }}>
        <div style={{ fontSize:t.z(15), fontWeight:700, color: titleColor||t.text }}>{title}</div>
        {sub && <div style={{ fontSize:t.z(12.5), color:t.textSoft, marginTop:2 }}>{sub}</div>}
      </div>
      {right && <span style={{ fontSize:t.z(13.5), color:t.textSoft, fontWeight:600, marginRight:4 }}>{right}</span>}
      {toggle
        ? <div style={{ width:46, height:27, borderRadius:14, background: on?t.primary:t.line, position:'relative' }}>
            <div style={{ width:21, height:21, borderRadius:11, background:'#fff', position:'absolute', top:3,
              left: on?22:3, boxShadow:'0 1px 3px rgba(0,0,0,0.2)' }} /></div>
        : <Icon name="chevron" c={t.textFaint} size={19} />}
    </div>
  );
}

/* ════════════════════════  7. MEMORY GARDEN / 기억의 정원  ════════════════════════ */
function ScreenGarden({ t, variant }) {
  return (
    <PhoneFrame t={t} nav={false} height={900}
      bg={`linear-gradient(180deg, ${t.cat.mem}22 0%, ${t.bg} 55%)`}>
      <div style={{ display:'flex', alignItems:'center', gap:14, padding:'10px 22px' }}>
        <Icon name="chevron" c={t.text} size={22} sw={2.4} style={{ transform:'rotate(180deg)' }} />
        <span style={{ flex:1, textAlign:'center', fontSize:t.z(18), fontWeight:800 }}>기억의 정원</span>
        <Icon name="voice" c={t.text} size={22} />
      </div>
      <Body pad={24} style={{ display:'flex', flexDirection:'column' }}>
        <div style={{ textAlign:'center', marginTop:6 }}>
          <div style={{ fontSize:t.z(18), fontWeight:800, lineHeight:1.4 }}>따스한 봄볕 아래<br/>정원이 깨어나고 있어요</div>
          <div style={{ fontSize:t.z(13.5), color:t.cat.mem, fontWeight:700, marginTop:8 }}>현재 제철 꽃: 벚꽃 🌸</div>
        </div>

        {/* garden scene illustration */}
        <div style={{ position:'relative', height:300, margin:'10px 0 6px',
          display:'flex', alignItems:'center', justifyContent:'center' }}>
          <GardenArt t={t} />
        </div>

        <Card t={t} pad={22}>
          <GardenBar t={t} label="신체 활동 (걸음 수)" value={0.73} color={t.cat.read} />
          <div style={{ height:18 }} />
          <GardenBar t={t} label="두뇌 훈련 (정답률)" value={0.62} color={t.cat.calc} />
          <div style={{ fontSize:t.z(12.5), color:t.textSoft, marginTop:16, textAlign:'center' }}>
            조금 더 힘내시면 정원의 꽃이 더 활짝 피어납니다!</div>
        </Card>
      </Body>
    </PhoneFrame>
  );
}
function GardenBar({ t, label, value, color }) {
  return (
    <div>
      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:8 }}>
        <span style={{ fontSize:t.z(13.5), fontWeight:800 }}>{label}</span>
        <span style={{ fontSize:t.z(13.5), fontWeight:800, color }}>{Math.round(value*100)}%</span>
      </div>
      <Progress t={t} value={value} color={color} h={12} />
    </div>
  );
}
function GardenArt({ t }) {
  return (
    <svg width="280" height="280" viewBox="0 0 280 280">
      <circle cx="140" cy="140" r="120" fill="#fff" opacity="0.45" />
      <ellipse cx="140" cy="232" rx="110" ry="20" fill={t.cat.mem} opacity="0.16" />
      {/* pot */}
      <path d="M104 196h72l-9 40a8 8 0 0 1-8 7h-38a8 8 0 0 1-8-7z" fill={t.cat.read} />
      <rect x="100" y="186" width="80" height="16" rx="6" fill={t.cat.read} opacity="0.85" />
      {/* stem + leaves */}
      <path d="M140 196c0-30-2-54 0-78" stroke={t.cat.mem} strokeWidth="6" strokeLinecap="round" fill="none" />
      <path d="M140 150c-18-4-30-16-30-32 18 2 30 14 30 32z" fill={t.cat.mem} opacity="0.85" />
      <path d="M140 168c18-4 30-16 30-32-18 2-30 14-30 32z" fill={t.cat.mem} />
      {/* blossoms */}
      {[[140,96],[112,118],[168,118],[124,86],[156,86]].map(([cx,cy],i)=>(
        <g key={i}>
          {[0,72,144,216,288].map(a=>(
            <ellipse key={a} cx={cx} cy={cy-9} rx="7" ry="11" fill="#F8A6C4"
              transform={`rotate(${a} ${cx} ${cy})`} />
          ))}
          <circle cx={cx} cy={cy} r="5" fill={t.cat.read} />
        </g>
      ))}
      {/* sparkles */}
      <path d="M70 80l2 6 6 2-6 2-2 6-2-6-6-2 6-2z" fill={t.primary} opacity="0.6" />
      <path d="M210 100l2 6 6 2-6 2-2 6-2-6-6-2 6-2z" fill={t.primary} opacity="0.5" />
    </svg>
  );
}

/* ════════════════════════  8. LOGIN / ONBOARDING  ════════════════════════ */
function ScreenLogin({ t, variant }) {
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <Body pad={32} style={{ display:'flex', flexDirection:'column' }}>
        <div style={{ textAlign:'center', marginTop:36 }}>
          <div style={{ width:120, height:120, margin:'0 auto', borderRadius:36, background:t.gradSoft,
            display:'flex', alignItems:'center', justifyContent:'center', boxShadow:t.cardShadow }}>
            <Mascot t={t} size={92} />
          </div>
          <div style={{ fontSize:t.z(30), fontWeight:900, marginTop:24, letterSpacing:'-0.02em', color:t.primary }}>MemoryLink</div>
          <div style={{ fontSize:t.z(15), color:t.textSoft, marginTop:8 }}>당신의 소중한 기억을 잇다</div>
        </div>

        <div style={{ marginTop:44, display:'flex', flexDirection:'column', gap:14 }}>
          <Field t={t} icon="user" placeholder="사용자 아이디" />
          <Field t={t} icon="shield" placeholder="비밀번호" />
        </div>

        <div style={{ marginTop:28, background:t.primary, color:'#fff', borderRadius:t.r(18), padding:'18px',
          textAlign:'center', fontSize:t.z(18), fontWeight:800, boxShadow:t.shadow }}>로그인</div>
        <div style={{ textAlign:'center', marginTop:22, fontSize:t.z(14.5), color:t.textSoft }}>
          처음이신가요? <b style={{ color:t.primary }}>회원가입</b></div>

        <div style={{ marginTop:'auto', display:'flex', alignItems:'center', justifyContent:'center', gap:8,
          fontSize:t.z(12.5), color:t.textFaint }}>
          <Icon name="shield" c={t.textFaint} size={15} />개인정보는 안전하게 암호화되어 보호됩니다</div>
      </Body>
    </PhoneFrame>
  );
}
function Field({ t, icon, placeholder }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, background:t.surface, border:`1px solid ${t.line}`,
      borderRadius:t.r(16), padding:'16px 16px' }}>
      <Icon name={icon} c={t.primary} size={21} />
      <span style={{ fontSize:t.z(15.5), color:t.textFaint }}>{placeholder}</span>
    </div>
  );
}

Object.assign(window, {
  ScreenHome, ScreenHub, ScreenGame, ScreenReport, ScreenWalk, ScreenProfile, ScreenGarden, ScreenLogin,
});
