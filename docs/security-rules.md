# Security rules

The authoritative rules are in [`firestore.rules`](../firestore.rules). This
document explains the model and operational expectations; if the two disagree,
the checked-in rules file wins.

## Role model

Roles are derived only from Firebase Authentication:

| Role | How it is determined | What it can do |
| --- | --- | --- |
| Guest | `request.auth == null`, or an anonymous provider | Read published guides; keep local favorites/pins; use local data and AI |
| Registered | Signed in with a non-anonymous provider | Read published guides and own drafts; create guides; edit/delete own guides; sync own profile |
| Admin | Custom claim `admin == true` | Read all guides; create own guides; edit/delete any guide |

Admin is a **custom claim**, not a profile field. A client can read its claims but
cannot write them. Only a trusted operator using the Admin SDK or Identity Toolkit
Admin API can set the claim. See [Admin configuration](admin-setup.md).

The app never reads a `role` field from a user document, and the rules reject
profile documents containing unexpected fields. Adding a `role` field to a
profile therefore cannot grant privileges.

## `commands/{commandId}`

### Read

```text
published guide
OR admin
OR signed-in author reading their own document
```

This permits:

- Unauthenticated/public reads of published guides.
- Authors reading their own drafts and archived guides.
- Admins reading everything.

Queries must be constrained so every returned document satisfies the rule. The
public sync query filters `status == "published"`. An author query filters
`authorUid == <uid>`.

### Create

```text
registered provider
AND request.resource.data.authorUid == request.auth.uid
AND validCommand(request.resource.data)
```

Anonymous users are rejected even though they have a Firebase UID. This implements
"guests cannot upload public posts" at the server, not just in the UI.

### Update

```text
(admin)
OR (registered AND owner
    AND authorUid is unchanged
    AND createdAt is unchanged
    AND version does not decrease
    AND validCommand)
```

The `authorUid` and `createdAt` immutability prevents ownership transfer. The
version check allows offline edits to arrive after newer ones only if they carry a
version at least as high; the repository itself increments versions on every save.

### Delete

```text
admin
OR (registered owner)
```

Hard delete. The app deletes the author's guides before deleting the Auth account.

### Validation

`validCommand` enforces:

- The exact allowed top-level keys and step keys.
- Name 1–100 characters; description ≤ 4000.
- A valid category ID.
- ≤ 10 tags whose combined length is ≤ 320 characters. `join()` fails for
  non-string elements, so the array stays string-typed; the app trims and
  length-validates each tag before upload.
- ≤ 12 metadata entries. The rules cannot iterate arbitrary map keys, so only
  the entry count is enforced server-side; the app requires string values and
  the 1 MiB Firestore document cap bounds the payload.
- ≤ 30 steps. The first five steps are validated field by field: shape, ID,
  0-based order, title, description, command and run mode, with command ≤ 64,000,
  description ≤ 2000 and title ≤ 120 characters. Later steps rely on the size cap
  plus client-side validation.
- `authorUid` non-empty; `authorNickname` ≤ 40.
- `createdAt`/`updatedAt` are timestamps; `version` is an integer ≥ 1.
- Status is `published`, `draft` or `archived`.
- A published guide has at least one step with a non-empty title and command.

Firestore rules evaluate at most 1,000 expressions per request and have no way to
iterate a list, so validating all 30 steps would exceed the evaluation budget.
Deep-checking the first five steps keeps the common guide shapes strict while
leaving room in the budget for tags, metadata and profile writes. This is a
schema-integrity trade-off, not an authorization boundary: only the registered
owner or an admin may write a command document at all, and the Flutter app
validates every step before upload (`CommandRepository`).

The rules do not attempt to validate shell syntax. Command text is data and must
not be executed by the editor or formatter.

## `users/{uid}`

```text
read/delete: owner only
create/update: owner only, with validation
```

The profile contains favorites and pins, so it is private. The rules require:

- `uid` exactly matches the document ID and caller.
- Only the allowed keys: `uid`, `nickname`, `email`, `avatarId`, `favoriteIds`,
  `pinnedIds`, `createdAt`, `updatedAt`.
- `uid`, `nickname`, `email`, `avatarId`, `createdAt` and `updatedAt` are present.
- The favorite/pin arrays may be absent briefly during profile bootstrap, but when
  present they are validated as lists.
- `createdAt` is immutable on update.
- Nickname ≤ 40, email ≤ 254, avatar ID ≤ 40.
- ≤ 5000 favorite IDs and ≤ 200 pinned IDs; each ID is a non-empty string.
- Timestamps are actual timestamps.

There is no public profile directory. A displayed author nickname is stored on the
command document at write time. If a user later changes their nickname, existing
guides keep the old display name until they are updated; this avoids an extra
read/query and a denormalized update fan-out.

## Everything else

A catch-all rule denies all other paths. Do not add a client-writable roles
collection, admin flag document or Storage path without a review of the whole
authorization model.

## Deploying rules

```bash
firebase deploy --only firestore:rules
```

Rules changes are security changes. Review the diff, test with the emulator or a
staging project, and deploy deliberately. Do not deploy from an untrusted
workstation or with a service-account key committed to the repository.

## Emulator testing

The Firestore emulator can validate rules before deployment:

```bash
firebase emulators:start --only auth,firestore
```

Use the Emulator UI or a rules-unit-testing harness to verify at least:

1. Guest reads a published guide.
2. Guest cannot create a guide.
3. Registered user creates a guide with their own UID.
4. Registered user cannot create a guide with another UID.
5. Owner edits their own guide, preserving `authorUid` and `createdAt`.
6. Owner cannot change `authorUid` or lower `version`.
7. A second user cannot edit or delete the first user's guide.
8. Admin can edit/delete any guide.
9. Owner reads/writes only their own `users/{uid}` document.
10. A user cannot add a role-like field to a profile.
11. Oversized tags/steps/arrays are rejected.
12. A draft can omit steps; publishing requires at least one usable step.
13. A maximum-density guide (30 steps, 10 tags, 12 metadata entries) is accepted
    end to end; one step beyond the limit is rejected.

The rules suite lives in `test/rules/rules.test.mjs` with 25 tests. Run it with:

```bash
# Requires Java on PATH. On Windows without a system JDK, point JAVA_HOME at a
# JDK (for example Android Studio's bundled JBR) and prepend its bin to PATH.
npx --yes firebase-tools@latest emulators:exec \
  --only firestore --project demo-termux "node test/rules/rules.test.mjs"
```

Setup lives in `test/rules/package.json` (`@firebase/rules-unit-testing`, `firebase`)
and the tests read `firestore.rules` directly, so they always run against the
current file.

The Flutter app's Dart tests run without Firebase. Rules tests require Java for
the emulator and are a separate integration step; they are not executed by
`flutter test`.

## Known trade-offs

- Public reads are allowed for published guides, including by unauthenticated
  clients. The app itself uses local guests until a Firebase session exists.
- Favorites and pins are arrays in one document. Concurrent writes from two devices
  can overwrite each other; the app's conflict policy is documented in
  [Synchronization](synchronization.md).
- Rules validate shape and ownership, not content quality or command safety.
- App Check is not enabled. Consider it before a large public launch.
- Firebase client identifiers are not secrets; a service-account key is. Never
  ship server credentials in the app.
