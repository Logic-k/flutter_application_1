// ml-screens4.jsx — MemoryLink 방향 A · 잔여 화면 일괄 구현
// 비교 게임(AI 제거) · 구구단 · 문장읽기 · 동의 · 정보수정 · CS 하위 · 기관연계 · 관리자
const { PhoneFrame, Icon, Mascot, Senior, Card, IconTile, Badge, Body, AppBar, RoundBtn, BarChart } = window;
const GameShell = window.GameShell; // ml-screens3.jsx 에서 정의 (런타임에 사용)

/* ════════ 23. 누가 큰가요? (비교 — AI 제거, 좌/우 카드) ════════ */
function GameComparison({ t }) {
  return (
    <window.GameShell t={t} title="누가 큰가요?" objective="더 큰 숫자를 가진 쪽을 터치하세요." step={4} total={10} height={832}>
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
        <div style={{ display:'flex', alignItems:'center', gap:14, width:'100%' }}>
          <CompareCard t={t} expr="37 + 48" />
          <span style={{ fontSize:t.z(22), fontWeight:900, color:t.textFaint }}>VS</span>
          <CompareCard t={t} expr="9 × 9" dim />
        </div>
        <div style={{ marginTop:30, fontSize:t.z(15), color:t.textSoft, fontWeight:600 }}>= 같으면 가운데를 터치 =</div>
      </div>
    </window.GameShell>
  );
}
function CompareCard({ t, expr, dim }) {
  return (
    <div style={{ flex:1, height:180, display:'flex', alignItems:'center', justifyContent:'center',
      background:t.surface, borderRadius:t.r(20), border:`2px solid ${dim?t.line:t.primary}`,
      boxShadow: dim?t.cardShadow:t.shadow }}>
      <span style={{ fontSize:t.z(34), fontWeight:900, color: dim?t.text:t.primary }}>{expr}</span>
    </div>
  );
}

/* ════════ 24. 구구단 맞추기 ════════ */
function GameMultiply({ t }) {
  return (
    <window.GameShell t={t} title="구구단 맞추기" objective="가운데 수식의 정답을 아래에서 선택하세요." step={6} total={10} height={900}>
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center' }}>
        <div style={{ padding:'48px 56px', background:t.surfaceAlt, borderRadius:t.r(28), marginBottom:50 }}>
          <span style={{ fontSize:t.z(52), fontWeight:900, color:t.primary }}>7 × 8</span></div>
        <div style={{ width:'100%', display:'grid', gridTemplateColumns:'1fr 1fr', gap:18 }}>
          {[54,56,63,48].map((o,i)=>(
            <div key={i} style={{ height:84, display:'flex', alignItems:'center', justifyContent:'center',
              fontSize:t.z(30), fontWeight:800, borderRadius:t.r(18),
              background: i===1?t.primary:t.surface, color:i===1?'#fff':t.text,
              border:`1.5px solid ${i===1?t.primary:t.line}`, boxShadow:i===1?t.shadow:t.cardShadow }}>{o}</div>
          ))}
        </div>
      </div>
    </window.GameShell>
  );
}

/* ════════ 25. 문장 소리 내어 읽기 ════════ */
function GameSentence({ t }) {
  return (
    <window.GameShell t={t} title="문장 소리 내어 읽기"
      objective={"화면에 보이는 문장을 또박또박 읽어주세요.\n언어 자극을 통해 뇌를 활성화합니다."} step={2} total={5} height={900}>
      <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center' }}>
        <div style={{ marginTop:24, padding:32, background:t.surface, borderRadius:t.r(24),
          border:`1px solid ${t.primary}33`, boxShadow:t.cardShadow, width:'100%' }}>
          <div style={{ fontSize:t.z(22), fontWeight:800, textAlign:'center', lineHeight:1.6 }}>
            건강을 위해 매일<br/>꾸준히 걷는 것이 좋습니다.</div>
        </div>
        <div style={{ flex:1 }} />
        <div style={{ fontSize:t.z(17), color:t.primary, fontWeight:800, marginBottom:28, textAlign:'center' }}>
          건강을 위해 매일 꾸준히…</div>
        <div style={{ width:84, height:84, borderRadius:42, background:t.primary,
          display:'flex', alignItems:'center', justifyContent:'center', boxShadow:t.shadow }}>
          <Icon name="voice" c="#fff" size={40} /></div>
        <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:16 }}>듣고 있습니다… (다 읽으면 버튼 클릭)</div>
      </div>
    </window.GameShell>
  );
}

