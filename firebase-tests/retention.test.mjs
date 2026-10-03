// 보존기간 정리(firebase-ops/retention.mjs) 테스트 — 에뮬레이터 전용
//
// 실행: firebase emulators:exec --config ../firebase.json --project demo-memorylink --only firestore,auth "npm test"
// 규칙 테스트와 데이터가 섞이지 않게 별도 demo- 프로젝트를 쓴다.
import { test, describe, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  POLICY, RetentionError, createClient, collectSnapshot, planRetention, applyPlan, runRetention, redact, parseArgs,
} from '../firebase-ops/retention.mjs';

const PROJECT = 'demo-retention';
const FS = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8180';
const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '127.0.0.1:9099';
const DOCS = `http://${FS}/v1/projects/${PROJECT}/databases/(default)/documents`;
const ADMIN = { Authorization: 'Bearer owner', 'Content-Type': 'application/json' };
const DAY = 24 * 60 * 60 * 1000;

const LIVE = 'LiveLiveLiveLiveLive01';
const EXPIRED = 'ExpiredExpiredExpired1';
const GRACE = 'GraceGraceGraceGrace01';
const MALFORMED = 'MalformedMalformed0001';
const LEGACY16 = 'LEGACY0123456789';
const LEGACY8 = 'OLD12345';

const ts = (ms) => ({ timestampValue: new Date(ms).toISOString() });
const s = (v) => ({ stringValue: v });
const n = (v) => ({ integerValue: String(v) });

const client = () => createClient({ project: PROJECT, emulator: { firestore: FS, auth: AUTH } });

