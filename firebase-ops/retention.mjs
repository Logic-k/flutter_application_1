// MemoryLink 서버 데이터 보존기간 정리 (무료 요금제용)
//
// 무료(Spark) 요금제에는 Firestore TTL 자동 삭제와 예약 함수가 없다(TTL 삭제는 결제 활성화가 필요).
// 이 스크립트가 그 일을 대신한다. GitHub Actions(.github/workflows/firestore-retention.yml)가
// 매일 한 번 --apply로 돌리고, 사람이 손으로 돌릴 때는 기본이 미리보기(dry-run)다.
//
// 지우는 것 (POLICY)
//   보호자 링크   만료일이 1일 넘게 지난 링크(guardian_links·guardian_views 두 문서를 함께),
//                만료일·schema가 없는 예전(v0·v1) 공개 문서(이름·전화번호가 남아 있다)
//   문의          접수 후 365일이 지난 문의와 답변(inquiries, replies)
//   난이도        마지막 갱신 후 90일이 지난 예전 클라우드 난이도 기록(training_difficulty)
//   익명 계정     365일 동안 쓰이지 않았고 남은 서버 데이터가 없는 Firebase 익명 계정
//
// 개인정보 보호
//   - 문서는 필드 마스크로 소유자·시각 필드만 읽는다. 이름·전화번호·문의 본문은 읽지 않는다.
//   - 로그에는 개수만 쓴다. 문서 ID(보호자 토큰)와 uid는 공개 저장소의 Actions 로그에 남기지 않는다.
//   - 읽은 뒤 바뀐 문서는 updateTime 전제조건으로 건너뛴다(앱이 방금 연장한 링크를 지우지 않는다).
//   - 한 번에 지울 양이 상한을 넘으면 아무것도 지우지 않고 실패한다(판정 오류로 대량 삭제 방지).
//
// 실행
//   운영:      FIRESTORE_ACCESS_TOKEN=<token> node firebase-ops/retention.mjs [--apply]
//   에뮬레이터: FIRESTORE_EMULATOR_HOST·FIREBASE_AUTH_EMULATOR_HOST가 있으면 그쪽으로만 간다(demo- 프로젝트 전용).
//   선택:      --now=2026-10-04T00:00:00Z (판정 기준 시각), --max-deletes=500, --project=memorylink-7af26
//              GOOGLE_QUOTA_PROJECT=<id> (사용자 계정 토큰으로 돌릴 때 할당량 프로젝트)
import { pathToFileURL } from 'node:url';

export const POLICY = Object.freeze({
  guardianGraceDays: 1,
  inquiryRetentionDays: 365,
  difficultyStaleDays: 90,
  authInactiveDays: 365,
  maxDeletesPerRun: 500,
});

const DAY = 24 * 60 * 60 * 1000;
const PROD_PROJECT = 'memorylink-7af26';
const KNOWN_COLLECTIONS = ['faqs', 'notices', 'inquiries', 'guardian_links', 'guardian_views', 'training_difficulty'];
const SKIPPABLE = new Set(['FAILED_PRECONDITION', 'NOT_FOUND', 'ABORTED']);

export class RetentionError extends Error {}

