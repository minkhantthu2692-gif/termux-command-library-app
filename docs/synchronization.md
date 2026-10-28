# Synchronization and offline-first behavior

## Principles

1. **SQLite is the display source.** The UI opens and searches cached data without
   waiting for Firebase.
2. **Firestore is the sync source.** When online, remote changes are applied to
   SQLite; the UI updates through local Drift streams.
3. **No silent data loss.** Local mutations are written first and queued durably.
4. **No per-keystroke remote queries.** Search, filtering, sorting and pagination
   are local. Remote pulls are bounded and debounced by the coordinator.
5. **The app reports only what it can prove.** A queued write is pending, not
   synced; a command handed to Termux is sent, not completed.

## Startup sequence

```text
open SQLite
  → read settings / local guest UID
  → install or upgrade bundled seed catalogue
  → build providers and render UI from local data
  → if Firebase is configured: initialize Auth
  → auth session arrives
      → attach Firestore listeners
      → hydrate pages
      → process pending operations
      → apply remote profile
```

Firebase initialization failure leaves the app fully usable in local-only mode. It
does not block startup and does not clear local data.

## What is stored where

| Data | SQLite | Firestore |
| --- | --- | --- |
| Public commands | cached copy | `commands/{id}` |
| Seed commands | bundled, local-only | not uploaded |
| Own drafts/posts | local copy + pending state | `commands/{id}` |
| Favorites | per-UID rows | `users/{uid}.favoriteIds` |
| Pins + order | per-UID rows | `users/{uid}.pinnedIds` |
| Profile | per-UID row | `users/{uid}` |
| Settings | key/value | not synced |
| Pending operations | queue | not synced |
| AI history/cache/models | local | not synced |
| API keys | Android secure storage | never |

## Remote listeners

When a Firebase session is attached, the coordinator creates:

- A published-command listener:
  `where status == "published" orderBy updatedAt desc limit 250`.
- A profile listener for the signed-in UID.
- A pending-operation count listener.

Listeners are created once per session and cancelled on sign-out/dispose. Session
changes compare UID and local-only mode to avoid duplicate listeners.

Listener changes are applied as upserts/removals to SQLite. Drift streams then
notify the UI. Snapshot events are applied through a serialized async chain, so
two events cannot finish out of order and let an older upsert overwrite a newer
removal. Guide IDs with a queued delete, or deleted earlier in the session, are
filtered out before an upsert is applied. A listener error sets the sync status to
an error and schedules a bounded retry; it does not clear the local cache.

## Refresh

Manual swipe-to-refresh (or foreground resume when configured) calls
`SyncCoordinator.refresh`:

1. Pull up to 10 pages of 100 published commands, ordered by `updatedAt` descending.
2. Apply each page to SQLite using the conflict rules.
3. Fetch up to 200 guides authored by the current UID (including drafts).
4. Bootstrap the remote profile if it has not been bootstrapped this session.
5. Reconcile local pending flags with the queue, then process pending operations.
6. Record `lastSyncedAt` only when every queued write succeeded.

The refresh never truncates the local cache first. A failed page leaves earlier
pages and all existing local data intact. The app avoids overlapping refreshes with
a guard flag. A queued write that is still failing makes the refresh report an
error instead of claiming success, so the retry action is honest and actionable.

The realtime listener observes the newest 250 documents while paged refresh can
hydrate up to 1000. This is intentional: the UI remains bounded, and a full
history is not downloaded on every launch.

## Pending-operation queue

Local mutations while online enqueue a durable row in `pending_operations`:

| Type | Purpose |
| --- | --- |
| `commandUpsert` | Create/update an owned guide |
| `commandDelete` | Delete an owned guide |
| `favoritesSync` | Push the current favorite set |
| `pinsSync` | Push the current ordered pin list |
| `profileSync` | Create/update nickname/email/avatar |

The queue is keyed by `(uid, type, entityId)`. Repeated toggles of the same
favorite or pin collapse into one latest operation instead of growing without
bound. Command upserts and deletes are keyed by command ID. Queuing a delete
removes any pending upsert for the same guide in one transaction, because the
delete is the user's final intent; a later repair pass also refuses to re-queue an
upsert while a delete row exists.

