/// Built-in avatars keep profile images local. Firebase Storage is not used,
/// so no user file ever needs to be uploaded.
abstract final class AppAvatars {
  static const defaultId = 'orbit';

  /// Shown for local-only profiles until the user picks a design. Appended
  /// last so existing avatars keep their color indices.
  static const localOnlyId = 'person';

  static const all = <String>[
    'orbit',
    'sprout',
    'wave',
    'sun',
    'moon',
    'spark',
    'leaf',
    'pixel',
    'person',
  ];

  static bool isValid(String id) => all.contains(id);
  static String normalize(String? id) =>
      id != null && isValid(id) ? id : defaultId;
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    required this.avatarId,
    required this.createdAt,
    required this.updatedAt,
    this.email = '',
    this.isLocalOnly = false,
  });

  final String uid;
  final String nickname;
  final String email;
  final String avatarId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocalOnly;

  String get effectiveNickname => nickname.trim();

  /// The avatar actually rendered for this profile. A local-only profile that
  /// has not picked a design shows the human-figure avatar; an explicit choice
  /// or any registered profile always keeps its own avatar.
  String get displayAvatarId => isLocalOnly && avatarId == AppAvatars.defaultId
      ? AppAvatars.localOnlyId
      : avatarId;

  UserProfile copyWith({
    String? uid,
    String? nickname,
    String? email,
    String? avatarId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocalOnly,
  }) => UserProfile(
    uid: uid ?? this.uid,
    nickname: nickname ?? this.nickname,
    email: email ?? this.email,
    avatarId: avatarId ?? this.avatarId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isLocalOnly: isLocalOnly ?? this.isLocalOnly,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'nickname': nickname,
    'email': email,
    'avatarId': avatarId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'isLocalOnly': isLocalOnly,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return UserProfile(
      uid: json['uid'] as String,
      nickname: (json['nickname'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      avatarId: AppAvatars.normalize(json['avatarId'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      isLocalOnly: (json['isLocalOnly'] as bool?) ?? false,
    );
  }

  factory UserProfile.guest({
    required String uid,
    String nickname = '',
    String avatarId = AppAvatars.defaultId,
  }) {
    final now = DateTime.now().toUtc();
    return UserProfile(
      uid: uid,
      nickname: nickname,
      avatarId: avatarId,
      createdAt: now,
      updatedAt: now,
      isLocalOnly: true,
    );
  }
}

class UserPreferences {
  const UserPreferences({
    this.favoriteIds = const {},
    this.pinnedIds = const [],
  });

  final Set<String> favoriteIds;

  /// Ordered by the user's own pin order. The list index is the position.
  final List<String> pinnedIds;

  bool isFavorite(String commandId) => favoriteIds.contains(commandId);
  bool isPinned(String commandId) => pinnedIds.contains(commandId);

  UserPreferences copyWith({
    Set<String>? favoriteIds,
    List<String>? pinnedIds,
  }) => UserPreferences(
    favoriteIds: favoriteIds ?? this.favoriteIds,
    pinnedIds: pinnedIds ?? this.pinnedIds,
  );

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      _setEquals(favoriteIds, other.favoriteIds) &&
      _listEquals(pinnedIds, other.pinnedIds);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(favoriteIds),
    Object.hashAll(pinnedIds),
  );
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class LibraryStats {
  const LibraryStats({
    this.total = 0,
    this.mine = 0,
    this.favorites = 0,
    this.pins = 0,
  });

  final int total;
  final int mine;
  final int favorites;
  final int pins;

  @override
  bool operator ==(Object other) =>
      other is LibraryStats &&
      total == other.total &&
      mine == other.mine &&
      favorites == other.favorites &&
      pins == other.pins;

  @override
  int get hashCode => Object.hash(total, mine, favorites, pins);
}

class CategoryCount {
  const CategoryCount({required this.categoryId, required this.count});

  final String categoryId;
  final int count;
}
