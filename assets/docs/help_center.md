# Termux Command Library — Help Centre

Termux Command Library is an offline-first collection of practical Termux guides. It works without an account, and it never asks for a Termux password or your device's root access.

## Getting started

1. Browse the **Home** tab for recent and pinned guides.
2. Use **Library** to search, filter by category, and sort the full collection.
3. Tap a guide to read every step, copy one command, copy all of them, or send a step to Termux.
4. Use **Profile** to sign in, keep favorites and pins in sync, and change the appearance.

You can use the app entirely as a guest. Guest favorites and pins are stored on this device. Signing in adds cloud sync and lets you publish guides.

## Offline-first behaviour

SQLite on the device is the source of truth for everything you see. When a connection is available, Firestore changes are copied into SQLite in the background. Search, filtering and sorting always run locally, which keeps typing responsive and avoids a network request for every keystroke.

- The small badge near the library header shows whether the app is local-only, syncing, up to date, or waiting to retry.
- Pull down on Home, Library or Profile to request a manual sync.
- A sync failure leaves cached content intact. Open the badge or retry from Settings after the connection returns.
- Pending edits are queued locally. Do not clear app data while a queue is waiting unless you accept losing those changes.

## Favorites and pins

Favorites are a set; pins have an order that you control. They belong to the signed-in account and are mirrored into a local table for instant display.

- Guests keep their own local collection.
- When a guest signs in or registers, the app offers to import the guest collection once.
- Signing out does not delete the cloud collection.
- Clearing local cache removes downloaded guide data but does not delete your cloud favorites, pins or posts.

## Copying versus running

The app is a command library, not a terminal emulator.

- **Copy** places the exact command text on the clipboard, including newlines and quotes.
- **Run in Termux** opens a confirmation sheet first. The sheet shows the command, the risk label, whether it will run in the foreground or background, and whether the terminal stays open.
- **Keep terminal open** is on by default for foreground runs. It keeps the session and its output visible after the command finishes; press Enter in Termux to close it. Background runs ignore this option.
- Sending a command only means Android accepted the intent. The app cannot see the output or prove that the command succeeded inside Termux.

Always read a command before sending it. Destructive commands are labelled, but the label is guidance, not a guarantee.

## Termux setup

1. Install Termux from the [official GitHub releases](https://github.com/termux/termux-app/releases). Play Store builds are outdated and do not support this integration.
2. Open Termux once so its environment is created.
3. Allow the `RUN_COMMAND` permission when Android asks. If the dialog no longer appears, grant it from Android Settings → Apps → **Termux Command Library** → Permissions. The in-app Termux guide also has an **Open app settings** action.
4. For direct execution, enable external apps in Termux:

```bash
mkdir -p ~/.termux
echo "allow-external-apps=true" >> ~/.termux/termux.properties
```

5. Restart Termux, or run `termux-reload-settings`. Without this setting Termux rejects the request with a `RunCommandService requires 'allow-external-apps'` toast, and the app cannot detect that rejection.
6. On Android 10 and later, allow Termux **Display over other apps** so it can open a session while this app is in front: **Settings → Apps → Termux → Display over other apps → Allow**, or use **Open Termux display settings** in the Termux guide. Without it Termux shows its own dialog and the command does not run. Background runs do not need it.

Use **Run via Termux** on a step or **Run all in Termux** on a guide. Every command is shown for confirmation first. Leave **Keep terminal open** on to read the output before the session closes.

For guides that use built-in `termux-*` commands, install **both** parts of Termux:API:

1. The [Termux:API APK](https://github.com/termux/termux-api).
2. The package inside Termux: `pkg install termux-api`.

Test them with `termux-toast "Termux:API connection OK"`. The app detects the APK only; it cannot see the package inside Termux. It stops before running a `termux-*` command when the APK is missing, and the confirmation sheet reminds you about the package. Install Termux and Termux:API from the same source, because GitHub and F-Droid builds use different signing keys.

The in-app **Termux guide** checks whether Termux and the API app are installed and whether the run permission is available. It cannot grant Android permissions for you.

## Optional AI assistant

AI is disabled by default and uses your own Groq API key (BYOK).

1. Create a key at [console.groq.com/keys](https://console.groq.com/keys).
2. Open **Settings → AI assistant**, paste the key, and test it.
3. Fetch the model list, choose a model, then enable the assistant.
4. The key is stored in Android's encrypted secure storage, never in SQLite, Firestore, AI history or logs.
5. Conversation history and cached answers stay on this device. They are not uploaded to Firebase.
6. File attachments are limited to small text files (TXT, MD, SH, PY, LOG). Content is sent only with the request you confirm and is not saved in history.
7. Remove the key at any time from AI settings. Removing it disables requests immediately.

The assistant can be wrong. Verify commands before running them, especially commands that change files, install software or require elevated access.

## Appearance and accessibility

- Choose light, dark or system theme.
- Pick an accent colour, enable or reduce blur, and adjust vibration intensity.
- Choose a system font or one of the bundled readable font families.
- Adjust the app text size. Myanmar text falls back to Noto Sans Myanmar when the chosen font has no Myanmar glyphs.
- System font scaling and display size continue to apply.

## Account and data

The account screen separates three different actions:

- **Clear local cache** removes downloaded guide data and local AI cache/history. Public posts and your cloud favorites remain.
- **Remove guest profile** deletes the on-device guest identity and its local favorites and pins. It cannot be undone.
- **Delete account** permanently removes the Firebase account, profile and private cloud data. It requires recent authentication. Public guides you published may be removed with the account.

Signing out is not deletion. You can sign back in and keep your cloud collection.

## Troubleshooting

### The library is empty after a reinstall

The built-in starter guides are installed on first launch. If they are missing, check free storage and restart the app. Signed-in users can pull to refresh; guest content has no cloud copy.

### Sync keeps failing

Check that the device is online, that the Firebase project is configured in the build, and that the account has not been disabled. A permission-denied error usually means the Firestore security rules or the account role changed. The cached library still works.

### "Termux is not installed" but it is

Android package visibility can take a moment after installation. Reopen the app, then use **Check again** on the Termux guide. Sideloaded or differently signed Termux builds may be invisible to the integration.

### Commands are sent but nothing happens

Confirm `allow-external-apps=true` is in `~/.termux/termux.properties`, restart Termux, and check that the `RUN_COMMAND` permission is granted. Battery optimisation may also delay background work; use a wake lock for long tasks.

### The AI key test fails

Keys are tied to the provider account that created them. Check for extra spaces, a revoked key, an exhausted quota, or a provider outage. Fetching models again after a success is a good final check.

### Myanmar text looks wrong

Set the font to a family that includes Myanmar glyphs, or leave the system font selected. The app supplies Noto Sans Myanmar as a fallback, but combining scripts can still affect line height.

## Limits and privacy

- Command name: 100 characters; description: 4,000 characters.
- Up to 30 steps per guide; each command is stored exactly as typed.
- Favorites: 5,000 per account; pins: 200 per account.
- One AI attachment per request, up to 256 KB on disk and 20,000 characters placed in the prompt.
- No Firebase Storage or file uploads are used. Avatars are built into the app.
- API keys never leave secure storage except as an authorization header to the chosen AI provider.

## Open source and licences

The app bundles several open-source fonts. Open **Settings → Licences** to read their licences together with Flutter's package notices. The Termux name and logo belong to their respective owners; this project is not affiliated with the Termux maintainers.
