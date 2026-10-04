// Firestore 보안 규칙 허용·거부 테스트 (에뮬레이터 전용)
//
// 실행: firebase emulators:exec --config ../firebase.json --project demo-memorylink --only firestore "npm test"
// demo- 프로젝트는 운영 Firebase에 연결되지 않는다.
import { test, before, after, beforeEach, describe } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const PROJECT_ID = 'demo-memorylink';
const { FieldValue, Timestamp } = firebase.firestore;
const DAY = 24 * 60 * 60 * 1000;
const TOKEN = 'AbCdEfGhIjKlMnOpQrStUv'; // 22자 base64url, 132비트
const OTHER_TOKEN = 'ZyXwVuTsRqPoNmLkJiHgFe';
const V1_TOKEN = 'ABCDEFGH12345678'; // 예전 16자 토큰

let env;

function emulatorHostPort() {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8180').split(':');
  return { host, port: Number(port) };
}

before(async () => {
  assert.ok(PROJECT_ID.startsWith('demo-'), '운영 프로젝트로 테스트하지 않는다');
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      ...emulatorHostPort(),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const asUser = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
const asGuest = () => env.unauthenticatedContext().firestore();
const daysFromNow = (n) => Timestamp.fromMillis(Date.now() + n * DAY);
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

function linkData(uid, expiresAt) {
  return { ownerUid: uid, createdAt: FieldValue.serverTimestamp(), expiresAt, schema: 2 };
}

function viewData(expiresAt, extra = {}) {
  return {
    schema: 2,
    display_name: '민준',
    today_steps: 4200,
    weekly_steps: [3000, 4100, 3900],
    weekly_dates: ['2026-10-01', '2026-10-02', '2026-10-03'],
    weekly_avg: 3667,
    scores: [{ category: '기억', score: 72 }],
    is_anomaly: false,
    anomaly_message: '',
    last_sync: FieldValue.serverTimestamp(),
    expiresAt,
    ...extra,
  };
}

function share(db, uid, { token = TOKEN, expiresAt = daysFromNow(30), view = {} } = {}) {
  const batch = db.batch();
  batch.set(db.collection('guardian_links').doc(token), linkData(uid, expiresAt));
  batch.set(db.collection('guardian_views').doc(token), viewData(expiresAt, view));
  return batch.commit();
}

describe('보호자 링크 v2', () => {
  test('소유자는 비공개 링크와 공개 사본을 한 batch로 만든다', async () => {
    await assertSucceeds(share(asUser('owner-a'), 'owner-a'));
  });

  test('누구나 토큰으로 만료 전 공개 사본을 읽는다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const snap = await assertSucceeds(asGuest().collection('guardian_views').doc(TOKEN).get());
    assert.equal(snap.data().today_steps, 4200);
    assert.equal(snap.data().ownerUid, undefined);
  });

  test('공개 사본 목록 조회는 막는다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    await assertFails(asGuest().collection('guardian_views').get());
    await assertFails(asUser('owner-a').collection('guardian_views').get());
  });

  test('없는 토큰은 읽지 못한다', async () => {
    await assertFails(asGuest().collection('guardian_views').doc(OTHER_TOKEN).get());
  });

  test('만료된 공개 사본은 아무도 읽지 못한다', async () => {
    await seed((db) => db.collection('guardian_views').doc(TOKEN).set(viewData(daysFromNow(-1))));
    await assertFails(asGuest().collection('guardian_views').doc(TOKEN).get());
  });

  test('만료일이 없는 v1 문서(전화번호 포함)는 읽지 못한다', async () => {
    await seed((db) => db.collection('guardian_views').doc(V1_TOKEN).set({
      ownerUid: 'owner-a', user_name: 'kim', today_steps: 10, emergency_contact: '01000000000',
    }));
    await assertFails(asGuest().collection('guardian_views').doc(V1_TOKEN).get());
  });

  test('비공개 링크 없이 공개 사본만 만들 수 없다', async () => {
    const db = asUser('owner-a');
    await assertFails(db.collection('guardian_views').doc(TOKEN).set(viewData(daysFromNow(30))));
  });

  test('다른 사용자는 남의 공개 사본을 덮어쓰지 못한다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const db = asUser('intruder');
    await assertFails(db.collection('guardian_views').doc(TOKEN).set(
      viewData(daysFromNow(30), { is_anomaly: true, anomaly_message: '가짜 경고' })));
  });

  test('다른 사용자는 링크를 빼앗지 못한다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const db = asUser('intruder');
    await assertFails(db.collection('guardian_links').doc(TOKEN).set(linkData('intruder', daysFromNow(30))));
    await assertFails(db.collection('guardian_links').doc(TOKEN).update({ ownerUid: 'intruder' }));
  });

  test('소유자도 링크의 소유자를 바꾸지 못한다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    await assertFails(asUser('owner-a').collection('guardian_links').doc(TOKEN).update({ ownerUid: 'owner-b' }));
  });

  test('허용 목록 밖 필드(전화번호·ownerUid)는 공개 사본에 쓸 수 없다', async () => {
    const db = asUser('owner-a');
    await assertFails(share(db, 'owner-a', { view: { emergency_contact: '01000000000' } }));
    await assertFails(share(db, 'owner-a', { view: { ownerUid: 'owner-a' } }));
  });

  test('걸음 수는 0~100000 정수만 허용한다', async () => {
    const db = asUser('owner-a');
    await assertFails(share(db, 'owner-a', { view: { today_steps: -1 } }));
    await assertFails(share(db, 'owner-a', { view: { today_steps: 100001 } }));
    await assertFails(share(db, 'owner-a', { view: { today_steps: '4200' } }));
  });

  test('목록 길이와 문구 길이를 제한한다', async () => {
    const db = asUser('owner-a');
    await assertFails(share(db, 'owner-a', { view: { weekly_steps: [1, 2, 3, 4, 5, 6, 7, 8] } }));
    await assertFails(share(db, 'owner-a', { view: { scores: [1, 2, 3, 4, 5] } }));
    await assertFails(share(db, 'owner-a', { view: { anomaly_message: 'x'.repeat(201) } }));
    await assertFails(share(db, 'owner-a', { view: { display_name: 'x'.repeat(21) } }));
  });

  test('공개 사본의 만료일은 비공개 링크와 같아야 한다', async () => {
    const db = asUser('owner-a');
    const batch = db.batch();
    batch.set(db.collection('guardian_links').doc(TOKEN), linkData('owner-a', daysFromNow(30)));
    batch.set(db.collection('guardian_views').doc(TOKEN), viewData(daysFromNow(29)));
    await assertFails(batch.commit());
  });

  test('만료일은 미래 31일 안이어야 한다', async () => {
    const db = asUser('owner-a');
    await assertFails(share(db, 'owner-a', { expiresAt: daysFromNow(40) }));
    await assertFails(share(db, 'owner-a', { expiresAt: daysFromNow(-1) }));
  });

  test('16자 v1 토큰으로는 새 링크를 만들 수 없다', async () => {
    await assertFails(share(asUser('owner-a'), 'owner-a', { token: V1_TOKEN }));
  });

  test('소유자는 하트비트로 걸음 수를 갱신하고 만료일을 민다', async () => {
    await share(asUser('owner-a'), 'owner-a', { expiresAt: daysFromNow(10) });
    const db = asUser('owner-a');
    const next = daysFromNow(30);
    const batch = db.batch();
    batch.update(db.collection('guardian_links').doc(TOKEN), { expiresAt: next });
    batch.update(db.collection('guardian_views').doc(TOKEN), {
      today_steps: 5100, last_heartbeat: FieldValue.serverTimestamp(), expiresAt: next,
    });
    await assertSucceeds(batch.commit());
  });

  test('다른 사용자는 하트비트를 쓸 수 없다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const db = asUser('intruder');
    await assertFails(db.collection('guardian_views').doc(TOKEN).update({ today_steps: 0 }));
  });

  test('소유자는 공유를 중지(두 문서 삭제)하고 그 뒤에는 읽을 수 없다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const db = asUser('owner-a');
    const batch = db.batch();
    batch.delete(db.collection('guardian_views').doc(TOKEN));
    batch.delete(db.collection('guardian_links').doc(TOKEN));
    await assertSucceeds(batch.commit());
    await assertFails(asGuest().collection('guardian_views').doc(TOKEN).get());
  });

  test('다른 사용자는 공유를 중지시키지 못한다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    const db = asUser('intruder');
    await assertFails(db.collection('guardian_views').doc(TOKEN).delete());
    await assertFails(db.collection('guardian_links').doc(TOKEN).delete());
  });

  test('소유자는 자기 v1 잔존 문서를 지울 수 있고 남은 못 지운다', async () => {
    await seed((db) => db.collection('guardian_views').doc(V1_TOKEN).set({ ownerUid: 'owner-a', user_name: 'kim' }));
    await assertFails(asUser('intruder').collection('guardian_views').doc(V1_TOKEN).delete());
    await assertSucceeds(asUser('owner-a').collection('guardian_views').doc(V1_TOKEN).delete());
  });

  test('비공개 링크는 소유자만 읽고 목록은 막는다', async () => {
    await share(asUser('owner-a'), 'owner-a');
    await assertSucceeds(asUser('owner-a').collection('guardian_links').doc(TOKEN).get());
    await assertFails(asUser('intruder').collection('guardian_links').doc(TOKEN).get());
    await assertFails(asGuest().collection('guardian_links').doc(TOKEN).get());
    await assertFails(asUser('owner-a').collection('guardian_links').get());
  });

  test('로그인하지 않으면 보호자 문서를 쓸 수 없다', async () => {
    await assertFails(share(asGuest(), 'owner-a'));
  });
});

