import { readFileSync } from 'node:fs';
import test, { after } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
} from 'firebase/firestore';

const rules = readFileSync(
  new URL('../../firestore.rules', import.meta.url),
  'utf8',
);

const [emulatorHost, emulatorPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'
).split(':');

const testEnv = await initializeTestEnvironment({
  projectId: process.env.GCLOUD_PROJECT ?? 'demo-termux',
  firestore: {
    rules,
    host: emulatorHost,
    port: Number(emulatorPort),
  },
});

const CREATED_AT = Timestamp.fromMillis(1_700_000_000_000);
const UPDATED_AT = Timestamp.fromMillis(1_700_000_100_000);

function step(overrides = {}) {
  return {
    id: 'step-1',
    order: 0,
    title: 'Update packages',
    description: 'Refresh the package index.',
    command: 'pkg update -y',
    runMode: 'foreground',
    ...overrides,
  };
}

function command(overrides = {}) {
  return {
    name: 'Install a package',
    description: 'Refresh indexes and install a package.',
    categoryId: 'package_management',
    tags: ['pkg', 'install'],
    metadata: { shell: 'bash' },
    steps: [step()],
    authorUid: 'alice',
    authorNickname: 'Alice',
    createdAt: CREATED_AT,
    updatedAt: UPDATED_AT,
    version: 1,
    status: 'published',
    ...overrides,
  };
}

function profile(uid, overrides = {}, includeArrays = true) {
  return {
    uid,
    nickname: 'Alice',
    email: `${uid}@example.com`,
    avatarId: 'avatar-1',
    ...(includeArrays
      ? { favoriteIds: ['guide-1'], pinnedIds: ['guide-1'] }
      : {}),
    createdAt: CREATED_AT,
    updatedAt: UPDATED_AT,
    ...overrides,
  };
}

await testEnv.clearFirestore();

await testEnv.withSecurityRulesDisabled(async (context) => {
  const db = context.firestore();
  await setDoc(doc(db, 'commands/published'), command({ name: 'Published' }));
  await setDoc(
    doc(db, 'commands/draft'),
    command({ name: 'Draft', status: 'draft' }),
  );
  await setDoc(doc(db, 'commands/owned'), command({ name: 'Owned' }));
  await setDoc(
    doc(db, 'commands/admin-target'),
    command({ name: 'Admin target' }),
  );
  await setDoc(
    doc(db, 'commands/delete-me'),
    command({ name: 'Delete me' }),
  );
  await setDoc(doc(db, 'users/alice'), profile('alice'));
});

function guest() {
  return testEnv.unauthenticatedContext().firestore();
}

function asUser(uid, claims = {}) {
  return testEnv
    .authenticatedContext(uid, {
      email: `${uid}@example.com`,
      email_verified: true,
      firebase: { sign_in_provider: 'password' },
      ...claims,
    })
    .firestore();
}

const aliceDb = () => asUser('alice');
const bobDb = () => asUser('bob');
const adminDb = () => asUser('admin', { admin: true });

after(async () => {
  await testEnv.cleanup();
});

test('guest can read a published guide', async () => {
  await assertSucceeds(getDoc(doc(guest(), 'commands/published')));
});

test('guest cannot read a draft', async () => {
  await assertFails(getDoc(doc(guest(), 'commands/draft')));
});

test('guest cannot create a guide', async () => {
  await assertFails(
    setDoc(doc(guest(), 'commands/guest-created'), command({ authorUid: 'guest' })),
  );
});

test('anonymous Firebase user cannot create a guide', async () => {
  const anon = testEnv
    .authenticatedContext('anon', {
      firebase: { sign_in_provider: 'anonymous' },
    })
    .firestore();
  await assertFails(
    setDoc(doc(anon, 'commands/anon-created'), command({ authorUid: 'anon' })),
  );
});

test('registered user can create a published guide with their own UID', async () => {
  await assertSucceeds(
    setDoc(doc(aliceDb(), 'commands/alice-created'), command()),
  );
});

test('maximum-density guide is accepted end to end', async () => {
  const steps = Array.from({ length: 30 }, (_, index) =>
    step({
      id: `step-${index + 1}`,
      order: index,
      title: `Step ${index + 1}`,
      command: `echo step-${index + 1}`,
    }),
  );
  const tags = Array.from({ length: 10 }, (_, index) => `tag${index}`);
  const metadata = Object.fromEntries(
    Array.from({ length: 12 }, (_, index) => [`key${index}`, `value${index}`]),
  );
  await assertSucceeds(
    setDoc(
      doc(aliceDb(), 'commands/dense-guide'),
      command({ steps, tags, metadata }),
    ),
  );
});

