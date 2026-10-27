import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';

/// Firebase configuration for one project. Android builds normally resolve it
/// from the (git-ignored) `google-services.json`; compile-time `--dart-define`
/// values are supported for CI and other builds that do not bundle that file.
/// Local-only builds and tests work without either source.
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

  /// Reads back the options the native Firebase SDK resolved, which is how a
  /// build configured through `android/app/google-services.json` reports its
  /// project without any `--dart-define` values.
  factory FirebaseConfig.fromOptions(FirebaseOptions options) => FirebaseConfig(
    apiKey: options.apiKey,
    appId: options.appId,
    messagingSenderId: options.messagingSenderId,
    projectId: options.projectId,
    authDomain: options.authDomain,
  );

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
///
/// Android builds can be configured either way:
///
///   * `android/app/google-services.json` (the standard Firebase setup, read by
///     the native SDK), or
///   * `--dart-define=FIREBASE_*` values, for builds that do not bundle the
///     JSON (for example CI). If both sources exist, they must describe the
///     same Firebase app; the native default app is resolved first and
///     mismatched values make initialization fail.
abstract final class FirebaseBootstrap {
  /// Platforms whose native Firebase SDK can resolve app options from a bundled
  /// configuration file when no `--dart-define` values are supplied.
  static bool get _supportsNativeDefaults =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<FirebaseRuntime> initialize() async {
    final config = FirebaseConfig.fromEnvironment();
    final useNativeDefaults = config == null && _supportsNativeDefaults;
    if (config == null && !useNativeDefaults) {
      return FirebaseRuntime.disabled;
    }

    try {
      if (Firebase.apps.isEmpty) {
        // Passing null lets the Android SDK bootstrap from its bundled
        // google-services configuration when no define values are supplied.
        await Firebase.initializeApp(options: config?.toOptions());
      }
      return FirebaseRuntime(
        availability: FirebaseAvailability.ready,
        config: FirebaseConfig.fromOptions(Firebase.app().options),
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Firebase initialization failed (${error.code}). '
        'Continuing in local-only mode.',
      );
      // Without build values the failure most likely means no
      // google-services.json was processed, which is a supported local-only
      // build rather than a configuration error the user can act on.
      if (config == null) return FirebaseRuntime.disabled;
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
      if (config == null) return FirebaseRuntime.disabled;
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