Processing is serialized. Each operation:

1. Re-reads current local state (so a collapsed operation pushes the latest set).
2. Validates limits.
3. Writes to Firestore.
4. Marks the local command synced or removes the queue row.
5. On retryable failure, increments attempts, records a safe error code, and
   schedules a retry.
6. On permanent failure, records the error and continues with independent
   operations so one bad row does not block unrelated changes.

The queue is not cleared on sign-out. It is namespaced by UID and is cleared when
an account is deleted. Local-only guests never enqueue cloud operations.

Queue rows survive app restarts. `markFailed` truncates stored error text so a
server message cannot grow without bound or leak sensitive detail.

A local guide can still be marked `isPendingSync` after its queue row was lost, for
example when an older build acknowledged the write without clearing the flag. On
attach and refresh the coordinator re-queues such guides with `enqueueIfAbsent`,
which never replaces a payload that a concurrent edit already queued. The upsert is
idempotent, so a row that was already uploaded is simply acknowledged again.

## Conflict resolution

### Commands

The local row carries `isPendingSync`, `version` and `updatedAt`.

`applyRemotePost(post)`:

```text
if a local row exists:
  if local row is pending sync        → ignore remote (local intent wins for now)
  if remote.version < local.version   → ignore remote (stale)
  if remote.version == local.version
     and remote.updatedAt <= local.updatedAt → ignore remote
otherwise write remote row and clear pending
```

`markSynced(remotePost)`:

```text
if the local row became pending again while the write was in flight
  → keep the newer local state and pending flag
otherwise write the acknowledged remote state
```

This is a **version-first, timestamp-tiebreak, pending-local-wins** policy. It
prevents an in-flight listener snapshot from overwriting a newer unsent edit. After
the pending write is acknowledged, a later remote version wins normally.

The repository increments `version` on every save:

```text
newVersion = max(existing.version + 1, submitted.version + 1)
```

Firestore rules require a non-decreasing `authorUid`-preserving version, and the
immutability of `authorUid`/`createdAt`.

### Immutable timestamps and SQLite precision

SQLite stores command timestamps with second precision, while the server copy of
`createdAt` may carry microseconds. Re-sending a locally reconstructed `createdAt`
therefore changes the value and Firestore rejects the update with permission-denied.
Command writes update the mutable fields only; Firestore merges the stored
`createdAt` into the request resource, so the rules still see an unchanged value. A
full create is used only when the document genuinely does not exist. Profile writes
follow the same update-first rule for the same reason.

### Deletions

A user-initiated delete is tombstoned locally:

1. `deletePost` writes a durable `commandDelete` row for the UID and removes any
   pending `commandUpsert` for the same guide in one transaction.
2. It removes the local row and any favorite/pin references.
3. While the delete row exists, realtime snapshots and paged refreshes ignore that
   guide ID, so a document captured before the delete cannot resurrect it locally.
4. After the cloud delete succeeds the queue row is removed, and the ID is kept in
   an in-memory `recentlyDeleted` set for the rest of the session. This blocks
   late snapshots that were already in flight.
5. Manual refresh re-applies all tombstones after its fetch and delete passes.

`deleteRemoteCommand` handles a deletion that originated on another device. It
refuses to remove a local row that is still pending sync or is a seed guide. A
pending local edit therefore survives until it is pushed, at which point the guide
is recreated (subject to Firestore rules and version). This is deliberate:
unacknowledged local edits win, while an explicit user delete is protected by its
tombstone until the cloud delete is acknowledged.

### Favorites and pins

- Local toggles write SQLite first and enqueue a full-array push.
- While a local favorites or pins operation is pending, remote profile snapshots do
  **not** replace the local arrays.
- After the queue drains, a remote profile snapshot replaces the local arrays,
  because Firestore is the cross-device source of truth.
- Pins preserve the user's order; favorites are a set.

