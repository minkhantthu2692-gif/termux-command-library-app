import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/app_tokens.dart';
import 'localization/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. Theme, locale and system chrome are derived from the persisted
/// settings stream so a change in Appearance is reflected without a restart.
class TermuxCommandLibraryApp extends ConsumerStatefulWidget {
  const TermuxCommandLibraryApp({super.key});

  @override
  ConsumerState<TermuxCommandLibraryApp> createState() =>
      _TermuxCommandLibraryAppState();
}

class _TermuxCommandLibraryAppState
    extends ConsumerState<TermuxCommandLibraryApp>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBackgrounded = _lifecycle != AppLifecycleState.resumed;
    _lifecycle = state;
    if (state == AppLifecycleState.resumed && wasBackgrounded) {
      // Returning to the app is a natural sync point. Failures are surfaced by
      // the sync badge; they must not interrupt whatever the user was doing.
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _refreshAfterResume() async {
    try {
      final dependencies = ref.read(appDependenciesProvider);
      if (!dependencies.cloudConfigured) return;
      await ref.read(syncCoordinatorProvider).refresh(showBusy: false);
    } catch (_) {
      // Offline resume is expected; the coordinator already recorded the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(routerProvider);
    // Starts the persistent SQLite -> Firestore synchronization listeners.
    ref.watch(syncBootstrapProvider);

    final light = AppTheme.build(settings, Brightness.light);
    final dark = AppTheme.build(settings, Brightness.dark);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: light,
      darkTheme: dark,
      themeMode: settings.themeMode,
      themeAnimationDuration: AppDurations.medium,
      themeAnimationCurve: Curves.easeOutCubic,
      locale: Locale(settings.effectiveLanguageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        final theme = Theme.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.style(
            brightness: theme.brightness,
            navigationBarColor: theme.scaffoldBackgroundColor,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Keeps Android's status and navigation bars legible in both themes while the
/// app draws edge-to-edge. Pages with an AppBar layer their own status-bar style
/// above this one; the navigation bar always follows the app theme.
abstract final class AppSystemUi {
  static SystemUiOverlayStyle style({
    required Brightness brightness,
    required Color navigationBarColor,
  }) {
    final dark = brightness == Brightness.dark;
    final iconBrightness = dark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      // iOS considers the status-bar background brightness, not the icons.
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