async function put(path, fields) {
  const r = await fetch(`${DOCS}/${path}`, { method: 'PATCH', headers: ADMIN, body: JSON.stringify({ fields }) });
  assert.equal(r.status, 200, await r.text());
}
async function exists(path) {
  const r = await fetch(`${DOCS}/${path}`, { headers: ADMIN });
  return r.status === 200;
}
async function createUser() {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts`, {
    method: 'POST', headers: ADMIN, body: '{}',
  });
  const body = await r.json();
  assert.equal(r.status, 200, JSON.stringify(body));
  return body.localId;
}
async function userIds() {
  const r = await fetch(`http://${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:batchGet?maxResults=100`, { headers: ADMIN });
  return ((await r.json()).users ?? []).map((u) => u.localId).sort();
}
async function reset() {
  await fetch(`http://${FS}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${AUTH}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
}

const link = (owner, expiresAt) => ({ ownerUid: s(owner), createdAt: ts(expiresAt - 30 * DAY), expiresAt: ts(expiresAt), schema: n(2) });
const view = (expiresAt, name = '민준') => ({
  schema: n(2), display_name: s(name), today_steps: n(4200), is_anomaly: { booleanValue: false }, expiresAt: ts(expiresAt),
});

// 토큰별 상태가 다른 보호자 링크, 오래된·새 문의, 오래된·새 난이도, 운영 콘텐츠
async function seedFixture(now) {
  await put(`guardian_links/${LIVE}`, link('owner-live', now + 10 * DAY));
  await put(`guardian_views/${LIVE}`, view(now + 10 * DAY));
  await put(`guardian_links/${EXPIRED}`, link('owner-expired', now - 2 * DAY));
  await put(`guardian_views/${EXPIRED}`, view(now - 2 * DAY));
  await put(`guardian_links/${GRACE}`, link('owner-grace', now - DAY / 2));
  await put(`guardian_views/${GRACE}`, view(now - DAY / 2));
  await put(`guardian_views/${MALFORMED}`, { schema: n(2), today_steps: n(1) });
  await put(`guardian_views/${LEGACY16}`, {
    ownerUid: s('owner-legacy'), user_name: s('김민준'), emergency_contact: s('01012345678'), today_steps: n(10),
  });
  await put(`guardian_views/${LEGACY8}`, { user_name: s('이영희'), emergency_contact: s('01098765432'), today_steps: n(5) });
  await put('inquiries/old-inquiry', {
    authorUid: s('author-old'), title: s('제목'), body: s('비밀 본문'), status: s('answered'), created_at: ts(now - 400 * DAY),
  });
  await put('inquiries/old-inquiry/replies/r1', { body: s('답변'), created_at: ts(now - 399 * DAY) });
  await put('inquiries/old-inquiry/replies/r2', { body: s('추가 답변'), created_at: ts(now - 398 * DAY) });
  await put('inquiries/new-inquiry', {
    authorUid: s('author-new'), title: s('새 문의'), body: s('본문'), status: s('pending'), created_at: ts(now - 10 * DAY),
  });
  await put('training_difficulty/stale-doc', { ownerUid: s('owner-stale'), username: s('kim'), memory_level: n(2), updated_at: ts(now - 100 * DAY) });
  await put('training_difficulty/fresh-doc', { ownerUid: s('owner-fresh'), username: s('lee'), memory_level: n(3), updated_at: ts(now - 5 * DAY) });
  await put('notices/n1', { title: s('공지') });
  await put('faqs/f1', { question: s('질문') });
}

// ── 판정(순수 함수) ─────────────────────────────────────────────
const NOW = Date.parse('2026-10-04T00:00:00Z');
const doc = (path, extra) => ({ name: `projects/p/databases/(default)/documents/${path}`, id: path.split('/').pop(), updateTime: 'u', ...extra });
const emptySnapshot = { collections: [], links: [], views: [], inquiries: [], difficulty: [], users: [] };

describe('보존기간 판정', () => {
  test('v2 링크는 만료 후 1일이 지나야 두 문서를 함께 지운다', () => {
    const snap = {
      ...emptySnapshot,
      links: [doc(`guardian_links/${EXPIRED}`, { schema: 2, expiresAt: NOW - 2 * DAY, ownerUid: 'a' }),
        doc(`guardian_links/${GRACE}`, { schema: 2, expiresAt: NOW - DAY / 2, ownerUid: 'b' })],
      views: [doc(`guardian_views/${EXPIRED}`, { schema: 2, expiresAt: NOW - 2 * DAY, hasExpiresField: true }),
        doc(`guardian_views/${GRACE}`, { schema: 2, expiresAt: NOW - DAY / 2, hasExpiresField: true })],
    };
    const plan = planRetention(snap, NOW);
    assert.equal(plan.guardian.length, 1);
    assert.deepEqual(plan.guardian[0].map((d) => d.id), [EXPIRED, EXPIRED]);
    assert.equal(plan.counts.guardian_expired_links, 1);
  });

  test('만료일·schema가 없는 예전 공개 문서는 바로 지운다', () => {
    const snap = { ...emptySnapshot, views: [doc(`guardian_views/${LEGACY16}`, { schema: null, expiresAt: null, hasExpiresField: false })] };
    const plan = planRetention(snap, NOW);
    assert.equal(plan.counts.guardian_legacy_views, 1);
    assert.equal(plan.counts.guardian_docs, 1);
  });

  test('형식을 알 수 없는 v2 문서와 살아 있는 쪽이 있는 토큰은 남긴다', () => {
    const snap = {
      ...emptySnapshot,
      links: [doc(`guardian_links/${LIVE}`, { schema: 2, expiresAt: NOW - 5 * DAY, ownerUid: 'a' })],
      views: [doc(`guardian_views/${LIVE}`, { schema: 2, expiresAt: NOW + 5 * DAY, hasExpiresField: true }),
        doc(`guardian_views/${MALFORMED}`, { schema: 2, expiresAt: null, hasExpiresField: false })],
    };
    const plan = planRetention(snap, NOW);
    assert.equal(plan.guardian.length, 0);
    assert.equal(plan.counts.guardian_kept_malformed, 1);
  });

  test('문의는 접수 후 365일, 난이도는 갱신 후 90일이 지나야 지운다', () => {
    const snap = {
      ...emptySnapshot,
      inquiries: [doc('inquiries/a', { createdAt: NOW - 366 * DAY }), doc('inquiries/b', { createdAt: NOW - 364 * DAY })],
      difficulty: [doc('training_difficulty/a', { updatedAt: NOW - 91 * DAY }), doc('training_difficulty/b', { updatedAt: NOW - 89 * DAY })],
    };
    const plan = planRetention(snap, NOW);
    assert.deepEqual(plan.inquiries.map((d) => d.id), ['a']);
    assert.deepEqual(plan.difficulty.map((d) => d.id), ['a']);
  });

  test('익명 계정은 365일 동안 쓰이지 않았고 남는 데이터가 없을 때만 지운다', () => {
    const old = NOW - 400 * DAY;
    const snap = {
      ...emptySnapshot,
      links: [doc(`guardian_links/${LIVE}`, { schema: 2, expiresAt: NOW + 5 * DAY, ownerUid: 'keeps-link' }),
        doc(`guardian_links/${EXPIRED}`, { schema: 2, expiresAt: NOW - 5 * DAY, ownerUid: 'loses-link' })],
      views: [doc(`guardian_views/${LIVE}`, { schema: 2, expiresAt: NOW + 5 * DAY, hasExpiresField: true }),
        doc(`guardian_views/${EXPIRED}`, { schema: 2, expiresAt: NOW - 5 * DAY, hasExpiresField: true })],
      users: [
        { uid: 'idle', anonymous: true, privileged: false, lastActiveAt: old },
        { uid: 'keeps-link', anonymous: true, privileged: false, lastActiveAt: old },
        { uid: 'loses-link', anonymous: true, privileged: false, lastActiveAt: old },
        { uid: 'recent', anonymous: true, privileged: false, lastActiveAt: NOW - 30 * DAY },
        { uid: 'email-user', anonymous: false, privileged: false, lastActiveAt: old },
        { uid: 'admin', anonymous: true, privileged: true, lastActiveAt: old },
      ],
    };
    assert.deepEqual(planRetention(snap, NOW).users.sort(), ['idle', 'loses-link']);
  });

  test('명령줄 옵션을 검사한다', () => {
    assert.deepEqual(parseArgs(['--apply', '--max-deletes=10']), { apply: true, maxDeletes: 10 });
    assert.throws(() => parseArgs(['--now=어제']), RetentionError);
    assert.throws(() => parseArgs(['--delete-everything']), RetentionError);
  });

  test('에뮬레이터 모드는 demo- 프로젝트만, 운영 모드는 토큰이 있어야 한다', () => {
    assert.throws(() => createClient({ project: 'memorylink-7af26', emulator: { firestore: FS, auth: AUTH } }), RetentionError);
    assert.throws(() => createClient({ project: 'demo-x', token: 't' }), RetentionError);
    assert.throws(() => createClient({ project: 'memorylink-7af26' }), RetentionError);
  });

  test('오류 문구에서 문서 경로(토큰)를 가린다', () => {
    assert.equal(redact(`GET /v1/projects/p/databases/(default)/documents/guardian_views/${LIVE} failed`),
      'GET /v1/projects/p/databases/(default)/documents/… failed');
  });
});

// ── 에뮬레이터 실행 ─────────────────────────────────────────────
describe('에뮬레이터 정리 실행', () => {
  beforeEach(reset);

  test('미리보기는 개수만 세고 아무것도 지우지 않는다', async () => {
    const now = Date.now();
    await seedFixture(now);
    const summary = await runRetention({ client: client(), now, log: () => {} });
    assert.equal(summary.mode, 'dry-run');
    assert.deepEqual(summary.planned, {
      guardian_tokens: 3, guardian_docs: 4, guardian_legacy_views: 2, guardian_expired_links: 1,
      guardian_kept_malformed: 1, inquiries: 1, training_difficulty: 1, auth_users: 0, inquiry_replies: 2,
    });
    assert.equal(summary.result, undefined);
    for (const path of [`guardian_links/${EXPIRED}`, `guardian_views/${LEGACY8}`, 'inquiries/old-inquiry', 'training_difficulty/stale-doc']) {
      assert.ok(await exists(path), path);
    }
  });

  test('적용하면 계획한 문서만 지우고, 다시 돌리면 지울 것이 없다', async () => {
    const now = Date.now();
    await seedFixture(now);
    const summary = await runRetention({ client: client(), now, apply: true, log: () => {} });
    assert.deepEqual(summary.result, {
      deleted: { guardian_docs: 4, inquiries: 1, inquiry_replies: 2, training_difficulty: 1 }, skipped: {}, failed: 0,
    });
    for (const gone of [`guardian_links/${EXPIRED}`, `guardian_views/${EXPIRED}`, `guardian_views/${LEGACY16}`,
      `guardian_views/${LEGACY8}`, 'inquiries/old-inquiry', 'inquiries/old-inquiry/replies/r1',
      'inquiries/old-inquiry/replies/r2', 'training_difficulty/stale-doc']) {
      assert.equal(await exists(gone), false, gone);
    }
    for (const kept of [`guardian_links/${LIVE}`, `guardian_views/${LIVE}`, `guardian_links/${GRACE}`,
      `guardian_views/${GRACE}`, `guardian_views/${MALFORMED}`, 'inquiries/new-inquiry',
      'training_difficulty/fresh-doc', 'notices/n1', 'faqs/f1']) {
      assert.ok(await exists(kept), kept);
    }
    const again = await runRetention({ client: client(), now, apply: true, log: () => {} });
    assert.equal(again.planned.guardian_docs + again.planned.inquiries + again.planned.training_difficulty, 0);
    assert.deepEqual(again.result, { deleted: {}, skipped: {}, failed: 0 });
  });

  test('판정한 뒤 앱이 연장한 링크는 지우지 않고 건너뛴다', async () => {
    const now = Date.now();
    await put(`guardian_links/${EXPIRED}`, link('owner-expired', now - 2 * DAY));
    await put(`guardian_views/${EXPIRED}`, view(now - 2 * DAY));
    const c = client();
    const plan = planRetention(await collectSnapshot(c), now);
    assert.equal(plan.guardian.length, 1);
    // 앱의 동기화: 두 문서의 만료일을 30일 뒤로 민다
    await put(`guardian_links/${EXPIRED}`, link('owner-expired', now + 30 * DAY));
    await put(`guardian_views/${EXPIRED}`, view(now + 30 * DAY));
    const result = await applyPlan(c, plan);
    assert.deepEqual(result, { deleted: {}, skipped: { guardian_tokens: 1 }, failed: 0 });
    assert.ok(await exists(`guardian_links/${EXPIRED}`));
    assert.ok(await exists(`guardian_views/${EXPIRED}`));
  });

  test('스냅숏은 이름·전화번호·본문을 읽지 않는다', async () => {
    const now = Date.now();
    await seedFixture(now);
    const text = JSON.stringify(await collectSnapshot(client()));
    for (const secret of ['김민준', '이영희', '민준', '01012345678', '01098765432', '비밀 본문', 'kim']) {
      assert.equal(text.includes(secret), false, secret);
    }
  });

  test('로그에는 개수만 남고 토큰·uid·이름은 남지 않는다', async () => {
    const now = Date.now();
    await seedFixture(now);
    const lines = [];
    await runRetention({ client: client(), now, apply: true, log: (l) => lines.push(l) });
    const out = lines.join('\n');
    for (const secret of [LIVE, EXPIRED, GRACE, MALFORMED, LEGACY16, LEGACY8, 'owner-', 'author-', 'old-inquiry', '김민준', '0101234']) {
      assert.equal(out.includes(secret), false, secret);
    }
    assert.match(out, /"guardian_docs": 4/);
  });

  test('삭제 예정이 상한을 넘으면 아무것도 지우지 않고 중단한다', async () => {
    const now = Date.now();
    await seedFixture(now);
    await assert.rejects(
      runRetention({ client: client(), now, apply: true, policy: { ...POLICY, maxDeletesPerRun: 3 }, log: () => {} }),
      RetentionError);
    assert.ok(await exists(`guardian_views/${LEGACY8}`));
    assert.ok(await exists('inquiries/old-inquiry'));
  });

  test('오래 쓰지 않은 익명 계정은 지우고, 서버 데이터가 남는 계정은 둔다', async () => {
    const idle = await createUser();
    const keepsLink = await createUser();
    const keepsInquiry = await createUser();
    const losesLink = await createUser();
    // 계정은 방금 만들어졌으니 판정 시각을 400일 뒤로 옮긴다.
    const now = Date.now() + 400 * DAY;
    await put(`guardian_links/${LIVE}`, link(keepsLink, now + 10 * DAY));
    await put(`guardian_views/${LIVE}`, view(now + 10 * DAY));
    await put(`guardian_links/${EXPIRED}`, link(losesLink, now - 5 * DAY));
    await put(`guardian_views/${EXPIRED}`, view(now - 5 * DAY));
    await put('inquiries/recent', { authorUid: s(keepsInquiry), title: s('t'), body: s('b'), status: s('pending'), created_at: ts(now - 3 * DAY) });

    const summary = await runRetention({ client: client(), now, apply: true, log: () => {} });
    assert.equal(summary.planned.auth_users, 2);
    assert.equal(summary.result.deleted.auth_users, 2);
    assert.deepEqual(await userIds(), [keepsLink, keepsInquiry].sort());
    assert.equal(await exists(`guardian_links/${EXPIRED}`), false);
    assert.ok(idle);
  });
});
