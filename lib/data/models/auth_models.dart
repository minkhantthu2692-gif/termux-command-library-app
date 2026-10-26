import '../../core/errors/app_exception.dart';

/// Authentication state exposed to the UI. Profile details live separately in
/// [UserProfile]; this object only describes the identity/session.
class AuthSession {
  const AuthSession({
    required this.uid,
    required this.isAnonymous,
    required this.isAdmin,
    required this.isLocalOnly,
    this.email,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
  final bool isAdmin;

  /// True when Firebase is unavailable and the session exists only on-device.
  final bool isLocalOnly;

  bool get isRegistered => !isAnonymous;
  bool get canPublish => isRegistered;

  String get roleLabelKey {
    if (isAdmin) return 'admin';
    if (isRegistered) return 'member';
    return 'guest';
  }

  AuthSession copyWith({
    String? uid,
    String? email,
    bool? isAnonymous,
    bool? isAdmin,
    bool? isLocalOnly,
  }) => AuthSession(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    isAnonymous: isAnonymous ?? this.isAnonymous,
    isAdmin: isAdmin ?? this.isAdmin,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.uid == uid &&
      other.email == email &&
      other.isAnonymous == isAnonymous &&
      other.isAdmin == isAdmin &&
      other.isLocalOnly == isLocalOnly;

  @override
  int get hashCode =>
      Object.hash(uid, email, isAnonymous, isAdmin, isLocalOnly);
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
