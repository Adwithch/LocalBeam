// lib/presentation/screens/transfer/transfer_screen.dart
// Shows active transfer progress, file list, speed, ETA.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/peer.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';
import '../../widgets/beam_button.dart' show StatusBadge;

class TransferScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? args;

  const TransferScreen({super.key, this.args});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _log = AppLogger('TransferScreen');
  String? _sessionId;
  List<String>? _filePaths;
  Peer? _targetPeer;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.args?['sessionId'] as String?;
    _filePaths = (widget.args?['filePaths'] as List?)?.cast<String>();

    if (_sessionId == null && _filePaths != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPeerSelector());
    }
  }

  void _showPeerSelector() async {
    final peers = ref.read(peersProvider).valueOrNull ?? [];
    if (peers.isEmpty) {
      _showNoPeers();
      return;
    }

    final selected = await showModalBottomSheet<Peer>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PeerSelector(peers: peers),
    );

    if (selected != null && mounted) {
      setState(() => _targetPeer = selected);
      await _startTransfer(selected);
    }
  }

  Future<void> _startTransfer(Peer peer) async {
    if (_filePaths == null) return;
    setState(() => _starting = true);

    try {
      final manager = ref.read(transferManagerProvider);
      final id = await manager.sendFiles(
        peer: peer,
        filePaths: _filePaths!,
      );

      // Register in active transfers UI
      ref.read(activeTransfersProvider.notifier).addOutgoing(
        id,
        fileNames: _filePaths!.map((p) => p.split('/').last).toList(),
        total: await _computeTotal(_filePaths!),
        peerName: peer.name,
      );

      if (mounted) setState(() => _sessionId = id);
    } catch (e) {
      _log.error('Start transfer failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start transfer: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _showNoPeers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No nearby devices found. Are they on the same network?')),
    );
  }

  Future<int> _computeTotal(List<String> paths) async {
    int total = 0;
    for (final path in paths) {
      try {
        total += await File(path).length();
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final activeTransfers = ref.watch(activeTransfersProvider);
    final session = _sessionId != null ? activeTransfers[_sessionId] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (session?.status == 'inProgress') {
              _showCancelDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _starting
          ? const Center(child: CircularProgressIndicator())
          : session == null
              ? _WaitingState(onPickPeer: _showPeerSelector)
              : _TransferProgress(session: session),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Transfer?'),
        content: const Text('The transfer will be aborted and the receiver will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_sessionId != null) {
                ref.read(transferManagerProvider).cancelTransfer(_sessionId!);
              }
              Navigator.pop(context);
            },
            child: const Text('Cancel Transfer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Transfer progress ─────────────────────────────────────────────────────

class _TransferProgress extends StatelessWidget {
  final TransferSessionUiState session;

  const _TransferProgress({required this.session});

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)}MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)}GB';
  }

  String _fmtSpeed(double bps) {
    return '${_fmt(bps.toInt())}/s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = session.status == 'completed';
    final isFailed = session.status == 'failed';
    final isCancelled = session.status == 'cancelled';

    final statusColor = isFailed
        ? AppColors.error
        : isCancelled
            ? AppColors.warning
            : isComplete
                ? AppColors.success
                : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Circular progress
          CircularPercentIndicator(
            radius: 90,
            lineWidth: 10,
            percent: session.progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(session.progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (session.speedBps > 0)
                  Text(
                    _fmtSpeed(session.speedBps),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceDim,
                    ),
                  ),
              ],
            ),
            progressColor: statusColor,
            backgroundColor: AppColors.surfaceContainerHigh,
            animation: true,
            animateFromLastPercent: true,
            circularStrokeCap: CircularStrokeCap.round,
          )
              .animate()
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 700.ms),

          const SizedBox(height: 32),

          // Status
          StatusBadge(
            label: session.status.toUpperCase(),
            color: statusColor,
            icon: isComplete ? Icons.check_rounded : null,
          ),

          const SizedBox(height: 8),

          if (session.peerName != null)
            Text(
              isComplete
                  ? 'Transfer complete!'
                  : isFailed
                      ? session.errorMessage ?? 'Transfer failed'
                      : 'Sending to ${session.peerName}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'Sent', value: _fmt(session.transferred)),
              _Stat(label: 'Total', value: _fmt(session.total)),
              _Stat(
                label: 'Files',
                value: '${session.currentFileIndex + 1}/${session.totalFiles}',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // File list
          if (session.fileNames.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FILES',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.onSurfaceDim, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 10),
            ...session.fileNames.asMap().entries.map((entry) {
              final i = entry.key;
              final name = entry.value;
              final isCurrent = i == session.currentFileIndex && !isComplete;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary.withOpacity(0.5) : AppColors.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      i < session.currentFileIndex || isComplete
                          ? Icons.check_rounded
                          : isCurrent
                              ? Icons.upload_rounded
                              : Icons.schedule_rounded,
                      size: 16,
                      color: i < session.currentFileIndex || isComplete
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.primary
                              : AppColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isCurrent ? AppColors.onBackground : AppColors.onSurfaceDim,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: BeamButton(
                onPressed: () => Navigator.pop(context),
                label: 'Done',
                icon: Icons.check_rounded,
                fullWidth: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceMuted)),
      ],
    );
  }
}

class _WaitingState extends StatelessWidget {
  final VoidCallback onPickPeer;
  const _WaitingState({required this.onPickPeer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sensors_rounded, size: 64, color: AppColors.onSurfaceMuted),
          const SizedBox(height: 16),
          const Text('No active transfer'),
          const SizedBox(height: 24),
          BeamButton(onPressed: onPickPeer, label: 'Select Device', icon: Icons.devices_rounded),
        ],
      ),
    );
  }
}

// ─── Peer selector bottom sheet ─────────────────────────────────────────────

class _PeerSelector extends StatelessWidget {
  final List<Peer> peers;
  const _PeerSelector({required this.peers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Send To', style: theme.textTheme.titleLarge),
        ),
        const Divider(height: 1),
        ...peers.map((p) => ListTile(
              leading: const Icon(Icons.devices_rounded),
              title: Text(p.name),
              subtitle: Text(p.address),
              onTap: () => Navigator.pop(context, p),
            )),
        const SizedBox(height: 24),
      ],
    );
  }
}
