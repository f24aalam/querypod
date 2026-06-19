import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bgColor = theme.colors.secondary;
    final fgColor = theme.colors.secondaryForeground;
    final mutedColor = theme.colors.mutedForeground;

    return Container(
      height: 24,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: mutedColor),
          const SizedBox(width: 6),
          Text('Not Connected', style: TextStyle(fontSize: 11, color: fgColor)),
          const SizedBox(width: 16),
          Icon(Icons.dataset_outlined, size: 12, color: mutedColor),
          const SizedBox(width: 4),
          Text('No Database', style: TextStyle(fontSize: 11, color: fgColor)),
          const Spacer(),
          Text('0 rows', style: TextStyle(fontSize: 11, color: mutedColor)),
          const SizedBox(width: 16),
          Text('0ms', style: TextStyle(fontSize: 11, color: mutedColor)),
        ],
      ),
    );
  }
}
