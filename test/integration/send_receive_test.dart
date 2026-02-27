// test/integration/send_receive_test.dart
// Integration tests — run these on a device/emulator with:
//   flutter test integration_test/send_receive_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:localbeam/core/network/local_server.dart';
import 'package:localbeam/core/network/transfer_manager.dart';
import 'package:localbeam/core/security/crypto_service.dart';

/// Mock settings for integration tests
class _TestSettings implements TransferSettings {
  final String _downloadPath;
  _TestSettings(this._downloadPath);

  @override int get chunkSize => 64 * 1024; // small for test speed
  @override bool get autoAccept => true;
  @override String get downloadPath => _downloadPath;
  @override int get maxConcurrent => 1;
  @override bool get encryptByDefault => false;
  @override String? get defaultPassword => null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LocalServer + TransferManager integration', () {
    late Directory tempDir;
    late TransferManager managerA; // sender
    late TransferManager managerB; // receiver
    late LocalServer serverB;

    setUp(() async {
      tempDir = await getTemporaryDirectory();
      final sendDir = Directory('${tempDir.path}/send')..createSync();
      final recvDir = Directory('${tempDir.path}/recv')..createSync();

      managerA = TransferManager(settings: _TestSettings(sendDir.path));
      managerB = TransferManager(settings: _TestSettings(recvDir.path));

      serverB = LocalServer(
        deviceName: 'TestReceiver',
        deviceId: 'receiver-id',
        platform: 'test',
        transferManager: managerB,
      );
      await serverB.start(7500);
    });

    tearDown(() async {
      managerA.dispose();
      managerB.dispose();
      await serverB.stop();
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('can send a small file end-to-end', (tester) async {
      // Create a 1 KB test file
      final testFile = File('${tempDir.path}/send/hello.txt');
      await testFile.writeAsString('Hello, LocalBeam! ' * 50); // ~900 bytes

      // Set up receiver peer entity
      final receiverPeer = Peer(
        id: 'receiver-id',
        name: 'TestReceiver',
        address: '127.0.0.1',
        port: 7500,
        discoveredAt: DateTime.now(),
      );

      // Listen for completion on receiver
      final completer = Completer<TransferCompletedEvent>();
      managerB.events.listen((event) {
        if (event is TransferCompletedEvent) completer.complete(event);
      });

      // Start transfer
      await managerA.sendFiles(
        peer: receiverPeer,
        filePaths: [testFile.path],
      );

      // Wait up to 30s for completion
      final result = await completer.future.timeout(const Duration(seconds: 30));
      expect(result, isNotNull);

      // Verify file exists on receiver side
      final recvFile = File('${tempDir.path}/recv/hello.txt');
      expect(await recvFile.exists(), isTrue);
      expect(await recvFile.readAsString(), contains('Hello, LocalBeam!'));
    });

    testWidgets('encrypted transfer roundtrip', (tester) async {
      final testFile = File('${tempDir.path}/send/secret.txt');
      await testFile.writeAsString('Top secret data 🔒');

      final receiverPeer = Peer(
        id: 'receiver-id',
        name: 'TestReceiver',
        address: '127.0.0.1',
        port: 7500,
        discoveredAt: DateTime.now(),
      );

      final completer = Completer<TransferCompletedEvent>();
      managerB.events.listen((event) {
        if (event is TransferCompletedEvent) completer.complete(event);
      });

      await managerA.sendFiles(
        peer: receiverPeer,
        filePaths: [testFile.path],
        password: 'integration-test-pw',
      );

      final result = await completer.future.timeout(const Duration(seconds: 30));
      expect(result, isNotNull);
    });
  });
}

// Needed import
import 'dart:async';
import 'package:localbeam/domain/entities/peer.dart';
import 'package:localbeam/core/network/transfer_manager.dart';
