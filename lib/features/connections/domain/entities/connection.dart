import 'package:uuid/uuid.dart';

enum ConnectionType { mysql, sqlite, postgresql }

class Connection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final String workspaceId;
  final ConnectionType type;
  final bool useTls;

  const Connection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.workspaceId,
    this.type = ConnectionType.mysql,
    this.useTls = true,
  });

  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
    String? workspaceId,
    ConnectionType? type,
    bool? useTls,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
      workspaceId: workspaceId ?? this.workspaceId,
      type: type ?? this.type,
      useTls: useTls ?? this.useTls,
    );
  }

  static String generateId() => const Uuid().v4();

  ConnectionSessionIdentity get sessionIdentity => ConnectionSessionIdentity(
    id: id,
    host: host,
    port: port,
    user: user,
    password: password,
    database: database,
    type: type,
    useTls: useTls,
  );
}

class ConnectionSessionIdentity {
  final String id;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final ConnectionType type;
  final bool useTls;

  const ConnectionSessionIdentity({
    required this.id,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.type,
    required this.useTls,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionSessionIdentity &&
          id == other.id &&
          host == other.host &&
          port == other.port &&
          user == other.user &&
          password == other.password &&
          database == other.database &&
          type == other.type &&
          useTls == other.useTls;

  @override
  int get hashCode =>
      Object.hash(id, host, port, user, password, database, type, useTls);
}
