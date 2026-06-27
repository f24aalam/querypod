import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/entities/connection.dart';

import '../../../workspace/presentation/cubit/editor_tabs_cubit.dart';
import '../cubit/connection_cubit.dart';
import '../cubit/connection_editor_cubit.dart';
import '../cubit/connection_editor_state.dart';
import '../cubit/connection_state.dart';

class ConnectionForm extends StatelessWidget {
  const ConnectionForm({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocListener<ConnectionCubit, ConnectionsState>(
      listenWhen: (prev, curr) =>
          prev.feedbackNonce != curr.feedbackNonce &&
          curr.feedbackMessage != null,
      listener: (context, state) {
        showFToast(
          context: context,
          variant: state.feedbackIsError
              ? FToastVariant.destructive
              : FToastVariant.primary,
          title: Text(state.feedbackMessage!),
        );
      },
      child: BlocBuilder<ConnectionCubit, ConnectionsState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, connectionState) {
          return BlocBuilder<ConnectionEditorCubit, ConnectionEditorState>(
            builder: (context, editorState) {
              final draft = editorState.draft;
              final editor = context.read<ConnectionEditorCubit>();

              return Container(
                color: theme.colors.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            editorState.isNew
                                ? Icons.add_outlined
                                : Icons.edit_outlined,
                            size: 14,
                            color: theme.colors.foreground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            editorState.isNew
                                ? 'New Connection'
                                : 'Edit Connection',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Material(
                            color: Colors.transparent,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colors.card,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FormField(
                                      label: 'Name',
                                      value: draft.name,
                                      onChanged: editor.updateName,
                                    ),
                                    const SizedBox(height: 16),
                                    FSelect<ConnectionType>(
                                      label: const Text('Connection Type'),
                                      control: FSelectControl.lifted(
                                        value: draft.type,
                                        onChange: (value) {
                                          if (value != null) {
                                            editor.updateType(value);
                                          }
                                        },
                                      ),
                                      items: const {
                                        'MySQL': ConnectionType.mysql,
                                        'PostgreSQL': ConnectionType.postgresql,
                                        'SQLite': ConnectionType.sqlite,
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (draft.type == ConnectionType.mysql ||
                                        draft.type == ConnectionType.postgresql) ...[
                                      _FormField(
                                        label: 'Host',
                                        value: draft.host,
                                        onChanged: editor.updateHost,
                                      ),
                                      const SizedBox(height: 12),
                                      _FormField(
                                        label: 'Port',
                                        value: draft.port,
                                        onChanged: editor.updatePort,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 12),
                                      _FormField(
                                        label: 'User',
                                        value: draft.user,
                                        onChanged: editor.updateUser,
                                      ),
                                      const SizedBox(height: 12),
                                      _FormField(
                                        label: 'Password',
                                        value: draft.password,
                                        onChanged: editor.updatePassword,
                                        obscure: true,
                                        optional: true,
                                      ),
                                      const SizedBox(height: 12),
                                      _FormField(
                                        label: 'Database',
                                        value: draft.database,
                                        onChanged: editor.updateDatabase,
                                        optional: true,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Use TLS',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme
                                                        .colors
                                                        .foreground,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Encrypt the database connection. Recommended.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme
                                                        .colors
                                                        .mutedForeground,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FSwitch(
                                            value: draft.useTls,
                                            onChange: editor.updateUseTls,
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: _FormField(
                                              label: 'Database File Path',
                                              value: draft.database,
                                              onChanged: editor.updateDatabase,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: FButton.icon(
                                              onPress: () async {
                                                const typeGroup = XTypeGroup(
                                                  label: 'SQLite Databases',
                                                  extensions: <String>[
                                                    'sqlite',
                                                    'db',
                                                    'sqlite3',
                                                  ],
                                                );
                                                final file = await openFile(
                                                  acceptedTypeGroups: <XTypeGroup>[
                                                    typeGroup,
                                                  ],
                                                );
                                                if (file != null) {
                                                  editor.updateDatabase(file.path);
                                                }
                                              },
                                              child: const Icon(Icons.folder_open),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        FButton(
                                          variant: FButtonVariant.outline,
                                          onPress:
                                              connectionState.status ==
                                                  ConnectionStatus.testing
                                              ? null
                                              : () => context
                                                    .read<ConnectionCubit>()
                                                    .test(draft.toConnection()),
                                          child: Text(
                                            connectionState.status ==
                                                    ConnectionStatus.testing
                                                ? 'Testing...'
                                                : 'Test',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FButton(
                                          onPress:
                                              connectionState.status ==
                                                  ConnectionStatus.saving
                                              ? null
                                              : () => _save(context, draft),
                                          child: Text(
                                            connectionState.status ==
                                                    ConnectionStatus.saving
                                                ? 'Saving...'
                                                : 'Save',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context, ConnectionDraft draft) async {
    final connection = draft.toConnection();
    final saved = await context.read<ConnectionCubit>().save(connection);
    if (!context.mounted || !saved) return;

    context.read<ConnectionEditorCubit>().markSaved(connection);
    context.read<EditorTabsCubit>().syncConnectionEditor(
      connectionId: connection.id,
      connectionName: connection.name,
    );
  }
}

class _FormField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool optional;

  const _FormField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.obscure = false,
    this.keyboardType,
    this.optional = false,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _FormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.value) return;
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final control = FTextFieldControl.managed(
      controller: _controller,
      onChange: (value) => widget.onChanged(value.text),
    );

    if (widget.obscure) {
      return FTextField.password(
        control: control,
        label: Text(
          widget.optional ? '${widget.label} (optional)' : widget.label,
        ),
        keyboardType: widget.keyboardType,
      );
    }

    return FTextField(
      control: control,
      label: Text(
        widget.optional ? '${widget.label} (optional)' : widget.label,
      ),
      keyboardType: widget.keyboardType,
    );
  }
}