/* ════════ 26. 개인정보 동의 ════════ */
function ScreenConsent({ t }) {
  const items = [
    { title:'개인정보 처리 동의', req:true, on:true },
    { title:'건강정보 취급 동의', req:true, on:true },
    { title:'보호자 데이터 공유', req:false, on:false },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="개인정보 동의" back />
      <Body pad={24} style={{ display:'flex', flexDirection:'column' }}>
        <div style={{ fontSize:t.z(25), fontWeight:900, lineHeight:1.4, letterSpacing:'-0.02em', marginTop:8 }}>
          서비스 이용을 위해<br/>필수 동의가 필요합니다.</div>
        <div style={{ display:'flex', flexDirection:'column', gap:14, marginTop:32 }}>
          {items.map(it=>(
            <div key={it.title} style={{ display:'flex', alignItems:'center', gap:14, padding:'18px 18px',
              background: it.on?t.primarySoft:t.surface, borderRadius:t.r(16),
              border:`1.5px solid ${it.on?t.primary:t.line}` }}>
              <div style={{ width:28, height:28, borderRadius:9, flex:'0 0 28px',
                background: it.on?t.primary:'transparent', border:`2px solid ${it.on?t.primary:t.line}`,
                display:'flex', alignItems:'center', justifyContent:'center' }}>
                {it.on && <Icon name="check" c="#fff" size={17} sw={3} />}</div>
              <span style={{ flex:1, fontSize:t.z(16), fontWeight:700 }}>{it.title}</span>
              <Badge t={t} color={it.req?t.bad:t.textSoft}>{it.req?'필수':'선택'}</Badge>
            </div>
          ))}
        </div>
        <div style={{ display:'flex', alignItems:'center', gap:10, marginTop:20, padding:'0 4px' }}>
          <Icon name="info" c={t.textFaint} size={16} />
          <span style={{ fontSize:t.z(12.5), color:t.textFaint }}>각 항목을 누르면 상세 약관을 확인할 수 있습니다.</span>
        </div>
        <div style={{ marginTop:'auto', background:t.primary, color:'#fff', borderRadius:t.r(18),
          padding:'18px', textAlign:'center', fontSize:t.z(18), fontWeight:800, boxShadow:t.shadow }}>다음으로</div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════ 27. 정보 수정 ════════ */
function ScreenEditProfile({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={1180}>
      <AppBar t={t} title="정보 수정" back right={
        <span style={{ fontSize:t.z(16), fontWeight:800, color:t.primary }}>저장</span>} />
      <Body pad={24}>
        {/* avatar */}
        <div style={{ display:'flex', flexDirection:'column', alignItems:'center', marginTop:8 }}>
          <div style={{ position:'relative' }}>
            <div style={{ width:104, height:104, borderRadius:34, background:t.primarySoft, overflow:'hidden',
              display:'flex', alignItems:'flex-end', justifyContent:'center' }}><Senior t={t} size={98} /></div>
            <div style={{ position:'absolute', right:-2, bottom:-2, width:34, height:34, borderRadius:17,
              background:t.primary, border:`3px solid ${t.bg}`, display:'flex', alignItems:'center', justifyContent:'center' }}>
              <Icon name="play" c="#fff" size={14} fill /></div>
          </div>
          <div style={{ fontSize:t.z(14), color:t.primary, fontWeight:700, marginTop:12 }}>프로필 사진 변경</div>
        </div>

        <div style={{ fontSize:t.z(15), fontWeight:800, color:t.primary, marginTop:24, marginBottom:12 }}>기본 계정 정보</div>
        <EditField t={t} icon="user" label="이름" val="김민수" />

        <div style={{ fontSize:t.z(15), fontWeight:800, color:t.primary, marginTop:26, marginBottom:12 }}>생체 및 의료 정보</div>
        <div style={{ display:'flex', gap:12 }}>
          <EditField t={t} icon="cal" label="나이 (세)" val="65" flex />
          <EditField t={t} icon="weight" label="몸무게 (kg)" val="68.5" flex />
        </div>
        <div style={{ height:12 }} />
        <EditField t={t} icon="blood" label="혈액형" val="A형" />
        <div style={{ height:12 }} />
        <EditField t={t} icon="pill" label="복용 중인 약물" val="혈압약" />
        <div style={{ height:12 }} />
        <EditField t={t} icon="bell" label="비상 연락처" val="010-1234-5678" />

        <div style={{ marginTop:26, background:t.primary, color:'#fff', borderRadius:t.r(16), padding:'17px',
          textAlign:'center', fontSize:t.z(17), fontWeight:800, boxShadow:t.shadow }}>수정 완료</div>
      </Body>
    </PhoneFrame>
  );
}
function EditField({ t, icon, label, val, flex }) {
  return (
    <div style={{ flex: flex?1:undefined }}>
      <div style={{ fontSize:t.z(12.5), fontWeight:700, color:t.textSoft, marginBottom:6 }}>{label}</div>
      <div style={{ display:'flex', alignItems:'center', gap:10, background:t.surface,
        border:`1px solid ${t.line}`, borderRadius:t.r(14), padding:'14px 14px' }}>
        <Icon name={icon} c={t.primary} size={19} />
        <span style={{ fontSize:t.z(15.5), fontWeight:700 }}>{val}</span>
      </div>
    </div>
  );
}

/* ════════ 28. FAQ ════════ */
function ScreenFAQ({ t }) {
  const groups = [
    { cat:'계정', items:[
      { q:'비밀번호를 잊어버렸어요.', open:true, a:'로그인 화면의 "비밀번호 찾기"를 눌러 가입 시 등록한 비상 연락처로 인증하면 재설정할 수 있습니다.' },
      { q:'아이디를 변경할 수 있나요?' }]},
    { cat:'훈련', items:[
      { q:'훈련 난이도는 어떻게 정해지나요?' },
      { q:'하루에 몇 번 훈련하면 좋나요?' }]},
    { cat:'보행', items:[
      { q:'걸음 수가 측정되지 않아요.' }]},
  ];
  return (
    <PhoneFrame t={t} nav={false} height={1000}>
      <AppBar t={t} title="자주 묻는 질문" back />
      <Body pad={20}>
        {groups.map(g=>(
          <div key={g.cat} style={{ marginTop:14 }}>
            <div style={{ fontSize:t.z(14), fontWeight:800, color:t.primary, margin:'8px 4px 10px' }}>{g.cat}</div>
            <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
              {g.items.map((it,i)=>(
                <Card t={t} key={i} pad={16}>
                  <div style={{ display:'flex', alignItems:'center', gap:11 }}>
                    <Icon name="info" c={t.primary} size={19} />
                    <span style={{ flex:1, fontSize:t.z(14.5), fontWeight:700 }}>{it.q}</span>
                    <Icon name="chevron" c={t.textFaint} size={18}
                      style={{ transform: it.open?'rotate(90deg)':'none' }} />
                  </div>
                  {it.open && <div style={{ marginTop:13, padding:'13px 15px', background:t.primarySoft,
                    borderRadius:t.r(11), fontSize:t.z(13.5), color:t.text, lineHeight:1.6 }}>{it.a}</div>}
                </Card>
              ))}
            </div>
          </div>
        ))}
      </Body>
    </PhoneFrame>
  );
}

/* ════════ 29. 1:1 문의하기 ════════ */
function ScreenInquiry({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="1:1 문의하기" back />
      <Body pad={22}>
        <div style={{ fontSize:t.z(13), fontWeight:700, color:t.textSoft, marginTop:6, marginBottom:8 }}>제목</div>
        <div style={{ background:t.surface, border:`1px solid ${t.line}`, borderRadius:t.r(14), padding:'15px 16px',
          fontSize:t.z(15), color:t.textFaint }}>문의 제목을 입력해 주세요</div>

        <div style={{ fontSize:t.z(13), fontWeight:700, color:t.textSoft, marginTop:18, marginBottom:8 }}>문의 내용</div>
        <div style={{ background:t.surface, border:`1px solid ${t.line}`, borderRadius:t.r(14), padding:'15px 16px',
          fontSize:t.z(15), color:t.textFaint, height:200, position:'relative', lineHeight:1.6 }}>
          궁금하신 내용을 자세히 작성해 주세요
          <span style={{ position:'absolute', right:14, bottom:12, fontSize:t.z(12), color:t.textFaint }}>0 / 500</span>
        </div>

        <div style={{ marginTop:24, background:t.primary, color:'#fff', borderRadius:t.r(16), padding:'17px',
          textAlign:'center', fontSize:t.z(17), fontWeight:800, boxShadow:t.shadow }}>문의 제출</div>

        <div style={{ marginTop:20, display:'flex', gap:11, background:t.primarySoft, borderRadius:t.r(14),
          padding:'14px 16px', alignItems:'flex-start' }}>
          <Icon name="headset" c={t.primary} size={20} />
          <span style={{ fontSize:t.z(13), color:t.text, lineHeight:1.5 }}>
            평일 09:00–18:00 접수된 문의는 24시간 이내에 답변드립니다.</span>
        </div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════ 30. 내 문의 내역 ════════ */
function ScreenMyInquiries({ t }) {
  const list = [
    { title:'걸음 수가 측정되지 않습니다', date:'2026.05.18', answered:true },
    { title:'보호자 연결 QR이 안 떠요', date:'2026.05.12', answered:true },
    { title:'훈련 점수 초기화 문의', date:'2026.05.03', answered:false },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="내 문의 내역" back />
      <Body pad={20}>
        <div style={{ display:'flex', flexDirection:'column', gap:10, marginTop:6 }}>
          {list.map((it,i)=>(
            <Card t={t} key={i} pad={16} style={{ display:'flex', alignItems:'center', gap:12 }}>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:t.z(15), fontWeight:700 }}>{it.title}</div>
                <div style={{ fontSize:t.z(12.5), color:t.textFaint, marginTop:4 }}>{it.date}</div>
              </div>
              <div style={{ display:'flex', alignItems:'center', gap:5, padding:'5px 11px', borderRadius:11,
                background:(it.answered?t.good:t.warn)+'1F' }}>
                <Icon name={it.answered?'check':'clock'} c={it.answered?t.good:t.warn} size={14} sw={2.5} />
                <span style={{ fontSize:t.z(12), fontWeight:800, color:it.answered?t.good:t.warn }}>
                  {it.answered?'답변 완료':'답변 대기중'}</span></div>
            </Card>
          ))}
        </div>
      </Body>
      {/* FAB */}
      <div style={{ position:'absolute', right:20, bottom:24, display:'flex', alignItems:'center', gap:9,
        background:t.primary, color:'#fff', borderRadius:30, padding:'14px 20px', boxShadow:t.shadow,
        fontSize:t.z(15), fontWeight:800 }}>
        <Icon name="plus" c="#fff" size={19} sw={2.5} />새 문의</div>
    </PhoneFrame>
  );
}

/* ════════ 31. 공지사항 ════════ */
function ScreenNotices({ t }) {
  const list = [
    { pin:true, title:'v1.1 업데이트 — 보행 정밀 분석 개선', body:'이중 과제 모드의 정확도가 향상되고, 주간 리포트에 새로운 지표가 추가되었습니다.', date:'2026.05.20' },
    { title:'개인정보 처리방침 개정 안내', body:'2026년 6월 1일부터 적용되는 개인정보 처리방침 변경 사항을 안내드립니다.', date:'2026.05.14' },
    { title:'정기 점검 안내 (5/10 02:00–04:00)', body:'서버 안정화를 위한 정기 점검이 진행됩니다. 해당 시간 일부 기능 사용이 제한됩니다.', date:'2026.05.08' },
  ];
  return (
    <PhoneFrame t={t} nav={false} height={832}>
      <AppBar t={t} title="공지사항" back />
      <Body pad={20}>
        <div style={{ display:'flex', flexDirection:'column', gap:10, marginTop:6 }}>
          {list.map((n,i)=>(
            <Card t={t} key={i} pad={16}>
              <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:7 }}>
                {n.pin && <span style={{ fontSize:t.z(11), fontWeight:800, color:'#fff', background:t.primary,
                  padding:'2px 8px', borderRadius:6 }}>고정</span>}
                <span style={{ flex:1, fontSize:t.z(15.5), fontWeight:800 }}>{n.title}</span>
              </div>
              <div style={{ fontSize:t.z(13), color:t.textSoft, lineHeight:1.5 }}>{n.body}</div>
              <div style={{ fontSize:t.z(12), color:t.textFaint, marginTop:10 }}>{n.date}</div>
            </Card>
          ))}
        </div>
      </Body>
    </PhoneFrame>
  );
}

