import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/domain/entities/connection.dart';
import '../cubit/connection_metadata_cubit.dart';

class CreateSchemaDialog extends StatefulWidget {
  final Connection connection;
  final String database;

  const CreateSchemaDialog({
    required this.connection,
    required this.database,
    super.key,
  });

  static void show(
    BuildContext context, {
    required Connection connection,
    required String database,
  }) {
    showFDialog(
      context: context,
      builder: (dialogContext, style, animation) => BlocProvider.value(
        value: context.read<ConnectionMetadataCubit>(),
        child: _CreateSchemaDialogBody(
          animation: animation,
          connection: connection,
          database: database,
        ),
      ),
    );
  }

  @override
  State<CreateSchemaDialog> createState() => _CreateSchemaDialogState();
}

class _CreateSchemaDialogState extends State<CreateSchemaDialog> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CreateSchemaDialog.show(
          context,
          connection: widget.connection,
          database: widget.database,
        );
        Navigator.of(context).pop();
      }
    });
    return const SizedBox.shrink();
  }
}

class _CreateSchemaDialogBody extends StatefulWidget {
  final Animation<double> animation;
  final Connection connection;
  final String database;

  const _CreateSchemaDialogBody({
    required this.animation,
    required this.connection,
    required this.database,
  });

  @override
  State<_CreateSchemaDialogBody> createState() =>
      _CreateSchemaDialogBodyState();
}

class _CreateSchemaDialogBodyState extends State<_CreateSchemaDialogBody> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Schema name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<ConnectionMetadataCubit>().createSchema(
        widget.connection,
        widget.database,
        name,
      );
      if (mounted) Navigator.of(context).pop();
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
      title: const Text('Create Schema'),
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
            label: const Text('Schema Name'),
            hint: 'analytics',
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colors.destructive, fontSize: 13),
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
