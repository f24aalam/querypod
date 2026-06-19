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
}
