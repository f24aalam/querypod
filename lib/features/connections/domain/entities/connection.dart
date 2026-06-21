import 'package:uuid/uuid.dart';

enum ConnectionType { mysql, sqlite }

class Connection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;
  final ConnectionType type;

  const Connection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    this.type = ConnectionType.mysql,
  });

  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
    ConnectionType? type,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
      type: type ?? this.type,
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

  const ConnectionSessionIdentity({
    required this.id,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.type,
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
          type == other.type;

  @override
  int get hashCode =>
      Object.hash(id, host, port, user, password, database, type);
}
