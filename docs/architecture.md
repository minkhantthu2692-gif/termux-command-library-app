# Architecture

## Goals

- Offline-first: SQLite is the source of truth for everything the UI lists.
- Clear separation between UI, business logic, persistence and external services.
- Replaceable backends and AI providers.
- Predictable state and bounded work: no per-keystroke Firestore queries, no
  unbounded lists, no hidden global mutable state.
- A polished Material 3 UI with centralized design tokens.

## Layers

```text
┌─────────────────────────────────────────────────────────────┐
│ features/  (screens and feature widgets)                     │
│   watch providers, render immutable state, send intents      │
└──────────────────────────┬──────────────────────────────────┘
                           │ Riverpod providers
┌──────────────────────────▼──────────────────────────────────┐
│ app/providers.dart, app/bootstrap.dart                       │
│   dependency graph, startup mode, theme/router wiring        │
└──────────────────────────┬──────────────────────────────────┘
                           │ repositories / services
┌──────────────────────────▼──────────────────────────────────┐
│ data/repositories, data/services                             │
│   business rules, validation, synchronization, AI, Termux    │
└───────────────┬───────────────────────────┬─────────────────┘
                │                           │
┌───────────────▼──────────────┐  ┌─────────▼────────────────┐
│ data/local (Drift/SQLite)    │  │ data/remote (Firebase)   │
│ tables, DAOs, migrations     │  │ Auth + Firestore only    │
└──────────────────────────────┘  └──────────────────────────┘
```

`lib/data/remote/firestore_cloud_store.dart` is the only file that knows Firestore
document shapes. `lib/data/remote/firebase_auth_gateway.dart` is the only file that
calls Firebase Auth APIs. Feature screens never import Firebase packages.

The AI equivalent is `lib/data/services/ai/`: `AiProvider` is the interface,
`GroqAiProvider` is one implementation, and `AiRepository` owns validation, cache,
history and prompt assembly. Feature widgets see only `AiRepository`/models.

## Directory guide

```text
lib/app/
  app.dart            MaterialApp.router, theme/locale/system UI
  bootstrap.dart      AppDependencies, Firebase/local-only startup
  providers.dart      Riverpod graph
  router.dart         go_router graph and onboarding guard
  theme/              Material 3 theme from settings/tokens
  settings/           immutable AppSettings, fonts, vibration
  localization/       ARB + generated localizations

lib/core/
  constants/          collection names, limits, URLs
  errors/             AppException and stable error codes
  utils/              validators, command risk analysis, streams
  design_system/      spacing, typography, radii, durations, colors

lib/data/
  local/database/     Drift database, tables, DAOs, migrations
  models/             CommandPost, profile, query, settings, AI models
  remote/             Firebase bootstrap, Auth gateway, Firestore store,
                      cloud interfaces and error mapping
  repositories/       auth, commands, profiles, settings, AI
  services/           sync coordinator, seed service, Termux, clipboard,
                      haptics, file attachments, secure key store

lib/features/         welcome, authentication, home, command_library,
                      command_details, upload, profile, settings,
                      ai_assistant, termux, docs
lib/shared/           reusable widgets and UI actions
```

## Startup

`main.dart` calls `AppBootstrap.run()`:

1. Initialize Flutter bindings.
2. Initialize the Drift database and settings (creates a persistent local guest
   UID if none exists).
3. Try to initialize Firebase from compile-time values.
4. Install the bundled seed catalogue if its version is newer.
5. Construct `AppDependencies`:
   - database
   - initial settings
   - `FirebaseRuntime`
   - optional `AuthGateway`
   - optional `CloudStore`
6. Run `TermuxCommandLibraryApp` inside a `ProviderScope`, overriding
   `appDependenciesProvider`.

If Firebase is missing or initialization fails, `FirebaseRuntime.availability` is
`disabled`/`unavailable` and the gateways are null. Features check
`AppDependencies.cloudConfigured`; the sync coordinator reports local-only status
instead of starting listeners. There is no crash and no fake "connected" state.

## Dependency graph

`app/providers.dart` is intentionally the only composition root:

```text
appDependenciesProvider
  ├─ databaseProvider
  ├─ settingsRepositoryProvider → settingsControllerProvider
  ├─ authGateway? → authRepositoryProvider → currentSessionProvider
  ├─ cloudStore?  → syncCoordinatorProvider
  ├─ commandRepositoryProvider
  ├─ profileRepositoryProvider
  ├─ preferenceRepositoryProvider
  └─ aiRepositoryProvider
       ├─ aiProviderProvider (Groq implementation)
       ├─ apiKeyStoreProvider (secure storage)
       └─ settingsRepositoryProvider
```

The database is closed when the provider scope is disposed. The sync coordinator
owns its listeners and timers and cancels both on dispose. AI provider HTTP clients
are closed on dispose. Tests override the composition root with fakes.

## Immutable state

Domain models are immutable classes with `copyWith`. Settings are an immutable
`AppSettings` value. Riverpod notifiers expose new values rather than mutating
shared objects. Streams from Drift are mapped into immutable models at the
repository boundary.

## Local database

Drift tables cover:

