# Termux integration

Termux Command Library is not a terminal emulator. It prepares commands, shows
them to the user, copies them, or asks Termux to run them through Termux's
documented `RUN_COMMAND` intent. Termux owns the shell session and the output.

---

## 1. Install Termux

Install Termux from the official GitHub releases:

<https://github.com/termux/termux-app/releases>

Choose the APK that matches the device architecture (usually `arm64-v8a` for
modern phones). The Play Store build has been deprecated/outdated for years; do
not treat it as the supported source.

Termux:API is optional and only needed for guides that use `termux-*` API
commands. If you use it, install Termux:API from its official releases:

<https://github.com/termux/termux-api/releases>

The app detects whether `com.termux` and `com.termux.api` are installed, but it
does not install either package.

## 2. Allow external commands

Termux blocks external `RUN_COMMAND` intents unless the user opts in:

```bash
echo "allow-external-apps=true" >> ~/.termux/termux.properties
termux-reload-settings
```

If the file already contains `allow-external-apps`, edit it instead of appending a
duplicate. The property must be `true`.

Open Termux at least once after installation so its home directory and package
manager are initialized.

## 3. Grant the Android permission

This app declares:

```xml
<uses-permission android:name="com.termux.permission.RUN_COMMAND" />
```

When you use **Run in Termux** for the first time, the app:

1. Checks that Termux is installed.
2. Checks `RUN_COMMAND` permission.
3. Explains the permission and asks for confirmation.
4. Calls Android's runtime permission request if needed.

If the dialog does not appear or permission was previously denied, open Android
**Settings → Apps → Termux Command Library → Permissions** and grant the
`RUN_COMMAND` permission, or use the app's Termux guide to open Termux's app info.

The app also declares Android 11+ package visibility for `com.termux` and
`com.termux.api`, so detection works without broad package-query permissions.

## 4. What happens when you run a command

The only supported flow is `showTermuxRunFlow`:

1. If Termux is missing, show the official install link.
2. If permission is missing, explain and request it.
3. Analyze the command(s) for risky patterns.
4. Show a confirmation sheet containing the exact command text, foreground or
   background mode, and warnings.
5. For risky commands, require an explicit acknowledgement.
6. Send one `RUN_COMMAND` intent per step, with a short delay between steps so
   Termux can create/switch sessions.
7. Report **"Sent to Termux"** — never "completed", "succeeded" or "output".

The intent uses:

```text
action:    com.termux.RUN_COMMAND
component: com.termux/com.termux.app.RunCommandService
path:      /data/data/com.termux/files/usr/bin/bash
arguments: -c <command>
workdir:   /data/data/com.termux/files/home
```

Each step is sent as separate `-c` arguments. Newlines, quotes, pipes, redirects
and other shell syntax are preserved exactly; the app does not split or reformat
commands.

Because the app does not receive the command's exit status, it cannot claim the
command succeeded. Check the Terminal output in Termux.

## 5. Copy instead of run

Use **Copy** on a step or **Copy all** on a guide. Copying does not require Termux
or permissions and preserves the original text. This is the recommended option
when:

- You want to review or edit a command first.
- The command needs an interactive prompt.
- Termux integration is unavailable.
- A guide contains a destructive command.

## 6. Risk warnings

The risk analyzer looks for patterns such as recursive deletes, disk formatting,
raw block-device writes, package-manager removals, privilege escalation and
piping remote content into a shell. It is a usability warning, **not a sandbox**
and not a guarantee that every dangerous command will be detected.

The user must still read the command. Never run a command you do not understand.
The app cannot undo a command once Termux starts it.

## 7. Foreground vs. background

- **Foreground** creates/switches to a Termux terminal session and is appropriate
  for interactive or long-running output.
- **Background** uses Termux's background mode; output may not be visible in the
  same way. Use it only when the guide is written for that behavior.

The confirmation sheet defaults to background only when every selected step uses
`runMode: background`. The user can change the mode before confirming.

## 8. Filtering and multiple steps

- Running one step sends one intent.
- Running all sends each step in order with a 350 ms pause between intents.
- If an intent fails partway through, the app reports the error; commands already
  accepted by Termux are not rolled back.
- The app does not automatically retry a potentially destructive command.

## 9. Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| "Termux not installed" | Install the official `com.termux` APK; check Android package visibility. |
| Permission dialog does not appear | Grant `RUN_COMMAND` in Android app settings; check that Termux is installed. |
| Command does nothing | Set `allow-external-apps=true`, run `termux-reload-settings`, and restart Termux. |
| `termux-*` command not found | Install Termux:API and grant the relevant Android permissions. |
| Output is not visible | Check Termux's terminal session; the app cannot capture output. |
| Background command seems silent | Use foreground mode or inspect Termux output/logs. |
| Emulator cannot run Termux | Termux targets real Android; use a physical device or a suitable Android image. |
| Play Store Termux fails | Use the official GitHub releases, not the deprecated store build. |

Android vendors may restrict background services. If commands fail while the app
is backgrounded, disable battery optimization for Termux and keep its service
allowed by the vendor's battery settings.

## 10. Security notes

- The app never executes a command silently.
- The confirmation sheet always displays the command before it is sent.
- Copying is always available as a non-executing alternative.
- `RUN_COMMAND` runs with Termux's app permissions, not as root. `sudo`/root
  commands will only work if the device and Termux are explicitly configured for
  them.
- Do not grant Termux broad device permissions unless a guide requires them.
- Treat public command guides as untrusted input. Review before running.
