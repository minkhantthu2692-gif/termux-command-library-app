import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/command_category.dart';
import '../../../data/models/command_post.dart';
import '../../../data/models/command_query.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/haptics_service.dart';
import '../../../shared/utils/category_visual.dart';
import '../../../shared/utils/ui_actions.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/command_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/sync_status_badge.dart';

enum LibraryTab { all, favorites, pinned, mine }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({
    super.key,
    this.initialTab,
    this.initialCategoryId,
    this.focusSearch = false,
  });

  final String? initialTab;
  final String? initialCategoryId;
  final bool focusSearch;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _search = '';
  LibraryTab _tab = LibraryTab.all;
  String? _categoryId;
  CommandSort _sort = CommandSort.recentlyUpdated;
  bool _includeDrafts = true;
  int _limit = AppConstants.pageSize;

  @override
  void initState() {
    super.initState();
    _applyRouteParameters();
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab ||
        oldWidget.initialCategoryId != widget.initialCategoryId ||
        oldWidget.focusSearch != widget.focusSearch) {
      setState(_applyRouteParameters);
      if (widget.focusSearch) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _searchFocus.requestFocus();
        });
      }
    }
  }

  void _applyRouteParameters() {
    _tab = switch (widget.initialTab) {
      'favorites' => LibraryTab.favorites,
      'pinned' => LibraryTab.pinned,
      'mine' => LibraryTab.mine,
      _ => LibraryTab.all,
    };
    _categoryId = CommandCategories.isValid(widget.initialCategoryId ?? '')
        ? widget.initialCategoryId
        : null;
    _limit = AppConstants.pageSize;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  CommandListQuery _queryFor(AuthSession session) {
    return CommandListQuery(
      search: _search,
      categoryId: _categoryId,
      sort: _sort,
      favoritesOnly: _tab == LibraryTab.favorites,
      pinnedOnly: _tab == LibraryTab.pinned,
      authorUid: _tab == LibraryTab.mine ? session.uid : null,
      includeDrafts: _tab == LibraryTab.mine && _includeDrafts,
      limit: _limit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(currentSessionProvider);
    final preferences =
        ref.watch(preferencesProvider).value ?? const UserPreferences();
    final pinnedAll = ref.watch(pinnedCommandsProvider).value ?? const [];
    final query = _queryFor(session);
    final async = _tab == LibraryTab.pinned
        ? null
        : ref.watch(commandsProvider(query));

    final pinnedFiltered = _tab == LibraryTab.pinned
        ? pinnedAll
              .where((command) {
                if (_categoryId != null && command.categoryId != _categoryId) {
                  return false;
                }
                final search = _search.trim().toLowerCase();
                if (search.isEmpty) return true;
                final haystack =
                    '${command.name} ${command.description} ${command.tags.join(' ')} ${command.categoryId}'
                        .toLowerCase();
                return haystack.contains(search);
              })
              .toList(growable: false)
        : const <CommandSummary>[];

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x4,
                AppSpacing.x5,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _LibraryHeader(
                  onRefresh: () => _refresh(context),
                  onHistory: () => context.push('/ai/history'),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x4,
              AppSpacing.x5,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    autofocus: widget.focusSearch,
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  _TabStrip(
                    selected: _tab,
                    showMine: session.canPublish,
                    onSelected: (tab) {
                      unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                      setState(() {
                        _tab = tab;
                        _limit = AppConstants.pageSize;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _FilterBar(
                    categoryId: _categoryId,
                    sort: _sort,
                    tab: _tab,
                    includeDrafts: _includeDrafts,
                    hasSearch: _search.trim().isNotEmpty,
                    onCategory: _pickCategory,
                    onSort: _pickSort,
                    onDrafts: () {
                      unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
                      setState(() => _includeDrafts = !_includeDrafts);
                    },
                    onClear: _clearFilters,
                  ),
                  if (_search.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      l10n.searchResultsFor(_search.trim()),
                      style: context.texts.labelSmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x3),
                ],
              ),
            ),
          ),
          if (_tab == LibraryTab.pinned)
            ..._buildPinnedSlivers(
              context,
              pinnedFiltered,
              preferences,
              session,
            )
          else
            ...async!.when(
              data: (commands) =>
                  _buildCommandSlivers(context, commands, preferences, session),
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingState(),
                ),
              ],
              error: (error, stack) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: l10n.errorDatabase,
                    onRetry: () => ref.invalidate(commandsProvider(query)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPinnedSlivers(
    BuildContext context,
    List<CommandSummary> commands,
    UserPreferences preferences,
    AuthSession session,
  ) {
    final l10n = AppLocalizations.of(context);
    if (commands.isEmpty) {
      final searching = _search.trim().isNotEmpty || _categoryId != null;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.push_pin_outlined,
            title: l10n.emptyPinsTitle,
            body: searching ? l10n.noCommandsBody : l10n.emptyPinsBody,
            actionLabel: searching ? l10n.clearFilters : l10n.browseLibrary,
            onAction: searching
                ? _clearFilters
                : () => setState(() {
                    _tab = LibraryTab.all;
                    _categoryId = null;
                    _searchController.clear();
                    _search = '';
                  }),
          ),
        ),
      ];
    }
    return _buildCommandSlivers(
      context,
      commands,
      preferences,
      session,
      showLoadMore: false,
      preservePinOrder: true,
    );
  }

  List<Widget> _buildCommandSlivers(
    BuildContext context,
    List<CommandSummary> commands,
    UserPreferences preferences,
    AuthSession session, {
    bool showLoadMore = true,
    bool preservePinOrder = false,
  }) {
    final l10n = AppLocalizations.of(context);
    if (commands.isEmpty) {
      final searching = _search.trim().isNotEmpty || _categoryId != null;
      final (icon, title, body) = switch (_tab) {
        LibraryTab.favorites => (
          Icons.bookmark_border_rounded,
          l10n.emptyFavoritesTitle,
          l10n.emptyFavoritesBody,
        ),
        LibraryTab.mine => (
          Icons.description_outlined,
          l10n.emptyMineTitle,
          l10n.emptyMineBody,
        ),
        LibraryTab.pinned => (
          Icons.push_pin_outlined,
          l10n.emptyPinsTitle,
          l10n.emptyPinsBody,
        ),
        LibraryTab.all => (
          Icons.menu_book_outlined,
          l10n.noCommandsTitle,
          searching ? l10n.noCommandsBody : l10n.searchCommands,
        ),
      };
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: icon,
            title: title,
            body: searching ? l10n.noCommandsBody : body,
            actionLabel: searching ? l10n.clearFilters : null,
            onAction: searching ? _clearFilters : null,
          ),
        ),
      ];
    }

    final hasMore = showLoadMore && commands.length >= _limit;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          0,
          AppSpacing.x5,
          AppSpacing.x4,
        ),
        sliver: SliverList.builder(
          itemCount: commands.length,
          itemBuilder: (context, index) {
            final command = commands[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == commands.length - 1 && !hasMore
                    ? 0
                    : AppSpacing.x2 + 2,
              ),
              child: CommandCard(
                command: command,
                preferences: preferences,
                onTap: () => context.push('/command/${command.id}'),
                onFavorite: () =>
                    _toggleFavorite(context, session, preferences, command),
                onPin: () => _togglePin(context, session, preferences, command),
                showAuthor: _tab == LibraryTab.all,
              ),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x6),
          child: Center(
            child: hasMore
                ? OutlinedButton.icon(
                    onPressed: () => setState(
                      () => _limit = (_limit + AppConstants.pageSize).clamp(
                        1,
                        AppConstants.maxPageSize,
                      ),
                    ),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(l10n.loadMore),
                  )
                : Text(
                    l10n.endOfResults,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x8)),
    ];
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.localSearchDebounce, () {
      if (!mounted) return;
      setState(() {
        _search = value;
        _limit = AppConstants.pageSize;
      });
    });
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategorySheet(selectedId: _categoryId),
    );
    if (selected == null || !mounted) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    setState(() {
      _categoryId = selected == _allCategoriesValue ? null : selected;
      _limit = AppConstants.pageSize;
    });
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<CommandSort>(
      context: context,
      builder: (context) => _SortSheet(selected: _sort),
    );
    if (selected == null || !mounted) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    setState(() {
      _sort = selected;
      _limit = AppConstants.pageSize;
    });
  }

  void _clearFilters() {
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    setState(() {
      _searchController.clear();
      _search = '';
      _categoryId = null;
      _sort = CommandSort.recentlyUpdated;
      _includeDrafts = true;
      _limit = AppConstants.pageSize;
    });
  }

  Future<void> _refresh(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final deps = ref.read(appDependenciesProvider);
    if (!deps.cloudConfigured) {
      context.showSnack(l10n.localOnly);
      return;
    }
    try {
      await ref.read(syncCoordinatorProvider).refresh();
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      if (context.mounted) context.showSnack(l10n.refreshed);
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    AuthSession session,
    UserPreferences preferences,
    CommandSummary command,
  ) async {
    final l10n = AppLocalizations.of(context);
    final next = !preferences.isFavorite(command.id);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setFavorite(session: session, commandId: command.id, favorite: next);
      if (context.mounted) {
        context.showSnack(next ? l10n.favoritedSnack : l10n.unfavoritedSnack);
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }

  Future<void> _togglePin(
    BuildContext context,
    AuthSession session,
    UserPreferences preferences,
    CommandSummary command,
  ) async {
    final l10n = AppLocalizations.of(context);
    final next = !preferences.isPinned(command.id);
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    try {
      await ref
          .read(commandRepositoryProvider)
          .setPinned(session: session, commandId: command.id, pinned: next);
      if (context.mounted) {
        context.showSnack(next ? l10n.pinnedSnack : l10n.unpinnedSnack);
      }
    } catch (error) {
      if (context.mounted) context.showErrorSnack(error);
    }
  }
}

const _allCategoriesValue = '__all__';

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.onRefresh, required this.onHistory});

  final VoidCallback onRefresh;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.communityLibrary, style: context.texts.headlineSmall),
              const SizedBox(height: AppSpacing.x1),
              Text(
                l10n.librarySubtitle,
                style: context.texts.bodySmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: AppSizes.minTapTarget,
          child: Center(child: SyncStatusBadge(compact: true, iconSize: 24)),
        ),
        IconButton(
          tooltip: l10n.refresh,
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.selected,
    required this.showMine,
    required this.onSelected,
  });

  final LibraryTab selected;
  final bool showMine;
  final ValueChanged<LibraryTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (LibraryTab.all, l10n.allCommands, Icons.apps_rounded),
      (LibraryTab.favorites, l10n.favorites, Icons.bookmark_rounded),
      (LibraryTab.pinned, l10n.pinned, Icons.push_pin_rounded),
      if (showMine) (LibraryTab.mine, l10n.myPosts, Icons.description_outlined),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x2),
        itemBuilder: (context, index) {
          final (tab, label, icon) = entries[index];
          final active = tab == selected;
          return ChoiceChip(
            showCheckmark: false,
            selected: active,
            onSelected: (_) => onSelected(tab),
            avatar: Icon(
              icon,
              size: AppIconSizes.xs,
              color: active
                  ? context.scheme.onPrimaryContainer
                  : context.scheme.onSurfaceVariant,
            ),
            label: Text(label),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categoryId,
    required this.sort,
    required this.tab,
    required this.includeDrafts,
    required this.hasSearch,
    required this.onCategory,
    required this.onSort,
    required this.onDrafts,
    required this.onClear,
  });

  final String? categoryId;
  final CommandSort sort;
  final LibraryTab tab;
  final bool includeDrafts;
  final bool hasSearch;
  final VoidCallback onCategory;
  final VoidCallback onSort;
  final VoidCallback onDrafts;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active =
        categoryId != null || sort != CommandSort.recentlyUpdated || hasSearch;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            icon: Icons.category_outlined,
            label: categoryId == null
                ? l10n.allCategories
                : categoryLabel(l10n, categoryId),
            active: categoryId != null,
            onTap: onCategory,
          ),
          const SizedBox(width: AppSpacing.x2),
          _FilterChip(
            icon: Icons.swap_vert_rounded,
            label: l10n.sort,
            active: sort != CommandSort.recentlyUpdated,
            onTap: onSort,
          ),
          if (tab == LibraryTab.mine) ...[
            const SizedBox(width: AppSpacing.x2),
            _FilterChip(
              icon: Icons.edit_note_rounded,
              label: l10n.drafts,
              active: includeDrafts,
              onTap: onDrafts,
            ),
          ],
          if (active) ...[
            const SizedBox(width: AppSpacing.x2),
            _FilterChip(
              icon: Icons.close_rounded,
              label: l10n.clearFilters,
              onTap: onClear,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        icon,
        size: AppIconSizes.xs,
        color: active ? scheme.primary : scheme.onSurfaceVariant,
      ),
      label: Text(label),
      backgroundColor: active
          ? scheme.primary.withValues(alpha: 0.09)
          : context.appColors.card,
      side: BorderSide(
        color: active
            ? scheme.primary.withValues(alpha: 0.22)
            : scheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.category, style: context.texts.titleMedium),
              trailing: IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.apps_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(l10n.allCategories),
                    selected: selectedId == null,
                    selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                    onTap: () => Navigator.of(context).pop(_allCategoriesValue),
                  ),
                  for (final category in CommandCategories.all)
                    ListTile(
                      leading: Icon(
                        CategoryVisual.of(category.id).icon,
                        color: CategoryVisual.of(category.id).color,
                      ),
                      title: Text(categoryLabel(l10n, category.id)),
                      selected: selectedId == category.id,
                      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
                      onTap: () => Navigator.of(context).pop(category.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final CommandSort selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (CommandSort.recentlyUpdated, l10n.sortRecentlyUpdated),
      (CommandSort.newest, l10n.sortNewest),
      (CommandSort.nameAscending, l10n.sortNameAsc),
      (CommandSort.mostSteps, l10n.sortMostSteps),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.sort, style: context.texts.titleMedium),
              trailing: IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            RadioGroup<CommandSort>(
              groupValue: selected,
              onChanged: (next) {
                if (next != null) Navigator.of(context).pop(next);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (value, label) in entries)
                    RadioListTile<CommandSort>(
                      value: value,
                      title: Text(label),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
