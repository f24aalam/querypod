enum TableCellKind { nullValue, text, binary }

class TableCellValue {
  final TableCellKind kind;
  final String display;
  final String? fullText;

  const TableCellValue._({
    required this.kind,
    required this.display,
    this.fullText,
  });

  const TableCellValue.nullValue()
    : this._(kind: TableCellKind.nullValue, display: 'NULL');

  const TableCellValue.text(String value)
    : this._(kind: TableCellKind.text, display: value, fullText: value);

  const TableCellValue.binary(int bytes)
    : this._(kind: TableCellKind.binary, display: '<binary: $bytes bytes>');
}

class TableDataColumn {
  final String name;
  final String databaseType;
  final int length;
  final bool isPrimaryKey;

  const TableDataColumn({
    required this.name,
    required this.databaseType,
    required this.length,
    required this.isPrimaryKey,
  });
}

class TableDataRow {
  final List<TableCellValue> cells;

  TableDataRow(List<TableCellValue> cells) : cells = List.unmodifiable(cells);
}

class TableStructure {
  final List<TableDataColumn> columns;
  final String orderColumn;

  TableStructure({
    required List<TableDataColumn> columns,
    required this.orderColumn,
  }) : columns = List.unmodifiable(columns);
}

class TableRowsPage {
  final List<TableDataRow> rows;
  final Duration queryDuration;

  TableRowsPage({required List<TableDataRow> rows, required this.queryDuration})
    : rows = List.unmodifiable(rows);
}
