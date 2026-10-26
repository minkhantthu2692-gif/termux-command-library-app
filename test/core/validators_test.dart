import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/constants/app_constants.dart';
import 'package:termux_command_library/core/utils/validators.dart';

void main() {
  group('email normalisation', () {
    test('completes a bare username with gmail.com', () {
      expect(Validators.normalizeEmail('minkh'), 'minkh@gmail.com');
      expect(Validators.normalizeEmail('  minkh  '), 'minkh@gmail.com');
    });

    test('never rewrites an explicit non-Gmail domain', () {
      expect(
        Validators.normalizeEmail('minkh@example.org'),
        'minkh@example.org',
      );
      expect(Validators.normalizeEmail('minkh@yahoo.com'), 'minkh@yahoo.com');
    });

    test('leaves empty input empty', () {
      expect(Validators.normalizeEmail('   '), isEmpty);
    });

    test('validates completed usernames and rejects malformed addresses', () {
      expect(Validators.isValidEmail('minkh'), isTrue);
      expect(Validators.isValidEmail('first.last+tag@gmail.com'), isTrue);
      expect(Validators.isValidEmail('name@example.co.uk'), isTrue);
      expect(Validators.isValidEmail('name@localhost'), isFalse);
      expect(Validators.isValidEmail('name@@gmail.com'), isFalse);
      expect(Validators.isValidEmail('name @gmail.com'), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
    });

    test('uses stable error keys for form validation', () {
      expect(Validators.emailError(null), 'required');
      expect(Validators.emailError('   '), 'required');
      expect(Validators.emailError('not an email'), 'invalid');
      expect(Validators.emailError('someone'), isNull);
    });
  });

  group('password rules', () {
    test('requires at least eight characters', () {
      expect(Validators.passwordStrength('Ab1!'), PasswordStrength.tooShort);
      expect(Validators.passwordStrength('abcdefgh'), PasswordStrength.weak);
    });

    test('scores length and character variety', () {
      expect(
        Validators.passwordStrength('aB3!aB3!aB3!'),
        PasswordStrength.strong,
      );
      expect(
        Validators.passwordStrength('abcdefgh1234'),
        PasswordStrength.medium,
      );
    });

    test('confirmation must be non-empty and exact', () {
      expect(Validators.passwordsMatch('secret123', 'secret123'), isTrue);
      expect(Validators.passwordsMatch('secret123', 'secret124'), isFalse);
      expect(Validators.passwordsMatch('', ''), isFalse);
    });
  });

  group('names and command fields', () {
    test('name errors cover empty, short and long values', () {
      expect(Validators.nameError(''), 'required');
      expect(Validators.nameError(' a '), 'tooShort');
      expect(
        Validators.nameError('a' * (AppConstants.maxCommandNameLength + 1)),
        'tooLong',
      );
      expect(Validators.nameError('Git essentials'), isNull);
    });

    test('nickname has its own 40 character cap', () {
      expect(Validators.nicknameError('a'), 'tooShort');
      expect(Validators.nicknameError('a' * 40), isNull);
      expect(Validators.nicknameError('a' * 41), 'tooLong');
    });

    test('command text is required without trimming stored content', () {
      expect(Validators.commandError('   '), 'required');
      expect(Validators.commandError('  printf "%s\\n" hi  '), isNull);
    });
  });

  group('tags', () {
    test('trims, collapses whitespace, de-duplicates and caps', () {
      final tags = Validators.normalizeTags([
        '  git ',
        'Git',
        'shell   scripting',
        '',
        'x' * 50,
      ]);
      expect(tags.take(3), ['git', 'shell scripting', 'x' * 32]);
      expect(tags, hasLength(3));
    });

    test('limits the number of tags', () {
      final tags = Validators.normalizeTags(
        List.generate(AppConstants.maxTags + 5, (index) => 'tag$index'),
      );
      expect(tags, hasLength(AppConstants.maxTags));
    });
  });

  test('HTTP URL validation only accepts web URLs with a host', () {
    expect(Validators.isValidHttpUrl('https://termux.dev'), isTrue);
    expect(Validators.isValidHttpUrl('http://example.com/path'), isTrue);
    expect(Validators.isValidHttpUrl('ftp://example.com'), isFalse);
    expect(Validators.isValidHttpUrl('https://'), isFalse);
    expect(Validators.isValidHttpUrl('termux.dev'), isFalse);
  });

  test('LIKE escaping makes user input literal', () {
    expect(Validators.escapeLike(r'100%_done\path'), r'100\%\_done\\path');
  });
}
