import '../../domain/entities/connection.dart';

class ConnectionDraft {
  final String id;
  final String? sourceConnectionId;
  final String name;
  final String host;
  final String port;
  final String user;
  final String password;
  final String database;
  final ConnectionType type;
  final bool useTls;

  const ConnectionDraft({
    required this.id,
    required this.sourceConnectionId,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
    required this.type,
    required this.useTls,
  });

  factory ConnectionDraft.empty() => ConnectionDraft(
    id: Connection.generateId(),
    sourceConnectionId: null,
    name: '',
    host: '',
    port: '',
    user: '',
    password: '',
    database: '',
    type: ConnectionType.mysql,
    useTls: true,
  );

  factory ConnectionDraft.fromConnection(Connection connection) =>
      ConnectionDraft(
        id: connection.id,
        sourceConnectionId: connection.id,
        name: connection.name,
        host: connection.host,
        port: connection.port.toString(),
        user: connection.user,
        password: connection.password,
        database: connection.database,
        type: connection.type,
        useTls: connection.useTls,
      );

  ConnectionDraft copyWith({
    String? name,
    String? host,
    String? port,
    String? user,
    String? password,
    String? database,
    ConnectionType? type,
    bool? useTls,
  }) {
    return ConnectionDraft(
      id: id,
      sourceConnectionId: sourceConnectionId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
      type: type ?? this.type,
      useTls: useTls ?? this.useTls,
    );
  }

  Connection toConnection() {
    int defaultPort = 3306;
    if (type == ConnectionType.postgresql) {
      defaultPort = 5432;
    }

    return Connection(
      id: id,
      name: name,
      host: host,
      port: int.tryParse(port) ?? defaultPort,
      user: user,
      password: password,
      database: database,
      type: type,
      useTls: useTls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionDraft &&
          id == other.id &&
          sourceConnectionId == other.sourceConnectionId &&
          name == other.name &&
          host == other.host &&
          port == other.port &&
          user == other.user &&
          password == other.password &&
          database == other.database &&
          type == other.type &&
          useTls == other.useTls;

  @override
  int get hashCode => Object.hash(
    id,
    sourceConnectionId,
    name,
    host,
    port,
    user,
    password,
    database,
    type,
    useTls,
  );
}

class ConnectionEditorState {
  final ConnectionDraft draft;
  final ConnectionDraft baseline;

  const ConnectionEditorState({required this.draft, required this.baseline});

  bool get isDirty => draft != baseline;
  bool get isNew => draft.sourceConnectionId == null;
}
