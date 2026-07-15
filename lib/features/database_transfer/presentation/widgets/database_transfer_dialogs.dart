import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/confirmation_dialog.dart';
import '../../../connections/domain/entities/connection.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../editor/presentation/cubit/connection_metadata_cubit.dart';
import '../../../editor/presentation/cubit/editor_tabs_cubit.dart';
import '../../domain/database_transfer.dart';
import '../cubit/database_transfer_cubit.dart';
import '../cubit/database_transfer_state.dart';

Future<void> showDatabaseImportFlow(BuildContext context) async {
  final selection = _activeSelection(context);
  if (selection == null) return;
  final file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: '${selection.connection.type.name} database files',
        extensions: _importExtensions(selection.connection.type),
      ),
    ],
    confirmButtonText: 'Import',
  );
  if (file == null || !context.mounted) return;

  final format = _detectFormat(selection.connection.type, file.path);
  if (format == null) {
    showFToast(
      context: context,
      variant: FToastVariant.destructive,
      title: const Text('The selected file is not supported for this database'),
    );
    return;
  }
  final forcedClean = format == DatabaseTransferFormat.sqliteDatabase;
  final mode = await showDialog<DatabaseRestoreMode>(
    context: context,
    builder: (_) => _ImportOptionsDialog(
      connection: selection.connection,
      database: selection.database,
      path: file.path,
      format: format,
      forcedClean: forcedClean,
    ),
  );
  if (mode == null || !context.mounted) return;
  if (mode == DatabaseRestoreMode.clean) {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Clean and restore database?',
      message:
          'All existing objects in "${selection.database}" will be removed before the import. This cannot be undone.',
      confirmLabel: 'Clean and Import',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
  }

  final request = DatabaseTransferRequest(
    direction: DatabaseTransferDirection.import,
    connection: selection.connection,
    database: selection.database,
    path: file.path,
    format: format,
    restoreMode: mode,
    gzip: file.path.toLowerCase().endsWith('.gz'),
  );
  await _runTransfer(context, request);
}

Future<void> showDatabaseExportFlow(BuildContext context) async {
  final selection = _activeSelection(context);
  if (selection == null) return;
  final options = await showDialog<_ExportOptions>(
    context: context,
    builder: (_) => _ExportOptionsDialog(
      connection: selection.connection,
      database: selection.database,
    ),
  );
  if (options == null || !context.mounted) return;

  final extension =
      '${options.format.defaultExtension}${options.gzip ? '.gz' : ''}';
  final safeDatabase = selection.database.replaceAll(
    RegExp(r'[^A-Za-z0-9_.-]'),
    '_',
  );
  final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final location = await getSaveLocation(
    suggestedName: '${safeDatabase}_$date.$extension',
    acceptedTypeGroups: [
      XTypeGroup(label: options.format.label, extensions: [extension]),
    ],
    confirmButtonText: 'Export',
  );
  if (location == null || !context.mounted) return;

  final request = DatabaseTransferRequest(
    direction: DatabaseTransferDirection.export,
    connection: selection.connection,
    database: selection.database,
    path: location.path,
    format: options.format,
    content: options.content,
    gzip: options.gzip,
  );
  await _runTransfer(context, request);
}

Future<void> _runTransfer(
  BuildContext context,
  DatabaseTransferRequest request,
) async {
  final succeeded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TransferProgressDialog(request: request),
  );
  if (succeeded != true || !context.mounted) return;
  context.read<EditorTabsCubit>().closeDatabaseTabs(
    connectionId: request.connection.id,
    database: request.database,
  );
  await context.read<ConnectionMetadataCubit>().refreshTables(
    request.connection,
    request.database,
  );
}

_ActiveDatabaseSelection? _activeSelection(BuildContext context) {
  final connection = context.read<ConnectionCubit>().state.activeConnection;
  final database = context
      .read<ConnectionMetadataCubit>()
      .state
      .selectedDatabase;
  if (connection == null || database == null) {
    showFToast(
      context: context,
      variant: FToastVariant.destructive,
      title: const Text('Select a connection and database first'),
    );
    return null;
  }
  return _ActiveDatabaseSelection(connection: connection, database: database);
}

