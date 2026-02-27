// lib/presentation/screens/history/history_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/logger.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          if (history.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Export logs',
              onPressed: () => _exportLogs(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all',
              onPressed: () => _confirmClear(context, ref),
            ),
          ],
        ],
      ),
      body: history.isEmpty
          ? _EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (_, i) => _HistoryItem(
                entry: history[i],
                onDelete: () => ref.read(historyProvider.notifier).delete(history[i].id),
              ).animate(delay: Duration(milliseconds: i * 20)).slideY(begin: 0.1).fadeIn(),
            ),
    );
  }

  Future<void> _exportLogs(BuildContext context, WidgetRef ref) async {
    try {
      final logs = await ref.read(historyProvider.notifier).exportLogs();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/localbeam_transfer_log.txt');
      await file.writeAsString(logs);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LocalBeam Transfer Logs',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will delete all transfer records permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(historyProvider.notifier).clearAll();
    }
  }
}

class _HistoryItem extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onDelete;

  const _HistoryItem({required this.entry, required this.onDelete});

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(2)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSend = entry.direction == 'send';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isSend ? AppColors.primary : AppColors.secondary).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isSend ? Icons.upload_rounded : Icons.download_rounded,
            color: isSend ? AppColors.primary : AppColors.secondary,
            size: 20,
          ),
        ),
        title: Text(
          entry.fileNames.length == 1
              ? entry.fileNames.first
              : '${entry.fileNames.length} files',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${isSend ? "Sent to" : "Received from"} ${entry.peerName}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceDim),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmt(entry.totalBytes)} · ${_fmtDate(entry.date)}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.wasEncrypted)
              const Icon(Icons.lock_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Icon(
              entry.success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: entry.success ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(context),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Remove this transfer from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 72, color: AppColors.onSurfaceMuted)
              .animate()
              .fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'No transfers yet',
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.onSurfaceDim),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed transfers will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
