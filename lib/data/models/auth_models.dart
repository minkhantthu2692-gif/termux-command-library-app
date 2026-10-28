import '../../core/errors/app_exception.dart';

/// External identity providers offered by the authentication screens. The data
/// layer maps these to concrete Firebase providers so feature UI never imports
/// Firebase Auth.
enum AuthProviderKind { google, github }

/// Stable Firebase provider IDs exposed through [AuthSession.linkedProviders].
abstract final class AuthProviderIds {
  static const password = 'password';
  static const google = 'google.com';
  static const github = 'github.com';
}

/// Authentication state exposed to the UI. Profile details live separately in
/// [UserProfile]; this object only describes the identity/session.
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.isAnonymous,
    required this.isAdmin,
    required this.isLocalOnly,
    this.email,
    this.displayName,
    this.linkedProviders = const {},
  });

  final String uid;
  final String? email;

  /// Name supplied by the identity provider, when available. Used only as a
  /// fallback when creating the local profile; the editable nickname lives in
  /// the profile document.
  final String? displayName;
  final bool isAnonymous;
  final bool isAdmin;

  /// True when Firebase is unavailable and the session exists only on-device.
  final bool isLocalOnly;

  /// Firebase provider IDs linked to this account, such as `password`,
  /// `google.com` or `github.com`. Local-only sessions have no providers.
  final Set<String> linkedProviders;

  bool get isRegistered => !isAnonymous;
  bool get canPublish => isRegistered;
  bool get hasGithub => linkedProviders.contains(AuthProviderIds.github);

  String get roleLabelKey {
    if (isAdmin) return 'admin';
    if (isRegistered) return 'member';
    return 'guest';
  }

  AuthSession copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAnonymous,
    bool? isAdmin,
    bool? isLocalOnly,
    Set<String>? linkedProviders,
  }) => AuthSession(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    isAdmin: isAdmin ?? this.isAdmin,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    linkedProviders: linkedProviders ?? this.linkedProviders,
  );

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.isAnonymous == isAnonymous &&
      other.isAdmin == isAdmin &&
      other.isLocalOnly == isLocalOnly &&
      _sameProviders(other.linkedProviders, linkedProviders);

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    displayName,
    isAnonymous,
    isAdmin,
    isLocalOnly,
    Object.hashAllUnordered(linkedProviders),
  );
}

bool _sameProviders(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

/// A GitHub device-flow challenge that is ready to show in the UI.
///
/// [userCode] and [verificationUri] are safe to display. [result] completes
/// once GitHub authorizes the app and Firebase accepts the token. [cancel]
/// stops polling and is safe to call after completion.
class GithubDeviceSignIn {
  const GithubDeviceSignIn({
    required this.userCode,
    required this.verificationUri,
    required this.expiresAt,
    required this.result,
    required this.cancel,
  });

  final String userCode;
  final Uri verificationUri;
  final DateTime expiresAt;
  final Future<AuthSession> result;
  final void Function() cancel;
}

enum CloudAvailability { disabled, initializing, ready, unavailable }

class CloudStatus {
  const CloudStatus({required this.availability, this.projectId, this.error});

  final CloudAvailability availability;
  final String? projectId;
  final AppException? error;

  bool get isConfigured => availability != CloudAvailability.disabled;
  bool get isReady => availability == CloudAvailability.ready;

  static const disabled = CloudStatus(availability: CloudAvailability.disabled);
}

enum SyncPhase { localOnly, idle, syncing, success, error }

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.pendingOperations = 0,
    this.lastSyncedAt,
    this.error,
  });

  final SyncPhase phase;
  final int pendingOperations;
  final DateTime? lastSyncedAt;
  final AppException? error;

  bool get isBusy => phase == SyncPhase.syncing;
  bool get isRemote => phase != SyncPhase.localOnly;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingOperations,
    DateTime? lastSyncedAt,
    AppException? error,
    bool clearError = false,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    pendingOperations: pendingOperations ?? this.pendingOperations,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    error: clearError ? null : (error ?? this.error),
  );

  static const localOnly = SyncStatus(phase: SyncPhase.localOnly);
  static const idle = SyncStatus(phase: SyncPhase.idle);
}
