import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../domain/entities/table_data.dart';
import '../cubit/create_table_cubit.dart';
import '../cubit/create_table_state.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/connection_metadata_cubit.dart';

class CreateTableEditor extends StatelessWidget {
  final EditorTab tab;

  const CreateTableEditor({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateTableCubit(
        connectionCubit: context.read<ConnectionCubit>(),
        workspaceMetadataCubit: context.read<ConnectionMetadataCubit>(),
      ),
      child: _CreateTableEditorContent(tab: tab),
    );
  }
}

class _CreateTableEditorContent extends StatefulWidget {
  final EditorTab tab;

  const _CreateTableEditorContent({required this.tab});

  @override
  State<_CreateTableEditorContent> createState() => _CreateTableEditorContentState();
}

class _CreateTableEditorContentState extends State<_CreateTableEditorContent> {
  final _tableNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final key = widget.tab.key as CreateTableTabKey;
    if (key.tableToEdit != null) {
      context.read<CreateTableCubit>().loadTableSchema(key.database, key.tableToEdit!);
    }
  }

  @override
  void dispose() {
    _tableNameController.dispose();
    super.dispose();
  }

  void _handleSuccess(BuildContext context) {
    final key = widget.tab.key as CreateTableTabKey;
    final state = context.read<CreateTableCubit>().state;
    context.read<EditorTabsCubit>().closeTab(key);

    if (state.originalTableName != null && state.originalTableName != state.tableName) {
      final oldTableTabKey = TableTabKey(
        connectionId: key.connectionId,
        database: key.database,
        tableName: state.originalTableName!,
      );
      context.read<EditorTabsCubit>().closeTab(oldTableTabKey);
    }

    final tableTabKey = TableTabKey(
      connectionId: key.connectionId,
      database: key.database,
      tableName: state.tableName,
    );
    context.read<TableDataCubit>().refresh(tableTabKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocConsumer<CreateTableCubit, CreateTableState>(
      listenWhen: (prev, curr) => prev.isSuccess != curr.isSuccess || prev.errorMessage != curr.errorMessage || prev.tableName != curr.tableName,
      listener: (context, state) {
        if (state.tableName.isNotEmpty && _tableNameController.text != state.tableName && state.originalTableName != null) {
           _tableNameController.text = state.tableName;
        }
        if (state.isSuccess) {
          _handleSuccess(context);
        } else if (state.errorMessage != null) {
          // Could show a toast, but using error text below
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.colors.primary),
                const SizedBox(height: 16),
                Text('Loading table schema...', style: TextStyle(color: theme.colors.mutedForeground)),
              ],
            ),
          );
        }

        return Container(
          color: theme.colors.background,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.originalTableName != null ? 'Edit Table' : 'Create Table',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: 300,
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: _tableNameController,
                    onChange: (val) => context.read<CreateTableCubit>().setTableName(val.text),
                  ),
                  label: const Text('Table Name'),
                  hint: 'Enter table name...',
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Text(
                    'Columns',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const Spacer(),
                  FButton.icon(
                    onPress: context.read<CreateTableCubit>().addColumn,
                    size: FButtonSizeVariant.sm,
                    variant: FButtonVariant.outline,
                    child: const Icon(Icons.add, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    itemCount: state.columns.length,
                    separatorBuilder: (context, index) => Divider(color: theme.colors.border, height: 1),
                    itemBuilder: (context, index) {
                      return _ColumnEditorRow(
                        index: index,
                        column: state.columns[index],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colors.destructive),
                  ),
                ),
                
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    onPress: () => context.read<EditorTabsCubit>().closeTab(widget.tab.key),
                    variant: FButtonVariant.outline,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FButton(
                    onPress: state.isSubmitting
                        ? null
                        : () {
                            final key = widget.tab.key as CreateTableTabKey;
                            context.read<CreateTableCubit>().submit(key.database);
                          },
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(state.originalTableName != null ? 'Save Changes' : 'Create Table'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColumnEditorRow extends StatefulWidget {
  final int index;
  final TableColumnDefinition column;

  const _ColumnEditorRow({required this.index, required this.column});

  @override
  State<_ColumnEditorRow> createState() => _ColumnEditorRowState();
}

class _ColumnEditorRowState extends State<_ColumnEditorRow> {
  late TextEditingController _nameController;
  late TextEditingController _lengthController;
  late TextEditingController _defaultController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.column.name);
    _lengthController = TextEditingController(text: widget.column.length?.toString() ?? '');
    _defaultController = TextEditingController(text: widget.column.defaultValue ?? '');
  }

  @override
  void didUpdateWidget(_ColumnEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.column.name != widget.column.name && _nameController.text != widget.column.name) {
      _nameController.text = widget.column.name;
    }
    final lengthStr = widget.column.length?.toString() ?? '';
    if (oldWidget.column.length != widget.column.length && _lengthController.text != lengthStr) {
      _lengthController.text = lengthStr;
    }
    final defaultStr = widget.column.defaultValue ?? '';
    if (oldWidget.column.defaultValue != widget.column.defaultValue && _defaultController.text != defaultStr) {
      _defaultController.text = defaultStr;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _defaultController.dispose();
    super.dispose();
  }

  void _update(TableColumnDefinition updated) {
    context.read<CreateTableCubit>().updateColumn(widget.index, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // Use connection type to determine types list
    final connCubit = context.watch<ConnectionCubit>();
    final connType = connCubit.state.activeConnection?.type ?? ConnectionType.postgresql;
    
    final categories = connType == ConnectionType.postgresql
        ? postgresCategories
        : connType == ConnectionType.mysql
            ? mysqlCategories
            : sqliteCategories;

    final typeUpper = widget.column.type.toUpperCase();
    final supportsLength = typeUpper.contains('VARCHAR') || typeUpper.contains('CHAR');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _nameController,
                onChange: (val) => _update(widget.column.copyWith(name: val.text)),
              ),
              label: const Text('Name'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FSelect<String>.rich(
              label: const Text('Type'),
              format: (s) => s,
              control: FSelectControl.lifted(
                value: widget.column.type,
                onChange: (val) {
                  if (val != null) _update(widget.column.copyWith(type: val));
                },
              ),
              children: [
                for (final category in categories)
                  FSelectSection<String>(
                    label: Text(category.name),
                    items: {
                      for (final t in category.types) t: t,
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Opacity(
              opacity: supportsLength ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !supportsLength,
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: _lengthController,
                    onChange: (val) => _update(widget.column.copyWith(length: int.tryParse(val.text))),
                  ),
                  label: const Text('Length'),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _defaultController,
                onChange: (val) => _update(widget.column.copyWith(defaultValue: val.text)),
              ),
              label: const Text('Default'),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text('PK', style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground)),
              const SizedBox(height: 8),
              FSwitch(
                value: widget.column.isPrimaryKey,
                onChange: (val) => _update(widget.column.copyWith(isPrimaryKey: val)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text('Null', style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground)),
              const SizedBox(height: 8),
              FSwitch(
                value: widget.column.isNullable,
                onChange: (val) => _update(widget.column.copyWith(isNullable: val)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text('A.I.', style: TextStyle(fontSize: 12, color: theme.colors.mutedForeground)),
              const SizedBox(height: 8),
              FSwitch(
                value: widget.column.isAutoIncrement,
                onChange: (val) => _update(widget.column.copyWith(isAutoIncrement: val)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FButton.icon(
              onPress: () => context.read<CreateTableCubit>().removeColumn(widget.index),
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              child: Icon(Icons.delete_outline, size: 16, color: theme.colors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}

class ColumnTypeCategory {
  final String name;
  final List<String> types;

  const ColumnTypeCategory(this.name, this.types);
}

const postgresCategories = [
  ColumnTypeCategory('Numeric', ['SMALLINT', 'INTEGER', 'BIGINT', 'DECIMAL', 'NUMERIC', 'REAL', 'DOUBLE PRECISION', 'SERIAL', 'BIGSERIAL']),
  ColumnTypeCategory('Character', ['VARCHAR', 'CHAR', 'TEXT']),
  ColumnTypeCategory('Date & Time', ['DATE', 'TIME', 'TIMESTAMP', 'INTERVAL']),
  ColumnTypeCategory('Boolean', ['BOOLEAN']),
  ColumnTypeCategory('JSON', ['JSON', 'JSONB']),
  ColumnTypeCategory('Binary/Other', ['BYTEA', 'UUID', 'XML']),
];

const mysqlCategories = [
  ColumnTypeCategory('Numeric', ['TINYINT', 'SMALLINT', 'MEDIUMINT', 'INT', 'BIGINT', 'DECIMAL', 'FLOAT', 'DOUBLE']),
  ColumnTypeCategory('Character', ['VARCHAR', 'CHAR', 'TINYTEXT', 'TEXT', 'MEDIUMTEXT', 'LONGTEXT']),
  ColumnTypeCategory('Date & Time', ['DATE', 'TIME', 'DATETIME', 'TIMESTAMP', 'YEAR']),
  ColumnTypeCategory('Boolean', ['BOOLEAN']),
  ColumnTypeCategory('JSON', ['JSON']),
  ColumnTypeCategory('Binary/Other', ['BINARY', 'VARBINARY', 'BLOB']),
];

const sqliteCategories = [
  ColumnTypeCategory('Numeric', ['INTEGER', 'REAL', 'NUMERIC']),
  ColumnTypeCategory('Character', ['TEXT']),
  ColumnTypeCategory('Date & Time', ['DATETIME', 'DATE', 'TIME']),
  ColumnTypeCategory('Boolean', ['BOOLEAN']),
  ColumnTypeCategory('JSON', ['JSON']),
  ColumnTypeCategory('Binary/Other', ['BLOB']),
];
