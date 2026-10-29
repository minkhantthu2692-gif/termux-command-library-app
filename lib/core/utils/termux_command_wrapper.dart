/// Builds the shell script that Termux runs for a command.
///
/// Termux closes a foreground terminal session as soon as its command exits,
/// which hides the output. Wrapping the command in a subshell and waiting for
/// Enter keeps the session and its scrollback open.
///
/// This only changes how the command is executed. The command text shown in the
/// app, copied to the clipboard, and stored in a guide is never modified.
String termuxCommandForExecution(
  String command, {
  required bool keepOpen,
  String keepOpenHint = 'Command finished. Press Enter to close.',
}) {
  if (!keepOpen) return command;

  // The hint is passed as a single-quoted shell argument. A single quote inside
  // the hint is closed, escaped and reopened so the text is preserved.
  final quotedHint = "'${keepOpenHint.replaceAll("'", "'\\''")}'";
  return '(\n'
      '$command\n'
      '\n'
      'echo\n'
      "printf '%s\\n' $quotedHint\n"
      'read -r __termux_keep_open\n'
      ')';
}
