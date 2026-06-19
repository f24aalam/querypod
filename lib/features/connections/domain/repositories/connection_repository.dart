import '../entities/connection.dart';

abstract class ConnectionRepository {
  Future<List<Connection>> getAll();
  Future<Connection> save(Connection connection);
  Future<void> delete(String id);
  Future<String?> getSelectedId();
  Future<void> setSelectedId(String? id);
}
