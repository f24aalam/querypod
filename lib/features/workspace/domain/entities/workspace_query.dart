class WorkspaceQuery {
  final String id;
  final String connectionId;
  final String title;
  final String sql;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkspaceQuery({
    required this.id,
    required this.connectionId,
    required this.title,
    required this.sql,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkspaceQuery copyWith({String? title, String? sql, DateTime? updatedAt}) {
    return WorkspaceQuery(
      id: id,
      connectionId: connectionId,
      title: title ?? this.title,
      sql: sql ?? this.sql,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
