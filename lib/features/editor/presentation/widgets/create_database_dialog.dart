import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../cubit/connection_metadata_cubit.dart';

class CreateDatabaseDialog extends StatefulWidget {
  final Connection connection;

  const CreateDatabaseDialog({required this.connection, super.key});

  static void show(BuildContext context, Connection connection) {
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => BlocProvider.value(
        value: context.read<ConnectionMetadataCubit>(),
        child: _CreateDatabaseDialogBody(
          animation: animation,
          connection: connection,
        ),
      ),
    );
  }

  @override
  State<CreateDatabaseDialog> createState() => _CreateDatabaseDialogState();
}

class _CreateDatabaseDialogState extends State<CreateDatabaseDialog> {
  @override
  Widget build(BuildContext context) {
    // Delegate to the static show method pattern
    // This widget exists so it can be used as a simple constructor call too.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CreateDatabaseDialog.show(context, widget.connection);
        Navigator.of(context).pop();
      }
    });
    return const SizedBox.shrink();
  }
}

class _CreateDatabaseDialogBody extends StatefulWidget {
  final Animation<double> animation;
  final Connection connection;

  const _CreateDatabaseDialogBody({
    required this.animation,
    required this.connection,
  });

  @override
  State<_CreateDatabaseDialogBody> createState() =>
      _CreateDatabaseDialogBodyState();
}

class _CreateDatabaseDialogBodyState extends State<_CreateDatabaseDialogBody> {
  final _nameController = TextEditingController();
  final _charsetController = TextEditingController();
  final _collationController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _charsetController.dispose();
    _collationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Database name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final charset = _charsetController.text.trim();
      final collation = _collationController.text.trim();

      await context.read<ConnectionMetadataCubit>().createDatabase(
        widget.connection,
        name,
        charset: charset.isNotEmpty ? charset : null,
        collation: collation.isNotEmpty ? collation : null,
      );

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

    return FDialog(
      animation: widget.animation,
      direction: Axis.horizontal,
      title: const Text('Create Database'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FTextField(
            autofocus: true,
            enabled: !_isLoading,
            control: FTextFieldControl.managed(
              controller: _nameController,
              onChange: (_) {},
            ),
            label: const Text('Database Name'),
            hint: 'my_database',
          ),
          const SizedBox(height: 16),
          FTextField(
            enabled: !_isLoading,
            control: FTextFieldControl.managed(
              controller: _charsetController,
              onChange: (_) {},
            ),
            label: const Text('Charset (Optional)'),
            hint: widget.connection.type == ConnectionType.postgresql
                ? 'e.g., UTF8'
                : 'e.g., utf8mb4',
          ),
          const SizedBox(height: 16),
          FTextField(
            enabled: !_isLoading,
            control: FTextFieldControl.managed(
              controller: _collationController,
              onChange: (_) {},
            ),
            label: const Text('Collation (Optional)'),
            hint: widget.connection.type == ConnectionType.postgresql
                ? 'e.g., en_US.UTF-8'
                : 'e.g., utf8mb4_unicode_ci',
          ),
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
          onPress: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
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
