import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/design_system/app_tokens.dart';

void main() {
  test('offers twelve unique accent choices', () {
    expect(AppAccents.all, hasLength(12));
    expect(
      AppAccents.all.map((accent) => accent.id).toSet(),
      hasLength(AppAccents.all.length),
    );
    expect(
      AppAccents.all.map((accent) => accent.labelKey).toSet(),
      hasLength(AppAccents.all.length),
    );
  });

  test('byId resolves every accent and falls back to indigo', () {
    for (final accent in AppAccents.all) {
      expect(AppAccents.byId(accent.id), same(accent));
    }
    expect(AppAccents.byId('neon'), AppAccents.indigo);
    expect(AppAccents.byId(null), AppAccents.indigo);
  });
}
