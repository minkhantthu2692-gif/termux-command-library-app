import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/data/models/auth_models.dart';

void main() {
  const base = AuthSession(
    uid: 'user-1',
    email: 'user@example.com',
    displayName: 'User',
    isAnonymous: false,
    isAdmin: false,
    isLocalOnly: false,
    linkedProviders: {AuthProviderIds.password, AuthProviderIds.google},
  );

  test('hasGithub only reflects the GitHub provider id', () {
    expect(base.hasGithub, isFalse);
    expect(
      base.copyWith(linkedProviders: const {AuthProviderIds.github}).hasGithub,
      isTrue,
    );
  });

  test('provider sets compare without depending on order', () {
    final reordered = base.copyWith(
      linkedProviders: const {AuthProviderIds.google, AuthProviderIds.password},
    );

    expect(reordered, base);
    expect(reordered.hashCode, base.hashCode);
  });

  test('a different provider set is not equal', () {
    final linked = base.copyWith(
      linkedProviders: const {
        AuthProviderIds.password,
        AuthProviderIds.google,
        AuthProviderIds.github,
      },
    );

    expect(linked, isNot(base));
  });

  test('copyWith preserves identity unless explicitly changed', () {
    final linked = base.copyWith(
      linkedProviders: const {AuthProviderIds.github},
    );

    expect(linked.uid, base.uid);
    expect(linked.email, base.email);
    expect(linked.displayName, base.displayName);
    expect(linked.isAnonymous, base.isAnonymous);
    expect(linked.isAdmin, base.isAdmin);
    expect(linked.isLocalOnly, base.isLocalOnly);
  });
}
