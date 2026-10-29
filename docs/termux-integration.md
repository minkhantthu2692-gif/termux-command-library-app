# Termux integration

Termux Command Library is not a terminal emulator. It prepares commands, shows
them to the user, copies them, or asks Termux to run them through Termux's
documented `RUN_COMMAND` intent. Termux owns the shell session and the output.

The app reports a command as **sent to Termux**, never as completed or
successful, because Android does not return the command's exit status here.

---

## Quick start

1. Install Termux from the official GitHub releases.
2. Open Termux once and enable external commands (`allow-external-apps=true`).
3. Open **Termux setup guide** in the app and grant the `RUN_COMMAND` permission.
4. On Android 10+, allow Termux **Display over other apps** so it can open a
   session while this app is in front.
5. Tap **Run via Termux** on a step, or **Run all in Termux** on a guide.
6. For guides that use `termux-*` commands, also install the Termux:API APK and
   the `termux-api` package inside Termux.

---

## 1. Install Termux

Install Termux from the official GitHub releases:

<https://github.com/termux/termux-app/releases>

Choose the APK that matches the device architecture (usually `arm64-v8a` for
modern phones). The Play Store build has been deprecated/outdated for years; do
not treat it as the supported source.

Open Termux at least once after installation so its home directory and package
manager are initialized.

## 2. Install Termux:API (only for `termux-*` commands)

Termux:API is optional. It is needed only for guides that call one of the
built-in `termux-*` programs, such as `termux-battery-status`, `termux-toast`,
`termux-clipboard-get` or `termux-notification`.

Termux:API has **two separate parts** and both are required:

| Part | What it provides | Where it comes from |
| --- | --- | --- |
| Termux:API APK (`com.termux.api`) | The Android-side bridge that talks to device APIs | <https://github.com/termux/termux-api> |
| `termux-api` package | The `termux-*` executables used inside the shell | `pkg install termux-api` inside Termux |

Official source and install instructions:

<https://github.com/termux/termux-api>

Direct APK downloads:

<https://github.com/termux/termux-api/releases>

Install the package inside Termux:

```bash
pkg update
pkg install termux-api
```

Verify both parts with a harmless toast:

```bash
termux-toast "Termux:API connection OK"
```

If the toast appears, the APK and package are working together. If the command
is not found, the package is missing. If the command runs but nothing appears,
the APK is missing, disabled, or one of its Android permissions was denied.

### Permissions for Termux:API

Termux:API exposes device features, so Android may ask for permissions such as
SMS, contacts, location, camera, microphone or storage. Grant only the
permissions a guide actually needs. The app's Termux guide has an **Open
Termux:API settings** button that opens the APK's Android app-info page, where
permissions can be reviewed.

### Same install source

Install Termux and Termux:API from the same source. GitHub and F-Droid builds
are signed with different keys, so switching sources requires uninstalling every
Termux app and plugin first. Back up important files under `~/` before doing
that; uninstalling Termux removes its private data.

### What the app can detect

The app can see whether the `com.termux.api` APK is installed. It **cannot** see
which packages are installed inside Termux, so the `termux-api` package is not
detected. The Termux:API status pill therefore means "APK installed", not
"`termux-*` commands will work".

When a command calls a `termux-*` program and the APK is missing, the app stops
before the confirmation sheet and shows the Termux:API install guidance. When
the APK is installed, the confirmation sheet still shows a short reminder that
the `termux-api` package is required.

Core Termux commands such as `termux-reload-settings`, `termux-setup-storage`,
`termux-open`, `termux-open-url`, `termux-wake-lock` and `termux-change-repo`
ship with the Termux app or its `termux-tools` package and do **not** require
Termux:API.

## 3. Allow external commands

Termux blocks external `RUN_COMMAND` intents unless the user opts in:

```bash
mkdir -p ~/.termux
echo "allow-external-apps=true" >> ~/.termux/termux.properties
termux-reload-settings
```

If the file already contains `allow-external-apps`, edit it instead of appending
a duplicate. The property must be `true`. Restart Termux if the setting does not
take effect.

This step is mandatory. Without it, Termux rejects the request and shows a toast
similar to:

```text
(2) Error: RunCommandService requires 'allow-external-apps' property to be set
to 'true' in '~/.termux/termux.properties' file.
```

The app cannot read Termux's private property file, so it cannot verify this
setting in advance. It also cannot see Termux's rejection toast. If the app says
"Command sent to Termux" but nothing happens, check Termux's screen for that
message and repeat this step.

## 4. Grant Android permissions

### 4.1 `RUN_COMMAND` for this app

This app declares:

```xml
<uses-permission android:name="com.termux.permission.RUN_COMMAND" />
```

When you use **Run via Termux** or **Run all in Termux** for the first time, the
app:

1. Checks that Termux is installed.
2. Checks the `RUN_COMMAND` permission.
3. Explains the permission and asks for confirmation.
4. Calls Android's runtime permission request if needed.

If the dialog does not appear or permission was previously denied, open Android
**Settings → Apps → Termux Command Library → Permissions** and grant the
`RUN_COMMAND` permission. The app's Termux guide also has an **Open app
settings** action.

The app declares Android 11+ package visibility for `com.termux` and
`com.termux.api`, so detection works without broad package-query permissions.

### 4.2 "Display over other apps" for Termux (Android 10+)

Android 10 and later blocks Termux from opening a terminal session while another
app is in front unless Termux has the **Display over other apps**
(`SYSTEM_ALERT_WINDOW`) permission. This is a Termux permission, not a
permission of this app.

Grant it from the app's Termux guide (**Open Termux display settings**), or
manually:

**Settings → Apps → Termux → Display over other apps → Allow**.

