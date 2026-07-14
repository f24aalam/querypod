abstract class PinnedTablesRepository {
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
  });

  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    required List<String> tableNames,
  });
}
