enum CommandSort {
  recentlyUpdated,
  newest,
  nameAscending,
  mostSteps;

  String get labelKey => switch (this) {
    CommandSort.recentlyUpdated => 'sortRecentlyUpdated',
    CommandSort.newest => 'sortNewest',
    CommandSort.nameAscending => 'sortNameAsc',
    CommandSort.mostSteps => 'sortMostSteps',
  };
}

/// Immutable query used by the local SQLite repository. It is also the family
/// argument for Riverpod, therefore equality is meaningful and deliberate.
class CommandListQuery {
  const CommandListQuery({
    this.search = '',
    this.categoryId,
    this.sort = CommandSort.recentlyUpdated,
    this.favoritesOnly = false,
    this.pinnedOnly = false,
    this.authorUid,
    this.limit = 20,
    this.offset = 0,
    this.includeDrafts = false,
  });

  final String search;
  final String? categoryId;
  final CommandSort sort;
  final bool favoritesOnly;
  final bool pinnedOnly;

  /// When set, only commands authored by this UID are returned.
  final String? authorUid;
  final int limit;
  final int offset;

  /// Own drafts are shown in "My posts" when true. Public browsing never
  /// includes drafts.
  final bool includeDrafts;

  CommandListQuery copyWith({
    String? search,
    String? categoryId,
    bool clearCategory = false,
    CommandSort? sort,
    bool? favoritesOnly,
    bool? pinnedOnly,
    String? authorUid,
    bool clearAuthor = false,
    int? limit,
    int? offset,
    bool? includeDrafts,
  }) => CommandListQuery(
    search: search ?? this.search,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    sort: sort ?? this.sort,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    pinnedOnly: pinnedOnly ?? this.pinnedOnly,
    authorUid: clearAuthor ? null : (authorUid ?? this.authorUid),
    limit: limit ?? this.limit,
    offset: offset ?? this.offset,
    includeDrafts: includeDrafts ?? this.includeDrafts,
  );

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      categoryId != null ||
      favoritesOnly ||
      pinnedOnly ||
      authorUid != null;

  @override
  bool operator ==(Object other) =>
      other is CommandListQuery &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.sort == sort &&
      other.favoritesOnly == favoritesOnly &&
      other.pinnedOnly == pinnedOnly &&
      other.authorUid == authorUid &&
      other.limit == limit &&
      other.offset == offset &&
      other.includeDrafts == includeDrafts;

  @override
  int get hashCode => Object.hash(
    search,
    categoryId,
    sort,
    favoritesOnly,
    pinnedOnly,
    authorUid,
    limit,
    offset,
    includeDrafts,
  );
}
