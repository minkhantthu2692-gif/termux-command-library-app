import '../models/auth_models.dart';
import '../models/command_post.dart';

/// Contract for authentication. Firebase is the first implementation, but no
/// feature code imports Firebase Auth directly, which keeps a future backend
/// migration contained to the data layer.
abstract interface class AuthGateway {
  AuthSession? get currentSession;

  Stream<AuthSession?> watchSessions();

  Future<AuthSession> signInAnonymously();

  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<AuthSession> signIn({required String email, required String password});

  /// Starts the provider's browser flow and signs in with Google or GitHub.
  ///
  /// When [linkAnonymous] is true and the current user is an anonymous Firebase
  /// account, the provider is linked to that account instead of replacing it,
  /// which preserves favorites, pins and authored guides. Linking fails with a
  /// normal authentication error if the provider account already belongs to
  /// another user; the UI then asks the user to sign in instead.
  Future<AuthSession> signInWithProvider(
    AuthProviderKind provider, {
    bool linkAnonymous = false,
  });

  /// Links an anonymous Firebase account to an email/password credential while
  /// preserving its UID and therefore its favorites, pins and posts.
  Future<AuthSession> linkAnonymousAccount({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updateDisplayName(String displayName);

  Future<void> sendEmailVerification();

  Future<void> reload();

  Future<void> reauthenticateWithPassword(String password);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  Future<void> deleteAccount();
}

/// Snapshot of the user's cloud profile document. Favorite and pin arrays live
/// in this per-user document, never on shared command documents.
class CloudProfile {
  const CloudProfile({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.avatarId,
    required this.favoriteIds,
    required this.pinnedIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String nickname;
  final String email;
  final String avatarId;
  final Set<String> favoriteIds;

  /// User-defined order is significant and preserved.
  final List<String> pinnedIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// A page fetched from Cloud Firestore. [cursor] is opaque to repositories; it
/// is a Firestore document snapshot for the concrete implementation.
class CloudCommandPage {
  const CloudCommandPage({
    required this.commands,
    required this.hasMore,
    this.cursor,
  });

  final List<CommandPost> commands;
  final bool hasMore;
  final Object? cursor;
}

/// Realtime event for cached public commands. Removed documents are explicit so
/// the local cache can drop them without guessing from a limited query window.
class CloudCommandEvent {
  const CloudCommandEvent({required this.upserts, required this.removedIds});

  final List<CommandPost> upserts;
  final List<String> removedIds;
}

/// Cloud database contract. Implementations must not expose Firebase types to
/// repositories or UI code.
abstract interface class CloudStore {
  Stream<CloudCommandEvent> watchLatestCommands({int limit});

  Stream<CloudProfile?> watchProfile(String uid);

  Future<CloudProfile?> fetchProfile(String uid);

  Future<CloudCommandPage> fetchCommandsPage({int limit, Object? cursor});

  /// Fetches the signed-in user's own documents, including drafts.
  Future<List<CommandPost>> fetchAuthoredCommands(String uid);

  Future<void> saveCommand(CommandPost command);

  Future<void> deleteCommand(String commandId);

  /// Creates or merges the profile document. Arrays are only written when
  /// supplied, so a nickname edit cannot accidentally erase a concurrent pin
  /// change.
  Future<void> saveProfile({
    required String uid,
    String? nickname,
    String? email,
    String? avatarId,
    Set<String>? favoriteIds,
    List<String>? pinnedIds,
    bool createIfMissing = false,
  });

  Future<void> deleteProfile(String uid);
}
