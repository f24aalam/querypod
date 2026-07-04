import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  return await showFDialog<bool>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext, style, animation) => FDialog(
          animation: animation,
          direction: Axis.horizontal,
          title: Text(title),
          body: Text(message),
          actions: [
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FButton(
              variant: isDestructive
                  ? FButtonVariant.destructive
                  : FButtonVariant.primary,
              onPress: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
