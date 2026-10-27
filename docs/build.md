# Build instructions

## Toolchain

| Tool | Version used for this project |
| --- | --- |
| Flutter | 3.47.8 (stable) |
| Dart | 3.13.7 |
| Java/JDK | 17 |
| Android min SDK | 24 (Android 7.0) |
| Android compile/target SDK | Flutter defaults for the installed Flutter version |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |

Use a JDK that matches the Android Gradle Plugin requirement (JDK 17 is the safe
choice for this repository). Flutter's Android Studio bundle includes a suitable
JDK; `flutter doctor -v` shows which one is in use.

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

## Release APK

```bash
flutter build apk --release
```

The current `android/app/build.gradle.kts` deliberately uses the debug signing
configuration for release builds as a development placeholder. **Do not distribute
that artifact as a production release.**

To configure a private release key:

1. Create a keystore outside the repository, for example:

   ```bash
   keytool -genkeypair -v \
     -keystore ~/keystores/termux-command-library.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias termux-command-library
   ```

2. Create `android/key.properties` (already ignored by Git):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=termux-command-library
   storeFile=/absolute/path/to/termux-command-library.jks
   ```

3. Load the properties in `android/app/build.gradle.kts` and define a release
   signing config, then use it in `buildTypes.release`.
4. Never commit the keystore, `key.properties`, passwords or the extracted signing
   certificate.
5. Build and verify the signed APK/AAB:

   ```bash
   flutter build apk --release
   flutter build appbundle --release
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
- AI repository caching, history, model selection and provider errors.
- Groq HTTP key validation, model parsing and SSE streaming.
- Authentication error mapping and the Google/GitHub provider buttons.
- App onboarding, shell navigation, theme and Myanmar locale propagation.

Widget tests that use Drift must unmount the widget tree, pump the fake async
zone so Drift's stream-cleanup timers run, and close the database inside
`tester.runAsync`. Skipping this can deadlock `Database.close()` in the fake async
zone.

Firebase rules tests and live Firebase/Groq end-to-end tests require external
projects and are not run by `flutter test`.

The Firestore rules tests run locally against the Firestore emulator with Node
(Java only for the emulator itself); see
[Security Rules › Emulator testing](security-rules.md#emulator-testing) for the
exact command and the 25 covered cases.

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
