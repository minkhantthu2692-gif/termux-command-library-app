# Troubleshooting

## The app opens in local-only mode

**Symptom:** Sign-in says Firebase is not configured, the sync badge says
local-only, but browsing works.

**Cause:** Neither Firebase configuration source was available, or
initialization failed: `android/app/google-services.json` was missing/for a
different package, and the `--dart-define` overrides were incomplete.

**Check:**

1. Confirm `android/app/google-services.json` exists, that its
   `android_client_info.package_name` is `com.termuxcommandlibrary.mm`, and that
   the package is registered in the Firebase console.
2. If you are using overrides instead, all four of these must be present:

   ```bash
   flutter run --dart-define=FIREBASE_API_KEY=... \
     --dart-define=FIREBASE_APP_ID=... \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
     --dart-define=FIREBASE_PROJECT_ID=...
   ```

   The auth domain is optional.
3. Values are compile-time. Hot reload does not pick up new defines; restart the
   app. Replacing `google-services.json` also requires a rebuild.
4. Check `flutter logs` for the generic Firebase initialization warning.
5. The app intentionally does not print credentials or raw Firebase errors.

If you only need offline browsing, local-only mode is expected and supported.

## `PERMISSION_DENIED` from Firestore

Possible causes:

1. Rules were not deployed. Run:
   `firebase deploy --only firestore:rules`.
2. The user is anonymous and is trying to publish. Anonymous users are guests;
   link or register first.
3. The document's `authorUid` does not match the signed-in UID.
4. An update changed `authorUid`, `createdAt`, or lowered `version`.
5. A field limit in `validCommand`/`validProfile` was exceeded.
6. The profile document contains an unexpected field (for example a manually
   added `role`).
7. The user is editing another user's guide without the admin claim.
8. The admin claim was just granted but the ID token is stale. Sign out/in or
   refresh the token.

Read the Firestore error details in a debug build. Do not paste service-account
credentials or full tokens into issue reports.

## `failed-precondition` / missing index

Firestore needs the composite indexes in `firestore.indexes.json`:

```bash
firebase deploy --only firestore:indexes
```

Index builds can take minutes. The error usually includes a console link. Until
the index is ready, manual refresh fails but local browsing continues. Do not work
around it by fetching unbounded collections in the client.

## Sign-in or registration fails

| Error | Checks |
| --- | --- |
| `operation-not-allowed` | Email/Password, Anonymous, Google or GitHub provider is disabled in Firebase Auth |
| `invalid-email` | Email syntax; a bare username is completed as `@gmail.com` |
| `wrong-password` / `invalid-credential` | Credentials; use password reset |
| `email-already-in-use` | Sign in instead of registering, or link from the anonymous account |
| `weak-password` | Use at least 8 characters |
| `credential-already-in-use` | The email/provider account belongs to another Firebase UID; sign in to that account. Different UIDs are not merged. |
| `requires-recent-login` | Re-authenticate with the current password before changing/deleting |
| Google sign-in returns without signing in | Verify the app's debug/release SHA-1 and SHA-256 fingerprints in Firebase, confirm the Android OAuth client matches the signing certificate, then re-download `google-services.json` |
| `missing initial state` / browser sessionStorage error | GitHub uses Firebase's hosted browser flow. Update to the current build (Google now uses the native picker), close the tab and retry in a normal tab, and verify the OAuth callback URL |
| GitHub sign-in fails with a redirect error | The GitHub OAuth App callback must be exactly `https://<project-id>.firebaseapp.com/__/auth/handler` |
| GitHub account has no email | Keep the `user:email` scope request in the gateway; otherwise private-email accounts return no address |
| Provider flow closes with no message | This is treated as a cancellation and is intentionally silent |

Password reset emails require the device to receive email and the Firebase
authorized-domain/template configuration to be valid. The app never handles OTP
codes.

Google sign-in uses the native Android account picker and does not visit
Firebase's hosted handler, so browser session-storage errors do not affect it.
GitHub still uses Firebase's hosted Custom Tab flow; it requires a real device or
emulator with a browser and cannot complete inside a Flutter widget test. If the
provider buttons are missing entirely, the build is in local-only mode and
`android/app/google-services.json` (or the complete `--dart-define` set) is not
being applied.

## Google or GitHub sign-in fails in the browser

**Symptom:** Chrome shows:

```text
Unable to process request due to missing initial state. This may happen if
browser sessionStorage is inaccessible or accidentally cleared...
```

on `termuxcommandlibrary.firebaseapp.com/__/auth/handler`.

