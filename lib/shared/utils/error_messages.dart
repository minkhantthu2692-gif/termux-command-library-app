import '../../app/localization/generated/app_localizations.dart';
import '../../core/errors/app_exception.dart';

/// Maps stable repository error codes to actionable, localized messages. Raw
/// exception strings are deliberately never shown to users.
String localizeError(AppLocalizations l10n, Object error) {
  final exception = error is AppException ? error : null;
  final code = exception?.code ?? AppErrorCode.unknown;
  return switch (code) {
    AppErrorCode.network => l10n.errorNetwork,
    AppErrorCode.timeout => l10n.errorTimeout,
    AppErrorCode.authRequired => l10n.errorAuthRequired,
    AppErrorCode.authInvalidCredentials => l10n.errorInvalidCredentials,
    AppErrorCode.authEmailInUse => l10n.errorEmailInUse,
    AppErrorCode.authWeakPassword => l10n.errorWeakPassword,
    AppErrorCode.authTooManyRequests => l10n.errorTooManyRequests,
    AppErrorCode.authRecentLoginRequired => l10n.errorRecentLogin,
    AppErrorCode.authCancelled => l10n.errorAuthCancelled,
    AppErrorCode.authProviderUnavailable => l10n.errorAuthProviderUnavailable,
    AppErrorCode.authAccountDeleted => l10n.errorAuthRequired,
    AppErrorCode.permissionDenied => l10n.errorPermissionDenied,
    AppErrorCode.firebaseUnavailable => l10n.errorFirebaseUnavailable,
    AppErrorCode.firebaseNotConfigured => l10n.errorFirebaseNotConfigured,
    AppErrorCode.validation => l10n.errorValidation,
    AppErrorCode.notFound => l10n.errorNotFound,
    AppErrorCode.database => l10n.errorDatabase,
    AppErrorCode.conflict => l10n.errorConflict,
    AppErrorCode.limitReached => l10n.errorLimitReached,
    AppErrorCode.aiDisabled => l10n.errorAiDisabled,
    AppErrorCode.aiKeyMissing => l10n.errorAiKeyMissing,
    AppErrorCode.aiInvalidKey => l10n.errorAiInvalidKey,
    AppErrorCode.aiRateLimited => l10n.errorAiRateLimited,
    AppErrorCode.aiProviderUnavailable => l10n.errorAiProviderUnavailable,
    AppErrorCode.aiModelUnavailable => l10n.errorAiModelUnavailable,
    AppErrorCode.aiRequestTooLarge => l10n.errorAiRequestTooLarge,
    AppErrorCode.aiEmptyResponse => l10n.errorAiEmptyResponse,
    AppErrorCode.aiCancelled => l10n.errorAiCancelled,
    AppErrorCode.attachmentTooLarge => l10n.attachmentTooLarge,
    AppErrorCode.attachmentUnsupported => l10n.attachmentUnsupported,
    AppErrorCode.attachmentReadFailed => l10n.attachmentReadFailed,
    AppErrorCode.termuxMissing => l10n.errorTermuxMissing,
    AppErrorCode.termuxPermissionMissing => l10n.errorTermuxPermission,
    AppErrorCode.termuxExternalAppsDisabled => l10n.errorTermuxExternalApps,
    AppErrorCode.termuxError => l10n.errorTermux,
    AppErrorCode.unsupported => l10n.errorUnsupported,
    AppErrorCode.unknown => l10n.errorUnknown,
  };
}

/// Validation messages use short stable keys from [Validators]. This keeps the
/// validators free of BuildContext and localization dependencies.
String? localizeValidation(AppLocalizations l10n, String? key) {
  return switch (key) {
    null => null,
    'required' => l10n.validationRequired,
    'tooShort' => l10n.validationTooShort,
    'tooLong' => l10n.validationTooLong,
    'invalid' => l10n.validationInvalid,
    _ => l10n.validationInvalid,
  };
}
