// lib/core/network/discovery_service.dart
// Discovers peers on the local network via mDNS (multicast DNS).
// Falls back to manual IP entry on platforms where mDNS is restricted.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../../domain/entities/peer.dart';

class DiscoveryService {
  final _log = AppLogger('DiscoveryService');
  final _peers = <String, Peer>{};
  final _peerController = StreamController<List<Peer>>.broadcast();
  final _uuid = const Uuid();

  MDnsClient? _mdns;
  Timer? _announceTimer;
  Timer? _cleanupTimer;

  String? _localIp;
  int _serverPort = AppConstants.defaultServerPort;
  String _deviceName = 'LocalBeam';
  String _deviceId = '';
  String _platform = '';
  bool _isRunning = false;

  Stream<List<Peer>> get peersStream => _peerController.stream;
  List<Peer> get currentPeers => List.unmodifiable(_peers.values);
  String? get localIp => _localIp;

  Future<void> start({
    required String deviceName,
    required String deviceId,
    required String platform,
    required int serverPort,
  }) async {
    if (_isRunning) return;
    _deviceName = deviceName;
    _deviceId = deviceId;
    _platform = platform;
    _serverPort = serverPort;

    _localIp = await NetworkInfo().getWifiIP();
    _log.info('Local IP: $_localIp');

    await _startMdns();
    _startAnnouncements();
    _startCleanup();
    _isRunning = true;
    _log.info('Discovery started for $deviceName');
  }

  Future<void> stop() async {
    _isRunning = false;
    _announceTimer?.cancel();
    _cleanupTimer?.cancel();
    _mdns?.stop();
    _mdns = null;
    _log.info('Discovery stopped');
  }

  Future<void> _startMdns() async {
    try {
      _mdns = MDnsClient(
        rawDatagramSocketFactory: (dynamic host, int port,
            {bool? reuseAddress, bool? reusePort, int? ttl}) {
          return RawDatagramSocket.bind(host, port,
              reuseAddress: true, reusePort: false, ttl: ttl ?? 1);
        },
      );
      await _mdns!.start();
      _discoverPeers();
    } catch (e) {
      _log.warn('mDNS start failed (may not be available on this platform): $e');
      // Non-fatal — manual discovery still works
    }
  }

  void _discoverPeers() {
    if (_mdns == null) return;

    _mdns!
        .lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(AppConstants.serviceType),
    )
        .listen((PtrResourceRecord ptr) async {
      await _mdns!
          .lookup<SrvResourceRecord>(
        ResourceRecordQuery.service(ptr.domainName),
      )
          .forEach((SrvResourceRecord srv) async {
        await _mdns!
            .lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(srv.target),
        )
            .forEach((IPAddressResourceRecord ip) async {
          final address = ip.address.address;
          if (address == _localIp) return; // Skip self

          await _resolvePeer(address, srv.port);
        });
      });
    });
  }

  /// Probes a device at [address]:[port] and adds it to peers if valid.
  Future<void> _resolvePeer(String address, int port) async {
    try {
      final resp = await http
          .get(Uri.parse('http://$address:$port/info'))
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final info = jsonDecode(resp.body) as Map<String, dynamic>;
        final peer = Peer(
          id: info['id'] as String? ?? _uuid.v4(),
          name: info['name'] as String? ?? 'Unknown Device',
          address: address,
          port: port,
          platform: info['platform'] as String?,
          discoveredAt: DateTime.now(),
          isReachable: true,
        );
        _addOrUpdatePeer(peer);
      }
    } catch (e) {
      _log.debug('Could not probe $address:$port — $e');
    }
  }

  void _addOrUpdatePeer(Peer peer) {
    _peers[peer.id] = peer;
    _peerController.add(currentPeers);
  }

  /// Announces this device presence via HTTP broadcast to subnet.
  void _startAnnouncements() {
    _announceTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _broadcastPresence();
    });
    _broadcastPresence(); // Immediate first announce
  }

  Future<void> _broadcastPresence() async {
    if (_localIp == null) return;
    final parts = _localIp!.split('.');
    if (parts.length != 4) return;

    // Scan subnet .1–.254 for potential devices (use small batches)
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
    final futures = <Future>[];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      if (ip == _localIp) continue;
      futures.add(_resolvePeer(ip, _serverPort));
    }

    // Batch with max 20 concurrent probes
    for (int i = 0; i < futures.length; i += 20) {
      final batch = futures.sublist(i, (i + 20).clamp(0, futures.length));
      await Future.wait(batch, eagerError: false);
    }
  }

  void _startCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final stale = <String>[];
      for (final entry in _peers.entries) {
        final age = DateTime.now().difference(entry.value.discoveredAt);
        if (age > const Duration(seconds: 60)) {
          stale.add(entry.key);
        }
      }
      for (final id in stale) {
        _peers.remove(id);
      }
      if (stale.isNotEmpty) {
        _peerController.add(currentPeers);
      }
    });
  }

  /// Manually add a peer by IP address.
  Future<Peer?> addManualPeer(String address, int port) async {
    try {
      await _resolvePeer(address, port);
      return _peers.values
          .where((p) => p.address == address)
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stop();
    _peerController.close();
  }
}
