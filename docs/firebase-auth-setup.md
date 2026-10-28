# Firebase Authentication setup

## Supported flows

| Flow | Behavior |
| --- | --- |
| Continue as guest | Local-only identity (`local-guest-<uuid>`). No Firebase user is created, so no network or Firebase project is required. |
| Anonymous Firebase user | Created when the user chooses an online guest flow. The UID can later be upgraded by account linking. |
| Register | Avatar, nickname, email, password and confirmation. |
| Sign in | Email/password. |
| Google sign-in | Native Google account picker through `google_sign_in` (Android Credential Manager). The ID token is exchanged with `signInWithCredential(GoogleAuthProvider.credential(...))`. Available below the email form on the sign-in and registration screens. |
| GitHub sign-in | GitHub OAuth **device flow**. The app shows a short code, opens `github.com/login/device` and polls for an access token, which is exchanged with `signInWithCredential(GithubAuthProvider.credential(...))`. No client secret ships in the app. Available below the email form on the sign-in and registration screens. |
| Link guest → provider | On the registration screen, the provider is linked to the current anonymous UID with `linkWithCredential` (Google and GitHub), preserving UID, posts, favorites and pins. |
| Password reset | Firebase reset email; no OTP or SMS step. |
| Link guest → registered | The current anonymous UID is linked to email/password, preserving UID, posts, favorites and pins. |
| Change password | Requires the current password (re-authentication) and a new password of at least 8 characters. |
| Sign out | Returns to the local guest identity; local cache and seed content remain. |
| Delete account | Re-authenticates, deletes authored cloud guides, profile, Auth user and local user rows. |

The app intentionally does **not** implement:

- OTP or SMS verification.
- Mandatory email verification gates.
- Custom password-reset codes.
- Apple, Facebook or other social providers. Only Google and GitHub are
  offered; adding another provider only requires a new `AuthProviderKind` case
  and a Firebase console configuration.

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
7. Enable **Google** and **GitHub** as described below. Both are optional: the
   buttons are hidden when Firebase is not configured, and a disabled provider
   shows a clear "sign-in method not enabled" message instead of crashing.

Anonymous accounts are not automatically cleaned up. If online guest accounts
are enabled in production, review Firebase Auth's anonymous-user cleanup options
or provide an in-app upgrade path. This app already provides account linking.

## Google sign-in setup

1. Firebase console → **Authentication → Sign-in method → Google → Enable**.
2. Choose a **project support email**. It is shown on the account picker.
3. Add the signing fingerprints for every build you distribute. In **Project
   settings → Your apps → Android app → Add fingerprint**, add the debug
   SHA-1/SHA-256 and the release/Play App Signing SHA-1/SHA-256. Without them
   the native Google SDK cannot obtain an ID token, even though the console shows
   the provider as enabled.
4. Download the refreshed `google-services.json` after adding fingerprints or
   clients and replace `android/app/google-services.json`.
5. Rebuild the app. The native SDK reads the Web OAuth client
   (`client_type: 3`) from `google-services.json`; the Android OAuth client
   (`client_type: 1`) must match the signing certificate. No server client ID
   needs to be hard-coded.

Google sign-in does **not** use Firebase's hosted `/__/auth/handler` redirect.
It opens the Android account picker and sends the returned ID token to Firebase
with `signInWithCredential`, so it is not affected by browser session-storage
partitioning or the "missing initial state" error. The app depends on
`google_sign_in` only inside `GoogleIdentityClient`; the rest of the app still
uses the provider-neutral `AuthGateway` contract.

If you build without `google-services.json` (for example an iOS or CI build),
pass the Web OAuth client explicitly:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

## GitHub sign-in setup

1. Create a GitHub OAuth App: GitHub **Settings → Developer settings → OAuth Apps
   → New OAuth App**.
2. Set **Authorization callback URL** to the Firebase Auth handler for the
   project:

   ```text
   https://<project-id>.firebaseapp.com/__/auth/handler
   ```

   For the current project that is
   `https://termuxcommandlibrary.firebaseapp.com/__/auth/handler`. The device
   flow does not use this callback, but GitHub still requires the field when the
   OAuth App is created.
3. Copy the **Client ID** and generate a **Client secret**.
4. Firebase console → **Authentication → Sign-in method → GitHub → Enable** and
   paste both values. Save.
5. In the same GitHub OAuth App settings, tick **Enable Device Flow** and update
   the app. This is required: without it GitHub answers
   `device_flow_disabled` and the app shows a configuration error.
