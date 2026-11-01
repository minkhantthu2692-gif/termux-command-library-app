# Release guide

This document describes how the project is verified, signed and packaged for an
Android release. It complements [Build instructions](build.md) and the
`FINALIZATION_NOTES.md` generated inside each `final_release_<timestamp>/`
folder.

## Environment used for finalization

| Tool | Version |
| --- | --- |
| Flutter | 3.47.8 (stable) |
| Dart | 3.13.7 |
| Android SDK | 36.0.0 (platform 37 installed) |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
| JDK | Android Studio bundled OpenJDK 25.0.3 |
| Min SDK | 24 (Android 7.0) |

The Android toolchain, licences and connected device checks passed with
`flutter doctor -v`. Visual Studio is not installed; Windows desktop builds are
not part of this Android release.

## Preflight checks

Run these before packaging:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The finalized source passes formatting, reports no analyzer issues and passes
**272 Dart tests**. Firestore security-rules tests are separate and require the
Firebase emulator and Node dependencies under `test/rules/`.

## Signing

### Debug key

Debug builds use the standard per-machine Android debug keystore at
`~/.android/debug.keystore` (Windows:
`%USERPROFILE%\.android\debug.keystore`). Its fingerprints are recorded in
`SHA_KEYS.txt` for local reference only.

### Release / upload key

The project is signed with a private **4096-bit RSA upload key** that is stored
outside the repository:

```text
C:\Users\minkh\keystores\termux-command-library-main-upload.jks
alias: main-upload
```

`android/key.properties` points at that file and is git-ignored. It contains the
passwords, so it must never be committed, zipped or shared.

| Certificate | SHA-1 | SHA-256 |
| --- | --- | --- |
| Upload (`main-upload`) | `39:93:56:E7:0F:D6:92:DE:AC:34:39:E8:D8:98:3A:FB:C6:78:59:4A` | `55:C9:FB:28:8C:52:5B:AA:BE:27:14:49:67:E7:4A:7A:D4:9E:23:8C:69:A2:BA:D9:81:0F:29:B2:01:1B:4A:CB` |
| Debug | `EF:40:69:72:75:93:87:8B:4D:2C:56:CA:F4:68:43:70:C4:91:DD:00` | `63:42:1E:96:B0:70:7E:58:93:3B:BD:38:56:E5:17:FD:67:E1:65:4D:C4:85:E6:D8:E5:66:F3:AE:30:B9:6E:22` |

All four fingerprints are registered in the existing Firebase Android app
`1:901373434656:android:6a53fc7c6af468aa011545` (project
`termuxcommandlibrary`), so Google Sign-In works for both debug and release
builds.

`android/app/build.gradle.kts` loads `android/key.properties` automatically when
it exists. When it is absent — for example after cloning the repository on a new
machine — release builds fall back to the debug signing configuration so local
verification still works. **Never distribute the fallback artifact.**

Never commit or archive:

- the keystore (`.jks` / `.keystore`),
- `android/key.properties`,
- passwords or private key material.

Record only certificate fingerprints, never secrets. To print fingerprints:

```bash
keytool -list -v -keystore <keystore> -alias <alias>
```

## Build and export

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Expected Flutter output locations:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

The archival snapshot workflow copies the source into:

```text
final_release_<YYYYMMDD_HHMM>/
  SHA_KEYS.txt
  FINALIZATION_NOTES.md
  README.md
  docs/
  lib/
  android/
  assets/
  test/
  pubspec.yaml
  pubspec.lock
  ...
final_release_<YYYYMMDD_HHMM>.zip
```

The ZIP is a **source snapshot**: it excludes signing secrets,
`android/app/google-services.json`, built artifacts (`exports/`, `build/`),
caches, `.git`, `node_modules` and log files. The unzipped folder keeps the
Firebase client configuration needed for a local Firebase-enabled build. Treat
the unzipped folder as private.

## Verifying the signer

Use the Android SDK `apksigner`:

```bash
"$ANDROID_HOME/build-tools/36.0.0/apksigner" verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

Compare the reported SHA-256 digest with the upload certificate. A debug
certificate means the artifact must not be uploaded to a store.

## Firebase configuration

Firebase Authentication and Firestore need `android/app/google-services.json`
(or equivalent `--dart-define` values). The file is git-ignored because it
contains Android client identifiers. The archive ZIP omits it by design; add it
from the Firebase console before building a Firebase-enabled release elsewhere.

For Google sign-in, the release/upload SHA-1/SHA-256 are registered in the
Firebase console, and the local `google-services.json` was refreshed on
2026-11-01 so it contains **both** Android OAuth clients (debug and release)
plus the web client. For GitHub sign-in, keep the OAuth callback and device-flow
configuration described in [Firebase Authentication](firebase-auth-setup.md).

## Known limitations and risks

- **Signature change on existing installs.** Earlier builds on the test device
  were debug-signed. Android refuses to update an app when the signing
  certificate changes, so uninstall the old build once before installing the
  upload-signed APK (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Uninstalling removes
  local SQLite data, so back up anything important first.
- **Play App Signing is not enabled.** The upload key above is the signing
  identity for local release builds; if you enrol in Play App Signing, Google
  re-signs the bundle and you must register the *app signing* SHA fingerprints
  in Firebase as well.
- `google-services.json` is environment-specific and git-ignored.
- Groq AI requires a user-supplied BYOK key; no key is bundled.
- Termux `RUN_COMMAND` cannot confirm command completion. The UI reports that a
  command was **sent**, not that it finished.
- Android 10+ requires Termux to have **Display over other apps** before it can
  open a session while this app is in front.
- Firestore rules tests and live Firebase/Groq end-to-end tests need external
  projects and are not part of `flutter test`.
- No app-store listing, privacy policy, screenshots or content rating are
  included.
- No open-source licence has been selected for the application. Bundled font
  licences are included under `assets/fonts/licenses/`.
- Twenty transitive packages report newer incompatible versions; they were not
  upgraded during finalization to avoid unverified regressions.

## Manual steps before publishing

1. Back up the upload keystore and its passwords offline (see
   [Keystore backup](#keystore-backup)); losing them permanently prevents
   updates under the same identity.
2. If you enrol in Play App Signing, register the app-signing SHA-1/SHA-256 in
   Firebase and any Google/GitHub OAuth configuration.
3. Test the release build on Android 7, 10+ and a current Android release,
   including Termux run/copy flows and offline mode.
4. Prepare the store listing, privacy policy, screenshots and content rating.
5. Choose an application licence and add it to the repository.

## Keystore backup

The keystore is the only way to ship updates under the same identity, so keep at
least two offline copies:

1. Copy `termux-command-library-main-upload.jks` and its credentials file to an
   encrypted archive (for example a password-manager attachment or a VeraCrypt
   container).
2. Store the archive on two separate physical media in different locations, or
   in an encrypted cloud vault that is **not** the repository.
3. Record the SHA-256 checksum of the keystore file next to the archive so a
   restore can be verified.
4. Test the backup by restoring it into a temporary folder and running
   `keytool -list -v -keystore <restored file>` — the fingerprints must match the
   table above.
5. Never email the keystore or its passwords, and never commit them to Git.
