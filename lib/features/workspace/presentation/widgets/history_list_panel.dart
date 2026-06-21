import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../domain/entities/query_history.dart';
import '../../domain/repositories/query_history_repository.dart';
import 'package:intl/intl.dart';

import '../../../../app/injection.dart';

class HistoryListPanel extends StatefulWidget {
  const HistoryListPanel({super.key});

  @override
  State<HistoryListPanel> createState() => _HistoryListPanelState();
}

class _HistoryListPanelState extends State<HistoryListPanel> {
  final _repository = getIt<QueryHistoryRepository>();
  List<QueryHistory>? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final connection = context.read<ConnectionCubit>().state.activeConnection;
    if (connection == null) return;

    try {
      final history = await _repository.getAllForConnection(connection.id);
      if (mounted) {
        setState(() {
          _history = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final connection = context.read<ConnectionCubit>().state.activeConnection;
    if (connection == null) return;

    try {
      await _repository.clearHistory(connection.id);
      if (mounted) {
        setState(() {
          _history = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (_error != null) {
      return Center(
        child: Text(
          'Error loading history: $_error',
          style: TextStyle(color: theme.colors.destructive),
        ),
      );
    }

    if (_history == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history!.isEmpty) {
      return Center(
        child: Text(
          'No query history available.',
          style: TextStyle(color: theme.colors.mutedForeground),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_history!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _clearHistory,
                child: Text(
                  'Clear History',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colors.destructive,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _history!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = _history![index];
              final isError = item.status == 'error';
              final dateFormat = DateFormat('MMM d, h:mm a');

              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isError
                      ? theme.colors.destructive.withAlpha(13)
                      : theme.colors.secondary,
                  border: Border.all(
                    color: isError
                        ? theme.colors.destructive
                        : theme.colors.border,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.sourceType == 'table'
                                  ? Icons.table_chart_outlined
                                  : Icons.code_outlined,
                              size: 12,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.sourceType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          dateFormat.format(item.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.sql,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                    if (isError && item.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.errorMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colors.destructive,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
