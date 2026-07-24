abstract class PinnedTablesRepository {
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
  });

  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
    required List<String> tableNames,
  });
}
