import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/app_tokens.dart';
import '../data/services/haptics_service.dart';
import '../shared/utils/ui_actions.dart';
import '../shared/widgets/glass_surface.dart';
import 'localization/generated/app_localizations.dart';

/// Persistent four-destination shell. Each branch keeps its own navigation
/// stack, so browsing a guide and returning to the library preserves filters.
///
/// Switching tabs is not added to the root navigator stack, so Android back
/// would normally leave the app. The shell keeps a small per-session history of
/// visited tabs and walks back through it first; back only leaves the app when
/// the user is already on the first tab in that history.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Previously visited branch indexes, most recent last.
  final List<int> _tabHistory = <int>[];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recordExternalChange(widget.navigationShell.currentIndex);
  }

  /// Records a branch change that did not originate from a bottom-nav tap, for
  /// example a Quick Action using `context.go('/library')`.
  void _recordExternalChange(int index) {
    if (index == _currentIndex) return;
    _tabHistory.add(_currentIndex);
    _currentIndex = index;
  }

  void _selectTab(int index) {
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    if (index == _currentIndex) {
      // Re-selecting the active destination returns that branch to its root,
      // matching the standard bottom-navigation behavior.
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    _tabHistory.add(_currentIndex);
    _currentIndex = index;
    widget.navigationShell.goBranch(index);
    setState(() {});
  }

  void _goBackToPreviousTab() {
    if (_tabHistory.isEmpty) return;
    final previous = _tabHistory.removeLast();
    _currentIndex = previous;
    // Update _currentIndex first so didUpdateWidget does not record this
    // back-navigation as another forward tab change.
    widget.navigationShell.goBranch(previous);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = context.scheme;
    return PopScope(
      // Only consume back once there is a previous tab to return to. At the
      // start of the history the normal Android behavior (leave the app)
      // remains available.
      canPop: _tabHistory.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goBackToPreviousTab();
      },
      child: Scaffold(
        // Let tab content scroll behind the bar so the frosted glass has a
        // backdrop. Tab screens add MediaQuery.padding.bottom (which Scaffold
        // reports as the bar height) to their scroll extent.
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: GlassSurface(
          borderRadius: BorderRadius.zero,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _selectTab,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book_rounded),
                  label: l10n.navLibrary,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  selectedIcon: const Icon(Icons.auto_awesome_rounded),
                  label: l10n.navAssistant,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: l10n.navProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