6. The app requests the `read:user user:email` scopes, so GitHub accounts with a
   private primary email still return an address to Firebase. Without
   `user:email` those users sign in with a null email.
7. The GitHub app can stay in development mode while testing. Only GitHub
   accounts added as testers can authorize it until the app is published.

GitHub does **not** use Firebase's hosted OAuth handler. It uses GitHub's
secret-less device flow:

1. The app requests a one-time user code from GitHub.
2. The user taps **Open GitHub**, enters the displayed code on
   `github.com/login/device`, and approves the OAuth app.
3. The app polls GitHub until it receives an access token.
4. The token is passed to Firebase with `signInWithCredential` and is never
   stored or logged.

The device flow works in any Android browser, so it is not affected by browser
session-storage partitioning or the `missing initial state` error. The app's
public OAuth client ID is embedded in the build (it is not a secret). Override it
for another environment with
`--dart-define=GITHUB_CLIENT_ID=<client-id>`. The client secret must stay in the
Firebase console and must never appear in the app, source control,
`--dart-define`, logs or documentation.

If GitHub still reports `device_flow_disabled`, the OAuth App is missing the
**Enable Device Flow** checkbox; see
[Troubleshooting](troubleshooting.md#github-device-flow-problems).

## Social sign-in behavior

- Two compact icon buttons, Google and GitHub, appear **below** the email form
  on both authentication screens. Email/password remains the primary path. The
  buttons are hidden when the build is local-only (no Firebase configuration).
- Google opens the native account picker. GitHub opens a device-code dialog and
  the browser; the app polls until the code is approved.
- On **Sign in**, the provider creates or reuses a Firebase account. On
  **Create account**, if the current session is an anonymous Firebase user, the
  provider is linked to that UID so the existing collection and authored guides
  survive.
- If the provider account is already attached to a different Firebase user, the
  link fails and the app reports that an account already exists. The user must
  sign in with the provider instead; two Firebase UIDs are never merged.
- An email collision (`account-exists-with-different-credential`) is shown as a
  non-retryable error in the GitHub dialog: the user must sign in with the method
  that owns the email. Registered accounts cannot link GitHub in the current app.
  See
  [Troubleshooting › GitHub email already belongs to another account](troubleshooting.md#github-email-already-belongs-to-another-account)
  for the available options and their security trade-offs.
- Closing the browser tab or cancelling the account picker is treated as a
  cancellation, not an error, and leaves the form usable.
- If a provider flow has not returned after 45 seconds, the screen suggests
  finishing sign-in in the browser or going back and trying again. The sign-in
  future is not force-timed-out, so a late result is still handled correctly.
- The provider display name seeds the local profile nickname when the profile is
  first created. The user can edit it later in Profile.
- The email field is disabled while a provider flow is active to prevent two
  concurrent sign-in attempts.

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

The app links the current anonymous user with `linkWithCredential` (email) or,
for providers, `linkWithCredential` (native Google ID token) and
`linkWithProvider` (GitHub). Because the UID does not change:

- Previously authored posts keep the same `authorUid`.
- Firestore profile favorites and pins remain attached to the same UID.
- Local rows keyed by UID remain valid.
- The sync coordinator queues a profile sync after linking.

After linking, the Firebase ID token's `sign_in_provider` becomes `password`,
`google.com` or `github.com`. Firestore rules use this provider value to
distinguish registered users from anonymous guests. The gateway forces a token
refresh after linking so writes made immediately afterwards use the updated
provider claim.

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
4. Sign in with Google and with GitHub on a real device. Google must open the
   native account picker without visiting `firebaseapp.com/__/auth/handler`;
   GitHub must show a device code, open `github.com/login/device`, and finish
   after the code is approved. Confirm the profile is created and a guide can be
   published.
5. As an anonymous Firebase user, open **Create account** and link Google and
   GitHub. Confirm the UID, favorites, pins and authored guides survive.
6. Cancel the Google account picker and close the GitHub device dialog. Confirm
   no error banner is shown and the form still works.
7. Attempt each provider before enabling it in the console. Confirm the
   "sign-in method is not enabled" message appears instead of a crash.
8. Try to update another account's command directly with the Firestore SDK; it
   must be rejected.
9. Delete an account and confirm authored guides, profile and local user rows are
   gone while public cached/seed guides remain.
10. Remove the Firebase defines and confirm the app still opens in local-only
    mode with the provider buttons hidden.
