enum WorkspaceTableType { table, view }

class WorkspaceTable {
  final String name;
  final WorkspaceTableType type;

  const WorkspaceTable({required this.name, required this.type});
}
