# Firebase Authentication setup

## Supported flows

| Flow | Behavior |
| --- | --- |
| Continue as guest | Local-only identity (`local-guest-<uuid>`). No Firebase user is created, so no network or Firebase project is required. |
| Anonymous Firebase user | Created when the user chooses an online guest flow. The UID can later be upgraded by account linking. |
| Register | Avatar, nickname, email, password and confirmation. |
| Sign in | Email/password. |
| Password reset | Firebase reset email; no OTP or SMS step. |
| Link guest → registered | The current anonymous UID is linked to email/password, preserving UID, posts, favorites and pins. |
| Change password | Requires the current password (re-authentication) and a new password of at least 8 characters. |
| Sign out | Returns to the local guest identity; local cache and seed content remain. |
| Delete account | Re-authenticates, deletes authored cloud guides, profile, Auth user and local user rows. |

The app intentionally does **not** implement:

- OTP or SMS verification.
- Mandatory email verification gates.
- Custom password-reset codes.
- Social sign-in providers.

`sendEmailVerification()` exists in the repository for future use, but no screen
blocks the user on verification.

## Enable the providers

1. Firebase console → **Authentication** → **Get started**.
2. **Sign-in method → Email/Password → Enable**. Email link can remain disabled.
3. **Sign-in method → Anonymous → Enable** if you want online guest accounts in
   addition to local-only guests.
4. Under **Settings → Authorized domains**, keep the generated Firebase domains
   and add any domain used for hosted builds. Password reset links use this list.
5. Customize **Templates** with your app name and support address so reset emails
   are recognizable.
6. Do not disable the Anonymous provider while anonymous accounts still exist;
   those users would lose access to their data.

Anonymous accounts are not automatically cleaned up. If online guest accounts
are enabled in production, review Firebase Auth's anonymous-user cleanup options
or provide an in-app upgrade path. This app already provides account linking.

## Email handling

`Validators.normalizeEmail` implements the requirements:

- Trims whitespace and lowercases the address.
- If the input has no `@`, appends `@gmail.com`:
  `myusername` → `myusername@gmail.com`.
- Explicit non-Gmail domains are preserved.
- Basic syntax is validated before calling Firebase.
- The registration screen validates password confirmation locally.

The rule is intentionally simple: an input containing `@` is treated as an
explicit email address. It never rewrites `user@outlook.com` to Gmail.

## Password policy

- Minimum 8 characters, enforced client-side and by Firebase.
- Show/hide toggle, correct keyboard type and focus traversal.
- Confirm-password matching with an inline message.
- Firebase remains the authority for password strength and rate limits.
- Reset emails are sent by Firebase; the app never sees the reset token.

## Anonymous-to-registered linking

The app calls `linkWithCredential` on the current anonymous user. Because the UID
does not change:

- Previously authored posts keep the same `authorUid`.
- Firestore profile favorites and pins remain attached to the same UID.
- Local rows keyed by UID remain valid.
- The sync coordinator queues a profile sync after linking.

After linking, the Firebase ID token's `sign_in_provider` becomes `password`.
Firestore rules use this provider value to distinguish registered users from
anonymous guests, so refresh the token (or restart the app) if a write is
unexpectedly denied immediately after linking.

If the email is already used by another Firebase account, linking fails with
`credential-already-in-use`. The app surfaces an authentication error; the user
must sign in to the existing account instead. This project does not merge two
different Firebase UIDs, because that would require transferring command
ownership and is outside the current authorization model.

## Account deletion

Deletion is a destructive, confirmed operation:

1. The user confirms the action and explains that public guides will be removed.
2. A registered user enters the current password for re-authentication.
3. Authored cloud guides are deleted, then the Firestore profile.
4. The Firebase Auth user is deleted.
5. Local user-owned commands, preferences, pending operations and profile rows
   are cleared. Cached public content and seed guides remain.
6. The app returns to a local guest identity.

Clearing local cache/data is a different operation and never deletes public
posts. See [Architecture](architecture.md) for the exact repository split.

If deletion fails midway, Firestore rules and Firebase Auth remain authoritative.
Sign in again and repeat the operation; the repository is designed to treat
already-deleted posts as success.

## Authorization model

| Role | Definition | Capabilities |
| --- | --- | --- |
| Guest | No Firebase user, or an anonymous Firebase user | Read published guides; local favorites/pins; use local AI. Guests cannot publish commands to Firestore. |
| Registered | Non-anonymous Firebase sign-in provider | Everything a guest can do, plus upload/edit/delete own guides and synchronize favorites/pins. |
| Admin | Registered user with custom claim `admin: true` | Manage all guides. Admin status is never stored in a profile document. |

The role is **not** stored in Firestore. A client cannot grant itself admin by
writing a field. See [Security rules](security-rules.md) and
[Admin configuration](admin-setup.md).

## Client-side checks vs. server enforcement

The UI hides upload actions for users who cannot publish and confirms destructive
actions. These checks are for usability, not security. Firestore rules enforce:

- Registered provider for command creation.
- `authorUid` equals the caller UID on create and is immutable on update.
- Owner or admin for update/delete.
- Field, list and string limits.
- Private profile access.

Hiding a button is never treated as authorization.

## Testing checklist

Without a live Firebase project the repository's Dart tests still pass in
local-only mode. With a project configured:

1. Register an account, sign out, sign in and reset the password.
2. Continue as local guest, favorite a guide, then register/link and confirm the
   favorite survives.
3. Sign out and back in; confirm favorites and pin ordering survive.
4. Try to update another account's command directly with the Firestore SDK; it
   must be rejected.
5. Delete an account and confirm authored guides, profile and local user rows are
   gone while public cached/seed guides remain.
6. Remove the Firebase defines and confirm the app still opens in local-only mode.