class _ActiveDatabaseSelection {
  final Connection connection;
  final String database;
  const _ActiveDatabaseSelection({
    required this.connection,
    required this.database,
  });
}

class _ImportOptionsDialog extends StatefulWidget {
  final Connection connection;
  final String database;
  final String path;
  final DatabaseTransferFormat format;
  final bool forcedClean;

  const _ImportOptionsDialog({
    required this.connection,
    required this.database,
    required this.path,
    required this.format,
    required this.forcedClean,
  });

  @override
  State<_ImportOptionsDialog> createState() => _ImportOptionsDialogState();
}

class _ImportOptionsDialogState extends State<_ImportOptionsDialog> {
  late DatabaseRestoreMode _mode = widget.forcedClean
      ? DatabaseRestoreMode.clean
      : DatabaseRestoreMode.merge;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Database'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TransferDetail(label: 'Connection', value: widget.connection.name),
            _TransferDetail(label: 'Database', value: widget.database),
            _TransferDetail(label: 'File', value: widget.path),
            _TransferDetail(label: 'Format', value: widget.format.label),
            const SizedBox(height: 18),
            DropdownButtonFormField<DatabaseRestoreMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Restore mode'),
              items: [
                if (!widget.forcedClean)
                  const DropdownMenuItem(
                    value: DatabaseRestoreMode.merge,
                    child: Text('Restore into current state'),
                  ),
                const DropdownMenuItem(
                  value: DatabaseRestoreMode.clean,
                  child: Text('Clean target first'),
                ),
              ],
              onChanged: widget.forcedClean
                  ? null
                  : (value) => setState(() => _mode = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _mode),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ExportOptionsDialog extends StatefulWidget {
  final Connection connection;
  final String database;

  const _ExportOptionsDialog({
    required this.connection,
    required this.database,
  });

  @override
  State<_ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<_ExportOptionsDialog> {
  late final List<DatabaseTransferFormat> _formats = _exportFormats(
    widget.connection.type,
  );
  late DatabaseTransferFormat _format = _formats.first;
  DatabaseTransferContent _content = DatabaseTransferContent.full;
  bool _gzip = false;

  @override
  Widget build(BuildContext context) {
    final binarySqlite = _format == DatabaseTransferFormat.sqliteDatabase;
    return AlertDialog(
      title: const Text('Export Database'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TransferDetail(label: 'Connection', value: widget.connection.name),
            _TransferDetail(label: 'Database', value: widget.database),
            const SizedBox(height: 18),
            DropdownButtonFormField<DatabaseTransferFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: _formats
                  .map(
                    (format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.label),
                    ),
                  )
                  .toList(),
              onChanged: (format) => setState(() {
                _format = format!;
                if (!_format.isPlainSql) _gzip = false;
                if (_format == DatabaseTransferFormat.sqliteDatabase) {
                  _content = DatabaseTransferContent.full;
                }
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DatabaseTransferContent>(
              initialValue: _content,
              decoration: const InputDecoration(labelText: 'Content'),
              items: const [
                DropdownMenuItem(
                  value: DatabaseTransferContent.full,
                  child: Text('Schema and data'),
                ),
                DropdownMenuItem(
                  value: DatabaseTransferContent.schemaOnly,
                  child: Text('Schema only'),
                ),
                DropdownMenuItem(
                  value: DatabaseTransferContent.dataOnly,
                  child: Text('Data only'),
                ),
              ],
              onChanged: binarySqlite
                  ? null
                  : (content) => setState(() => _content = content!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compress plain SQL with gzip'),
              value: _gzip,
              onChanged: _format.isPlainSql
                  ? (value) => setState(() => _gzip = value)
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ExportOptions(format: _format, content: _content, gzip: _gzip),
          ),
          child: const Text('Choose Destination'),
        ),
      ],
    );
  }
}

class _TransferProgressDialog extends StatefulWidget {
  final DatabaseTransferRequest request;
  const _TransferProgressDialog({required this.request});

  @override
  State<_TransferProgressDialog> createState() =>
      _TransferProgressDialogState();
}

class _TransferProgressDialogState extends State<_TransferProgressDialog> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<DatabaseTransferCubit>();
    cubit.reset();
    unawaited(cubit.start(widget.request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTransferCubit, DatabaseTransferState>(
      builder: (context, state) {
        final title =
            widget.request.direction == DatabaseTransferDirection.import
            ? 'Import Database'
            : 'Export Database';
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 620,
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (state.isRunning) ...[
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        state.phase,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: state.logs.isEmpty
                        ? Text(
                            state.isRunning
                                ? 'Waiting for tool output...'
                                : state.status == DatabaseTransferStatus.success
                                ? 'Operation completed without additional tool output.'
                                : 'No tool output was produced.',
                          )
                        : SingleChildScrollView(
                            reverse: true,
                            child: SelectableText(
                              state.logs.join('\n'),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ),
                ),
                if (state.duration != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${state.duration!.inMilliseconds} ms${state.bytes == null ? '' : ', ${state.bytes} bytes'}',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (state.isRunning)
              TextButton(
                onPressed: context.read<DatabaseTransferCubit>().cancel,
                child: const Text('Cancel'),
              )
            else
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  state.status == DatabaseTransferStatus.success,
                ),
                child: const Text('Close'),
              ),
          ],
        );
      },
    );
  }
}

class _TransferDetail extends StatelessWidget {
  final String label;
  final String value;
  const _TransferDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class _ExportOptions {
  final DatabaseTransferFormat format;
  final DatabaseTransferContent content;
  final bool gzip;
  const _ExportOptions({
    required this.format,
    required this.content,
    required this.gzip,
  });
}

List<String> _importExtensions(ConnectionType type) => switch (type) {
  ConnectionType.mysql => ['sql', 'gz'],
  ConnectionType.postgresql => ['sql', 'gz', 'dump', 'backup', 'tar'],
  ConnectionType.sqlite => ['sql', 'gz', 'db', 'sqlite', 'sqlite3'],
};

List<DatabaseTransferFormat> _exportFormats(ConnectionType type) =>
    switch (type) {
      ConnectionType.mysql => [DatabaseTransferFormat.mysqlSql],
      ConnectionType.postgresql => [
        DatabaseTransferFormat.postgresCustom,
        DatabaseTransferFormat.postgresPlain,
        DatabaseTransferFormat.postgresTar,
      ],
      ConnectionType.sqlite => [
        DatabaseTransferFormat.sqliteDatabase,
        DatabaseTransferFormat.sqliteSql,
      ],
    };

DatabaseTransferFormat? _detectFormat(ConnectionType type, String path) {
  final lower = path.toLowerCase();
  return switch (type) {
    ConnectionType.mysql =>
      lower.endsWith('.sql') || lower.endsWith('.sql.gz')
          ? DatabaseTransferFormat.mysqlSql
          : null,
    ConnectionType.postgresql =>
      lower.endsWith('.sql') || lower.endsWith('.sql.gz')
          ? DatabaseTransferFormat.postgresPlain
          : lower.endsWith('.tar')
          ? DatabaseTransferFormat.postgresTar
          : lower.endsWith('.dump') || lower.endsWith('.backup')
          ? DatabaseTransferFormat.postgresCustom
          : null,
    ConnectionType.sqlite =>
      lower.endsWith('.sql') || lower.endsWith('.sql.gz')
          ? DatabaseTransferFormat.sqliteSql
          : lower.endsWith('.db') ||
                lower.endsWith('.sqlite') ||
                lower.endsWith('.sqlite3')
          ? DatabaseTransferFormat.sqliteDatabase
          : null,
  };
}
