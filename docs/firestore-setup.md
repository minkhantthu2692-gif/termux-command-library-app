# Firestore setup

Firestore is used for two collections only:

```text
commands/{commandId}   public command guides
users/{uid}            private profile, favorite IDs and ordered pin IDs
```

There is **no Firebase Storage**, no per-favorite document, no per-pin document
and no client-writable role collection.

---

## 1. Create the database

1. Firebase console → **Firestore Database** → **Create database**.
2. Choose **production mode**. The checked-in rules then replace the defaults.
3. Choose a region. Firestore locations cannot be changed in place.
4. Deploy the rules and indexes as described in
   [Firebase setup](firebase-setup.md#6-deploy-rules-and-indexes).

The app also works with the Firestore emulator, but the Flutter build does not
auto-connect to it. Add an explicit debug configuration if you need that.

## 2. `commands` document shape

`FirestoreCloudStore` is the single place that understands this shape. Field
names are camelCase.

```json
{
  "name": "Install a package",
  "description": "Refresh indexes and install a package.",
  "categoryId": "package_management",
  "tags": ["pkg", "install"],
  "metadata": { "shell": "bash" },
  "steps": [
    {
      "id": "uuid",
      "order": 0,
      "title": "Update package lists",
      "description": "Refresh the available package index.",
      "command": "pkg update -y",
      "runMode": "foreground"
    }
  ],
  "authorUid": "firebase-auth-uid",
  "authorNickname": "Ada",
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>",
  "version": 1,
  "status": "published"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | 1–100 characters, required |
| `description` | string | Up to 4000 characters |
| `categoryId` | string | One of the ten stable category IDs |
| `tags` | list<string> | Up to 10 tags, each 1–32 characters |
| `metadata` | map<string,string> | Up to 12 entries; values up to 500 characters |
| `steps` | list<map> | Up to 30 ordered steps |
| `steps[].id` | string | Stable step ID, up to 64 characters |
| `steps[].order` | integer | 0-based; UI writes sequential values |
| `steps[].title` | string | Up to 120 characters |
| `steps[].description` | string | Up to 2000 characters |
| `steps[].command` | string | Up to 64,000 characters, preserved exactly |
| `steps[].runMode` | string | `foreground` or `background` |
| `authorUid` | string | Immutable; equals the creator's Auth UID |
| `authorNickname` | string | Denormalized for display; up to 40 characters |
| `createdAt` | timestamp | Immutable |
| `updatedAt` | timestamp | Updated on each save |
| `version` | integer | Monotonically increasing per guide |
| `status` | string | `published`, `draft` or `archived` |

The app enforces every bound in this table before upload. Cloud Firestore
Security Rules cannot iterate a list, and they may evaluate at most 1,000 rule
expressions per request, so the rules deep-check only the first five steps and
apply size caps to tags (≤ 10, combined length ≤ 320) and metadata (≤ 12
entries). See [Security Rules](security-rules.md#validation) for the exact
server-side behavior.

Category IDs:

```text
package_management
linux_distributions
shell_scripting
file_storage
git_version_control
programming_development
networking_remote
system_process
termux_api_device
security_testing
```

Seed guides are local-only and reserved to author UID `termux-library`. They are
not uploaded to Firestore. Do not use that UID for a real Firebase account.

### Commands are stored verbatim

`steps[].command` is never trimmed or rewritten. Newlines, quotes, pipes,
redirects, `$`, backticks and whitespace are part of the value. Use the Firebase
console cautiously when editing; it can change whitespace. Prefer editing through
the app.

## 3. `users` document shape

```json
{
  "uid": "firebase-auth-uid",
  "nickname": "Ada",
  "email": "ada@example.com",
  "avatarId": "built-in-avatar-id",
  "favoriteIds": ["command-id-1", "command-id-2"],
  "pinnedIds": ["command-id-3", "command-id-1"],
  "createdAt": "<Firestore Timestamp>",
  "updatedAt": "<Firestore Timestamp>"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `uid` | string | Must equal the document ID / Auth UID |
| `nickname` | string | Up to 40 characters |
| `email` | string | Up to 254 characters |
| `avatarId` | string | Built-in avatar identifier; no uploaded images |
| `favoriteIds` | list<string> | Maximum 5000 entries |
| `pinnedIds` | list<string> | Maximum 200 entries; order is meaningful |
| `createdAt` | timestamp | Set once |
| `updatedAt` | timestamp | Updated on each profile write |

Favorites are a set; pins are an ordered list. The app mirrors both in SQLite per
UID so the UI can respond immediately and offline. The Firestore profile is the
cross-device source of truth when no local toggle is waiting to sync.

A profile may briefly exist without the two arrays while bootstrap and the
favorites/pins queues catch up. Readers treat an absent array as an empty list.

The profile document is **private**. There is no public directory of users; the
author's nickname shown in a guide is denormalized into the command document.

### Document-size limits

Firestore documents are capped at 1 MiB. The 5000-favorite and 200-pin limits keep
the arrays comfortably below that. If the collection ever needs more:

1. Add a `favorites/{commandId}` and/or `pins/{commandId}` subcollection with an
   integer position.
2. Backfill from the existing arrays in a controlled migration.
3. Keep the profile document's arrays as a small cache during the transition.
4. Update the rules, the repository and the local schema in the same release.
5. Do not delete the arrays until readers have migrated.

This migration is not implemented now; the limits are documented in
`AppConstants` and enforced before writing.

## 4. Query patterns and indexes

The remote layer uses:

```text
commands where status == "published" order by updatedAt desc limit N
commands where authorUid == "<uid>" limit 200
users/{uid} snapshot
```

`firestore.indexes.json` defines the composite indexes used by the first query
and anticipates the author/updatedAt ordering:

- `status ASC, updatedAt DESC`
- `authorUid ASC, updatedAt DESC`

Index creation is asynchronous. Until it finishes, Firestore returns
`failed-precondition` with a console link. The UI surfaces a synchronization
error; local browsing still works.

Search, category filters and sort order are **local SQLite operations**. They do
not create per-keystroke Firestore queries. Synchronization pulls a bounded number
of pages per refresh; the latest 250 published commands are also observed through
a realtime listener.

## 5. Reading and writing

- A guest (no Firebase user) may read published commands through the rules, but
  the shipped app uses a local identity for guests and does not attach cloud
  listeners until a Firebase session exists.
- Registered users read published commands plus their own drafts.
- Admins read all commands.
- Only the owner may write their profile document.
- The app uses `set(..., merge: false)` for commands so stale fields are removed,
  and `set(..., merge: true)` for profile writes.

Deletes are hard deletes. The app removes the author's cloud guides before
deleting the Auth account. There is no soft-delete tombstone collection; a
removed command is removed from local caches by the realtime listener. Locally, a
queued `commandDelete` row acts as a temporary tombstone so a Firestore snapshot
captured before the delete cannot restore the guide.

## 6. Emulator

```bash
firebase emulators:start --only auth,firestore
```

Then point a debug build at the emulator. This is intentionally not wired into
release builds. The emulator requires Java 11+ and does not replace testing
against the real project's rules deployment.

## 7. Backups and operations

- Firestore managed exports require a Blaze plan. If the library has valuable
  community content, schedule exports before enabling public uploads.
- Use Firestore's built-in usage dashboard and set Google Cloud budget alerts.
- Review rules in source control; deploy them with the Firebase CLI.
- Never use the Firebase console to grant roles by editing profile documents.
  Admin is an Auth custom claim.
- Do not add a Storage bucket for avatars. Use the app's built-in avatar IDs.
