# Termux Command Library

A community-driven Android library for discovering, organizing and running
multi-step [Termux](https://termux.dev) command guides. Built with Flutter and
designed offline-first: the library opens instantly from SQLite, then syncs with
Cloud Firestore when an account and network are available.

> **Project status:** the application, local database, synchronization layer,
> Firebase gateways, Groq provider abstraction, UI, tests and documentation are
> implemented in this repository. Firebase and Groq credentials were **not**
> provided, so cloud/AI end-to-end verification against a live project has not
> been performed. The app deliberately starts in a fully usable local-only mode
> until those values are configured.

---

## What the app does

- Browse and search public command guides across ten categories.
- Read multi-step guides with exact shell syntax preserved.
- Copy one step or every command in a guide.
- Send a step to Termux through the documented `RUN_COMMAND` intent, after a
  confirmation and a destructive-command warning.
- Favorite guides and pin guides in a user-defined order.
- Upload, edit and delete your own guides; drafts are supported.
- Sign in with email/password or Google/GitHub, continue as an anonymous guest,
  link a guest to a registered account, reset a password and delete an account.
- Work offline. Changes are queued locally and synchronized later.
- Use an optional AI assistant with your own Groq API key (BYOK), including
  command explanations, title/description help and English/Myanmar translation.
- Customize theme, accent, blur, vibration, font size and font family.
- Switch between English and Myanmar; Myanmar text has a bundled fallback font.

The app is **not** a terminal emulator. Termux executes commands and owns their
output. The UI reports a command as *sent to Termux*, never as *completed* unless
a future integration can confirm completion.

## Technology

| Area | Choice |
| --- | --- |
| UI | Flutter, Material 3, custom 4dp design tokens |
| State | Riverpod |
| Navigation | go_router (four-branch `StatefulShellRoute`) |
| Local data | SQLite via Drift |
| Cloud | Firebase Authentication + Cloud Firestore |
| Secrets | `flutter_secure_storage` |
| AI | Provider abstraction, Groq implementation |
| Android bridge | Kotlin `MethodChannel` for Termux intents |
| Localization | Flutter `gen-l10n`, English and Myanmar |

**Firebase Storage is intentionally not used.** Firebase is limited to
Authentication and Firestore. No storage bucket is initialized and no service
account file is needed in the app.

## Project layout

```text
lib/
  app/             app root, router, providers, theme, bootstrap, settings
  core/            constants, errors, validators, design tokens, utilities
  data/
    local/         Drift database, tables, DAOs
    models/        immutable domain models
    remote/        Firebase Auth/Firestore gateway implementations
    repositories/  auth, commands, profiles, settings, AI
    services/      sync coordinator, seeding, Termux, clipboard, files
  features/        authentication, home, library, details, upload, profile,
                   settings, assistant, docs, welcome
  shared/          reusable widgets and UI helpers
assets/            seed catalogue, help content, bundled fonts and licenses
test/              unit, database, provider and widget tests
docs/              setup, architecture and operations documentation
```

The code is feature-first with strict separation between UI, business logic,
persistence and external services. The Firebase-specific implementation is
confined to `lib/data/remote/`; the Groq-specific implementation is confined to
the AI provider classes. See [Architecture](docs/architecture.md).

## Quick start (local-only)

Requirements:

- Flutter 3.47.8 or newer (Dart 3.13.7 or newer).
- Android SDK with API 24+; JDK 17 for the Android build.
- A connected Android device or emulator.

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Without `google-services.json` and without `--dart-define` values the app runs
entirely from SQLite with the bundled starter catalogue. Authentication screens
explain that an account requires Firebase configuration. This is the expected
mode for UI work and tests.

## Connect Firebase

The Android package is **`com.termuxcommandlibrary.mm`**. Firebase Auth and
Firestore are connected through the standard Firebase Android configuration.

1. In the Firebase console, register (or open) the Android app with that exact
   package name.
2. Download its `google-services.json` and place it at
   `android/app/google-services.json`. The file is git-ignored; download it per
   machine or CI secret instead of committing it.
3. Enable **Authentication → Sign-in method → Email/Password** and **Anonymous**.
   Optionally enable **Google** (add debug/release SHA-1 and SHA-256
   fingerprints) and **GitHub** (create a GitHub OAuth App whose callback is
   `https://<project-id>.firebaseapp.com/__/auth/handler`). See
   [Firebase Authentication](docs/firebase-auth-setup.md) for the exact steps.
4. Create a Cloud Firestore database.
5. Install the Firebase CLI, sign in, select the project and deploy the rules and
   indexes in this repository:

   ```bash
   firebase login
   firebase use --add
   firebase deploy --only firestore:rules,firestore:indexes
   ```

6. Run `flutter run`. The app reads the project automatically from the processed
   `google-services.json`.

For CI or environments where bundling the JSON is not possible, pass the same
values as compile-time defines instead. Use one source per build: if both are
present they must describe the same Firebase app, otherwise initialization
fails and the app stays local-only.

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=...
```

These are public Firebase client identifiers, not service-account secrets. Keep
`google-services.json` and environment-specific values out of Git. **Never**
commit a service-account JSON file.

Full instructions, including a Burmese walkthrough, are in
[docs/burmese-setup.md](docs/burmese-setup.md) and
[docs/firebase-setup.md](docs/firebase-setup.md).

## Termux setup

Install Termux from the official GitHub releases (the Play Store build is
outdated):

<https://github.com/termux/termux-app/releases>

To allow this app to send commands, enable external apps in Termux:

```bash
echo "allow-external-apps=true" >> ~/.termux/termux.properties
termux-reload-settings
```

Then open the app's Termux guide and grant the requested `RUN_COMMAND`
permission. Full details and safety notes: [Termux integration](docs/termux-integration.md).

## Groq AI setup

The AI assistant is optional and uses **your own** Groq API key:

1. Create a key at <https://console.groq.com/keys>.
2. In the app: **Profile → Settings → AI Assistant**.
3. Save the key, test it, fetch the model list and choose a model.
4. Enable the assistant.

The key is stored in Android secure storage, never sent to Firestore, and never
written to history, logs or the repository. See [Groq setup](docs/groq-setup.md).

## Build

```bash
flutter build apk --debug
flutter build apk --release
```

A release build currently uses the debug signing configuration as a development
placeholder. Configure a private keystore before distributing the app. See
[Build instructions](docs/build.md).

## Test and quality checks

```bash
dart format lib test
flutter analyze
flutter test
```

The suite covers validators, risk analysis, command models, the seed catalogue,
Drift DAOs and persistence, offline synchronization, AI caching/history, Groq
HTTP/SSE parsing, authentication error mapping, the provider buttons, the
Riverpod app shell and theme/locale propagation.

## Documentation

| Document | Contents |
| --- | --- |
| [Burmese next steps](docs/burmese-next-steps.md) | What remains to make this build fully functional, in Myanmar language |
| [Burmese setup guide](docs/burmese-setup.md) | Complete setup walkthrough in Myanmar language |
| [Firebase setup](docs/firebase-setup.md) | Project, Auth, Firestore, deployment |
| [Firebase Authentication](docs/firebase-auth-setup.md) | Providers, flows, account linking and deletion |
| [Firestore setup](docs/firestore-setup.md) | Collections, indexes, limits, emulator |
| [Security rules](docs/security-rules.md) | Role model, rule behavior and deployment |
| [Admin configuration](docs/admin-setup.md) | Custom admin claim and verification |
| [Groq API setup](docs/groq-setup.md) | BYOK, secure storage, models, cache and history |
| [Termux integration](docs/termux-integration.md) | Install, permissions, `RUN_COMMAND`, safety |
| [Build instructions](docs/build.md) | Debug/release builds, signing, defines |
| [Troubleshooting](docs/troubleshooting.md) | Common setup and runtime failures |
| [Architecture](docs/architecture.md) | Layers, providers, data flow, extension points |
| [Synchronization](docs/synchronization.md) | Offline-first flow, queue, conflicts, limits |

## Security and privacy summary

- No Firebase Storage, analytics, crash reporting or advertising SDK is used.
- AI keys live only in Android secure storage; they are never synchronized.
- AI history is local by default and can be deleted by the user.
- Favorites and pins are stored in the signed-in user's profile document and
  mirrored in SQLite for instant, offline access.
- Firestore rules enforce owner/admin authorization and validate document shape;
  hiding a button is never the only protection.
- Account deletion is separate from clearing local cache. Clearing local data
  does not delete public posts.
- The app cannot guarantee that a compromised device keeps secure storage safe.

## License

No license has been selected for this repository yet. Bundled font licenses are
included under `assets/fonts/` and are registered in the app's license screen.
