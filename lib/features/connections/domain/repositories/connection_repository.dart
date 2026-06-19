import '../entities/connection.dart';

abstract class ConnectionRepository {
  Future<List<Connection>> getAll();
  Future<Connection> save(Connection connection);
  Future<void> delete(String id);
}
