import '../../../features/editor/domain/entities/table_data.dart';

String quoteMySqlIdentifier(String value) => '`${value.replaceAll('`', '``')}`';

String quotePostgresIdentifier(String value) =>
    '"${value.replaceAll('"', '""')}"';

bool primaryKeyChanged(
  List<TableColumnDefinition> oldColumns,
  List<TableColumnDefinition> newColumns,
) {
  final oldNames = oldColumns
      .where((column) => column.isPrimaryKey)
      .map((column) => column.name)
      .toList();
  final newOriginalNames = newColumns
      .where((column) => column.isPrimaryKey)
      .map((column) => column.originalName ?? column.name)
      .toList();
  return oldNames.length != newOriginalNames.length ||
      Iterable.generate(
        oldNames.length,
      ).any((index) => oldNames[index] != newOriginalNames[index]);
}

List<String> buildMySqlAlterStatements({
  required String oldTableName,
  required String newTableName,
  required List<TableColumnDefinition> oldColumns,
  required List<TableColumnDefinition> newColumns,
}) {
  final table = quoteMySqlIdentifier(oldTableName);
  final statements = <String>[];
  final actions = <String>[];
  final oldMap = {for (final column in oldColumns) column.name: column};
  final retainedNames = <String>{};
  final pkChanged = primaryKeyChanged(oldColumns, newColumns);

  if (pkChanged && oldColumns.any((column) => column.isPrimaryKey)) {
    actions.add('DROP PRIMARY KEY');
  }

  for (final newColumn in newColumns) {
    final originalName = newColumn.originalName;
    final oldColumn = originalName == null ? null : oldMap[originalName];
    final definition = buildMySqlColumnDefinition(newColumn);
    if (oldColumn == null) {
      actions.add(
        'ADD COLUMN ${quoteMySqlIdentifier(newColumn.name)} $definition',
      );
      continue;
    }

    retainedNames.add(oldColumn.name);
    if (newColumn.name != oldColumn.name) {
      actions.add(
        'CHANGE COLUMN '
        '${quoteMySqlIdentifier(oldColumn.name)} '
        '${quoteMySqlIdentifier(newColumn.name)} $definition',
      );
    } else if (!_sameColumnProperties(oldColumn, newColumn)) {
      actions.add(
        'MODIFY COLUMN '
        '${quoteMySqlIdentifier(newColumn.name)} $definition',
      );
    }
  }

  for (final oldColumn in oldColumns) {
    if (!retainedNames.contains(oldColumn.name)) {
      actions.add('DROP COLUMN ${quoteMySqlIdentifier(oldColumn.name)}');
    }
  }

  if (pkChanged) {
    final primaryKeys = newColumns
        .where((column) => column.isPrimaryKey)
        .map((column) => quoteMySqlIdentifier(column.name))
        .join(', ');
    if (primaryKeys.isNotEmpty) {
      actions.add('ADD PRIMARY KEY ($primaryKeys)');
    }
  }

  if (actions.isNotEmpty) {
    statements.add('ALTER TABLE $table ${actions.join(', ')}');
  }

  if (oldTableName != newTableName) {
    statements.add(
      'RENAME TABLE $table TO ${quoteMySqlIdentifier(newTableName)}',
    );
  }
  return statements;
}

String buildMySqlColumnDefinition(TableColumnDefinition column) {
  var definition = column.type;
  if (column.length != null) definition += '(${column.length})';
  if (!column.isNullable) definition += ' NOT NULL';
  if (column.isAutoIncrement) definition += ' AUTO_INCREMENT';
  definition += _defaultClause(column.defaultValue);
  return definition;
}

