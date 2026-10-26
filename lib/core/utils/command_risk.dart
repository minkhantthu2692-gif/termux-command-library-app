/// Conservative client-side risk analysis for commands before they are sent to
/// Termux. This is guidance, not a sandbox or a security boundary. Copying is
/// always safe; running is always confirmed by the user.
enum CommandRiskLevel { none, medium, high }

enum CommandRiskReason {
  recursiveRootDelete,
  homeDelete,
  filesystemFormat,
  rawDiskWrite,
  systemPermissionChange,
  forkBomb,
  systemPower,
  pipeDownloadToShell,
  destructiveGitClean,
  packageRemoval,
  privilegeEscalation,
  forceKill,
}

class CommandRisk {
  const CommandRisk(this.level, this.reasons);

  final CommandRiskLevel level;
  final List<CommandRiskReason> reasons;

  bool get hasWarnings => reasons.isNotEmpty;
  bool get isHigh => level == CommandRiskLevel.high;
}

abstract final class CommandRiskAnalyzer {
  static final List<(RegExp, CommandRiskLevel, CommandRiskReason)> _rules = [
    (
      RegExp(r'rm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)+/(?:\s|$|\*)'),
      CommandRiskLevel.high,
      CommandRiskReason.recursiveRootDelete,
    ),
    (
      RegExp(r'rm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s+)+(~|\$HOME)(?:/|\s|$)'),
      CommandRiskLevel.high,
      CommandRiskReason.homeDelete,
    ),
    (
      RegExp(r'\bmkfs(?:\.\w+)?\b|\bwipefs\b'),
      CommandRiskLevel.high,
      CommandRiskReason.filesystemFormat,
    ),
    (
      RegExp(r'\bdd\b[^\n]*\bof=/dev/'),
      CommandRiskLevel.high,
      CommandRiskReason.rawDiskWrite,
    ),
    (
      RegExp(r'\bchmod\s+-R\s+(?:777|666)\s+/(?:\s|$)'),
      CommandRiskLevel.high,
      CommandRiskReason.systemPermissionChange,
    ),
    (
      RegExp(r':\s*\(\s*\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:'),
      CommandRiskLevel.high,
      CommandRiskReason.forkBomb,
    ),
    (
      RegExp(r'\b(?:shutdown|reboot|poweroff)\b'),
      CommandRiskLevel.high,
      CommandRiskReason.systemPower,
    ),
    (
      RegExp(
        r'\b(?:curl|wget)\b[^\n|]*\|\s*(?:sudo\s+)?(?:sh|bash|zsh)\b',
        caseSensitive: false,
      ),
      CommandRiskLevel.medium,
      CommandRiskReason.pipeDownloadToShell,
    ),
    (
      RegExp(r'\bgit\s+clean\s+-[a-zA-Z]*[fdx]'),
      CommandRiskLevel.medium,
      CommandRiskReason.destructiveGitClean,
    ),
    (
      RegExp(
        r'\b(?:pkg|apt|apt-get)\s+(?:uninstall|remove|purge)\b|\bpip(?:\d)?\s+uninstall\b',
      ),
      CommandRiskLevel.medium,
      CommandRiskReason.packageRemoval,
    ),
    (
      RegExp(r'(^|\s)(sudo|su\s+-)(\s|$)'),
      CommandRiskLevel.medium,
      CommandRiskReason.privilegeEscalation,
    ),
    (
      RegExp(r'\bkill\s+-9\b'),
      CommandRiskLevel.medium,
      CommandRiskReason.forceKill,
    ),
  ];

  static CommandRisk analyze(Iterable<String> commands) {
    final reasons = <CommandRiskReason>{};
    var level = CommandRiskLevel.none;
    for (final command in commands) {
      for (final (pattern, ruleLevel, reason) in _rules) {
        if (pattern.hasMatch(command)) {
          reasons.add(reason);
          if (ruleLevel == CommandRiskLevel.high) {
            level = CommandRiskLevel.high;
          } else if (level == CommandRiskLevel.none) {
            level = CommandRiskLevel.medium;
          }
        }
      }
    }
    return CommandRisk(level, reasons.toList(growable: false));
  }
}
