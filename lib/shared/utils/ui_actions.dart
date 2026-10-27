import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/settings/app_settings.dart';
import '../../data/services/haptics_service.dart';
import '../utils/error_messages.dart';

extension AppSnackBars on BuildContext {
  void showSnack(String message, {SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  void showErrorSnack(Object error) {
    _triggerContextHaptic(this, cue: HapticCue.error);
    final l10n = AppLocalizations.of(this);
    showSnack(localizeError(l10n, error));
  }
}

/// Fires a haptic from a non-Consumer context such as a dialog callback.
///
/// The app always runs inside a [ProviderScope]; the guard keeps standalone
/// widget tests and the earliest startup errors from failing here.
void _triggerContextHaptic(
  BuildContext context, {
  HapticCue cue = HapticCue.tap,
  VibrationIntensity? intensity,
}) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final selected =
        intensity ?? container.read(settingsControllerProvider).vibration;
    unawaited(
      container.read(hapticsServiceProvider).trigger(selected, cue: cue),
    );
  } catch (_) {
    // Haptics are optional feedback, never a prerequisite for an action.
  }
}

/// Confirmation helper used by destructive actions and Termux execution.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                )
              : null,
          onPressed: () {
            _triggerContextHaptic(
              dialogContext,
              cue: destructive ? HapticCue.warning : HapticCue.tap,
            );
            Navigator.of(dialogContext).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Copies text and confirms it with a snackbar + optional haptic feedback.
Future<void> copyWithFeedback(
  BuildContext context,
  WidgetRef ref,
  String text, {
  String? message,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await ref.read(clipboardServiceProvider).copy(text);
    await ref
        .read(hapticsServiceProvider)
        .trigger(
          ref.read(settingsControllerProvider).vibration,
          cue: HapticCue.tap,
        );
    if (context.mounted) {
      context.showSnack(message ?? l10n.copied);
    }
  } catch (error) {
    if (context.mounted) context.showErrorSnack(error);
  }
}

Future<void> triggerHaptic(
  WidgetRef ref, {
  HapticCue cue = HapticCue.tap,
  VibrationIntensity? intensity,
}) async {
  final AppSettings settings = ref.read(settingsControllerProvider);
  await ref
      .read(hapticsServiceProvider)
      .trigger(intensity ?? settings.vibration, cue: cue);
}
