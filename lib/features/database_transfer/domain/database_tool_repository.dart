import 'database_tool.dart';

abstract class DatabaseToolRepository {
  Future<String?> getOverride(DatabaseTool tool);
  Future<void> setOverride(DatabaseTool tool, String? path);
  Future<DatabaseToolStatus> inspect(DatabaseTool tool);
  Future<Map<DatabaseTool, DatabaseToolStatus>> inspectAll();
}