test('one step beyond the maximum is rejected', async () => {
  const steps = Array.from({ length: 31 }, (_, index) =>
    step({
      id: `step-${index + 1}`,
      order: index,
      title: `Step ${index + 1}`,
      command: `echo step-${index + 1}`,
    }),
  );
  await assertFails(
    setDoc(doc(aliceDb(), 'commands/thirty-one-steps'), command({ steps })),
  );
});

test('registered user cannot create a guide for another UID', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/spoofed-author'),
      command({ authorUid: 'bob' }),
    ),
  );
});

test('draft may have no steps', async () => {
  await assertSucceeds(
    setDoc(
      doc(aliceDb(), 'commands/alice-empty-draft'),
      command({ status: 'draft', steps: [] }),
    ),
  );
});

test('published guide must have at least one usable step', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/alice-empty-published'),
      command({ steps: [] }),
    ),
  );
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/alice-empty-command'),
      command({ steps: [step({ command: '' })] }),
    ),
  );
  // Every indexed step is validated, not only the first one.
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/alice-bad-second-step'),
      command({
        steps: [
          step(),
          step({ id: 'step-2', order: 1, title: '', command: 'pkg upgrade' }),
        ],
      }),
    ),
  );
});

test('owner can update their own guide and increment the version', async () => {
  await assertSucceeds(
    setDoc(
      doc(aliceDb(), 'commands/owned'),
      command({ name: 'Owned, edited', version: 2 }),
    ),
  );
});

test('owner cannot change the author UID', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/owned'),
      command({ authorUid: 'bob', version: 3 }),
    ),
  );
});

test('owner cannot lower the version', async () => {
  await assertFails(
    setDoc(doc(aliceDb(), 'commands/owned'), command({ version: 1 })),
  );
});

test('another registered user cannot update a guide', async () => {
  await assertFails(
    setDoc(
      doc(bobDb(), 'commands/owned'),
      command({ authorUid: 'alice', name: 'Hijacked', version: 4 }),
    ),
  );
});

test('admin can update another user guide', async () => {
  await assertSucceeds(
    setDoc(
      doc(adminDb(), 'commands/admin-target'),
      command({ name: 'Moderated', version: 2 }),
    ),
  );
});

test('admin can read a draft', async () => {
  await assertSucceeds(getDoc(doc(adminDb(), 'commands/draft')));
});

test('owner can delete their own guide', async () => {
  await assertSucceeds(deleteDoc(doc(aliceDb(), 'commands/delete-me')));
});

test('another user cannot delete a guide', async () => {
  await assertFails(deleteDoc(doc(bobDb(), 'commands/published')));
});

test('profile is private to its owner', async () => {
  await assertSucceeds(getDoc(doc(aliceDb(), 'users/alice')));
  await assertFails(getDoc(doc(bobDb(), 'users/alice')));
  await assertFails(setDoc(doc(bobDb(), 'users/alice'), profile('alice')));
});

test('profile may be created before the favorite and pin arrays exist', async () => {
  const carol = asUser('carol');
  await assertSucceeds(
    setDoc(doc(carol, 'users/carol'), profile('carol', {}, false)),
  );
  await assertSucceeds(getDoc(doc(carol, 'users/carol')));
});

test('profile cannot contain a role-like field', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'users/alice'),
      profile('alice', { role: 'admin' }),
    ),
  );
});

test('profile createdAt is immutable', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'users/alice'),
      profile('alice', { createdAt: Timestamp.fromMillis(1) }),
    ),
  );
});

test('favorite and pin arrays are bounded', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'users/alice'),
      profile('alice', {
        favoriteIds: Array.from({ length: 5001 }, (_, index) => `c-${index}`),
      }),
    ),
  );
  await assertFails(
    setDoc(
      doc(aliceDb(), 'users/alice'),
      profile('alice', {
        pinnedIds: Array.from({ length: 201 }, (_, index) => `c-${index}`),
      }),
    ),
  );
});

test('command tags are bounded', async () => {
  await assertFails(
    setDoc(
      doc(aliceDb(), 'commands/too-many-tags'),
      command({ tags: Array.from({ length: 11 }, (_, index) => `t${index}`) }),
    ),
  );
});

test('public published query works, unfiltered query does not', async () => {
  const guestDb = guest();
  await assertSucceeds(
    getDocs(
      query(
        collection(guestDb, 'commands'),
        where('status', '==', 'published'),
      ),
    ),
  );
  await assertFails(getDocs(collection(guestDb, 'commands')));
});
