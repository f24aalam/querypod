import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../cubit/editor_tabs_cubit.dart';
import '../cubit/editor_tabs_state.dart';
import '../cubit/table_data_cubit.dart';
import '../cubit/connection_metadata_cubit.dart';

enum DestructiveActionType { drop, truncate }

class TableDestructiveActionDialog extends StatefulWidget {
  final Connection connection;
  final String database;
  final String tableName;
  final DestructiveActionType actionType;

  const TableDestructiveActionDialog({
    required this.connection,
    required this.database,
    required this.tableName,
    required this.actionType,
    super.key,
  });

  static void show(
    BuildContext context, {
    required Connection connection,
    required String database,
    required String tableName,
    required DestructiveActionType actionType,
  }) {
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ConnectionMetadataCubit>()),
          BlocProvider.value(value: context.read<TableDataCubit>()),
          BlocProvider.value(value: context.read<EditorTabsCubit>()),
        ],
        child: _TableDestructiveActionDialogBody(
          animation: animation,
          connection: connection,
          database: database,
          tableName: tableName,
          actionType: actionType,
        ),
      ),
    );
  }

  @override
  State<TableDestructiveActionDialog> createState() =>
      _TableDestructiveActionDialogState();
}

class _TableDestructiveActionDialogState
    extends State<TableDestructiveActionDialog> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TableDestructiveActionDialog.show(
          context,
          connection: widget.connection,
          database: widget.database,
          tableName: widget.tableName,
          actionType: widget.actionType,
        );
        Navigator.of(context).pop();
      }
    });
    return const SizedBox.shrink();
  }
}

class _TableDestructiveActionDialogBody extends StatefulWidget {
  final Animation<double> animation;
  final Connection connection;
  final String database;
  final String tableName;
  final DestructiveActionType actionType;

  const _TableDestructiveActionDialogBody({
    required this.animation,
    required this.connection,
    required this.database,
    required this.tableName,
    required this.actionType,
  });

  @override
  State<_TableDestructiveActionDialogBody> createState() =>
      _TableDestructiveActionDialogBodyState();
}

class _TableDestructiveActionDialogBodyState
    extends State<_TableDestructiveActionDialogBody> {
  final _tableNameController = TextEditingController();
  bool _force = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tableNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isLoading) return false;
    if (_force && _tableNameController.text != widget.tableName) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.actionType == DestructiveActionType.drop) {
        await context.read<ConnectionMetadataCubit>().dropTable(
              widget.connection,
              widget.database,
              widget.tableName,
              cascade: _force,
            );
        if (mounted) {
          context.read<EditorTabsCubit>().closeTab(
                TableTabKey(
                  connectionId: widget.connection.id,
                  database: widget.database,
                  tableName: widget.tableName,
                ),
              );
        }
      } else {
        await context.read<ConnectionMetadataCubit>().truncateTable(
              widget.connection,
              widget.database,
              widget.tableName,
              cascade: _force,
            );
        if (mounted) {
          context.read<TableDataCubit>().refresh(
                TableTabKey(
                  connectionId: widget.connection.id,
                  database: widget.database,
                  tableName: widget.tableName,
                ),
              );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final actionName =
        widget.actionType == DestructiveActionType.drop ? 'Drop' : 'Truncate';

    return FDialog(
      animation: widget.animation,
      direction: Axis.horizontal,
      title: Text('$actionName Table'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to ${actionName.toLowerCase()} the table "${widget.tableName}"? This action cannot be undone.',
            style: TextStyle(color: theme.colors.foreground, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // We use a custom row for the checkbox because FCheckbox doesn't seem to have a standard component from the snippet
          GestureDetector(
            onTap: () {
              setState(() {
                _force = !_force;
                if (!_force) {
                  _tableNameController.clear();
                }
              });
            },
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _force ? theme.colors.primary : theme.colors.border,
                      width: 1,
                    ),
                    color: _force ? theme.colors.primary : Colors.transparent,
                  ),
                  child: _force
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: theme.colors.primaryForeground,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Force (cascade/ignore foreign keys)',
                  style: TextStyle(
                    color: theme.colors.foreground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_force) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.colors.destructive.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'WARNING: Forcing this action might break data integrity and remove dependent records.',
                style: TextStyle(
                  color: theme.colors.destructive,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please type "${widget.tableName}" to confirm:',
              style: TextStyle(color: theme.colors.foreground, fontSize: 13),
            ),
            const SizedBox(height: 8),
            FTextField(
              autofocus: true,
              enabled: !_isLoading,
              control: FTextFieldControl.managed(
                controller: _tableNameController,
                onChange: (_) {
                  setState(() {});
                },
              ),
              hint: widget.tableName,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: theme.colors.destructive,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actions: [
        FButton(
          onPress: _canSubmit ? _submit : null,
          variant: FButtonVariant.destructive,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(actionName),
        ),
        FButton(
          onPress: _isLoading ? null : () => Navigator.of(context).pop(),
          variant: FButtonVariant.outline,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
