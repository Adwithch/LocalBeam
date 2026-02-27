// lib/presentation/screens/home/widgets/peer_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../domain/entities/peer.dart';
import '../../../theme/app_theme.dart';

class PeerCard extends StatelessWidget {
  final Peer peer;
  final VoidCallback? onTap;

  const PeerCard({super.key, required this.peer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              // Platform icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _platformIcon(peer.platform),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${peer.address}:${peer.port}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceDim,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: peer.isReachable ? AppColors.success : AppColors.error,
                  boxShadow: [
                    BoxShadow(
                      color: (peer.isReachable ? AppColors.success : AppColors.error)
                          .withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.onSurfaceDim),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }

  IconData _platformIcon(String? platform) {
    switch (platform) {
      case 'android': return Icons.android_rounded;
      case 'ios': return Icons.apple;
      case 'macos': return Icons.laptop_mac_rounded;
      case 'windows': return Icons.window_rounded;
      case 'linux': return Icons.computer_rounded;
      default: return Icons.devices_rounded;
    }
  }
}

// lib/presentation/screens/home/widgets/quick_stats.dart

class QuickStats extends ConsumerWidget {
  const QuickStats({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final history = ref.watch(historyProvider);
    final totalFiles = history.fold(0, (sum, e) => sum + e.fileNames.length);
    final totalBytes = history.fold(0, (sum, e) => sum + e.totalBytes);

    return Row(
      children: [
        _StatCard(label: 'Transfers', value: history.length.toString(), icon: Icons.swap_horiz_rounded),
        const SizedBox(width: 12),
        _StatCard(label: 'Files Moved', value: totalFiles.toString(), icon: Icons.insert_drive_file_rounded),
        const SizedBox(width: 12),
        _StatCard(label: 'Data Sent', value: _fmt(totalBytes), icon: Icons.data_usage_rounded),
      ],
    );
  }

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/screens/home/widgets/active_transfer_banner.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';

class ActiveTransferBanner extends StatelessWidget {
  final List<TransferSessionUiState> transfers;
  const ActiveTransferBanner({super.key, required this.transfers});

  @override
  Widget build(BuildContext context) {
    final t = transfers.first;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/transfer', arguments: {'sessionId': t.id}),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.2), AppColors.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transfers.length} active transfer${transfers.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: t.progress,
                    backgroundColor: AppColors.outline,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
