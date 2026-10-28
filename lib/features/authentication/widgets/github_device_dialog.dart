import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../shared/utils/error_messages.dart';
import 'auth_scaffold.dart';

/// Starts the GitHub device flow and shows its code dialog.
///
/// Returns the authenticated session, or null when the user cancels. Starting
/// failures are handled inside the dialog so the user can retry without
/// leaving the sign-in screen. Set [linkExistingAccount] to connect GitHub to
/// the signed-in registered account instead of signing in.
Future<AuthSession?> showGithubDeviceSignInDialog(
  BuildContext context,
  WidgetRef ref, {
  bool linkAnonymous = false,
  bool linkExistingAccount = false,
}) {
  assert(!(linkAnonymous && linkExistingAccount));
  final repository = ref.read(authRepositoryProvider);
  final start = linkExistingAccount
      ? repository.startGithubAccountLink
      : () => repository.startGithubDeviceSignIn(linkAnonymous: linkAnonymous);
  return showDialog<AuthSession>(
    context: context,
    barrierDismissible: false,
    builder: (_) => GithubDeviceDialog(
      start: start,
      onCopyCode: (code) => ref.read(clipboardServiceProvider).copy(code),
      onOpenUri: _openGithubDevicePage,
    ),
  );
}

Future<bool> _openGithubDevicePage(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Device-flow code dialog shared by sign-in and account linking.
///
/// It never receives the OAuth device code or access token: only the short user
/// code and the GitHub verification URL reach this widget.
class GithubDeviceDialog extends StatefulWidget {
  const GithubDeviceDialog({
    super.key,
    required this.start,
    required this.onCopyCode,
    required this.onOpenUri,
  });

  /// Requests a fresh code. Called again when the user taps Try again.
  final Future<GithubDeviceSignIn> Function() start;

  final Future<void> Function(String code) onCopyCode;
  final Future<bool> Function(Uri uri) onOpenUri;

  @override
  State<GithubDeviceDialog> createState() => _GithubDeviceDialogState();
}

class _GithubDeviceDialogState extends State<GithubDeviceDialog> {
  GithubDeviceSignIn? _challenge;
  String? _error;
  AppErrorCode? _errorCode;
  bool _starting = true;
  bool _failed = false;
  bool _cancelled = false;
  bool _finished = false;
  bool _copied = false;
  bool _autoOpened = false;
  bool _openFailed = false;
  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    if (!_finished) {
      _cancelled = true;
      _challenge?.cancel();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final previous = _challenge;
    _challenge = null;
    previous?.cancel();
    setState(() {
      _starting = true;
      _failed = false;
      _error = null;
      _errorCode = null;
      _copied = false;
      _autoOpened = false;
      _openFailed = false;
    });

    try {
      final challenge = await widget.start();
      if (!mounted || _cancelled) {
        challenge.cancel();
        return;
      }
      setState(() {
        _challenge = challenge;
        _starting = false;
      });
      _maybeOpenBrowser();
      await _awaitResult(challenge);
    } on AppException catch (error) {
      _showError(error);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _awaitResult(GithubDeviceSignIn challenge) async {
    try {
      final session = await challenge.result;
      if (!mounted || _cancelled) return;
      _finished = true;
      Navigator.of(context).pop(session);
    } on AppException catch (error) {
      _showError(error);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted || _cancelled) return;
    setState(() {
      _starting = false;
      _failed = true;
      _errorCode = error is AppException ? error.code : AppErrorCode.unknown;
      _error = localizeError(AppLocalizations.of(context), error);
    });
  }

  /// Account-model conflicts cannot be fixed by requesting another device code.
  bool get _canRetry => switch (_errorCode) {
    AppErrorCode.authProviderAccountExists ||
    AppErrorCode.authProviderAlreadyLinked ||
    AppErrorCode.authProviderLinkedElsewhere => false,
    _ => true,
  };

  void _maybeOpenBrowser() {
    final challenge = _challenge;
    if (_autoOpened || challenge == null) return;
    _autoOpened = true;
    unawaited(_openBrowser(challenge.verificationUri));
  }

  Future<void> _openBrowser(Uri uri) async {
    final opened = await widget.onOpenUri(uri);
    if (!mounted || opened) return;
    setState(() => _openFailed = true);
  }

  Future<void> _copyCode() async {
    final challenge = _challenge;
    if (challenge == null) return;
    await widget.onCopyCode(challenge.userCode);
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _cancel() {
    _cancelled = true;
    _challenge?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final challenge = _challenge;
    // A terminal account-model conflict cannot succeed with a new device code,
    // so only offer Cancel and hide the browser hint.
    final canRetry = _canRetry;
    return AlertDialog(
      title: Text(l10n.githubDeviceTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_starting) _StartingBody(label: l10n.githubDeviceStarting),
              if (!_starting && challenge != null && !_failed) ...[
                Text(
                  l10n.githubDeviceInstructions,
                  style: context.texts.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.x4),
                _CodeCard(
                  label: l10n.githubDeviceCodeLabel,
                  code: challenge.userCode,
                  copied: _copied,
                  copyTooltip: _copied
                      ? l10n.githubDeviceCopied
                      : l10n.githubDeviceCopyCode,
                  onCopy: _copyCode,
                ),
                const SizedBox(height: AppSpacing.x3),
                FilledButton.icon(
                  onPressed: () =>
                      unawaited(_openBrowser(challenge.verificationUri)),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.githubDeviceOpen),
                ),
                if (_openFailed) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    l10n.githubDeviceOpenFailed,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
                Row(
                  children: [
                    const SizedBox(
                      width: AppIconSizes.sm,
                      height: AppIconSizes.sm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.x3),
                    Expanded(
                      child: Text(
                        l10n.githubDeviceWaiting,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_failed) ...[
                AuthErrorBanner(message: _error ?? l10n.errorUnknown),
                if (canRetry) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    l10n.githubDeviceOpenManually,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text(l10n.cancel)),
        if (_failed && canRetry)
          FilledButton(onPressed: _start, child: Text(l10n.tryAgain)),
      ],
    );
  }
}

class _StartingBody extends StatelessWidget {
  const _StartingBody({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: AppIconSizes.sm,
          height: AppIconSizes.sm,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(child: Text(label, style: context.texts.bodyMedium)),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.label,
    required this.code,
    required this.copied,
    required this.copyTooltip,
    required this.onCopy,
  });

  final String label;
  final String code;
  final bool copied;
  final String copyTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.medium,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.texts.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                SelectableText(
                  code,
                  style: context.texts.headlineSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: copyTooltip,
            onPressed: onCopy,
            icon: Icon(
              copied ? Icons.check_rounded : Icons.copy_rounded,
              color: copied ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
