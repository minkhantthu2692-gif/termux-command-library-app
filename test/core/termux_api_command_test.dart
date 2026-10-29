import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/utils/termux_api_command.dart';

void main() {
  group('detects Termux:API programs', () {
    test('a single termux-* command', () {
      expect(usesTermuxApiCommand('termux-battery-status'), isTrue);
      expect(usesTermuxApiCommand('termux-toast "Build finished"'), isTrue);
      expect(usesTermuxApiCommand('  termux-clipboard-get  '), isTrue);
    });

    test('commands in a chain or script', () {
      expect(
        usesTermuxApiCommand('cd ~/project && termux-toast "done"'),
        isTrue,
      );
      expect(
        usesTermuxApiCommand(
          'termux-battery-status\nmake build\ntermux-toast "done"',
        ),
        isTrue,
      );
      expect(
        usesTermuxApiCommand('echo start | termux-notification -t hi'),
        isTrue,
      );
      expect(usesTermuxApiCommand('(\n  termux-vibrate\n)'), isTrue);
    });

    test('wrapped executables and absolute paths', () {
      expect(usesTermuxApiCommand('sudo termux-wifi-enable true'), isTrue);
      expect(usesTermuxApiCommand('env DEBUG=1 termux-sensor -l'), isTrue);
      expect(
        usesTermuxApiCommand(
          '/data/data/com.termux/files/usr/bin/termux-toast hi',
        ),
        isTrue,
      );
      expect(usesTermuxApiCommand('"termux-toast" hi'), isTrue);
      expect(usesTermuxApiCommand(r'$(termux-battery-status)'), isTrue);
    });
  });

  group('ignores text that is not an API call', () {
    test('package installation and mentions in arguments', () {
      expect(usesTermuxApiCommand('pkg install termux-api'), isFalse);
      expect(usesTermuxApiCommand('echo termux-toast'), isFalse);
      expect(usesTermuxApiCommand('echo "termux-battery-status"'), isFalse);
      expect(
        usesTermuxApiCommand('git clone https://github.com/termux/termux-api'),
        isFalse,
      );
      expect(usesTermuxApiCommand('# termux-toast is optional'), isFalse);
    });

    test('core Termux commands that are not part of Termux:API', () {
      expect(usesTermuxApiCommand('termux-reload-settings'), isFalse);
      expect(usesTermuxApiCommand('termux-setup-storage'), isFalse);
      expect(usesTermuxApiCommand('termux-wake-lock'), isFalse);
      expect(usesTermuxApiCommand('termux-change-repo'), isFalse);
      expect(usesTermuxApiCommand('termux-info'), isFalse);
      expect(
        usesTermuxApiCommand('termux-open-url https://termux.dev'),
        isFalse,
      );
      expect(usesTermuxApiCommand('termux-open notes.txt'), isFalse);
      expect(usesTermuxApiCommand('termux-setup-package-manager'), isFalse);
    });

    test('empty and unrelated commands', () {
      expect(usesTermuxApiCommand(''), isFalse);
      expect(usesTermuxApiCommand('ls -la ~'), isFalse);
      expect(usesTermuxApiCommand('npm run termux-toast'), isFalse);
    });
  });

  test('checks every command in a list', () {
    expect(usesTermuxApiCommands(['ls', 'termux-battery-status']), isTrue);
    expect(usesTermuxApiCommands(['ls', 'pwd']), isFalse);
    expect(usesTermuxApiCommands(const []), isFalse);
  });
}