describe('1:1 문의', () => {
  function inquiry(uid, extra = {}) {
    return {
      username: 'kim', authorUid: uid, title: '걸음 수 질문', body: '어제 걸음 수가 0으로 나와요.',
      status: 'pending', created_at: FieldValue.serverTimestamp(), ...extra,
    };
  }

  test('작성자는 자기 문의를 만든다', async () => {
    await assertSucceeds(asUser('owner-a').collection('inquiries').add(inquiry('owner-a')));
  });

  test('남의 uid·답변 상태·초과 길이·추가 필드로는 만들 수 없다', async () => {
    const col = asUser('owner-a').collection('inquiries');
    await assertFails(col.add(inquiry('owner-b')));
    await assertFails(col.add(inquiry('owner-a', { status: 'answered' })));
    await assertFails(col.add(inquiry('owner-a', { title: 'x'.repeat(101) })));
    await assertFails(col.add(inquiry('owner-a', { body: 'x'.repeat(2001) })));
    await assertFails(col.add(inquiry('owner-a', { phone: '01000000000' })));
    await assertFails(asGuest().collection('inquiries').add(inquiry('owner-a')));
  });

  test('작성자만 읽고, 작성자 조건 질의는 허용한다', async () => {
    const ref = await asUser('owner-a').collection('inquiries').add(inquiry('owner-a'));
    await assertSucceeds(asUser('owner-a').collection('inquiries').doc(ref.id).get());
    await assertFails(asUser('owner-b').collection('inquiries').doc(ref.id).get());
    await assertFails(asGuest().collection('inquiries').doc(ref.id).get());
    await assertSucceeds(asUser('owner-a').collection('inquiries')
      .where('authorUid', '==', 'owner-a').where('username', '==', 'kim').get());
    await assertFails(asUser('owner-a').collection('inquiries').get());
  });

  test('작성자는 문의를 고칠 수 없고 지울 수는 있다', async () => {
    const ref = await asUser('owner-a').collection('inquiries').add(inquiry('owner-a'));
    const own = asUser('owner-a').collection('inquiries').doc(ref.id);
    await assertFails(own.update({ status: 'answered' }));
    await assertFails(own.update({ authorUid: 'owner-b' }));
    await assertFails(asUser('owner-b').collection('inquiries').doc(ref.id).delete());
    await assertSucceeds(own.delete());
  });

  test('관리자 답변은 작성자만 읽고 지울 수 있다', async () => {
    const ref = await asUser('owner-a').collection('inquiries').add(inquiry('owner-a'));
    const admin = asUser('ops', { admin: true });
    await assertSucceeds(admin.collection('inquiries').doc(ref.id).collection('replies').doc('r1')
      .set({ body: '확인했습니다.', created_at: FieldValue.serverTimestamp() }));
    await assertSucceeds(admin.collection('inquiries').doc(ref.id).update({ status: 'answered' }));
    const reply = (db) => db.collection('inquiries').doc(ref.id).collection('replies').doc('r1');
    await assertSucceeds(reply(asUser('owner-a')).get());
    await assertFails(reply(asUser('owner-b')).get());
    await assertFails(reply(asUser('owner-a')).set({ body: '작성자가 쓴 답변' }));
    await assertFails(reply(asUser('owner-b')).delete());
    await assertSucceeds(reply(asUser('owner-a')).delete());
  });
});

