import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ConnectionForm extends StatelessWidget {
  const ConnectionForm({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

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
                  'New Connection',
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
                            hint: 'Local Dev',
                            theme: theme,
                          ),
                          const SizedBox(height: 4),
                          _FormField(
                            label: 'Host',
                            hint: 'localhost',
                            theme: theme,
                          ),
                          const SizedBox(height: 4),
                          _FormField(label: 'Port', hint: '3306', theme: theme),
                          const SizedBox(height: 4),
                          _FormField(label: 'User', hint: 'root', theme: theme),
                          const SizedBox(height: 4),
                          _FormField(
                            label: 'Password',
                            hint: '••••••',
                            theme: theme,
                            obscure: true,
                          ),
                          const SizedBox(height: 4),
                          _FormField(
                            label: 'Database',
                            hint: 'mydb',
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              FButton(
                                variant: FButtonVariant.outline,
                                onPress: null,
                                child: const Text('Test Connection'),
                              ),
                              const SizedBox(width: 8),
                              FButton(onPress: null, child: const Text('Save')),
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
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final FThemeData theme;
  final bool obscure;

  const _FormField({
    required this.label,
    required this.hint,
    required this.theme,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: TextField(
            obscureText: obscure,
            style: TextStyle(fontSize: 13, color: theme.colors.foreground),
            cursorColor: theme.colors.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: theme.colors.mutedForeground,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              filled: true,
              fillColor: theme.colors.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.colors.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.colors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: theme.colors.primary, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
