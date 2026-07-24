import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../domain/entities/connection_table.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/connection_metadata_cubit.dart';
import '../cubit/connection_metadata_state.dart';
import 'create_database_dialog.dart';
import 'create_schema_dialog.dart';
import 'sidebar_header.dart';
import 'table_destructive_action_dialog.dart';

class TableListPanel extends StatefulWidget {
  const TableListPanel({super.key});

  @override
  State<TableListPanel> createState() => _TableListPanelState();
}

class _TableListPanelState extends State<TableListPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocListener<ConnectionMetadataCubit, ConnectionMetadataState>(
      listenWhen: (prev, curr) => prev.query != curr.query,
      listener: (context, state) {
        if (_searchController.text != state.query) {
          _searchController.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
      },
      child: BlocBuilder<ConnectionMetadataCubit, ConnectionMetadataState>(
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(
                right: BorderSide(color: theme.colors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SidebarHeader(
                  title: 'TABLES',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FButton.icon(
                        onPress: () {
                          final selectedConnection = context
                              .read<ConnectionCubit>()
                              .state
                              .activeConnection;
                          final database = state.selectedDatabase;
                          if (selectedConnection != null && database != null) {
                            context
                                .read<ConnectionMetadataCubit>()
                                .refreshTables(selectedConnection, database);
                          }
                        },
                        size: FButtonSizeVariant.sm,
                        variant: FButtonVariant.ghost,
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      FButton.icon(
                        onPress: () {
                          final selectedConnection = context
                              .read<ConnectionCubit>()
                              .state
                              .activeConnection;
                          final database = state.selectedDatabase;
                          if (selectedConnection != null && database != null) {
                            context.read<EditorTabsCubit>().openCreateTableTab(
                              connectionId: selectedConnection.id,
                              database: database,
                              schema: state.selectedSchema,
                            );
                          }
                        },
                        size: FButtonSizeVariant.sm,
                        variant: FButtonVariant.ghost,
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      height: 28,
                      child: TextField(
                        controller: _searchController,
                        onChanged: context
                            .read<ConnectionMetadataCubit>()
                            .search,
                        enabled:
                            !state.isLoadingDatabases &&
                            !state.isLoadingTables &&
                            state.tables.isNotEmpty,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colors.foreground,
                        ),
                        cursorColor: theme.colors.primary,
                        decoration: InputDecoration(
                          hintText: 'Search tables...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: theme.colors.mutedForeground,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 16,
                            color: theme.colors.mutedForeground,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: theme.colors.secondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: theme.colors.border,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: theme.colors.border,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: theme.colors.primary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _TableListBody(state: state, theme: theme),
                ),
                _DatabasePicker(state: state, theme: theme),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TableListBody extends StatelessWidget {
  final ConnectionMetadataState state;
  final FThemeData theme;

  const _TableListBody({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingDatabases) {
      return _EmptyState(message: 'Loading databases...', theme: theme);
    }

    if (state.isLoadingTables) {
      return _EmptyState(message: 'Loading tables...', theme: theme);
    }

    if (state.databases.isEmpty) {
      return _EmptyState(message: 'No databases found', theme: theme);
    }

    if (state.tables.isEmpty) {
      return _EmptyState(
        message: state.selectedDatabase == null
            ? 'Select a database'
            : 'No tables in ${state.selectedDatabase}',
        theme: theme,
      );
    }

    if (state.filteredTables.isEmpty) {
      return _EmptyState(message: 'No matching tables', theme: theme);
    }

    final pinnedTables = state.pinnedFilteredTables;
    final unpinnedTables = state.unpinnedFilteredTables;

    if (pinnedTables.isEmpty) {
      return ListView(
        padding: EdgeInsets.zero,
        children: unpinnedTables
            .map(
              (table) => _TableItem(
                table: table,
                isSelected: table.name == state.selectedTable?.name,
                isPinned: state.pinnedTableNames.contains(table.name),
                theme: theme,
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        ...pinnedTables.map(
          (table) => _TableItem(
            table: table,
            isSelected: table.name == state.selectedTable?.name,
            isPinned: true,
            theme: theme,
          ),
        ),
        Divider(height: 1, thickness: 1, color: theme.colors.border),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: unpinnedTables
                .map(
                  (table) => _TableItem(
                    table: table,
                    isSelected: table.name == state.selectedTable?.name,
                    isPinned: false,
                    theme: theme,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DatabasePicker extends StatelessWidget {
  final ConnectionMetadataState state;
  final FThemeData theme;

  const _DatabasePicker({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final selectedConnection = context
        .read<ConnectionCubit>()
        .state
        .activeConnection;
    final databaseItems = {for (final db in state.databases) db.name: db.name};
    final schemaItems = {
      for (final schema in state.schemas) schema.name: schema.name,
    };
    final showSchemaPicker =
        selectedConnection?.type == ConnectionType.postgresql;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: state.isLoadingDatabases
            ? Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.colors.border, width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading databases...',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FSelect<String>.search(
                          items: databaseItems,
                          size: FTextFieldSizeVariant.sm,
                          hint: 'Select database',
                          enabled:
                              selectedConnection != null &&
                              databaseItems.isNotEmpty,
                          clearable: false,
                          searchFieldProperties:
                              const FSelectSearchFieldProperties(
                                hint: 'Search databases...',
                              ),
                          contentConstraints: const FAutoWidthPortalConstraints(
                            maxHeight: 300,
                          ),
                          prefixBuilder: (context, fieldStyle, widget) =>
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.storage_outlined,
                                  size: 14,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                          suffixBuilder: (context, fieldStyle, widget) =>
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  size: 14,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                          control: FSelectControl.lifted(
                            value: state.selectedDatabase,
                            onChange: (value) {
                              if (value == null || selectedConnection == null) {
                                return;
                              }
                              context
                                  .read<ConnectionMetadataCubit>()
                                  .selectDatabase(selectedConnection, value);
                            },
                          ),
                        ),
                      ),
                      if (selectedConnection != null &&
                          selectedConnection.type != ConnectionType.sqlite) ...[
                        const SizedBox(width: 8),
                        FButton.icon(
                          onPress: () {
                            CreateDatabaseDialog.show(
                              context,
                              selectedConnection,
                            );
                          },
                          size: FButtonSizeVariant.sm,
                          variant: FButtonVariant.outline,
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ],
                    ],
                  ),
                  if (showSchemaPicker) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: FSelect<String>.search(
                            items: schemaItems,
                            size: FTextFieldSizeVariant.sm,
                            hint: 'Select schema',
                            enabled:
                                selectedConnection != null &&
                                state.selectedDatabase != null &&
                                schemaItems.isNotEmpty,
                            clearable: false,
                            searchFieldProperties:
                                const FSelectSearchFieldProperties(
                                  hint: 'Search schemas...',
                                ),
                            contentConstraints:
                                const FAutoWidthPortalConstraints(
                                  maxHeight: 300,
                                ),
                            prefixBuilder: (context, fieldStyle, widget) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.account_tree_outlined,
                                    size: 14,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                            suffixBuilder: (context, fieldStyle, widget) =>
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    size: 14,
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                            control: FSelectControl.lifted(
                              value: state.selectedSchema,
                              onChange: (value) {
                                final database = state.selectedDatabase;
                                if (value == null ||
                                    selectedConnection == null ||
                                    database == null) {
                                  return;
                                }
                                context
                                    .read<ConnectionMetadataCubit>()
                                    .selectSchema(
                                      selectedConnection,
                                      database,
                                      value,
                                    );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FButton.icon(
                          onPress: state.selectedDatabase == null
                              ? null
                              : () {
                                  CreateSchemaDialog.show(
                                    context,
                                    connection: selectedConnection!,
                                    database: state.selectedDatabase!,
                                  );
                                },
                          size: FButtonSizeVariant.sm,
                          variant: FButtonVariant.outline,
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TableItem extends StatelessWidget {
  final ConnectionTable table;
  final bool isSelected;
  final bool isPinned;
  final FThemeData theme;

  const _TableItem({
    required this.table,
    required this.isSelected,
    required this.isPinned,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FContextMenu(
      menuBuilder: (context, controller, menu) => [
        FItemGroup(
          children: [
            FItem(
              title: Text(isPinned ? 'Unpin' : 'Pin'),
              prefix: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 14,
              ),
              onPress: () {
                controller.hide();
                context.read<ConnectionMetadataCubit>().toggleTablePin(table);
              },
            ),
            FItem(
              title: const Text('Edit'),
              prefix: const Icon(Icons.edit_outlined, size: 14),
              onPress: () {
                controller.hide();
                final metadata = context.read<ConnectionMetadataCubit>();
                final connection = context
                    .read<ConnectionCubit>()
                    .state
                    .activeConnection;
                final database = metadata.state.selectedDatabase;
                if (connection == null || database == null) return;

                context.read<EditorTabsCubit>().openCreateTableTab(
                  connectionId: connection.id,
                  database: database,
                  schema: metadata.state.selectedSchema,
                  tableToEdit: table.name,
                );
              },
            ),
          ],
        ),
        FItemGroup(
          children: [
            FItem(
              title: Text(
                'Truncate',
                style: TextStyle(color: theme.colors.destructive),
              ),
              prefix: Icon(
                Icons.delete_sweep_outlined,
                size: 14,
                color: theme.colors.destructive,
              ),
              onPress: () {
                controller.hide();
                final metadata = context.read<ConnectionMetadataCubit>();
                final connection = context
                    .read<ConnectionCubit>()
                    .state
                    .activeConnection;
                final database = metadata.state.selectedDatabase;
                if (connection == null || database == null) return;

                TableDestructiveActionDialog.show(
                  context,
                  connection: connection,
                  database: database,
                  schema: metadata.state.selectedSchema,
                  tableName: table.name,
                  actionType: DestructiveActionType.truncate,
                );
              },
            ),
            FItem(
              title: Text(
                'Drop',
                style: TextStyle(color: theme.colors.destructive),
              ),
              prefix: Icon(
                Icons.delete_outline,
                size: 14,
                color: theme.colors.destructive,
              ),
              onPress: () {
                controller.hide();
                final metadata = context.read<ConnectionMetadataCubit>();
                final connection = context
                    .read<ConnectionCubit>()
                    .state
                    .activeConnection;
                final database = metadata.state.selectedDatabase;
                if (connection == null || database == null) return;

                TableDestructiveActionDialog.show(
                  context,
                  connection: connection,
                  database: database,
                  schema: metadata.state.selectedSchema,
                  tableName: table.name,
                  actionType: DestructiveActionType.drop,
                );
              },
            ),
          ],
        ),
      ],
      child: Container(
        color: isSelected ? theme.colors.secondary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _open(context, pin: false),
                onDoubleTap: () => _open(context, pin: true),
                child: Row(
                  children: [
                    Icon(
                      table.type == ConnectionTableType.view
                          ? Icons.visibility_outlined
                          : Icons.table_chart_outlined,
                      size: 14,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        table.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isPinned) ...[
              const SizedBox(width: 4),
              Icon(Icons.push_pin, size: 14, color: theme.colors.primary),
            ],
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, {required bool pin, bool describe = false}) {
    final metadata = context.read<ConnectionMetadataCubit>();
    final connection = context.read<ConnectionCubit>().state.activeConnection;
    final database = metadata.state.selectedDatabase;
    final schema = metadata.state.selectedSchema;
    if (connection == null || database == null) return;

    metadata.selectTable(table);
    final tabs = context.read<EditorTabsCubit>();
    if (pin) {
      tabs.pinTable(
        connectionId: connection.id,
        database: database,
        schema: schema,
        table: table,
      );
    } else {
      tabs.openTablePreview(
        connectionId: connection.id,
        database: database,
        schema: schema,
        table: table,
      );
    }

    final key = TableTabKey(
      connectionId: connection.id,
      database: database,
      schema: schema,
      tableName: table.name,
    );
    unawaited(
      context.read<TableDataCubit>().openTable(connection, key).then((_) {
        if (!context.mounted) return;
        if (describe) {
          context.read<TableDataCubit>().showTableStructure(key);
        }
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final FThemeData theme;

  const _EmptyState({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: theme.colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
