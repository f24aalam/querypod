class ConnectionQuery {
  final String id;
  final String connectionId;
  final String title;
  final String sql;
  final String? database;
  final String? schema;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConnectionQuery({
    required this.id,
    required this.connectionId,
    required this.title,
    required this.sql,
    this.database,
    this.schema,
    required this.createdAt,
    required this.updatedAt,
  });

  ConnectionQuery copyWith({
    String? title,
    String? sql,
    String? Function()? database,
    String? Function()? schema,
    DateTime? updatedAt,
  }) {
    return ConnectionQuery(
      id: id,
      connectionId: connectionId,
      title: title ?? this.title,
      sql: sql ?? this.sql,
      database: database != null ? database() : this.database,
      schema: schema != null ? schema() : this.schema,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
