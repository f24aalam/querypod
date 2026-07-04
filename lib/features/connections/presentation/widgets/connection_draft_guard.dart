import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/confirmation_dialog.dart';
import '../cubit/connection_editor_cubit.dart';

Future<bool> confirmDiscardConnectionDraft(BuildContext context) async {
  if (!context.read<ConnectionEditorCubit>().state.isDirty) return true;

  return showConfirmationDialog(
    context,
    title: 'Discard unsaved changes?',
    message: 'Your connection changes have not been saved.',
    confirmLabel: 'Discard',
    cancelLabel: 'Cancel',
    isDestructive: true,
    barrierDismissible: false,
  );
}
