enum ConnectionTableType { table, view }

class ConnectionTable {
  final String name;
  final ConnectionTableType type;

  const ConnectionTable({required this.name, required this.type});
}
