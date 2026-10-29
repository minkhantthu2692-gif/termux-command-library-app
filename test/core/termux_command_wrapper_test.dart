import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/utils/termux_command_wrapper.dart';

void main() {
  group('termuxCommandForExecution', () {
    test('returns the command untouched when keep-open is off', () {
      const command = 'termux-battery-status\n\nexit 0';
      expect(termuxCommandForExecution(command, keepOpen: false), command);
    });

    test('wraps a command in a subshell and waits for Enter', () {
      expect(
        termuxCommandForExecution(
          'termux-battery-status',
          keepOpen: true,
          keepOpenHint: 'Done.',
        ),
        '(\n'
        'termux-battery-status\n'
        '\n'
        'echo\n'
        "printf '%s\\n' 'Done.'\n"
        'read -r __termux_keep_open\n'
        ')',
      );
    });

    test('preserves multi-line commands, quotes and whitespace', () {
      const command = 'cd ~/project\n  make build && echo "ok"';
      final wrapped = termuxCommandForExecution(
        command,
        keepOpen: true,
        keepOpenHint: 'Done.',
      );
      expect(wrapped, contains('\n$command\n\n'));
    });

    test('keeps a trailing backslash from swallowing the wait', () {
      const command = 'echo hi \\';
      final wrapped = termuxCommandForExecution(
        command,
        keepOpen: true,
        keepOpenHint: 'Done.',
      );
      // The blank line after the command absorbs the escaped newline so the
      // echo/read lines still run.
      expect(wrapped, contains('\n$command\n\necho\n'));
    });

    test('escapes single quotes in the hint', () {
      final wrapped = termuxCommandForExecution(
        'echo hi',
        keepOpen: true,
        keepOpenHint: "It's done.",
      );
      expect(wrapped, contains("printf '%s\\n' 'It'\\''s done.'"));
    });
  });
}
