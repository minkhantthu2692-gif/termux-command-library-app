import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../data/models/auth_models.dart';
import '../../shared/utils/ui_actions.dart';

/// Finishes a successful sign-in/registration flow: offers to import the local
/// guest collection exactly once, marks onboarding complete, then navigates to
/// the requested destination. A data-import failure must never trap the user in
/// the auth flow, so it is reported but does not prevent navigation.
Future<void> finishAuthFlow(
  BuildContext context,
  WidgetRef ref,
  AuthSession session, {
  String? next,
}) async {
  final l10n = AppLocalizations.of(context);
  final settings = ref.read(settingsControllerProvider);
  final profileRepository = ref.read(profileRepositoryProvider);
  try {
    final hasGuestData = await profileRepository.hasGuestPreferences(
      settings.localGuestUid,
    );
    if (hasGuestData && context.mounted) {
      final shouldImport = await showConfirmDialog(
        context,
        title: l10n.linkGuestData,
        message: l10n.linkGuestDataBody,
        confirmLabel: l10n.importGuestData,
        cancelLabel: l10n.skipForNow,
      );
      if (shouldImport) {
        await profileRepository.importGuestPreferences(
          guestUid: settings.localGuestUid,
          targetUid: session.uid,
        );
        if (context.mounted) context.showSnack(l10n.guestDataImported);
      }
    }
  } catch (error) {
    if (context.mounted) context.showErrorSnack(error);
  }

  await ref
      .read(settingsControllerProvider.notifier)
      .setOnboardingCompleted(true);
  if (!context.mounted) return;
  final destination = _safeNext(next);
  context.go(destination ?? '/home');
}

String? _safeNext(String? next) {
  if (next == null || next.isEmpty) return null;
  if (!next.startsWith('/') || next.startsWith('//')) return null;
  return next;
}

/// Accepts only in-app destinations from a URL. Prevents using the auth flow as
/// an open redirect.
String? safeAuthNext(String? next) => _safeNext(next);