List<String> buildPostgresAlterStatements({
  required String oldTableName,
  required String newTableName,
  required List<TableColumnDefinition> oldColumns,
  required List<TableColumnDefinition> newColumns,
  required String? primaryKeyConstraint,
  required Map<String, String> serialSequences,
}) {
  final table = quotePostgresIdentifier(oldTableName);
  final statements = <String>[];
  final oldMap = {for (final column in oldColumns) column.name: column};
  final retainedNames = <String>{};
  final pkChanged = primaryKeyChanged(oldColumns, newColumns);

  if (pkChanged && primaryKeyConstraint != null) {
    statements.add(
      'ALTER TABLE $table DROP CONSTRAINT '
      '${quotePostgresIdentifier(primaryKeyConstraint)}',
    );
  }

  for (final newColumn in newColumns) {
    final originalName = newColumn.originalName;
    final oldColumn = originalName == null ? null : oldMap[originalName];
    if (oldColumn == null) {
      statements.add(
        'ALTER TABLE $table ADD COLUMN '
        '${quotePostgresIdentifier(newColumn.name)} '
        '${buildPostgresColumnDefinition(newColumn)}',
      );
      continue;
    }

    retainedNames.add(oldColumn.name);
    final columnName = quotePostgresIdentifier(newColumn.name);
    if (newColumn.name != oldColumn.name) {
      statements.add(
        'ALTER TABLE $table RENAME COLUMN '
        '${quotePostgresIdentifier(oldColumn.name)} TO $columnName',
      );
    }
    if (oldColumn.type != newColumn.type ||
        oldColumn.length != newColumn.length) {
      final type = _postgresType(newColumn);
      statements.add(
        'ALTER TABLE $table ALTER COLUMN $columnName TYPE $type '
        'USING $columnName::$type',
      );
    }
    if (oldColumn.isNullable != newColumn.isNullable) {
      statements.add(
        'ALTER TABLE $table ALTER COLUMN $columnName '
        '${newColumn.isNullable ? 'DROP NOT NULL' : 'SET NOT NULL'}',
      );
    }
    if (oldColumn.defaultValue != newColumn.defaultValue &&
        oldColumn.isAutoIncrement == newColumn.isAutoIncrement) {
      statements.add(
        'ALTER TABLE $table ALTER COLUMN $columnName '
        '${_postgresDefaultAction(newColumn.defaultValue)}',
      );
    }
    if (oldColumn.isAutoIncrement != newColumn.isAutoIncrement) {
      if (newColumn.isAutoIncrement) {
        statements.add(
          'ALTER TABLE $table ALTER COLUMN $columnName DROP DEFAULT',
        );
        statements.add(
          'ALTER TABLE $table ALTER COLUMN $columnName '
          'ADD GENERATED BY DEFAULT AS IDENTITY',
        );
      } else {
        statements.add(
          'ALTER TABLE $table ALTER COLUMN $columnName '
          'DROP IDENTITY IF EXISTS',
        );
        statements.add(
          'ALTER TABLE $table ALTER COLUMN $columnName DROP DEFAULT',
        );
        final serialSequence = serialSequences[oldColumn.name];
        if (serialSequence != null) {
          statements.add('DROP SEQUENCE IF EXISTS $serialSequence');
        }
        if (newColumn.defaultValue != null &&
            newColumn.defaultValue!.isNotEmpty) {
          statements.add(
            'ALTER TABLE $table ALTER COLUMN $columnName '
            '${_postgresDefaultAction(newColumn.defaultValue)}',
          );
        }
      }
    }
  }

  for (final oldColumn in oldColumns) {
    if (!retainedNames.contains(oldColumn.name)) {
      statements.add(
        'ALTER TABLE $table DROP COLUMN '
        '${quotePostgresIdentifier(oldColumn.name)}',
      );
    }
  }

  if (pkChanged) {
    final primaryKeys = newColumns
        .where((column) => column.isPrimaryKey)
        .map((column) => quotePostgresIdentifier(column.name))
        .join(', ');
    if (primaryKeys.isNotEmpty) {
      statements.add('ALTER TABLE $table ADD PRIMARY KEY ($primaryKeys)');
    }
  }

  if (oldTableName != newTableName) {
    statements.add(
      'ALTER TABLE $table RENAME TO '
      '${quotePostgresIdentifier(newTableName)}',
    );
  }
  return statements;
}

String buildPostgresColumnDefinition(TableColumnDefinition column) {
  var definition = _postgresType(column);
  if (column.isAutoIncrement) {
    definition += ' GENERATED BY DEFAULT AS IDENTITY';
  }
  if (!column.isNullable) definition += ' NOT NULL';
  if (!column.isAutoIncrement) {
    definition += _defaultClause(column.defaultValue);
  }
  return definition;
}

String _postgresType(TableColumnDefinition column) {
  var type = column.type;
  if (column.length != null) type += '(${column.length})';
  return type;
}

String _postgresDefaultAction(String? value) {
  if (value == null || value.isEmpty) return 'DROP DEFAULT';
  return 'SET${_defaultClause(value)}';
}

String _defaultClause(String? value) {
  if (value == null || value.isEmpty) return '';
  if (value.toUpperCase() == 'CURRENT_TIMESTAMP') {
    return ' DEFAULT CURRENT_TIMESTAMP';
  }
  return " DEFAULT '${value.replaceAll("'", "''")}'";
}

bool _sameColumnProperties(
  TableColumnDefinition oldColumn,
  TableColumnDefinition newColumn,
) =>
    oldColumn.type == newColumn.type &&
    oldColumn.length == newColumn.length &&
    oldColumn.isNullable == newColumn.isNullable &&
    oldColumn.isAutoIncrement == newColumn.isAutoIncrement &&
    oldColumn.defaultValue == newColumn.defaultValue;
