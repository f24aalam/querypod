enum TableCellKind { nullValue, text, binary }

class TableCellValue {
  final TableCellKind kind;
  final String display;
  final String? fullText;
  final Object? rawValue;
  final String editText;

  const TableCellValue._({
    required this.kind,
    required this.display,
    required this.editText,
    this.fullText,
    this.rawValue,
  });

  const TableCellValue.nullValue()
    : this._(kind: TableCellKind.nullValue, display: 'NULL', editText: '');

  const TableCellValue.text(String value)
    : this._(
        kind: TableCellKind.text,
        display: value,
        editText: value,
        fullText: value,
        rawValue: value,
      );

  TableCellValue.binary(List<int> value)
    : this._(
        kind: TableCellKind.binary,
        display: '<binary: ${value.length} bytes>',
        editText: value
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(),
        rawValue: List<int>.unmodifiable(value),
      );
}

class TableForeignKey {
  final String targetTable;
  final String targetColumn;

  const TableForeignKey({
    required this.targetTable,
    required this.targetColumn,
  });
}

class TableIndex {
  final String name;
  final List<String> columns;
  final bool isUnique;
  final bool isPrimaryKey;

  const TableIndex({
    required this.name,
    required this.columns,
    required this.isUnique,
    required this.isPrimaryKey,
  });
}

class TableColumnDefinition {
  final String name;
  final String? originalName;
  final String type;
  final int? length;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isAutoIncrement;
  final String? defaultValue;

  const TableColumnDefinition({
    required this.name,
    this.originalName,
    required this.type,
    this.length,
    this.isPrimaryKey = false,
    this.isNullable = true,
    this.isAutoIncrement = false,
    this.defaultValue,
  });

  TableColumnDefinition copyWith({
    String? name,
    String? originalName,
    String? type,
    int? length,
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isAutoIncrement,
    String? defaultValue,
  }) {
    return TableColumnDefinition(
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      type: type ?? this.type,
      length: length ?? this.length,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isNullable: isNullable ?? this.isNullable,
      isAutoIncrement: isAutoIncrement ?? this.isAutoIncrement,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}

class TableDataColumn {
  final String name;
  final String databaseType;
  final int length;
  final bool isPrimaryKey;
  final bool isNullable;
  final TableForeignKey? foreignKey;

  const TableDataColumn({
    required this.name,
    required this.databaseType,
    required this.length,
    required this.isPrimaryKey,
    required this.isNullable,
    this.foreignKey,
  });
}

class TableDataRow {
  final List<TableCellValue> cells;

  TableDataRow(List<TableCellValue> cells) : cells = List.unmodifiable(cells);
}

class TableCellCoordinate {
  final int rowIndex;
  final int columnIndex;

  const TableCellCoordinate({
    required this.rowIndex,
    required this.columnIndex,
  });

  @override
  bool operator ==(Object other) =>
      other is TableCellCoordinate &&
      rowIndex == other.rowIndex &&
      columnIndex == other.columnIndex;

  @override
  int get hashCode => Object.hash(rowIndex, columnIndex);
}

class TableCellEdit {
  final int rowIndex;
  final int columnIndex;
  final String originalText;
  final String draftText;

  const TableCellEdit({
    required this.rowIndex,
    required this.columnIndex,
    required this.originalText,
    required this.draftText,
  });

  bool get isDirty => draftText != originalText;

  TableCellCoordinate get coordinate =>
      TableCellCoordinate(rowIndex: rowIndex, columnIndex: columnIndex);

  TableCellEdit copyWith({String? draftText}) {
    return TableCellEdit(
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      originalText: originalText,
      draftText: draftText ?? this.draftText,
    );
  }
}

class TableCellChange {
  final TableDataRow row;
  final int columnIndex;
  final String value;

  const TableCellChange({
    required this.row,
    required this.columnIndex,
    required this.value,
  });
}

class TableStructure {
  final List<TableDataColumn> columns;
  final List<TableIndex> indexes;
  final String orderColumn;

  TableStructure({
    required List<TableDataColumn> columns,
    this.indexes = const [],
    required this.orderColumn,
  }) : columns = List.unmodifiable(columns);
}

class TableRowsPage {
  final List<TableDataRow> rows;
  final Duration queryDuration;

  TableRowsPage({required List<TableDataRow> rows, required this.queryDuration})
    : rows = List.unmodifiable(rows);
}

class TableFilter {
  final String column;
  final String operator;
  final String value;

  const TableFilter({
    required this.column,
    required this.operator,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      other is TableFilter &&
      column == other.column &&
      operator == other.operator &&
      value == other.value;

  @override
  int get hashCode => Object.hash(column, operator, value);
}

class ForeignRowPreview {
  final String tableName;
  final TableStructure structure;
  final TableDataRow row;

  const ForeignRowPreview({
    required this.tableName,
    required this.structure,
    required this.row,
  });
}
