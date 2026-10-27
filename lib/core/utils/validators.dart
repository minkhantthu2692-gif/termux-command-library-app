import '../constants/app_constants.dart';

/// Email/password validation and user-input normalisation.
///
/// Rules:
///  - A bare username is completed to `<username>@gmail.com`.
///  - An explicitly entered domain is never changed.
///  - Trimming happens only around the outside of the value. Command strings
///    are never normalised by these helpers.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  static String normalizeEmail(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.contains('@')) {
      return '$trimmed@gmail.com';
    }
    return trimmed;
  }

  static bool isValidEmail(String raw) {
    final email = normalizeEmail(raw);
    return email.length <= 254 && _emailPattern.hasMatch(email);
  }

  static bool isValidBareUsername(String raw) {
    final value = raw.trim();
    return value.isNotEmpty &&
        value.length <= 64 &&
        RegExp(r'^[a-zA-Z0-9._%+-]+$').hasMatch(value);
  }

  static String? emailError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'required';
    if (!isValidEmail(value)) return 'invalid';
    return null;
  }

  static PasswordStrength passwordStrength(String password) {
    if (password.length < 8) return PasswordStrength.tooShort;
    var score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) score++;
    if (password.length >= 16) score++;
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static bool passwordsMatch(String password, String confirmation) =>
      password.isNotEmpty && password == confirmation;

  static String? nameError(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'required';
    if (name.length < 2) return 'tooShort';
    if (name.length > AppConstants.maxCommandNameLength) return 'tooLong';
    return null;
  }

  static String? nicknameError(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'required';
    if (name.length < 2) return 'tooShort';
    if (name.length > AppConstants.maxNicknameLength) return 'tooLong';
    return null;
  }

  static String? descriptionError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'required';
    if (text.length > AppConstants.maxDescriptionLength) return 'tooLong';
    return null;
  }

  static String? requiredError(String? value) =>
      (value == null || value.trim().isEmpty) ? 'required' : null;

  static String? commandError(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (value.length > AppConstants.maxCommandLength) return 'tooLong';
    return null;
  }

  /// Tags are cleaned for storage only. Commands themselves are never cleaned.
  static List<String> normalizeTags(Iterable<String> rawTags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawTags) {
      final tag = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (tag.isEmpty) continue;
      final clipped = tag.length > AppConstants.maxTagLength
          ? tag.substring(0, AppConstants.maxTagLength)
          : tag;
      if (seen.add(clipped.toLowerCase())) {
        result.add(clipped);
      }
      if (result.length >= AppConstants.maxTags) break;
    }
    return result;
  }

  static bool isValidHttpUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  /// Search values are lower-cased once and stored in the local search blob.
  /// `%` and `_` are escaped so a literal search cannot widen the LIKE match.
  static String escapeLike(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

enum PasswordStrength { tooShort, weak, medium, strong }
