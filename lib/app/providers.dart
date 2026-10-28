import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/bootstrap.dart';
import '../../app/settings/app_settings.dart';
import '../../data/local/database/app_database.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/auth_models.dart';
import '../../data/models/command_post.dart';
import '../../data/models/command_query.dart';
import '../../data/models/user_profile.dart';
import '../../data/remote/github_device_client.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/command_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/ai/ai_provider.dart';
import '../../data/services/ai/groq_ai_provider.dart';
import '../../data/services/clipboard_service.dart';
import '../../data/services/file_attachment_service.dart';
import '../../data/services/haptics_service.dart';
import '../../data/services/secure_key_store.dart';
import '../../data/services/sync_coordinator.dart';
import '../../data/services/termux_service.dart';

final appDependenciesProvider = Provider<AppDependencies>((ref) {
  throw StateError(
    'appDependenciesProvider must be overridden by ProviderScope.',
  );
});

final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(appDependenciesProvider).database,
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider).settingsDao),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final dependencies = ref.watch(appDependenciesProvider);
    final repository = ref.watch(settingsRepositoryProvider);
    var disposed = false;
    final subscription = repository.watch().listen(
      (next) {
        if (!disposed) state = next;
      },
      onError: (_) {
        // Keep the last known settings rather than breaking the app shell.
      },
    );
    ref.onDispose(() {
      disposed = true;
      subscription.cancel();
    });
    return dependencies.initialSettings;
  }

  Future<void> save(AppSettings next) async {
    final previous = state;
    state = next;
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } catch (error) {
      state = previous;
      rethrow;
    }
  }

  Future<void> setOnboardingCompleted(bool value) =>
      save(state.copyWith(onboardingCompleted: value));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// -----------------------------------------------------------------------------
// Authentication
// -----------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dependencies = ref.watch(appDependenciesProvider);
  final database = dependencies.database;
  return AuthRepository(
    gateway: dependencies.authGateway,
    cloud: dependencies.cloudStore,
    profileDao: database.profileDao,
    preferenceDao: database.preferenceDao,
    commandDao: database.commandDao,
    syncDao: database.syncDao,
    localGuestUid: dependencies.initialSettings.localGuestUid,
    githubDeviceClient: ref.watch(githubDeviceClientProvider),
  );
});

/// The GitHub device-flow client is only available when Firebase is
/// configured, because the resulting token is exchanged for a Firebase
/// credential. Overridable in tests to avoid real HTTP requests.
final githubDeviceClientProvider = Provider<GithubDeviceClient?>((ref) {
  if (!ref.watch(appDependenciesProvider).cloudConfigured) return null;
  return HttpGithubDeviceClient();
});

final authSessionProvider = StreamProvider<AuthSession>((ref) {
  return ref.watch(authRepositoryProvider).watchSessions();
});

final currentSessionProvider = Provider<AuthSession>((ref) {
  final session = ref.watch(authSessionProvider).value;
  if (session != null) return session;
  return ref.watch(authRepositoryProvider).localGuestSession;
});

final currentUidProvider = Provider<String>(
  (ref) => ref.watch(currentSessionProvider).uid,
);

// -----------------------------------------------------------------------------
// Profile, preferences and commands
// -----------------------------------------------------------------------------

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ProfileRepository(
    profileDao: database.profileDao,
    preferenceDao: database.preferenceDao,
    syncDao: database.syncDao,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

final commandRepositoryProvider = Provider<CommandRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return CommandRepository(
    commandDao: database.commandDao,
    preferenceDao: database.preferenceDao,
    syncDao: database.syncDao,
    cloudConfigured: ref.watch(appDependenciesProvider).cloudConfigured,
  );
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});

final preferencesProvider = StreamProvider<UserPreferences>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(databaseProvider).preferenceDao.watchPreferences(uid);
});

final libraryStatsProvider = StreamProvider<LibraryStats>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(commandRepositoryProvider).watchStats(uid);
});

final pinnedCommandsProvider = StreamProvider<List<CommandSummary>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(commandRepositoryProvider).watchPinned(uid);
});

final categoryCountsProvider = StreamProvider<List<CategoryCount>>((ref) {
  return ref.watch(commandRepositoryProvider).watchCategoryCounts();
});

final commandsProvider =
    StreamProvider.family<List<CommandSummary>, CommandListQuery>((ref, query) {
      final uid = ref.watch(currentUidProvider);
      return ref.watch(commandRepositoryProvider).watchCommands(query, uid);
    });

final commandProvider = StreamProvider.family<CommandPost?, String>((ref, id) {
  return ref.watch(commandRepositoryProvider).watchCommand(id);
});

final cachedCommandCountProvider = FutureProvider<int>((ref) {
  return ref.watch(commandRepositoryProvider).countCommands();
});

// -----------------------------------------------------------------------------
// Sync
// -----------------------------------------------------------------------------

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final database = ref.watch(databaseProvider);
  final coordinator = SyncCoordinator(
    commandDao: database.commandDao,
    preferenceDao: database.preferenceDao,
    profileDao: database.profileDao,
    syncDao: database.syncDao,
    authRepository: ref.watch(authRepositoryProvider),
    cloud: ref.watch(appDependenciesProvider).cloudStore,
  );
  coordinator.start();
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  Stream<SyncStatus> stream() async* {
    yield coordinator.currentStatus;
    yield* coordinator.statusStream;
  }

  return stream();
});

/// Watching this provider early starts the coordinator and its listeners.
final syncBootstrapProvider = Provider<void>((ref) {
  ref.watch(syncCoordinatorProvider);
});

// -----------------------------------------------------------------------------
// AI
// -----------------------------------------------------------------------------

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => SecureApiKeyStore());

final aiProviderProvider = Provider<AiProvider>((ref) {
  final provider = GroqAiProvider();
  ref.onDispose(provider.close);
  return provider;
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(
    provider: ref.watch(aiProviderProvider),
    keyStore: ref.watch(apiKeyStoreProvider),
    dao: ref.watch(databaseProvider).aiDao,
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final aiModelsProvider = StreamProvider<List<AiModelInfo>>((ref) {
  return ref.watch(aiRepositoryProvider).watchModels();
});

/// Whether a provider key exists in secure storage. The key itself is never
/// exposed to widgets; key-entry screens invalidate this provider after a save
/// or removal.
final aiKeyPresentProvider = FutureProvider<bool>((ref) {
  return ref.watch(aiRepositoryProvider).hasApiKey();
});

final aiConversationsProvider =
    StreamProvider.family<List<AiConversation>, String>((ref, search) {
      return ref.watch(aiRepositoryProvider).watchConversations(search: search);
    });

final aiConversationProvider = StreamProvider.family<AiConversation?, String>((
  ref,
  id,
) {
  return ref.watch(aiRepositoryProvider).watchConversation(id);
});

final aiMessagesProvider = StreamProvider.family<List<AiStoredMessage>, String>(
  (ref, conversationId) {
    return ref.watch(aiRepositoryProvider).watchMessages(conversationId);
  },
);

// -----------------------------------------------------------------------------
// Platform services
// -----------------------------------------------------------------------------

final termuxServiceProvider = Provider<TermuxService>(
  (ref) => PlatformTermuxService(),
);

final clipboardServiceProvider = Provider<ClipboardService>(
  (ref) => const ClipboardService(),
);

final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => const HapticsService(),
);

final fileAttachmentServiceProvider = Provider<FileAttachmentService>(
  (ref) => const FileAttachmentService(),
);