- commands and ordered steps
- categories metadata where needed
- favorites and pins, namespaced by UID
- user profiles
- settings key/value entries
- pending synchronization operations
- sync bookkeeping (last sync time)
- AI conversations, messages, cached responses and model metadata

Schema versioning is explicit in `AppDatabase`; migrations must be additive and
must not delete user data. Indexes support command sorting, category filters,
author queries, favorites/pins and AI history.

Search/filter/sort run in SQLite. The UI uses bounded pages and a debounce for
local search. Commands are stored verbatim, including newlines and whitespace.

## Remote data

Firestore collections and shapes are documented in
[Firestore setup](firestore-setup.md). Favorites and pins live in
`users/{uid}` as arrays; there is no one-document-per-toggle fan-out. Pins are an
ordered list. The 1 MiB document limit is respected through explicit caps and a
documented migration path.

`CloudStore`/`AuthGateway` are interfaces, not concrete Firebase dependencies in
repositories. Replacing Firestore with Supabase would mean:

1. Implement `CloudStore` and `AuthGateway`.
2. Swap the implementations in `bootstrap.dart`.
3. Keep local tables, repositories and UI unchanged.
4. Revisit security rules/equivalents and UID semantics.

## Synchronization

The sync coordinator attaches when a Firebase session exists:

- Realtime published-command listener (bounded).
- Profile listener.
- Pending-operation count listener.
- Periodic/queued processing of local mutations.
- Manual refresh with paged pulls and authored-command fetch.
- Retry with backoff for retryable failures.
- Conflict rules in the DAO: pending local edits are not overwritten by remote
  snapshots; version/updatedAt determine remote acceptance.

Detailed behavior: [Synchronization](synchronization.md).

## Authentication and authorization

`AuthRepository` maps Firebase Auth sessions to `AuthSession` and owns profile
creation, guest linking, password reset, re-authentication, sign-out and account
deletion. UI screens never call Firebase Auth directly.

Authorization is enforced in Firestore rules. The client also checks ownership for
a better error message, but that is not the security boundary. Admin is an Auth
custom claim, never a profile field.

## AI

`AiRepository` is the orchestration point:

- Reads the key from `ApiKeyStore` only when needed.
- Validates configuration before calling a provider.
- Rebuilds history from SQLite before each request.
- Assembles contextual prompts with a versioned prompt builder.
- Computes a SHA-256 cache identity from provider/model/prompt version/messages/
  parameters.
- Streams deltas to the UI and persists the assistant response.
- Stores history and cache locally; never sends them to Firebase.

A provider replacement does not require feature UI changes. Prompt templates are
centralized in `ai_prompts.dart` and versioned via `AppConstants.aiPromptVersion`.

## Termux

`TermuxService` abstracts the Android `MethodChannel`. `MainActivity.kt` handles
package detection, permission checks/requests, opening Termux settings, and
`RUN_COMMAND`. `showTermuxRunFlow` is the single UI entry point for execution:

- shows commands and risk warnings,
- requires confirmation,
- reports "sent", not "completed",
- handles missing Termux/permission/external-apps states.

See [Termux integration](termux-integration.md).

## Design system and localization

- All spacing values come from `AppSpacing` (4dp scale).
- Typography, radii, icon sizes, elevation, durations and component dimensions
  are tokens in `lib/core/design_system/`.
- Material 3 color schemes derive from a selected accent; light/dark/system modes
  share the same token structure.
- Edge-to-edge system bars use `AnnotatedRegion` and theme-derived navigation bar
  colors.
- `gen-l10n` supplies English and Myanmar strings. `Noto Sans Myanmar` is a font
  fallback so Burmese remains readable when another Latin font is selected.
- Nine bundled families plus the system default are available; font licenses are
  registered lazily in the app's license screen.

## Error handling

`AppException` carries a stable `AppErrorCode`, an optional safe message and a
retryable flag. Repositories translate Firebase/platform/HTTP failures at the
boundary; UI code maps codes to localized messages and shows inline errors,
snackbars or dialogs. Generic exceptions are never displayed with raw server
payloads or secrets.

## Testing strategy

- Pure unit tests for validators, risk analysis and models.
- Drift DAO tests against `NativeDatabase.memory()`, plus a file-backed
  persistence test.
- Repository/service tests with fake providers and fake API key stores.
- HTTP/SSE tests with `http`'s mock client.
- Widget tests with a manually assembled `AppDependencies`, Firebase disabled and
  fake secure storage.

Firebase rules and live provider tests are separate integration concerns because
they need external projects/emulators.

## Extension points

| Change | Where |
| --- | --- |
| Add a category | `CommandCategories`, ARB strings, category visuals, validation/rules |
| Add a cloud backend | Implement `CloudStore`/`AuthGateway`, swap in bootstrap |
| Add an AI provider | Implement `AiProvider`, register factory, add settings/tests |
| Add a screen | Feature folder + route in `router.dart` |
| Change design tokens | `lib/core/design_system/app_tokens.dart` |
| Change Firebase collections | `AppConstants`, Firestore store, rules, docs |
| Support a new language | ARB + `supportedLocales`, font fallback review |

Any change that touches authorization, data shape or synchronization must update
the rules, the repository boundaries, tests and the relevant docs together.