/* ════════ 32. 기관 및 서비스 연계 ════════ */
function ScreenReferral({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={1000}>
      <AppBar t={t} title="기관 및 서비스 연계" back />
      <Body pad={24}>
        <div style={{ fontSize:t.z(25), fontWeight:900, lineHeight:1.4, letterSpacing:'-0.02em', marginTop:6 }}>
          더 자세한 도움이<br/>필요하신가요?</div>

        <div style={{ display:'flex', flexDirection:'column', gap:14, marginTop:26 }}>
          <Card t={t} pad={20}>
            <div style={{ fontSize:t.z(17), fontWeight:800 }}>중앙치매센터</div>
            <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:6, lineHeight:1.5 }}>전국 어디서나 24시간 치매 상담 콜센터</div>
            <div style={{ display:'flex', justifyContent:'flex-end', marginTop:16 }}>
              <div style={{ display:'flex', alignItems:'center', gap:8, background:t.primarySoft, color:t.primary,
                borderRadius:t.r(12), padding:'11px 16px', fontSize:t.z(14.5), fontWeight:800 }}>
                <Icon name="bell" c={t.primary} size={17} />1899-9988 전화하기</div></div>
          </Card>
          <Card t={t} pad={20}>
            <div style={{ fontSize:t.z(17), fontWeight:800 }}>지역 치매안심센터 안내</div>
            <div style={{ fontSize:t.z(13.5), color:t.textSoft, marginTop:6, lineHeight:1.5 }}>가까운 보건소 내 치매 지원 서비스를 찾아보세요.</div>
            <div style={{ display:'flex', justifyContent:'flex-end', marginTop:16 }}>
              <div style={{ display:'flex', alignItems:'center', gap:8, background:t.primarySoft, color:t.primary,
                borderRadius:t.r(12), padding:'11px 16px', fontSize:t.z(14.5), fontWeight:800 }}>
                <Icon name="map" c={t.primary} size={17} />가까운 센터 찾기</div></div>
          </Card>
        </div>

        <div style={{ fontSize:t.z(18.5), fontWeight:800, marginTop:28, marginBottom:14 }}>우리 앱만의 통합 연계</div>
        <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
          <FeatureRow t={t} icon="doc" title="리포트 자동 생성" desc="준비된 상담 자료를 의사에게 전달하세요." />
          <FeatureRow t={t} icon="headset" title="치매상담전화 바로가기" desc="콜센터(1899-9988)로 연결합니다." />
        </div>
      </Body>
    </PhoneFrame>
  );
}
function FeatureRow({ t, icon, title, desc }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:14, padding:18, background:t.surface,
      borderRadius:t.r(16), border:`1.5px solid ${t.primary}30` }}>
      <IconTile t={t} name={icon} color={t.primary} size={48} />
      <div style={{ flex:1 }}>
        <div style={{ fontSize:t.z(15.5), fontWeight:800 }}>{title}</div>
        <div style={{ fontSize:t.z(12.5), color:t.textSoft, marginTop:2 }}>{desc}</div>
      </div>
      <Icon name="chevron" c={t.textFaint} size={20} />
    </div>
  );
}

