import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/utils/command_risk.dart';

void main() {
  group('high-risk commands', () {
    test('recursive root delete', () {
      final risk = CommandRiskAnalyzer.analyze(['rm -rf /']);
      expect(risk.level, CommandRiskLevel.high);
      expect(risk.reasons, contains(CommandRiskReason.recursiveRootDelete));
      expect(risk.isHigh, isTrue);
      expect(risk.hasWarnings, isTrue);
    });

    test('home directory delete and raw disk writes', () {
      final risk = CommandRiskAnalyzer.analyze([
        'rm -rf ~/projects',
        'dd if=/dev/zero of=/dev/block/mmcblk0',
      ]);
      expect(risk.level, CommandRiskLevel.high);
      expect(
        risk.reasons,
        containsAll([
          CommandRiskReason.homeDelete,
          CommandRiskReason.rawDiskWrite,
        ]),
      );
    });

    test('format, permission and power operations', () {
      final risk = CommandRiskAnalyzer.analyze([
        'mkfs.ext4 /dev/block/by-name/userdata',
        'chmod -R 777 /',
        'sudo reboot',
      ]);
      expect(risk.level, CommandRiskLevel.high);
      expect(
        risk.reasons,
        containsAll([
          CommandRiskReason.filesystemFormat,
          CommandRiskReason.systemPermissionChange,
          CommandRiskReason.systemPower,
        ]),
      );
    });

    test('fork bomb is detected', () {
      final risk = CommandRiskAnalyzer.analyze([':(){ :|:& };:']);
      expect(risk.level, CommandRiskLevel.high);
      expect(risk.reasons, contains(CommandRiskReason.forkBomb));
    });
  });

  group('medium-risk commands', () {
    test('download piped to a shell', () {
      final risk = CommandRiskAnalyzer.analyze([
        'curl -fsSL https://example.com/install.sh | bash',
      ]);
      expect(risk.level, CommandRiskLevel.medium);
      expect(risk.reasons, contains(CommandRiskReason.pipeDownloadToShell));
    });

    test(
      'destructive clean, package removal, privilege escalation and kill',
      () {
        final risk = CommandRiskAnalyzer.analyze([
          'git clean -fdx',
          'pkg uninstall python',
          'sudo pkg install git',
          'kill -9 1234',
        ]);
        expect(risk.level, CommandRiskLevel.medium);
        expect(
          risk.reasons,
          containsAll([
            CommandRiskReason.destructiveGitClean,
            CommandRiskReason.packageRemoval,
            CommandRiskReason.privilegeEscalation,
            CommandRiskReason.forceKill,
          ]),
        );
      },
    );

    test('high risk always wins over medium risk', () {
      final risk = CommandRiskAnalyzer.analyze([
        'curl https://example.com/x.sh | sh',
        'rm -rf /',
      ]);
      expect(risk.level, CommandRiskLevel.high);
      expect(
        risk.reasons,
        containsAll([
          CommandRiskReason.pipeDownloadToShell,
          CommandRiskReason.recursiveRootDelete,
        ]),
      );
    });
  });

  group('safe commands', () {
    test('returns no warnings for ordinary package and file work', () {
      final risk = CommandRiskAnalyzer.analyze([
        'pkg update && pkg upgrade -y',
        'pkg install git',
        'ls -la ~/storage/shared',
        'cat > notes.md <<EOF\nhello\nEOF',
        'rm -rf ./build',
      ]);
      expect(risk.level, CommandRiskLevel.none);
      expect(risk.reasons, isEmpty);
      expect(risk.hasWarnings, isFalse);
      expect(risk.isHigh, isFalse);
    });

    test('handles an empty command list', () {
      final risk = CommandRiskAnalyzer.analyze(const []);
      expect(risk.level, CommandRiskLevel.none);
      expect(risk.reasons, isEmpty);
    });

    test('deduplicates repeated reasons', () {
      final risk = CommandRiskAnalyzer.analyze(['sudo ls', 'sudo whoami']);
      expect(risk.reasons, [CommandRiskReason.privilegeEscalation]);
    });
  });
}