**Cause:** Firebase's hosted OAuth handler keeps its state in browser session
storage. Storage partitioning, private browsing, a cleared tab, or opening the
handler in a different browser context can remove that state before the callback
finishes. Google no longer uses this page, so the error should only affect
GitHub on current builds.

**Fix:**

1. Update to the current build. Google sign-in now opens the native account
   picker and never visits `/__/auth/handler`.
2. For GitHub, close the browser tab, return to the app and start again in a
   normal (not private/incognito) tab. The app shows a recovery hint after 45
   seconds instead of hanging silently.
3. Confirm the GitHub OAuth App callback is exactly
   `https://<project-id>.firebaseapp.com/__/auth/handler`, with no trailing
   slash or different domain.
4. Confirm the Firebase project domain is listed under **Authentication →
   Settings → Authorized domains**.
5. If the browser still fails, go back and try again; once the flow finishes or
   is closed, email/password works as usual. The GitHub OAuth app can also
   be recreated and its client ID/secret re-entered in the Firebase console;
   never put the secret in the app.

## Favorites or pins disappear

- Confirm you are signed in to the same account/UID.
- Pins are ordered per user; favorites are a set.
- While offline, changes are queued. Check the sync badge for pending operations
  and errors.
- Signing out returns to the local guest identity, which has separate favorites and
  pins. This is expected; it is not data loss.
- Clearing local cache preserves favorites/pins. Clearing app storage or
  uninstalling removes local rows; cloud rows return after sign-in and sync.
