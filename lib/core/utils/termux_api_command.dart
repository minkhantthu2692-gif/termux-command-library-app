/// Detects commands that invoke one of Termux:API's `termux-*` programs.
///
/// This is used only to decide whether the run flow should check for the
/// `com.termux.api` APK and show the Termux:API guidance. It is intentionally
/// conservative: only the executable position of each shell segment is
/// inspected, so text such as `pkg install termux-api` or
/// `echo termux-battery-status` is not treated as an API call.
library;

final _segmentSeparator = RegExp(r'[;&|\n()]+');
final _whitespace = RegExp(r'\s+');
final _variableAssignment = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*=');
final _termuxProgram = RegExp(r'^termux-[a-z0-9][a-z0-9-]*$');
const _commandPrefixes = {'sudo', 'command', 'exec', 'nohup', 'time', 'env'};

/// `termux-*` names that ship with the Termux app or its base tools rather than
/// with Termux:API. They must not trigger the Termux:API requirement.
const _coreTermuxPrograms = {
  'termux-api', // package name, not an executable
  'termux-backup',
  'termux-change-repo',
  'termux-fix-shebang',
  'termux-info',
  'termux-open',
  'termux-open-url',
  'termux-reload-settings',
  'termux-reset',
  'termux-restore',
  'termux-setup-package-manager',
  'termux-setup-storage',
  'termux-wake-lock',
  'termux-wake-unlock',
};

/// Returns `true` when any shell segment starts with a `termux-*` program.
///
/// Examples that match: `termux-toast hi`, `foo && termux-battery-status`,
/// `sudo termux-wifi-enable true`, `/data/data/com.termux/files/usr/bin/termux-toast hi`.
/// Examples that do not match: `pkg install termux-api`, `echo termux-toast`.
bool usesTermuxApiCommand(String command) {
  for (final segment in command.split(_segmentSeparator)) {
    if (_segmentUsesTermuxApi(segment)) return true;
  }
  return false;
}

bool usesTermuxApiCommands(Iterable<String> commands) =>
    commands.any(usesTermuxApiCommand);

bool _segmentUsesTermuxApi(String rawSegment) {
  final tokens = rawSegment
      .trim()
      .split(_whitespace)
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) return false;

  var index = 0;
  var skipOptions = false;
  while (index < tokens.length) {
    final token = tokens[index];
    if (_variableAssignment.hasMatch(token)) {
      index++;
      continue;
    }
    if (skipOptions && token.startsWith('-')) {
      index++;
      continue;
    }
    if (_commandPrefixes.contains(token)) {
      index++;
      skipOptions = true;
      continue;
    }
    break;
  }
  if (index >= tokens.length) return false;

  final executable = tokens[index]
      .replaceAll(RegExp(r'''^['"]|['"]$'''), '')
      .split('/')
      .last;
  return _termuxProgram.hasMatch(executable) &&
      !_coreTermuxPrograms.contains(executable);
}
