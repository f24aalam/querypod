// ignore_for_file: prefer_initializing_formals

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ConnectionCredentialStore {
  Future<String?> readPassword(String connectionId);
  Future<void> writePassword(String connectionId, String password);
  Future<void> deletePassword(String connectionId);
}

class SecureConnectionCredentialStore implements ConnectionCredentialStore {
  static const _passwordPrefix = 'querypod_connection_';

  final FlutterSecureStorage _secureStorage;
  final String _passwordStoragePrefix;

  SecureConnectionCredentialStore({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    String keyNamespace = '',
  }) : _secureStorage = secureStorage,
       _passwordStoragePrefix = _withNamespace(_passwordPrefix, keyNamespace);

  static String _withNamespace(String key, String namespace) {
    final normalized = namespace.trim();
    if (normalized.isEmpty) return key;
    return '${normalized}_$key';
  }

  String keyFor(String connectionId) => '$_passwordStoragePrefix$connectionId';

  @override
  Future<String?> readPassword(String connectionId) =>
      _secureStorage.read(key: keyFor(connectionId));

  @override
  Future<void> writePassword(String connectionId, String password) =>
      _secureStorage.write(key: keyFor(connectionId), value: password);

  @override
  Future<void> deletePassword(String connectionId) =>
      _secureStorage.delete(key: keyFor(connectionId));
}