This is **last-write-wins per array**, with local pending writes taking priority
until acknowledged. Two devices that toggle different favorites at the same time
can overwrite one another because each push sends the full array. For the current
scale and product requirements this is acceptable and documented; a future version
can use atomic array operations or per-item documents if collaborative editing
becomes necessary.

### Profile

Nickname, email and avatar use the same pending-local-wins pattern. A profile
write is a merge on the server. The latest acknowledged profile is applied to
SQLite. Firebase Auth's display name is best-effort and does not block the local
profile.

## Sign-out, guest mode and account deletion

- **Sign-out** keeps public cache, seeds and local guest preferences. User-specific
  cloud rows are namespaced by UID and are not exposed to the guest identity.
- **Local guest** uses `local-guest-<uuid>` and never attaches Firestore listeners
  or enqueues cloud operations.
- **Clear local cache** removes cached public commands while preserving seeds, the
  user's own posts, favorites, pins and pending operations. It does not delete
  Firestore data.
- **Clear AI history/cache** is independent of command cache and cloud data.
- **Delete account** deletes authored cloud guides, the cloud profile and the Auth
  user, then removes that UID's local commands, preferences, pending rows and
  profile. Public cached/seed guides remain. This requires confirmation and
  re-authentication for registered accounts.

Clearing local data never deletes public posts.

## Retries and error states

- Retryable failures (network, timeout, rate limit, server) schedule a bounded
  retry and surface a status badge/message.
- Automatic processing attempts are capped so the app does not retry forever in a
  tight loop.
- Manual refresh can be used once connectivity returns.
- Permanent failures (permission denied, validation, missing profile) stop the
  batch and are shown to the user.
- Local usage is never blocked by a sync error.

The coordinator exposes phases (`localOnly`, `idle`, `syncing`, `error`) plus
pending count and last-sync time. The UI presents this as a compact status badge.

## Bounded work and performance

- Remote pull: max 10 pages × 100 documents per refresh.
- Realtime listener: latest 250 published commands.
- Authored command fetch: 200.
- Local page size: 20, max 100.
- Search debounce: 280 ms.
- Pending queue: one row per `(uid,type,entityId)`.
- Favorites: 5000; pins: 200.

These are constants, not unbounded queries. If the community grows beyond them,
add cursor-based pagination and a documented retention strategy rather than
raising limits silently.

## Testing offline behavior

The repository's Dart tests cover:

- remote upserts not overwriting pending local edits,
- older versions and older equal-version timestamps being rejected,
- equal versions using `updatedAt` as a tie-breaker,
- `markSynced` not clearing a newer pending edit,
- remote deletion preserving seeds and pending edits,
- an admin edit of another author's guide preserving the original UID, nickname
  and `createdAt`,
- an admin repair pass re-queueing another author's pending guide,
- a queued delete ignoring a stale remote snapshot,
- a snapshot arriving after a completed delete not restoring the guide,
- cache clearing preserving seeds/own posts/favorites/pending operations,
- account deletion clearing only the author's non-seed posts,
- queue collapse, ordering, retries, attempt counts and per-UID isolation,
- re-queuing a guide whose queue row was lost without overwriting a newer edit,
- failed queued writes being reported instead of a false "refreshed" result,
- file-backed SQLite persistence across close/reopen.

The Firestore rules suite also verifies that an owner can edit a guide by updating
mutable fields only, without resending `createdAt`.

To test manually: enable airplane mode, toggle favorites/pins, edit a draft,
restart the app, restore connectivity, then confirm the pending badge clears and
the remote document matches the latest local state.

## Migration path for larger profiles

If favorites/pins outgrow the arrays:

1. Introduce `users/{uid}/favorites/{commandId}` and/or
   `users/{uid}/pins/{commandId}` with position metadata.
2. Dual-write and backfill; keep the arrays as a cache.
3. Update rules, repositories, DAOs and sync tests together.
4. Remove the arrays only after all clients can read the new shape.
5. Keep the 1 MiB document limit in mind throughout.

This is not implemented in the current schema. The caps and this document are the
guardrails until a real need justifies the migration.
