import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../domain/entities/connection.dart';
import '../cubit/connection_cubit.dart';
import '../cubit/connection_state.dart';

class ConnectionForm extends StatefulWidget {
  const ConnectionForm({super.key});

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _databaseController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _fillForm(context.read<ConnectionCubit>().state.selectedConnection);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  void _fillForm(Connection? connection) {
    _nameController.text = connection?.name ?? '';
    _hostController.text = connection?.host ?? '';
    _portController.text = connection?.port.toString() ?? '';
    _userController.text = connection?.user ?? '';
    _passwordController.text = connection?.password ?? '';
    _databaseController.text = connection?.database ?? '';
  }

  Connection _buildConnection() {
    final selectedConnection = context
        .read<ConnectionCubit>()
        .state
        .selectedConnection;
    return Connection(
      id: selectedConnection?.id ?? Connection.generateId(),
      name: _nameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 3306,
      user: _userController.text,
      password: _passwordController.text,
      database: _databaseController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectionCubit, ConnectionsState>(
          listenWhen: (prev, curr) =>
              prev.selectionNonce != curr.selectionNonce,
          listener: (context, state) {
            _fillForm(state.selectedConnection);
          },
        ),
        BlocListener<ConnectionCubit, ConnectionsState>(
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
        ),
      ],
      child: BlocBuilder<ConnectionCubit, ConnectionsState>(
        builder: (context, state) {
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
                      bottom: BorderSide(color: theme.colors.border, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_outlined,
                        size: 14,
                        color: theme.colors.foreground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.selectedId != null
                            ? 'Edit Connection'
                            : 'New Connection',
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
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 12),
                                _FormField(
                                  label: 'Host',
                                  controller: _hostController,
                                ),
                                const SizedBox(height: 12),
                                _FormField(
                                  label: 'Port',
                                  controller: _portController,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 12),
                                _FormField(
                                  label: 'User',
                                  controller: _userController,
                                ),
                                const SizedBox(height: 12),
                                _FormField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  obscure: true,
                                  optional: true,
                                ),
                                const SizedBox(height: 12),
                                _FormField(
                                  label: 'Database',
                                  controller: _databaseController,
                                  optional: true,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    FButton(
                                      variant: FButtonVariant.outline,
                                      onPress:
                                          state.status ==
                                              ConnectionStatus.testing
                                          ? null
                                          : () => context
                                                .read<ConnectionCubit>()
                                                .test(_buildConnection()),
                                      child: Text(
                                        state.status == ConnectionStatus.testing
                                            ? 'Testing...'
                                            : 'Test',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FButton(
                                      onPress:
                                          state.status ==
                                              ConnectionStatus.saving
                                          ? null
                                          : () => context
                                                .read<ConnectionCubit>()
                                                .save(_buildConnection()),
                                      child: Text(
                                        state.status == ConnectionStatus.saving
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
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool optional;

  const _FormField({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    if (obscure) {
      return FTextField.password(
        control: FTextFieldControl.managed(controller: controller),
        label: Text(optional ? '$label (optional)' : label),
        keyboardType: keyboardType,
      );
    } else {
      return FTextField(
        control: FTextFieldControl.managed(controller: controller),
        label: Text(optional ? '$label (optional)' : label),
        keyboardType: keyboardType,
      );
    }
  }
}