Without it, tapping **Run via Termux** makes Termux show:

```text
Termux requires "Display over other apps" permission to start terminal
sessions from background on Android >= 10.
```

and the command does not run. The app checks the permission with Android's
AppOps API before a foreground run and stops with an explanation instead of
reporting a false success. Background runs do not open a session and do not
need this permission.

## 5. Run commands from the app

Commands can be triggered directly from buttons:

- **Run via Termux** on a step in the command details screen.
- **Run all in Termux** on a guide with multiple steps.
- **Send test command** in the app's Termux guide.
- **Send API test** in the Termux:API step of the guide (`termux-toast`).

The only supported flow is `showTermuxRunFlow`:

1. If Termux is missing, show the official install link.
2. If permission is missing, explain and request it.
3. If a step uses Termux:API and the APK is missing, show the Termux:API
   install guidance and stop.
4. Analyze the command(s) for risky patterns.
5. Show a confirmation sheet containing the exact command text, foreground or
   background mode, the keep-terminal-open option, and warnings.
6. For risky commands, require an explicit acknowledgement.
7. For a foreground run, verify that Termux has the "Display over other apps"
   permission. If it does not, stop with an explanation and a settings action.
8. Send one `RUN_COMMAND` intent per step, with a short delay between steps so
   Termux can create/switch sessions.
9. Report **"Command sent to Termux"** — never "completed", "succeeded" or
   "output".

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
command succeeded. Check the terminal output in Termux.

## 6. Copy instead of run

Use **Copy** on a step or **Copy all** on a guide. Copying does not require
Termux or permissions and preserves the original text. This is the recommended
option when:

- You want to review or edit a command first.
- The command needs an interactive prompt.
- Termux integration is unavailable.
- A guide contains a destructive command.

## 7. Risk warnings

The risk analyzer looks for patterns such as recursive deletes, disk formatting,
raw block-device writes, package-manager removals, privilege escalation and
piping remote content into a shell. It is a usability warning, **not a sandbox**
and not a guarantee that every dangerous command will be detected.

The user must still read the command. Never run a command you do not understand.
The app cannot undo a command once Termux starts it.

## 8. Foreground vs. background

- **Foreground** creates/switches to a Termux terminal session and is appropriate
  for interactive or long-running output.
- **Background** uses Termux's background mode; output may not be visible in the
  same way. Use it only when the guide is written for that behavior.

The confirmation sheet defaults to background only when every selected step uses
`runMode: background`. The user can change the mode before confirming.

### Keeping the terminal open

Termux closes a foreground `RUN_COMMAND` session as soon as the command exits.
Fast commands such as `termux-battery-status` therefore print their output and
the session disappears before it can be read.

To prevent that, the app wraps **foreground** commands in a subshell that waits
for Enter after the command finishes:

```bash
(
<original command>

echo
printf '%s\n' 'Command finished. Press Enter to close this session.'
read -r __termux_keep_open
)
```

- **Keep terminal open** is enabled by default in the confirmation sheet.
- The session stays on its own screen with the output visible. Press Enter in
  Termux to close it.
- The wrapper is execution-only. The command shown in the app, copied to the
  clipboard, and stored in the guide is never modified.
- The subshell isolates `exit` and `exec`, so the original command cannot close
  the terminal before the hint is printed.
- Turning the switch off sends the original command and lets Termux close the
  session when it exits.
- **Background** runs ignore the option and always send the original command,
  because they do not create a terminal session.

The app still reports only that the command was sent. It cannot read the output
or confirm success.

## 9. Filtering and multiple steps

- Running one step sends one intent.
- Running all sends each step in order with a 350 ms pause between intents.
- If an intent fails partway through, the app reports the error; commands already
  accepted by Termux are not rolled back.
- The app does not automatically retry a potentially destructive command.

## 10. Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| "Termux not installed" | Install the official `com.termux` APK; check Android package visibility. |
| Permission dialog does not appear | Grant `RUN_COMMAND` in Android app settings; check that Termux is installed. |
| Termux shows "Display over other apps" dialog | Allow **Display over other apps** for Termux on Android 10+, or use background mode. |
| App says "sent" but Termux shows `allow-external-apps` error | Set `allow-external-apps=true`, run `termux-reload-settings`, and restart Termux. |
| Command does nothing and Termux is not visible | Open Termux and check its terminal for an error toast; check battery restrictions. |
| `termux-*` command not found | Run `pkg install termux-api` inside Termux. |
| `termux-*` runs but nothing happens | Install or enable the Termux:API APK and grant its Android permissions. |
| Termux:API status pill is green but API commands fail | The pill only checks the APK; install the `termux-api` package inside Termux. |
| Output is not visible | Check Termux's terminal session; the app cannot capture output. |
| Termux flashes `[2] bash` and returns to `[1] bash` | The command exited and Termux closed its session. Leave **Keep terminal open** on, or use a command that stays interactive. |
| Background command seems silent | Use foreground mode or inspect Termux output/logs. |
| Emulator cannot run Termux | Termux targets real Android; use a physical device or a suitable Android image. |
| Play Store Termux fails | Use the official GitHub releases, not the deprecated store build. |

Android vendors may restrict background services. If commands fail while the app
is backgrounded, disable battery optimization for Termux and keep its service
allowed by the vendor's battery settings.

## 11. Security notes

- The app never executes a command silently.
- The confirmation sheet always displays the command before it is sent.
- Copying is always available as a non-executing alternative.
- `RUN_COMMAND` runs with Termux's app permissions, not as root. `sudo`/root
  commands will only work if the device and Termux are explicitly configured for
  them.
- Do not grant Termux or Termux:API broad device permissions unless a guide
  requires them.
- Treat public command guides as untrusted input. Review before running.