- Two devices editing favorites at the same time can overwrite each other's array.
  See [Synchronization](synchronization.md#favorites-and-pins).

## Changes remain "pending"

- Check network connectivity and the sync status message.
- Retryable failures back off automatically; manual refresh can force a retry.
- A permanent permission/validation failure stops the batch. Fix the cause (for
  example, sign in again or correct an oversized field), then refresh.
- Do not clear app data to "fix" pending writes; that discards unsynced local
  changes. Use the visible retry/refresh path.

## A deleted guide reappears

- Update to the current build (`4d61128` or later). Older builds could restore a
  deleted guide from a Firestore snapshot that was captured before the delete.
- The current build writes a durable `commandDelete` row before removing the local
  guide, ignores remote snapshots for tombstoned IDs, and re-applies tombstones
  after refresh.
- Check the sync badge. If a delete is still pending or failed, refresh once
  connectivity returns; do not clear app data, which would discard the queued
  delete.
- If the document still exists in the Firebase console after a successful sync,
  check that the signed-in UID owns the guide or has the admin claim.

## Admin controls or the Admin badge are missing

- Confirm the account has the custom claim `{"admin": true}`. See
  [Admin configuration](admin-setup.md).
- Claims are embedded in the ID token. Open **Settings → Account → Refresh
  account type**, or sign out and in again. Restarting alone is not guaranteed to
  refresh a still-valid cached token.
- Firestore rules remain the authority. Hiding or showing a button is not the
  security boundary.

## Termux is not detected

- Install the official `com.termux` APK from GitHub releases, not the outdated Play
  Store build.
- Android 11+ requires package visibility. This repo declares
  `<queries><package android:name="com.termux" /></queries>`; do not remove it.
- Open Termux once after installation.
- Rebuild/reinstall the app after manifest changes.

## `RUN_COMMAND` permission is denied / command does nothing

1. Enable external apps in Termux:

   ```bash
   echo "allow-external-apps=true" >> ~/.termux/termux.properties
   termux-reload-settings
   ```

2. Grant the permission in Android settings:
   **Apps → Termux Command Library → Permissions**.
3. Restart Termux and the app.
4. Use foreground mode for output; background commands may not show output.
5. The app only reports "sent". Check Termux's terminal for the actual result.

If `termux-*` commands are missing, install Termux:API and grant the Android
permissions it requests. See [Termux integration](termux-integration.md).

## AI key test fails

| Status | Meaning |
| --- | --- |
| 401 / 403 | Invalid, revoked or unauthorized key |
| 429 | Rate limit; wait and retry |
| 5xx | Groq service error; retry later |
| Timeout/network | No connectivity to `api.groq.com` |
| Empty model list | Key valid but no models available; refresh later |

- Copy the key without spaces or quotes.
- The key is stored in Android secure storage. If secure storage is unavailable on
  a modified device, remove/reinstall the app and try again.
- Test the key in the Groq console to separate app and account issues.
- The app does not use a hard-coded fallback model. Fetch models and select one.
- Revoke a leaked key immediately in the Groq console.

## AI answers are not cached

- Caching must be enabled with a non-zero duration.
- The cache key includes provider, model, prompt version, messages, temperature and
  max tokens. Changing any of them produces a new entry.
- History clearing does not clear the response cache; use the separate cache
  control.
- Cache entries expire. Changing the model or prompt version invalidates old
  entries by design.

## Attachments are rejected

Supported types: `.txt`, `.md`, `.sh`, `.py`, `.log`. Maximum size is 256 KB and
one file per message. Large text files are truncated to the first 20,000
characters for the prompt; the UI discloses this. Attachment contents are not
saved in history, only the file name. Do not attach secrets.

## Myanmar text renders poorly

- Select **Myanmar** in Settings → Appearance.
- Keep the Myanmar fallback font enabled; it is bundled as `NotoSansMyanmar`.
- If a selected Latin font lacks Myanmar glyphs, Flutter falls back to Noto Sans
  Myanmar. Do not remove the fallback from the theme.
- Test on a physical device; some OEM font overrides can behave differently.

## Haptics are weak, identical, or absent

- Check **Settings → Appearance → Haptics**. Off suppresses every app-managed
  vibration, including slider ticks and tooltips.
- Android's system touch-vibration setting and battery saver can override or mute
  an app's vibration. Test with the system setting enabled.
- Some devices have no amplitude control. Light, Medium and Strong then differ only
  by duration, which is expected. Emulators often have no vibration hardware at
  all.
- The native channel is Android-only. Other platforms use Flutter's standard
  `HapticFeedback`, which does not expose custom waveforms.
- A slider emits one tick per discrete division; continuous sliders are throttled
  to roughly 16 ticks per second rather than vibrating on every pixel.
- Haptics are best-effort and never surface an error. If an action succeeds but
  there is no vibration, verify the settings above before treating it as a bug.

## Theme/navigation bar colors look wrong

- The app supports light, dark and system modes. The system navigation bar color
  follows the app theme.
- Some Android OEMs enforce their own navigation-bar contrast. The app disables
  contrast enforcement where supported, but cannot override every vendor skin.
- Test gesture and three-button navigation on the target Android version.
- Status-bar icon brightness is derived from the theme; a custom `AppBar`
  `systemOverlayStyle` can override it intentionally.

## Database or migration failure

- Never delete or rewrite the SQLite file to "fix" a schema issue; that loses
  unsynced data.
- Add an explicit, additive migration in `AppDatabase.migration`.
- Regenerate Drift code after schema changes:
  `dart run build_runner build --delete-conflicting-outputs`.
- Check foreign keys and indexes.
- If the database is corrupt, the app should surface an error; recovering data is
  preferable to silently clearing it.

## `flutter analyze` fails on generated files

Regenerate the generated code first:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Do not hand-edit `*.g.dart` or `lib/app/localization/generated/`.

## `flutter test` hangs

Widget tests that use Drift must:

1. Unmount the `ProviderScope` (`pumpWidget(const SizedBox.shrink())`).
2. Pump the fake async zone enough for Drift's stream-cleanup timers to run.
3. Close the database inside `tester.runAsync`.

Awaiting `db.close()` directly in the fake async test zone can deadlock because
Drift waits for timers that only run when the test advances time. The widget test
helpers in this repository demonstrate the correct sequence.

Also make sure no stale `flutter test`/Dart processes are holding files; stop them
and rerun.

## Android build fails

- Use JDK 17. Run `flutter doctor -v` and check the Java version.
- Accept Android SDK licenses: `flutter doctor --android-licenses`.
- Clean only when necessary; deleting `build/` is safe, deleting user data or
  generated source is not:
  `flutter clean && flutter pub get`.
- Ensure `android/local.properties` points at the installed Flutter SDK.
- If Gradle fails after an SDK/AGP upgrade, read the first error, not the last
  cascade.
- Release builds currently use debug signing as a placeholder. Configure a private
  keystore before distribution.

## App cannot be installed over an existing build

The signing key changed. Uninstall the old development build first, or use the same
signing key consistently. Never uninstall a production app without confirming that
cloud data is synchronized and local-only drafts are backed up.

## Firebase quota or billing surprise

- Firestore reads/writes and Auth usage are visible in the Firebase console.
- Set Google Cloud budget alerts.
- The app limits sync pages, listener size and local search to reduce reads.
- Do not run refresh loops or per-keystroke Firestore queries.
- Managed Firestore exports require a Blaze plan.

## Nothing here matches

Collect:

- Flutter and Dart versions (`flutter --version`).
- Android version and device model.
- Exact reproduction steps.
- Whether Firebase is configured (without printing keys).
- A redacted debug log.

Do not include API keys, service-account JSON, keystores, passwords, full ID
tokens or private command content in a public issue.
