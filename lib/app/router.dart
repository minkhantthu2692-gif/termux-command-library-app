import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_assistant/ai_history_screen.dart';
import '../features/ai_assistant/assistant_chat_screen.dart';
import '../features/ai_assistant/assistant_screen.dart';
import '../features/authentication/register_screen.dart';
import '../features/authentication/reset_password_screen.dart';
import '../features/authentication/sign_in_screen.dart';
import '../features/command_details/command_details_screen.dart';
import '../features/command_library/library_screen.dart';
import '../features/docs/docs_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/change_password_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/account_settings_screen.dart';
import '../features/settings/ai_settings_screen.dart';
import '../features/settings/appearance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/termux/termux_guide_screen.dart';
import '../features/upload/command_editor_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../shared/widgets/app_page.dart';
import '../shared/widgets/section_header.dart';
import 'app_shell.dart';
import 'localization/generated/app_localizations.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _assistantNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'assistant',
);
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// The route graph. All screens live behind `/` destinations so the four-tab
/// shell keeps an independent stack per tab, while detail/auth screens use the
/// root navigator and therefore cover the navigation bar.
final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsControllerProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: settings.onboardingCompleted ? '/home' : '/welcome',
    redirect: (context, state) {
      final onboardingComplete = ref
          .read(settingsControllerProvider)
          .onboardingCompleted;
      if (onboardingComplete) return null;

      final location = state.matchedLocation;
      final exempt =
          location == '/welcome' ||
          location.startsWith('/auth/') ||
          location == '/docs';
      return exempt ? null : '/welcome';
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        name: 'sign-in',
        builder: (context, state) =>
            SignInScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) =>
            RegisterScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: '/auth/reset',
        name: 'reset-password',
        builder: (context, state) => ResetPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/assistant/chat',
        name: 'assistant-chat',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return AssistantChatScreen(
            conversationId: query['conversation'],
            commandId: query['command'],
            initialPrompt: query['prompt'],
          );
        },
      ),
      GoRoute(
        path: '/ai/history',
        name: 'ai-history',
        builder: (context, state) => const AiHistoryScreen(),
      ),
      GoRoute(
        path: '/command/:id/edit',
        name: 'command-edit',
        builder: (context, state) =>
            CommandEditorScreen(commandId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/command/:id',
        name: 'command-details',
        builder: (context, state) =>
            CommandDetailsScreen(commandId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/upload',
        name: 'upload',
        builder: (context, state) => const CommandEditorScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        name: 'account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        name: 'appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/settings/ai',
        name: 'ai-settings',
        builder: (context, state) => const AiSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/termux-guide',
        name: 'termux-guide',
        builder: (context, state) => const TermuxGuideScreen(),
      ),
      GoRoute(
        path: '/docs',
        name: 'docs',
        builder: (context, state) => const DocsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                name: 'library',
                pageBuilder: (context, state) {
                  final query = state.uri.queryParameters;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: LibraryScreen(
                      initialTab: query['tab'],
                      initialCategoryId: query['category'],
                      focusSearch: query['focus'] == '1',
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _assistantNavigatorKey,
            routes: [
              GoRoute(
                path: '/assistant',
                name: 'assistant',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AssistantScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _RouteErrorScreen(),
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Shown for malformed links rather than a blank screen. It deliberately offers
/// only an in-app destination so it cannot be used as an open redirect.
class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n.somethingWentWrong,
      scrollable: false,
      child: EmptyState(
        icon: Icons.explore_off_outlined,
        title: l10n.somethingWentWrong,
        body: l10n.errorNotFound,
        actionLabel: l10n.navHome,
        onAction: () => context.go('/home'),
      ),
    );
  }
}
