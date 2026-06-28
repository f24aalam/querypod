import '../../domain/entities/connection.dart';

class ConnectionModel extends Connection {
  const ConnectionModel({
    required super.id,
    required super.name,
    required super.host,
    required super.port,
    required super.user,
    required super.password,
    required super.database,
    required super.workspaceId,
    super.type = ConnectionType.mysql,
    super.useTls = true,
  });

  factory ConnectionModel.fromJson(
    Map<String, dynamic> json, {
    String password = '',
  }) {
    return ConnectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      user: json['user'] as String,
      password: password,
      database: json['database'] as String,
      workspaceId: json['workspaceId'] as String? ?? 'default',
      type: ConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConnectionType.mysql,
      ),
      useTls: json['useTls'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'user': user,
      'database': database,
      'workspaceId': workspaceId,
      'type': type.name,
      'useTls': useTls,
    };
  }

  factory ConnectionModel.fromEntity(Connection entity) {
    return ConnectionModel(
      id: entity.id,
      name: entity.name,
      host: entity.host,
      port: entity.port,
      user: entity.user,
      password: entity.password,
      database: entity.database,
      workspaceId: entity.workspaceId,
      type: entity.type,
      useTls: entity.useTls,
    );
  }
}
