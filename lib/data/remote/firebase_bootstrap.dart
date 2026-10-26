import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

/// Firebase configuration comes from compile-time `--dart-define` values. This
/// keeps the repository free of service-account files and makes local-only
/// builds (including CI and tests) work without Firebase credentials.
class FirebaseConfig {
  const FirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
  });

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseConfig? fromEnvironment() {
    if (!isConfigured) return null;
    return FirebaseConfig(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
    );
  }

  FirebaseOptions toOptions() => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain ?? '$projectId.firebaseapp.com',
    // Firebase Storage is intentionally not used by this app. The option is
    // left unset so no storage client is initialised for Android.
  );
}

enum FirebaseAvailability { disabled, ready, unavailable }

class FirebaseRuntime {
  const FirebaseRuntime({required this.availability, this.config, this.error});

  final FirebaseAvailability availability;
  final FirebaseConfig? config;
  final AppException? error;

  bool get isReady => availability == FirebaseAvailability.ready;
  bool get isConfigured => availability != FirebaseAvailability.disabled;

  String? get projectId => config?.projectId;

  static const disabled = FirebaseRuntime(
    availability: FirebaseAvailability.disabled,
  );
}

/// Initialises Firebase once. A missing or broken configuration degrades to the
/// fully usable local-only mode instead of crashing the application.
abstract final class FirebaseBootstrap {
  static Future<FirebaseRuntime> initialize() async {
    final config = FirebaseConfig.fromEnvironment();
    if (config == null) return FirebaseRuntime.disabled;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: config.toOptions());
      }
      return FirebaseRuntime(
        availability: FirebaseAvailability.ready,
        config: config,
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Firebase initialization failed (${error.code}). '
        'Continuing in local-only mode.',
      );
      return FirebaseRuntime(
        availability: FirebaseAvailability.unavailable,
        config: config,
        error: const AppException(
          AppErrorCode.firebaseUnavailable,
          message: 'Firebase could not be initialised from the build values.',
          retryable: true,
        ),
      );
    } catch (error) {
      debugPrint(
        'Firebase initialization failed. Continuing in local-only mode.',
      );
      return FirebaseRuntime(
        availability: FirebaseAvailability.unavailable,
        config: config,
        error: const AppException(
          AppErrorCode.firebaseUnavailable,
          retryable: true,
        ),
      );
    }
  }
}
