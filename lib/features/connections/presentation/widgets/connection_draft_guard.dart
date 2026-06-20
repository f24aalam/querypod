import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../cubit/connection_editor_cubit.dart';

Future<bool> confirmDiscardConnectionDraft(BuildContext context) async {
  if (!context.read<ConnectionEditorCubit>().state.isDirty) return true;

  return await showFDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context, style, animation) => Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discard unsaved changes?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your connection changes have not been saved.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ) ??
      false;
}