// ── HTTP 클라이언트 ─────────────────────────────────────────────
// 오류 메시지에는 URL·응답 본문을 넣지 않는다(문서 경로에 보호자 토큰이 들어 있다).
export function createClient({ project, token, emulator, quotaProject, fetchImpl = fetch }) {
  if (!project) throw new RetentionError('project가 필요합니다');
  let docsBase, authBase, bearer;
  if (emulator) {
    if (!project.startsWith('demo-')) throw new RetentionError('에뮬레이터 모드는 demo- 프로젝트만 씁니다');
    if (!emulator.firestore || !emulator.auth) {
      throw new RetentionError('에뮬레이터 모드에는 Firestore와 Auth 에뮬레이터 주소가 모두 필요합니다');
    }
    docsBase = `http://${emulator.firestore}/v1/projects/${project}/databases/(default)/documents`;
    authBase = `http://${emulator.auth}/identitytoolkit.googleapis.com/v1/projects/${project}`;
    bearer = 'owner';
  } else {
    if (project.startsWith('demo-')) throw new RetentionError('demo- 프로젝트는 에뮬레이터에서만 씁니다');
    if (!token) throw new RetentionError('FIRESTORE_ACCESS_TOKEN이 필요합니다');
    docsBase = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
    authBase = `https://identitytoolkit.googleapis.com/v1/projects/${project}`;
    bearer = token;
  }
  const headers = { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' };
  if (quotaProject) headers['x-goog-user-project'] = quotaProject;

  async function call(label, url, { method = 'GET', body } = {}) {
    const res = await fetchImpl(url, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
    const json = await res.json().catch(() => ({}));
    if (!res.ok) {
      const status = json?.error?.status ?? '';
      const err = new RetentionError(`${label}: HTTP ${res.status} ${status}`.trim());
      err.status = status;
      throw err;
    }
    return json;
  }

  return {
    project,
    docsBase,
    async listCollectionIds() {
      let ids = [];
      let pageToken;
      do {
        const r = await call('컬렉션 목록', `${docsBase}:listCollectionIds`, { method: 'POST', body: { pageSize: 100, pageToken } });
        ids = ids.concat(r.collectionIds ?? []);
        pageToken = r.nextPageToken;
      } while (pageToken);
      return ids;
    },
    // 필드 마스크로 필요한 필드만 받는다. path는 'guardian_views' 또는 'inquiries/{id}/replies'.
    async listDocuments(path, fields, label = path.split('/')[0]) {
      const mask = fields.map((f) => `mask.fieldPaths=${encodeURIComponent(f)}`).join('&');
      let docs = [];
      let pageToken;
      do {
        const page = pageToken ? `&pageToken=${encodeURIComponent(pageToken)}` : '';
        const r = await call(`${label} 목록`, `${docsBase}/${path}?pageSize=300&${mask}${page}`);
        docs = docs.concat(r.documents ?? []);
        pageToken = r.nextPageToken;
      } while (pageToken);
      return docs;
    },
    // 한 묶음을 원자적으로 지운다. 읽은 뒤 바뀌었거나 이미 없으면 'skipped'.
    async commitDeletes(label, deletes) {
      try {
        await call(`${label} 삭제`, `${docsBase}:commit`, {
          method: 'POST',
          body: {
            writes: deletes.map(({ name, updateTime }) => (
              updateTime ? { delete: name, currentDocument: { updateTime } } : { delete: name })),
          },
        });
        return 'deleted';
      } catch (e) {
        if (e instanceof RetentionError && SKIPPABLE.has(e.status)) return 'skipped';
        throw e;
      }
    },
    async listUsers() {
      let users = [];
      let next;
      do {
        const page = next ? `&nextPageToken=${encodeURIComponent(next)}` : '';
        const r = await call('익명 계정 목록', `${authBase}/accounts:batchGet?maxResults=1000${page}`);
        users = users.concat(r.users ?? []);
        next = r.nextPageToken;
      } while (next);
      return users;
    },
    async deleteUsers(uids) {
      let failed = 0;
      for (let i = 0; i < uids.length; i += 1000) {
        const r = await call('익명 계정 삭제', `${authBase}/accounts:batchDelete`, {
          method: 'POST', body: { localIds: uids.slice(i, i + 1000), force: true },
        });
        failed += (r.errors ?? []).length;
      }
      return { deleted: uids.length - failed, failed };
    },
  };
}

// ── 스냅숏: 판정에 필요한 필드만 ────────────────────────────────
const tsMs = (v) => {
  if (!v || typeof v.timestampValue !== 'string') return null;
  const ms = Date.parse(v.timestampValue);
  return Number.isFinite(ms) ? ms : null;
};
const num = (v) => (v?.integerValue !== undefined ? Number(v.integerValue) : v?.doubleValue ?? null);
const str = (v) => (typeof v?.stringValue === 'string' ? v.stringValue : null);
const docId = (name) => name.slice(name.lastIndexOf('/') + 1);

function decodeUser(u) {
  const anonymous = !u.email && !u.phoneNumber && !(u.providerUserInfo?.length);
  const privileged = Boolean(u.customAttributes) || u.disabled === true;
  const lastActiveAt = Math.max(
    Number(u.createdAt ?? 0),
    Number(u.lastLoginAt ?? 0),
    u.lastRefreshAt ? Date.parse(u.lastRefreshAt) || 0 : 0,
  );
  return { uid: u.localId, anonymous, privileged, lastActiveAt };
}

export async function collectSnapshot(client) {
  const collections = await client.listCollectionIds();
  const has = (c) => collections.includes(c);
  const [links, views, inquiries, difficulty, users] = await Promise.all([
    has('guardian_links') ? client.listDocuments('guardian_links', ['ownerUid', 'expiresAt', 'schema']) : [],
    has('guardian_views') ? client.listDocuments('guardian_views', ['ownerUid', 'expiresAt', 'schema']) : [],
    has('inquiries') ? client.listDocuments('inquiries', ['authorUid', 'created_at']) : [],
    has('training_difficulty') ? client.listDocuments('training_difficulty', ['ownerUid', 'updated_at']) : [],
    client.listUsers(),
  ]);
  return {
    collections,
    links: links.map((d) => ({
      name: d.name, id: docId(d.name), updateTime: d.updateTime,
      schema: num(d.fields?.schema), expiresAt: tsMs(d.fields?.expiresAt), ownerUid: str(d.fields?.ownerUid),
    })),
    views: views.map((d) => ({
      name: d.name, id: docId(d.name), updateTime: d.updateTime,
      schema: num(d.fields?.schema), expiresAt: tsMs(d.fields?.expiresAt),
      hasExpiresField: d.fields?.expiresAt !== undefined, ownerUid: str(d.fields?.ownerUid),
    })),
    inquiries: inquiries.map((d) => ({
      name: d.name, id: docId(d.name), updateTime: d.updateTime,
      createdAt: tsMs(d.fields?.created_at) ?? Date.parse(d.createTime), authorUid: str(d.fields?.authorUid),
    })),
    difficulty: difficulty.map((d) => ({
      name: d.name, updateTime: d.updateTime,
      updatedAt: tsMs(d.fields?.updated_at) ?? Date.parse(d.updateTime), ownerUid: str(d.fields?.ownerUid),
    })),
    users: users.map(decodeUser),
  };
}

// ── 판정 (순수 함수) ───────────────────────────────────────────
export function planRetention(snapshot, now, policy = POLICY) {
  const guardianCutoff = now - policy.guardianGraceDays * DAY;
  const linkState = (l) => {
    if (l.schema !== 2 || l.expiresAt == null) return 'malformed';
    return l.expiresAt < guardianCutoff ? 'expired' : 'live';
  };
  const viewState = (v) => {
    if (v.schema == null && !v.hasExpiresField) return 'legacy';
    if (v.schema !== 2 || v.expiresAt == null) return 'malformed';
    return v.expiresAt < guardianCutoff ? 'expired' : 'live';
  };

  const groups = new Map();
  const group = (id) => {
    if (!groups.has(id)) groups.set(id, {});
    return groups.get(id);
  };
  for (const l of snapshot.links) group(l.id).link = l;
  for (const v of snapshot.views) group(v.id).view = v;

  const guardian = [];
  let legacyViews = 0;
  let expiredTokens = 0;
  let malformedKept = 0;
  for (const g of groups.values()) {
    const states = [g.link && linkState(g.link), g.view && viewState(g.view)].filter(Boolean);
    // 형식을 알 수 없는 문서는 지우지 않고 개수만 알린다. 살아 있는 쪽이 하나라도 있으면 둘 다 둔다.
    if (states.includes('malformed')) { malformedKept += 1; continue; }
    if (states.includes('live')) continue;
    guardian.push([g.link, g.view].filter(Boolean));
    if (!g.link && states[0] === 'legacy') legacyViews += 1;
    else expiredTokens += 1;
  }

  const inquiryCutoff = now - policy.inquiryRetentionDays * DAY;
  const inquiries = snapshot.inquiries.filter((q) => q.createdAt < inquiryCutoff);
  const difficultyCutoff = now - policy.difficultyStaleDays * DAY;
  const difficulty = snapshot.difficulty.filter((d) => d.updatedAt < difficultyCutoff);

  // 이번 정리 뒤에도 남는 서버 데이터의 소유자 계정은 지우지 않는다.
  const doomed = new Set([...guardian.flat(), ...inquiries, ...difficulty].map((d) => d.name));
  const owners = new Set();
  for (const d of [...snapshot.links, ...snapshot.views, ...snapshot.difficulty]) {
    if (!doomed.has(d.name) && d.ownerUid) owners.add(d.ownerUid);
  }
  for (const q of snapshot.inquiries) {
    if (!doomed.has(q.name) && q.authorUid) owners.add(q.authorUid);
  }
  const authCutoff = now - policy.authInactiveDays * DAY;
  const users = snapshot.users
    .filter((u) => u.anonymous && !u.privileged && u.lastActiveAt < authCutoff && !owners.has(u.uid))
    .map((u) => u.uid);

  const counts = {
    guardian_tokens: guardian.length,
    guardian_docs: guardian.flat().length,
    guardian_legacy_views: legacyViews,
    guardian_expired_links: expiredTokens,
    guardian_kept_malformed: malformedKept,
    inquiries: inquiries.length,
    training_difficulty: difficulty.length,
    auth_users: users.length,
  };
  const unknownCollections = snapshot.collections.filter((c) => !KNOWN_COLLECTIONS.includes(c));
  return { guardian, inquiries, difficulty, users, counts, unknownCollections };
}

// ── 적용 ──────────────────────────────────────────────────────
export async function applyPlan(client, plan, { replies } = {}) {
  const result = { deleted: {}, skipped: {}, failed: 0 };
  const bump = (bucket, key, n = 1) => { result[bucket][key] = (result[bucket][key] ?? 0) + n; };

  for (const docs of plan.guardian) {
    const r = await client.commitDeletes('보호자 링크', docs);
    if (r === 'deleted') bump('deleted', 'guardian_docs', docs.length);
    else bump('skipped', 'guardian_tokens');
  }
  for (const q of plan.inquiries) {
    const ids = replies?.get(q.name) ?? [];
    // 답변이 많으면 먼저 나눠 지우고, 마지막 묶음에서 문의를 지운다(한 commit은 500건까지).
    const head = ids.length - (ids.length % 499);
    for (let i = 0; i < head; i += 499) {
      await client.commitDeletes('문의 답변', ids.slice(i, i + 499).map((name) => ({ name })));
    }
    const rest = ids.slice(head).map((name) => ({ name }));
    const r = await client.commitDeletes('문의', [...rest, { name: q.name, updateTime: q.updateTime }]);
    if (r === 'deleted') {
      bump('deleted', 'inquiries');
      bump('deleted', 'inquiry_replies', ids.length);
    } else {
      bump('skipped', 'inquiries');
    }
  }
  for (const d of plan.difficulty) {
    const r = await client.commitDeletes('난이도', [d]);
    if (r === 'deleted') bump('deleted', 'training_difficulty');
    else bump('skipped', 'training_difficulty');
  }
  if (plan.users.length) {
    const r = await client.deleteUsers(plan.users);
    bump('deleted', 'auth_users', r.deleted);
    result.failed += r.failed;
  }
  return result;
}

export async function listReplies(client, inquiries) {
  const map = new Map();
  for (const q of inquiries) {
    const path = q.name.slice(q.name.indexOf('/documents/') + '/documents/'.length);
    const docs = await client.listDocuments(`${path}/replies`, ['created_at'], 'replies');
    map.set(q.name, docs.map((d) => d.name));
  }
  return map;
}

export async function runRetention({ client, now = Date.now(), apply = false, policy = POLICY, log = console.log }) {
  const snapshot = await collectSnapshot(client);
  const plan = planRetention(snapshot, now, policy);
  const replies = await listReplies(client, plan.inquiries);
  const replyCount = [...replies.values()].reduce((n, ids) => n + ids.length, 0);
  const total = plan.counts.guardian_docs + plan.counts.inquiries + replyCount
    + plan.counts.training_difficulty + plan.counts.auth_users;
  const summary = {
    mode: apply ? 'apply' : 'dry-run',
    now: new Date(now).toISOString(),
    policy,
    found: {
      guardian_links: snapshot.links.length,
      guardian_views: snapshot.views.length,
      inquiries: snapshot.inquiries.length,
      training_difficulty: snapshot.difficulty.length,
      auth_users: snapshot.users.length,
    },
    planned: { ...plan.counts, inquiry_replies: replyCount },
    unknown_collections: plan.unknownCollections,
  };
  if (total > policy.maxDeletesPerRun) {
    log(JSON.stringify(summary, null, 2));
    throw new RetentionError(
      `삭제 예정 ${total}건이 상한 ${policy.maxDeletesPerRun}건을 넘어 중단합니다. 판정을 확인한 뒤 --max-deletes로 올리세요.`);
  }
  if (apply) summary.result = await applyPlan(client, plan, { replies });
  log(JSON.stringify(summary, null, 2));
  return summary;
}

// ── CLI ───────────────────────────────────────────────────────
export function clientFromEnv(env, project) {
  if (env.FIRESTORE_EMULATOR_HOST || env.FIREBASE_AUTH_EMULATOR_HOST) {
    return createClient({
      project,
      emulator: { firestore: env.FIRESTORE_EMULATOR_HOST, auth: env.FIREBASE_AUTH_EMULATOR_HOST },
    });
  }
  return createClient({ project, token: env.FIRESTORE_ACCESS_TOKEN, quotaProject: env.GOOGLE_QUOTA_PROJECT });
}

export function parseArgs(argv) {
  const opts = { apply: false };
  for (const a of argv) {
    if (a === '--apply') opts.apply = true;
    else if (a.startsWith('--now=')) opts.now = Date.parse(a.slice('--now='.length));
    else if (a.startsWith('--max-deletes=')) opts.maxDeletes = Number(a.slice('--max-deletes='.length));
    else if (a.startsWith('--project=')) opts.project = a.slice('--project='.length);
    else throw new RetentionError(`모르는 옵션: ${a}`);
  }
  if (opts.now !== undefined && !Number.isFinite(opts.now)) throw new RetentionError('--now 형식이 잘못됐습니다');
  if (opts.maxDeletes !== undefined && !(Number.isInteger(opts.maxDeletes) && opts.maxDeletes >= 0)) {
    throw new RetentionError('--max-deletes 형식이 잘못됐습니다');
  }
  return opts;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const project = opts.project ?? (process.env.GCP_PROJECT || PROD_PROJECT);
  const client = clientFromEnv(process.env, project);
  const policy = opts.maxDeletes === undefined ? POLICY : { ...POLICY, maxDeletesPerRun: opts.maxDeletes };
  const summary = await runRetention({ client, now: opts.now ?? Date.now(), apply: opts.apply, policy });
  if (!opts.apply) console.log('미리보기(dry-run)라 아무것도 지우지 않았습니다. 지우려면 --apply.');
  if (summary.result?.failed) process.exitCode = 1;
}

// 예상하지 못한 오류도 원인은 보이되, 문서 경로(보호자 토큰)는 가린다.
export const redact = (text) => String(text).replace(/\/documents\/[^\s"'?]+/g, '/documents/…');

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((e) => {
    console.error(e instanceof RetentionError ? `중단: ${e.message}` : `중단: ${redact(`${e?.name}: ${e?.message}`)}`);
    process.exitCode = 1;
  });
}