describe('공지·FAQ', () => {
  test('로그인 사용자는 읽고 관리자만 쓴다', async () => {
    await seed((db) => db.collection('notices').doc('n1').set({ title: '안내', body: '본문' }));
    await assertSucceeds(asUser('owner-a').collection('notices').doc('n1').get());
    await assertFails(asGuest().collection('notices').doc('n1').get());
    await assertFails(asUser('owner-a').collection('notices').doc('n2').set({ title: 'x' }));
    await assertFails(asUser('owner-a').collection('faqs').doc('f1').set({ question: 'x' }));
    await assertSucceeds(asUser('ops', { admin: true }).collection('faqs').doc('f1').set({ question: 'x' }));
  });
});

describe('global_stats', () => {
  test('클라이언트는 읽지도 쓰지도 못한다', async () => {
    await seed((db) => db.collection('global_stats').doc('score_stats').set({ avg_score: 65 }));
    const db = asUser('owner-a');
    await assertFails(db.collection('global_stats').doc('score_stats').set({ avg_score: 99 }));
    await assertFails(db.collection('global_stats').doc('score_stats').get());
  });
});

describe('훈련 난이도 (클라우드 저장 종료)', () => {
  test('소유자는 예전 문서를 읽고 지울 수 있지만 새로 쓰지 못한다', async () => {
    await seed((db) => db.collection('training_difficulty').doc('owner-a_kim').set({ ownerUid: 'owner-a', memory_level: 3 }));
    const db = asUser('owner-a');
    await assertSucceeds(db.collection('training_difficulty').doc('owner-a_kim').get());
    await assertSucceeds(db.collection('training_difficulty').doc('owner-a_none').get());
    await assertFails(db.collection('training_difficulty').doc('owner-a_kim').set({ ownerUid: 'owner-a', memory_level: 4 }));
    await assertFails(db.collection('training_difficulty').doc('owner-a_new').set({ ownerUid: 'owner-a' }));
    await assertFails(asUser('owner-b').collection('training_difficulty').doc('owner-a_kim').get());
    await assertFails(asUser('owner-b').collection('training_difficulty').doc('owner-a_kim').delete());
    await assertSucceeds(db.collection('training_difficulty').doc('owner-a_kim').delete());
  });
});

describe('기본 차단', () => {
  test('규칙에 없는 경로는 막는다', async () => {
    await assertFails(asUser('owner-a').collection('users').doc('owner-a').set({ name: 'x' }));
    await assertFails(asUser('owner-a').collection('users').doc('owner-a').get());
  });
});