/* ════════ 33. 관리자 로그인 ════════ */
function ScreenAdminLogin({ t }) {
  return (
    <PhoneFrame t={t} nav={false} height={832} bg={t.text}>
      <Body pad={32} style={{ display:'flex', flexDirection:'column', flex:1, justifyContent:'center' }}>
        <div style={{ textAlign:'center', marginBottom:40 }}>
          <div style={{ width:84, height:84, margin:'0 auto', borderRadius:26, background:'rgba(255,255,255,0.1)',
            display:'flex', alignItems:'center', justifyContent:'center', border:'1px solid rgba(255,255,255,0.16)' }}>
            <Icon name="shield" c="#fff" size={42} /></div>
          <div style={{ fontSize:t.z(24), fontWeight:900, color:'#fff', marginTop:20 }}>관리자 콘솔</div>
          <div style={{ fontSize:t.z(14), color:'rgba(255,255,255,0.6)', marginTop:6 }}>MemoryLink Admin</div>
        </div>
        <div style={{ display:'flex', flexDirection:'column', gap:13 }}>
          <AdminField t={t} icon="user" placeholder="관리자 아이디" />
          <AdminField t={t} icon="shield" placeholder="비밀번호" />
        </div>
        <div style={{ marginTop:24, background:t.primary, color:'#fff', borderRadius:t.r(14), padding:'17px',
          textAlign:'center', fontSize:t.z(17), fontWeight:800 }}>로그인</div>
        <div style={{ textAlign:'center', marginTop:'auto', display:'flex', alignItems:'center', justifyContent:'center', gap:7,
          fontSize:t.z(12), color:'rgba(255,255,255,0.4)' }}>
          <Icon name="shield" c="rgba(255,255,255,0.4)" size={14} />권한이 있는 관리자만 접근 가능합니다</div>
      </Body>
    </PhoneFrame>
  );
}
function AdminField({ t, icon, placeholder }) {
  return (
    <div style={{ display:'flex', alignItems:'center', gap:12, background:'rgba(255,255,255,0.08)',
      border:'1px solid rgba(255,255,255,0.14)', borderRadius:t.r(14), padding:'16px' }}>
      <Icon name={icon} c="rgba(255,255,255,0.7)" size={20} />
      <span style={{ fontSize:t.z(15), color:'rgba(255,255,255,0.5)' }}>{placeholder}</span>
    </div>
  );
}

