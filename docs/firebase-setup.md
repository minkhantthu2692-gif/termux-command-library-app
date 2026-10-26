# Firebase setup

The application uses exactly two Firebase products:

- **Authentication** for anonymous guests and email/password accounts.
- **Cloud Firestore** for public command guides and private user profiles.

Firebase Storage is not used. Crashlytics, Analytics, Remote Config, Cloud
Messaging and other Firebase products are not configured by this project.

Firebase is configured at compile time from `--dart-define` values. No
`google-services.json` and no service-account key are required by the Flutter
app. If the values are missing or invalid, the app starts in **local-only mode**
with SQLite and the bundled seed catalogue; it does not crash.

---

## 1. Prerequisites

- A Google account.
- A Firebase project on the Spark (free) plan is sufficient for evaluation;
  production traffic may require Blaze.
- Node.js 20+ and the Firebase CLI:

  ```bash
  npm install -g firebase-tools
  firebase login
  ```

- Flutter and Android tooling as described in [Build instructions](build.md).

## 2. Create the Firebase project

1. Open <https://console.firebase.google.com>.
2. **Add project**, choose a name (for example `termux-command-library`) and
   continue.
3. Google Analytics is not required by this app; either choice is acceptable,
   because the app does not initialize Analytics.

Record the **project ID** from **Project settings → General**. It is the value
for `FIREBASE_PROJECT_ID` and is also used by the CLI.

## 3. Register the Android app

1. In **Project settings → Your apps**, choose the Android icon.
2. Use the package name from `android/app/build.gradle.kts`:

   ```text
   com.minkh.termux_command_library
   ```

3. A nickname is optional. The debug SHA-1 is only needed for providers such as
   Google Sign-In; email/password and Anonymous do not require it. Add release
   SHA-1/SHA-256 values before enabling additional providers later.
4. The console offers `google-services.json`. **This project does not read that
   file**; you may skip it or keep it outside the repository. Configuration is
   passed with `--dart-define` instead, which keeps the build reproducible and
   makes local-only CI builds possible.

Copy these values from **Project settings → General → Your apps → SDK setup and
configuration**:

| `--dart-define` name | Console value |
| --- | --- |
| `FIREBASE_API_KEY` | `apiKey` / Web API Key |
| `FIREBASE_APP_ID` | `mobilesdk_app_id`, e.g. `1:1234567890:android:abcdef` |
| `FIREBASE_MESSAGING_SENDER_ID` | `project_number` |
| `FIREBASE_PROJECT_ID` | `project_id` |
| `FIREBASE_AUTH_DOMAIN` | `project_id.firebaseapp.com` (optional; derived if omitted) |

These are Firebase **client identifiers**, not service-account credentials. They
are normally shipped inside an app binary. Do not commit a service-account JSON
file, and do not put server credentials in `--dart-define`.

## 4. Enable Authentication

In **Authentication → Get started**:

1. Enable **Email/Password**. Email link sign-in is not needed.
2. Enable **Anonymous**.

No OTP, SMS, mandatory email verification or custom claims are required for
normal use. Details: [Firebase Authentication setup](firebase-auth-setup.md).

## 5. Create Cloud Firestore

1. Open **Firestore Database → Create database**.
2. Start in **production mode**. The repository's rules replace the defaults.
3. Choose a region close to your users. This cannot be changed later without a
   migration.
4. Do not create a Storage bucket for the app.

Collections used by the app:

```text
commands/{commandId}
users/{uid}
```

See [Firestore setup](firestore-setup.md) for document shapes and indexes.

## 6. Deploy rules and indexes

From the repository root:

```bash
firebase login
firebase use --add          # select your project and give it an alias
firebase deploy --only firestore:rules,firestore:indexes
```

`firebase.json` points the CLI at `firestore.rules` and
`firestore.indexes.json`. Review [Security rules](security-rules.md) before
production use. The first index build can take several minutes; a query may fail
with `failed-precondition` until it finishes.

### Local emulator (optional)

The project defines Auth (`9099`), Firestore (`8080`) and Emulator UI (`4000`)
ports in `firebase.json`:

```bash
firebase emulators:start --only auth,firestore
```

The Flutter app does not automatically connect to the emulator. Add a debug-only
host/port configuration if you want to exercise it; do not ship emulator
settings in release builds. The Firestore emulator requires Java 11+.

## 7. Run the app with Firebase

PowerShell (one line per argument, backtick for continuation):

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

Bash/zsh:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

All four of API key, app ID, sender ID and project ID are required for online
mode; the auth domain is optional. When configured correctly, the start-up flow
calls `Firebase.initializeApp` before the Riverpod graph is built.

## 8. Verify online mode

1. Open **Profile → Sign in** and create an email/password account.
2. Publish a guide via **Upload**.
3. Confirm the document appears in Firestore under `commands/{id}` with
   `status: "published"` and the same `authorUid` as the Auth UID.
4. Confirm `users/{uid}` exists with `favoriteIds` and `pinnedIds` arrays.
5. Favorite and pin guides, restart the app, and confirm the state returns.
6. Open a second device/account and confirm the published guide appears after a
   refresh.
7. In Firestore, attempt to update another user's command from a client; the
   rules must reject it.

## 9. Operational notes

- **App Check:** not implemented. Before a public launch, consider Firebase App
  Check for Firestore/Auth abuse protection and test it against the rules.
- **Budget alerts:** set a Google Cloud budget alert even on the free plan.
- **Rules changes:** deploy through review, not from a developer workstation
  with production credentials, once the project has real users.
- **Credentials:** never commit service-account JSON, API keys for server
  administration, keystores or signing passwords.
- **Storage:** leaving Firebase Storage uninitialized is intentional. Do not add
  Storage-backed avatars; the app uses built-in avatar IDs.
- **Region:** Firestore is regional. Choose deliberately; moving later requires
  exporting and importing data.
