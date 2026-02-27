// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';
import '../file_picker/file_picker_screen.dart';
import 'widgets/peer_card.dart';
import 'widgets/quick_stats.dart';
import 'widgets/active_transfer_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _SendTab(),
          _ReceiveTab(),
          _HistoryTabProxy(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_rounded),
            label: 'Send',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_rounded),
            label: 'Receive',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// ─── Send tab ────────────────────────────────────────────────────────────────

class _SendTab extends ConsumerWidget {
  const _SendTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final peers = ref.watch(peersProvider);
    final settings = ref.watch(settingsProvider);
    final activeTransfers = ref.watch(activeTransfersProvider);

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  settings.deviceName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceDim,
                  ),
                ),
              ],
            ),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Active transfer banner
              if (activeTransfers.isNotEmpty) ...[
                ActiveTransferBanner(transfers: activeTransfers.values.toList()),
                const SizedBox(height: 16),
              ],

              // Quick stats
              const QuickStats(),
              const SizedBox(height: 24),

              // Send files button
              Row(
                children: [
                  Expanded(
                    child: BeamButton(
                      onPressed: () => _pickAndSend(context, ref),
                      label: 'Pick Files',
                      icon: Icons.add_rounded,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  BeamButton(
                    onPressed: () => _showQrScanner(context),
                    label: 'Scan QR',
                    icon: Icons.qr_code_scanner_rounded,
                    outlined: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Peers section
              Row(
                children: [
                  Text(
                    'NEARBY DEVICES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceDim,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  // Scanning indicator
                  peers.when(
                    data: (_) => const SizedBox.shrink(),
                    loading: () => const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                    error: (_, __) => const Icon(Icons.wifi_off_rounded, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              peers.when(
                data: (peerList) => peerList.isEmpty
                    ? _EmptyPeers()
                    : Column(
                        children: peerList
                            .map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: PeerCard(
                                    peer: p,
                                    onTap: () => _sendToPeer(context, ref, p.id),
                                  ),
                                ))
                            .toList(),
                      ),
                loading: () => const _PeersLoading(),
                error: (e, _) => _PeersError(error: e.toString()),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  void _pickAndSend(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const FilePickerScreen()),
    );
    if (result == null || result.isEmpty) return;

    // Navigate to peer selection
    if (context.mounted) {
      Navigator.pushNamed(context, '/transfer', arguments: {
        'filePaths': result,
      });
    }
  }

  void _sendToPeer(BuildContext context, WidgetRef ref, String peerId) {
    Navigator.pushNamed(context, '/transfer', arguments: {'peerId': peerId});
  }

  void _showQrScanner(BuildContext context) {
    Navigator.pushNamed(context, '/receive');
  }
}

class _EmptyPeers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_find_rounded,
            size: 48,
            color: AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for devices...',
            style: TextStyle(
              color: AppColors.onSurfaceDim,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure devices are on the same Wi-Fi network.',
            style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _PeersLoading extends StatelessWidget {
  const _PeersLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 100))
            .shimmer(duration: 1.5.seconds, color: AppColors.surfaceContainerHigh),
      ),
    );
  }
}

class _PeersError extends StatelessWidget {
  final String error;
  const _PeersError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Text('Discovery error: $error',
          style: const TextStyle(color: AppColors.error, fontSize: 13)),
    );
  }
}

// ─── Receive tab ─────────────────────────────────────────────────────────────

class _ReceiveTab extends ConsumerWidget {
  const _ReceiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ReceiveTab();
  }
}

// Delegate to separate screen widget
class ReceiveTab extends StatelessWidget {
  const ReceiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/receive'),
          child: const Text('Open Receive Screen'),
        ),
      ),
    );
  }
}

// ─── History tab proxy ────────────────────────────────────────────────────────

class _HistoryTabProxy extends StatelessWidget {
  const _HistoryTabProxy();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (_) {
        // Inline history list for tab
        return const _InlineHistory();
      }),
    );
  }
}

class _InlineHistory extends ConsumerWidget {
  const _InlineHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('History'),
          pinned: true,
          actions: [
            if (history.isNotEmpty)
              TextButton(
                onPressed: () => ref.read(historyProvider.notifier).clearAll(),
                child: const Text('Clear All'),
              ),
          ],
        ),
        if (history.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppColors.onSurfaceMuted),
                  const SizedBox(height: 16),
                  Text('No transfers yet', style: TextStyle(color: AppColors.onSurfaceDim)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final e = history[i];
                  final isSend = e.direction == 'send';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        isSend ? Icons.upload_rounded : Icons.download_rounded,
                        color: isSend ? AppColors.primary : AppColors.secondary,
                      ),
                      title: Text(e.fileNames.join(', '),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${e.peerName} · ${_formatDate(e.date)}'),
                      trailing: Icon(
                        e.success ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: e.success ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                    ),
                  );
                },
                childCount: history.length,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}
