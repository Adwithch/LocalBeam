// lib/presentation/screens/receive/receive_screen.dart
// Shows device's QR code for pairing and accepts incoming transfers.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/local_server.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/beam_button.dart';
import 'widgets/incoming_offer_dialog.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  String? _localIp;
  int _port = AppConstants.defaultServerPort;
  bool _loadingIp = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
    _listenForOffers();
  }

  Future<void> _loadNetworkInfo() async {
    try {
      final ip = await NetworkInfo().getWifiIP();
      final server = GetIt.I<LocalServer>();
      setState(() {
        _localIp = ip;
        _port = server.port;
        _loadingIp = false;
      });
    } catch (e) {
      setState(() => _loadingIp = false);
    }
  }

  void _listenForOffers() {
    ref.listenManual(transferEventsProvider, (_, next) {
      next.whenData((event) {
        if (event is TransferOfferEvent) {
          _showOfferDialog(event);
        }
      });
    });
  }

  void _showOfferDialog(TransferOfferEvent event) {
    final settings = ref.read(settingsProvider);
    if (settings.autoAccept) {
      _acceptTransfer(event.sessionId);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomingOfferDialog(
        event: event,
        onAccept: () => _acceptTransfer(event.sessionId),
        onReject: () => _rejectTransfer(event.sessionId),
      ),
    );
  }

  void _acceptTransfer(String id) {
    ref.read(transferManagerProvider).acceptTransfer(id);
    Navigator.pushNamed(context, '/transfer', arguments: {'sessionId': id});
  }

  void _rejectTransfer(String id) {
    ref.read(transferManagerProvider).rejectTransfer(id);
  }

  String _buildQrData() {
    if (_localIp == null) return '';
    final settings = ref.read(settingsProvider);
    return jsonEncode({
      'name': settings.deviceName,
      'ip': _localIp,
      'port': _port,
      'v': AppConstants.appVersion,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final qrData = _buildQrData();

    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Text(
              'Ready to Receive',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Ask the sender to scan this QR code\nor enter your IP manually',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceDim),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // QR Code
            if (_loadingIp)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_localIp == null)
              _NoWifiWarning()
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  foregroundColor: const Color(0xFF0A0A0F),
                  embeddedImage: null,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut, duration: 700.ms)
                  .fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // IP / Port info
            if (_localIp != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.router_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    SelectableText(
                      '$_localIp:$_port',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Auto-accept indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: settings.autoAccept
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.autoAccept
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.autoAccept
                        ? Icons.auto_mode_rounded
                        : Icons.pending_actions_rounded,
                    size: 18,
                    color: settings.autoAccept ? AppColors.success : AppColors.onSurfaceDim,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      settings.autoAccept
                          ? 'Auto-accept enabled — files will be saved automatically'
                          : 'You will be prompted before accepting each transfer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: settings.autoAccept
                            ? AppColors.success
                            : AppColors.onSurfaceDim,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Manual scan button
            BeamButton(
              onPressed: () => _openQrScanner(context),
              label: 'Scan Sender\'s QR',
              icon: Icons.qr_code_scanner_rounded,
              outlined: true,
              fullWidth: true,
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerPage()),
    );
  }
}

class _NoWifiWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text(
            'No Wi-Fi connection',
            style: TextStyle(
                color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to a Wi-Fi network to receive files from nearby devices.',
            style: TextStyle(color: AppColors.warning.withOpacity(0.8), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Simple QR scanner page using mobile_scanner
class _QrScannerPage extends ConsumerWidget {
  const _QrScannerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // mobile_scanner widget — real implementation requires platform permissions
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppColors.onSurfaceMuted),
            const SizedBox(height: 24),
            const Text(
              'Point your camera at the\nsender\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceDim),
            ),
            const SizedBox(height: 24),
            // Placeholder — real implementation uses MobileScannerController
            // and MobileScanner widget from mobile_scanner package
            Text(
              'MobileScanner widget goes here.\nEnable camera permission in app settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
