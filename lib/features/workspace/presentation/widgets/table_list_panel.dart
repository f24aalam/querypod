import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../domain/entities/workspace_table.dart';
import '../cubit/workspace_metadata_cubit.dart';
import '../cubit/workspace_metadata_state.dart';

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

    return BlocListener<WorkspaceMetadataCubit, WorkspaceMetadataState>(
      listenWhen: (prev, curr) => prev.query != curr.query,
      listener: (context, state) {
        if (_searchController.text != state.query) {
          _searchController.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
      },
      child: BlocBuilder<WorkspaceMetadataCubit, WorkspaceMetadataState>(
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
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.colors.border, width: 1),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TABLES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
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
                            .read<WorkspaceMetadataCubit>()
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
  final WorkspaceMetadataState state;
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

    return ListView(
      padding: EdgeInsets.zero,
      children: state.filteredTables
          .map(
            (table) => _TableItem(
              table: table,
              isSelected: table.name == state.selectedTable?.name,
              theme: theme,
            ),
          )
          .toList(),
    );
  }
}

class _DatabasePicker extends StatelessWidget {
  final WorkspaceMetadataState state;
  final FThemeData theme;

  const _DatabasePicker({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final selectedConnection = context
        .read<ConnectionCubit>()
        .state
        .activeConnection;
    final items = {for (final db in state.databases) db.name: db.name};

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
            : FSelect<String>.search(
                items: items,
                size: FTextFieldSizeVariant.sm,
                hint: 'Select database',
                enabled: selectedConnection != null && items.isNotEmpty,
                clearable: false,
                searchFieldProperties: const FSelectSearchFieldProperties(
                  hint: 'Search databases...',
                ),
                contentConstraints: const FAutoWidthPortalConstraints(
                  maxHeight: 300,
                ),
                prefixBuilder: (context, fieldStyle, widget) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.storage_outlined,
                    size: 14,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                suffixBuilder: (context, fieldStyle, widget) => Padding(
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
                    context.read<WorkspaceMetadataCubit>().selectDatabase(
                      selectedConnection,
                      value,
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _TableItem extends StatelessWidget {
  final WorkspaceTable table;
  final bool isSelected;
  final FThemeData theme;

  const _TableItem({
    required this.table,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<WorkspaceMetadataCubit>().selectTable(table),
      child: Container(
        color: isSelected ? theme.colors.secondary : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              table.type == WorkspaceTableType.view
                  ? Icons.visibility_outlined
                  : Icons.table_chart_outlined,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                table.name,
                style: TextStyle(fontSize: 13, color: theme.colors.foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
