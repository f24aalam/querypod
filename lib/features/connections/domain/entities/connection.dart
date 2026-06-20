import 'package:uuid/uuid.dart';

class Connection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  const Connection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
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
  );
}

class ConnectionSessionIdentity {
  final String id;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  const ConnectionSessionIdentity({
    required this.id,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
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
          database == other.database;

  @override
  int get hashCode => Object.hash(id, host, port, user, password, database);
}
