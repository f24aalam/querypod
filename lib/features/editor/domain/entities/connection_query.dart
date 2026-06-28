class ConnectionQuery {
  final String id;
  final String connectionId;
  final String title;
  final String sql;
  final String? database;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConnectionQuery({
    required this.id,
    required this.connectionId,
    required this.title,
    required this.sql,
    this.database,
    required this.createdAt,
    required this.updatedAt,
  });

  ConnectionQuery copyWith({
    String? title,
    String? sql,
    String? Function()? database,
    DateTime? updatedAt,
  }) {
    return ConnectionQuery(
      id: id,
      connectionId: connectionId,
      title: title ?? this.title,
      sql: sql ?? this.sql,
      database: database != null ? database() : this.database,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
