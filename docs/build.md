# Build instructions

## Toolchain

| Tool | Version used for this project |
| --- | --- |
| Flutter | 3.47.8 (stable) |
| Dart | 3.13.7 |
| Java/JDK | 17 or newer (verified with Android Studio's bundled JDK 25.0.3) |
| Android min SDK | 24 (Android 7.0) |
| Android compile/target SDK | Flutter defaults for the installed Flutter version |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |

Use a JDK that matches the Android Gradle Plugin requirement (JDK 17 is the
minimum; this project was verified with Android Studio's bundled JDK 25.0.3).
Flutter's Android Studio bundle includes a suitable JDK; `flutter doctor -v`
shows which one is in use.

## Direct dependencies

| Package | Purpose |
| --- | --- |
| `flutter_riverpod` | Application state and dependency injection |
| `go_router` | Declarative navigation and the four-tab shell |
| `drift`, `drift_flutter` | SQLite schema, DAOs and native database access |
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Authentication and Firestore only |
| `flutter_secure_storage` | BYOK API key storage |
| `http` | Groq HTTP and streaming requests |
| `file_picker` | Bounded AI attachment selection |
| `url_launcher` | External documentation and Termux release links |
| `intl` | Date and number formatting |
| `crypto` | Cache keys and request hashing |
| `uuid` | Local entity identifiers |
| `flutter_markdown_plus` | Help-centre and Markdown rendering |
| `google_sign_in` | Google authentication provider |
| `dynamic_color`, `material_color_utilities` | Android 12+ wallpaper colour support |
| `flutter_svg` | Bundled avatar and brand artwork |

`path` and `path_provider` are pulled transitively by `drift_flutter`; the app
does not import them directly, so they are intentionally not declared again.

## First-time setup

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter doctor
```

`build_runner` generates `lib/data/local/database/app_database.g.dart` and related
Drift code. `flutter gen-l10n` generates `lib/app/localization/generated/`. Both are
already checked in for convenience, but regenerate them after changing tables,
DAOs or ARB files.

## Run locally (no Firebase, no Groq key)

```bash
flutter run
```

The app opens with the bundled 52-guide catalogue and a local guest identity.
Authentication screens explain that Firebase is not configured. This mode is
useful for UI work, offline testing and Dart tests.

## Run with Firebase

Place the Firebase Android configuration at `android/app/google-services.json`.
The build applies the Google Services Gradle plugin when that file exists, and
`FirebaseBootstrap` initialises the native default app from it. No flags are
needed:

```bash
flutter run
```

The file is git-ignored (it contains an Android client API key). Without it, the
app still builds and runs in local-only mode.

For CI, or builds that do not bundle the JSON, pass the client values as
compile-time defines. Use one source per build: if both are present they must
describe the same Firebase app or initialization fails.

PowerShell:

```powershell
flutter run `
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

Bash:

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT_ID.firebaseapp.com
```

The auth domain is optional. All other values are required for the override to
apply. If initialization fails, the app logs only a generic message and continues
in local-only mode.

For repeatable local builds, keep the downloaded JSON or defines in a private
location that is not committed. Do not store server credentials or a
service-account JSON in the repository.

## Debug APK

```bash
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

With `android/app/google-services.json` in place, no build flags are needed. If
you use compile-time overrides instead, append the same `--dart-define` flags to
`flutter build`.

## Release APK and App Bundle

```bash
flutter build apk --release
flutter build appbundle --release
```

Outputs:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

Signing is resolved automatically from `android/key.properties`:

1. The project already uses an upload keystore kept **outside** the repository:

   ```text
   C:\Users\minkh\keystores\termux-command-library-main-upload.jks
   alias: main-upload (RSA 4096, valid for 10000 days)
   ```

2. `android/key.properties` (git-ignored) points at it:

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=main-upload
   storeFile=C:/Users/minkh/keystores/termux-command-library-main-upload.jks
   ```

3. Build with the commands above. `android/app/build.gradle.kts` loads the file
   when present and uses the `release` signing config automatically.

To provision a fresh machine, copy the keystore and credentials from the secure
backup, recreate `android/key.properties`, and confirm the fingerprints with
`keytool -list -v`. The expected values are listed in
[Release guide](release.md#release--upload-key).

If `android/key.properties` is absent, the release build falls back to the debug
key so `flutter run --release` and local verification still work. **That fallback
artifact is not suitable for distribution.** Never commit the keystore,
`key.properties`, passwords or the extracted signing certificate.

Verify the signer before publishing:

```bash
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

Flutter can split by ABI to reduce APK size:

```bash
flutter build apk --release --split-per-abi
```

## Launcher icon

The launcher artwork lives in `assets/brand/app_icon.png` (legacy icon) and
`assets/brand/app_icon_foreground.png` (transparent adaptive foreground). Both
are generated from the same indigo terminal mark used by the in-app logo:

```powershell
powershell -ExecutionPolicy Bypass -File tool\generate_app_icon.ps1
```

The script writes every density-specific `mipmap-*/ic_launcher*.png` file. The
adaptive XML in `android/app/src/main/res/mipmap-anydpi-v26/` and the background
colour in `values/colors.xml` are committed separately. The foreground stays
inside the adaptive safe zone, so launcher masks do not clip the gold dot.

## Build without Firebase

Building without `android/app/google-services.json` and without `--dart-define`
values is valid for CI and local development. The resulting app is a complete
offline library; cloud sign-in and synchronization are unavailable. The UI must
not crash or silently claim that cloud features are configured.

## Tests and analysis

```bash
dart format lib test
flutter analyze
flutter test
```

Current coverage includes:

- Validators and command-risk analysis.
- Command models, seed catalogue and seeding behavior.
- Drift command/preference/settings/sync/AI DAOs, including file-backed
  persistence and conflict rules.
- Admin edits preserving attribution, delete tombstones rejecting stale remote
  snapshots, and queued upload/delete recovery.
- AI repository caching, history, model selection and provider errors.
- Groq HTTP key validation, model parsing and SSE streaming.
- Authentication error mapping, native Google error mapping, the GitHub device
  client (pending, slow-down, denial, expiry, disabled flow, malformed responses
  and cancellation) and the Google/GitHub provider buttons.
- App onboarding, shell navigation, theme and Myanmar locale propagation.
- Frosted-glass rendering: backdrop filter and sigma when enabled, opaque
  fallback when disabled or at zero intensity, clamping, and the shell
  navigation bar reacting to the live setting.

Widget tests that use Drift must unmount the widget tree, pump the fake async
zone so Drift's stream-cleanup timers run, and close the database inside
`tester.runAsync`. Skipping this can deadlock `Database.close()` in the fake async
zone.

Firebase rules tests and live Firebase/Groq end-to-end tests require external
projects and are not run by `flutter test`.

The Dart suite currently passes **272 tests**, and the Firestore rules tests pass
**29 cases** locally against the Firestore emulator with Node (Java only for the
emulator itself). See
[Security Rules › Emulator testing](security-rules.md#emulator-testing) for the
exact command.

## Continuous integration outline

A minimal CI job:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Use a pinned Flutter version. Do not inject production Firebase service-account
credentials into PR builds. Firebase client identifiers can be supplied as CI
secrets if an online smoke build is needed, but PRs from forks must not receive
them.

## Final release package layout

The finalization workflow produces:

```text
final_release_<YYYYMMDD_HHMM>/
  exports/debug/app-debug.apk
  exports/release/app-release.apk
  exports/bundle/app-release.aab
  SHA_KEYS.txt
  FINALIZATION_NOTES.md
  <cleaned Flutter project>
final_release_<YYYYMMDD_HHMM>.zip
```

The ZIP excludes signing secrets, `android/app/google-services.json`, build
caches, `.git`, `node_modules` and logs. See [Release guide](release.md).

## Generated files

- `lib/data/local/database/app_database.g.dart` — Drift code.
- `lib/app/localization/generated/` — `gen-l10n` output.
- `pubspec.lock` — commit for reproducible application builds.

Regenerate instead of hand-editing generated files. If `build_runner` reports
conflicting outputs, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Troubleshooting build failures

See [Troubleshooting](troubleshooting.md). The most common causes are a missing
JDK 17, an Android SDK/licence problem, a stale generated Drift file, or running
`flutter test` before `flutter pub get`.
