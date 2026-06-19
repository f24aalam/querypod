import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../../connections/presentation/cubit/connection_state.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bgColor = theme.colors.secondary;
    final fgColor = theme.colors.secondaryForeground;
    final mutedColor = theme.colors.mutedForeground;

    return BlocBuilder<ConnectionCubit, ConnectionsState>(
      buildWhen: (prev, curr) => prev.selectedId != curr.selectedId,
      builder: (context, state) {
        final connection = state.selectedConnection;
        final isConnected = connection != null;
        const connectedColor = Color(0xFF22C55E);

        return Container(
          height: 24,
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: isConnected ? connectedColor : mutedColor,
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? connection.name : 'Not Connected',
                style: TextStyle(
                  fontSize: 11,
                  color: isConnected ? connectedColor : fgColor,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.dataset_outlined, size: 12, color: mutedColor),
              const SizedBox(width: 4),
              Text(
                isConnected && connection.database.isNotEmpty
                    ? connection.database
                    : 'No Database',
                style: TextStyle(fontSize: 11, color: fgColor),
              ),
              const Spacer(),
              Text('0 rows', style: TextStyle(fontSize: 11, color: mutedColor)),
              const SizedBox(width: 16),
              Text('0ms', style: TextStyle(fontSize: 11, color: mutedColor)),
            ],
          ),
        );
      },
    );
  }
}
