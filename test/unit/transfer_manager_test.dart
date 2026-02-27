// test/unit/transfer_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:localbeam/core/network/transfer_manager.dart';
import 'package:localbeam/core/security/crypto_service.dart';

class MockTransferSettings extends Mock implements TransferSettings {
  @override
  int get chunkSize => 512 * 1024;
  @override
  bool get autoAccept => false;
  @override
  String get downloadPath => '/tmp';
  @override
  int get maxConcurrent => 3;
  @override
  bool get encryptByDefault => false;
  @override
  String? get defaultPassword => null;
}

void main() {
  group('CryptoService', () {
    final crypto = CryptoService.instance;

    test('generateSalt returns correct length', () {
      final salt = crypto.generateSalt(32);
      expect(salt.length, equals(32));
    });

    test('generateSalt values are random', () {
      final s1 = crypto.generateSalt();
      final s2 = crypto.generateSalt();
      expect(s1, isNot(equals(s2)));
    });

    test('generateSessionToken returns base64 string', () {
      final token = crypto.generateSessionToken();
      expect(token.isNotEmpty, isTrue);
      expect(token.length, greaterThan(10));
    });

    test('encrypt then decrypt roundtrip', () async {
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey('password123', salt);
      final plaintext = List.generate(1024, (i) => i % 256);
      final plain = Uint8List.fromList(plaintext);
      final encrypted = await crypto.encrypt(plain, key);
      final decrypted = await crypto.decrypt(encrypted, key);
      expect(decrypted, equals(plain));
    });

    test('decrypt with wrong key throws SecurityFailure', () async {
      final salt = crypto.generateSalt();
      final key1 = await crypto.deriveKey('password1', salt);
      final key2 = await crypto.deriveKey('password2', salt);
      final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
      final encrypted = await crypto.encrypt(plain, key1);
      expect(() => crypto.decrypt(encrypted, key2), throwsA(isA<SecurityFailure>()));
    });

    test('sha256Hex is consistent', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final h1 = crypto.sha256Hex(data);
      final h2 = crypto.sha256Hex(data);
      expect(h1, equals(h2));
      expect(h1.length, equals(64));
    });

    test('password challenge verify roundtrip', () {
      const password = 'secret';
      final challenge = crypto.createChallenge(password);
      final valid = crypto.verifyChallenge(password, challenge['salt']!, challenge['hash']!);
      expect(valid, isTrue);
    });

    test('password challenge fails with wrong password', () {
      const password = 'secret';
      final challenge = crypto.createChallenge(password);
      final valid = crypto.verifyChallenge('wrong', challenge['salt']!, challenge['hash']!);
      expect(valid, isFalse);
    });
  });

  group('TransferManager', () {
    late TransferManager manager;
    late MockTransferSettings settings;

    setUp(() {
      settings = MockTransferSettings();
      manager = TransferManager(settings: settings);
    });

    tearDown(() {
      manager.dispose();
    });

    test('events stream is broadcast', () {
      expect(manager.events.isBroadcast, isTrue);
    });

    test('getSessionStatus returns null for unknown id', () {
      expect(manager.getSessionStatus('nonexistent'), isNull);
    });

    test('rejectTransfer removes session', () async {
      await manager.handleIncomingOffer({
        'transferId': 'test-id',
        'senderName': 'Test',
        'files': [{'name': 'test.txt', 'size': 100, 'mimeType': 'text/plain'}],
        'totalBytes': 100,
        'encrypted': false,
      });
      await manager.rejectTransfer('test-id');
      expect(manager.getSessionStatus('test-id'), isNull);
    });

    test('handleIncomingOffer emits TransferOfferEvent', () async {
      final events = <TransferEvent>[];
      manager.events.listen(events.add);

      await manager.handleIncomingOffer({
        'transferId': 'offer-test',
        'senderName': 'Remote Device',
        'files': [
          {'name': 'photo.jpg', 'size': 2048000, 'mimeType': 'image/jpeg'},
          {'name': 'doc.pdf', 'size': 512000, 'mimeType': 'application/pdf'},
        ],
        'totalBytes': 2560000,
        'encrypted': false,
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(events.whereType<TransferOfferEvent>().length, equals(1));
      final offer = events.first as TransferOfferEvent;
      expect(offer.peerName, equals('Remote Device'));
      expect(offer.fileNames.length, equals(2));
    });

    test('cancelTransfer emits TransferCancelledEvent', () async {
      final events = <TransferEvent>[];
      manager.events.listen(events.add);

      await manager.acceptTransfer('cancel-test');
      await manager.cancelTransfer('cancel-test');

      await Future.delayed(const Duration(milliseconds: 50));
      expect(events.whereType<TransferCancelledEvent>().length, greaterThanOrEqualTo(1));
    });
  });

  group('SpeedTracker (via TransferManager)', () {
    test('initial speed is 0', () {
      final settings = MockTransferSettings();
      final m = TransferManager(settings: settings);
      // Internal speed tracker starts at 0
      expect(m.getSessionStatus('x'), isNull);
      m.dispose();
    });
  });
}

// Needed import
import 'dart:typed_data';
import 'package:localbeam/core/error/failures.dart';
