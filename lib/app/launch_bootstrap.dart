import '../features/connections/domain/entities/connection.dart';

class LaunchBootstrapConfig {
  final String profileNamespace;
  final BootstrapConnectionPreset? preset;

  const LaunchBootstrapConfig({
    required this.profileNamespace,
    required this.preset,
  });

  factory LaunchBootstrapConfig.fromEnvironment() {
    const profileNamespace = String.fromEnvironment(
      'QUERYPOD_PROFILE_NAMESPACE',
      defaultValue: '',
    );
    final preset = BootstrapConnectionPreset.fromEnvironment();
    return LaunchBootstrapConfig(
      profileNamespace: profileNamespace,
      preset: preset,
    );
  }
}

class BootstrapConnectionPreset {
  final String id;
  final String name;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final ConnectionType type;
  final bool useTls;
  final bool selectAfterSave;

  const BootstrapConnectionPreset({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.type,
    required this.useTls,
    required this.selectAfterSave,
  });

  static BootstrapConnectionPreset? fromEnvironment() {
    const id = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_CONNECTION_ID',
      defaultValue: '',
    );
    if (id.isEmpty) return null;

    const name = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_CONNECTION_NAME',
      defaultValue: '',
    );
    const host = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_HOST',
      defaultValue: '',
    );
    const portValue = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_PORT',
      defaultValue: '',
    );
    const user = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_USER',
      defaultValue: '',
    );
    const password = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_PASSWORD',
      defaultValue: '',
    );
    const database = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_DATABASE',
      defaultValue: '',
    );
    const typeValue = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_TYPE',
      defaultValue: '',
    );
    const useTlsValue = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_USE_TLS',
      defaultValue: 'false',
    );
    const selectValue = String.fromEnvironment(
      'QUERYPOD_BOOTSTRAP_SELECT',
      defaultValue: 'true',
    );

    final port = int.tryParse(portValue);
    if (name.isEmpty ||
        host.isEmpty ||
        port == null ||
        user.isEmpty ||
        database.isEmpty) {
      throw StateError(
        'Incomplete QueryPod launch bootstrap config. '
        'Expected name, host, port, user, database, and type when '
        'QUERYPOD_BOOTSTRAP_CONNECTION_ID is set.',
      );
    }

    return BootstrapConnectionPreset(
      id: id,
      name: name,
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
      type: _parseConnectionType(typeValue),
      useTls: _parseBool(useTlsValue),
      selectAfterSave: _parseBool(selectValue),
    );
  }

  static ConnectionType _parseConnectionType(String value) {
    switch (value) {
      case 'mysql':
        return ConnectionType.mysql;
      case 'postgresql':
        return ConnectionType.postgresql;
      case 'sqlite':
        return ConnectionType.sqlite;
      default:
        throw StateError(
          'Unsupported QUERYPOD_BOOTSTRAP_TYPE "$value". '
          'Use mysql, postgresql, or sqlite.',
        );
    }
  }

  static bool _parseBool(String value) => value.toLowerCase() == 'true';

  Connection toConnection({String workspaceId = 'default'}) {
    return Connection(
      id: id,
      name: name,
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
      workspaceId: workspaceId,
      type: type,
      useTls: useTls,
    );
  }
}
