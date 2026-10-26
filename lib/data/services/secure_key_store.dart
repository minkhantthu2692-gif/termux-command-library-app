import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key/value contract for API secrets. Only this service may touch secure
/// storage; keys are never written to SQLite, Firestore, logs or crash reports.
abstract interface class ApiKeyStore {
  Future<String?> readKey(String providerId);
  Future<void> saveKey(String providerId, String key);
  Future<void> deleteKey(String providerId);
  Future<bool> hasKey(String providerId);
}

class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _prefix = 'tcl.ai.apiKey.';

  String _keyFor(String providerId) => '$_prefix$providerId';

  @override
  Future<String?> readKey(String providerId) async {
    final value = await _storage.read(key: _keyFor(providerId));
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<void> saveKey(String providerId, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await deleteKey(providerId);
      return;
    }
    await _storage.write(key: _keyFor(providerId), value: trimmed);
  }

  @override
  Future<void> deleteKey(String providerId) =>
      _storage.delete(key: _keyFor(providerId));

  @override
  Future<bool> hasKey(String providerId) async =>
      (await readKey(providerId)) != null;
}
