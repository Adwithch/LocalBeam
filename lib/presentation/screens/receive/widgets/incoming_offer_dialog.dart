// lib/presentation/screens/receive/widgets/incoming_offer_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/beam_button.dart';

class IncomingOfferDialog extends StatelessWidget {
  final TransferOfferEvent event;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingOfferDialog({
    super.key,
    required this.event,
    required this.onAccept,
    required this.onReject,
  });

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Incoming Transfer')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender
          _InfoRow(label: 'From', value: event.peerName),
          const SizedBox(height: 8),
          _InfoRow(label: 'Size', value: _fmt(event.totalBytes)),
          const SizedBox(height: 8),
          _InfoRow(label: 'Files', value: '${event.fileNames.length}'),

          if (event.encrypted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Encrypted',
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // File names
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: event.fileNames
                  .take(5)
                  .map((name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_rounded,
                                size: 13, color: AppColors.onSurfaceDim),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList()
                ..addAll(event.fileNames.length > 5
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+ ${event.fileNames.length - 5} more files...',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.onSurfaceMuted),
                          ),
                        )
                      ]
                    : []),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            onReject();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onAccept();
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