/* ════════ 34. 관리자 대시보드 ════════ */
function ScreenAdmin({ t }) {
  const stats = [['전체 회원','1,284','family'],['오늘 활성','312','sparkle'],['주간 활성','847','chart']];
  const avg = [72,64,81,58,69,55];
  const labels = ['계산','논리','기억','집중','걸음','보행'];
  const users = [['김민수',65],['이영희',71],['박철수',68],['최정원',62]];
  return (
    <PhoneFrame t={t} nav={false} height={1240} bg={t.bg}>
      {/* admin appbar (primary bg) */}
      <div style={{ background:t.primary, padding:'12px 20px', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <span style={{ fontSize:t.z(19), fontWeight:800, color:'#fff' }}>관리자 대시보드</span>
        <div style={{ display:'flex', gap:14 }}>
          <Icon name="headset" c="#fff" size={22} /><Icon name="logout" c="#fff" size={22} /></div>
      </div>
      <Body pad={16}>
        {/* summary cards */}
        <div style={{ display:'flex', gap:10, marginTop:6 }}>
          {stats.map(([l,v,ic])=>(
            <Card t={t} key={l} pad={14} style={{ flex:1, textAlign:'center' }}>
              <Icon name={ic} c={t.primary} size={22} style={{ margin:'0 auto' }} />
              <div style={{ fontSize:t.z(22), fontWeight:900, marginTop:8 }}>{v}</div>
              <div style={{ fontSize:t.z(11.5), color:t.textFaint, marginTop:3 }}>{l}</div>
            </Card>
          ))}
        </div>

        {/* at-risk */}
        <Card t={t} pad={16} style={{ marginTop:14 }}>
          <div style={{ display:'flex', alignItems:'center', gap:10 }}>
            <Icon name="bell" c={t.bad} size={20} />
            <span style={{ flex:1, fontSize:t.z(15), fontWeight:800 }}>위험 사용자 알림</span>
            <Badge t={t} color={t.bad} soft={false}>2</Badge>
          </div>
          <div style={{ marginTop:12, display:'flex', flexDirection:'column', gap:8 }}>
            {[['이영희','기억력 -24%'],['최정원','보행 변동성 -18%']].map(([n,d])=>(
              <div key={n} style={{ display:'flex', alignItems:'center', gap:10, padding:'10px 12px',
                background:t.bad+'10', borderRadius:t.r(11) }}>
                <div style={{ width:30, height:30, borderRadius:15, background:t.bad+'22',
                  display:'flex', alignItems:'center', justifyContent:'center', fontSize:t.z(13), fontWeight:800, color:t.bad }}>{n[0]}</div>
                <span style={{ flex:1, fontSize:t.z(13.5), fontWeight:700 }}>{n}</span>
                <span style={{ fontSize:t.z(12.5), fontWeight:800, color:t.bad }}>{d}</span>
              </div>
            ))}
          </div>
        </Card>

        {/* avg score chart */}
        <Card t={t} pad={18} style={{ marginTop:14 }}>
          <div style={{ fontSize:t.z(15), fontWeight:800, marginBottom:14 }}>카테고리별 평균 점수</div>
          <BarChart t={t} data={avg} color={t.primary} w={300} h={150} goal={100} labels={labels} />
        </Card>

        {/* user list */}
        <Card t={t} pad={0} style={{ marginTop:14 }}>
          <div style={{ fontSize:t.z(15), fontWeight:800, padding:'16px 16px 10px' }}>전체 회원 목록</div>
          {users.map(([n,age],i)=>(
            <div key={n} style={{ display:'flex', alignItems:'center', gap:12, padding:'12px 16px',
              borderTop:`1px solid ${t.line}` }}>
              <div style={{ width:38, height:38, borderRadius:19, background:t.primarySoft,
                display:'flex', alignItems:'center', justifyContent:'center', fontSize:t.z(15), fontWeight:800, color:t.primary }}>{n[0]}</div>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:t.z(14.5), fontWeight:700 }}>{n}</div>
                <div style={{ fontSize:t.z(12), color:t.textFaint, marginTop:1 }}>나이: {age}세</div>
              </div>
              <Icon name="chevron" c={t.textFaint} size={18} />
            </div>
          ))}
        </Card>
      </Body>
    </PhoneFrame>
  );
}

Object.assign(window, {
  GameComparison, GameMultiply, GameSentence,
  ScreenConsent, ScreenEditProfile, ScreenFAQ, ScreenInquiry, ScreenMyInquiries,
  ScreenNotices, ScreenReferral, ScreenAdminLogin, ScreenAdmin,
});
