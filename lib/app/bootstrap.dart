import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/settings/app_settings.dart';
import '../data/local/database/app_database.dart';
import '../data/remote/cloud_gateways.dart';
import '../data/remote/firebase_auth_gateway.dart';
import '../data/remote/firebase_bootstrap.dart';
import '../data/remote/firestore_cloud_store.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/seed_service.dart';

/// Objects created once before the widget tree starts. Every provider reads
/// from this immutable dependency bundle, which keeps test overrides simple.
class AppDependencies {
  const AppDependencies({
    required this.database,
    required this.initialSettings,
    required this.firebase,
    required this.authGateway,
    required this.cloudStore,
  });

  final AppDatabase database;
  final AppSettings initialSettings;
  final FirebaseRuntime firebase;
  final AuthGateway? authGateway;
  final CloudStore? cloudStore;

  bool get cloudConfigured => authGateway != null && cloudStore != null;
}

class AppBootstrap {
  static Future<AppDependencies> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final database = AppDatabase();
    final settingsRepository = SettingsRepository(database.settingsDao);
    final initialSettings = await settingsRepository.initialize();

    final runtime = await FirebaseBootstrap.initialize();
    AuthGateway? authGateway;
    CloudStore? cloudStore;
    if (runtime.isReady) {
      try {
        authGateway = FirebaseAuthGateway(FirebaseAuth.instance);
        cloudStore = FirestoreCloudStore(FirebaseFirestore.instance);
      } catch (error) {
        debugPrint('Cloud services unavailable. Continuing locally.');
      }
    }

    final seedService = SeedService(
      commandDao: database.commandDao,
      syncDao: database.syncDao,
      loadAsset: () => rootBundle.loadString('assets/data/seed_commands.json'),
    );
    try {
      await seedService.ensureSeeded();
    } catch (error) {
      // A seed failure must not prevent access to previously cached data.
      debugPrint('Offline starter library could not be installed.');
    }

    return AppDependencies(
      database: database,
      initialSettings: initialSettings,
      firebase: runtime,
      authGateway: authGateway,
      cloudStore: cloudStore,
    );
  }
}
