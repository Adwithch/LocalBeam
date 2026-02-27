// lib/core/security/crypto_service.dart
// Handles AES-GCM encryption for file chunks, password hashing, session tokens.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

import '../error/failures.dart';
import '../utils/logger.dart';

class CryptoService {
  CryptoService._();
  static final CryptoService instance = CryptoService._();

  final _algorithm = AesGcm.with256bits();
  final _log = AppLogger('CryptoService');

  // ─── Key derivation ────────────────────────────────────────────────────────

  /// Derives a 32-byte key from [password] using PBKDF2-HMAC-SHA256.
  /// Run in isolate to avoid blocking UI.
  Future<Uint8List> deriveKey(String password, Uint8List salt) async {
    return await Isolate.run(() => _pbkdf2Sync(password, salt));
  }

  static Uint8List _pbkdf2Sync(String password, Uint8List salt) {
    // PBKDF2 using HMAC-SHA256, 100k iterations
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    // We need synchronous here but cryptography is async by default.
    // For isolate context, block using a temporary event loop approach.
    // We use a simpler PBKDF2 manual implementation:
    final key = utf8.encode(password);
    final hmac = Hmac(sha256, key);

    Uint8List result = Uint8List(32);
    final block = Uint8List(salt.length + 4);
    block.setAll(0, salt);
    block[salt.length] = 0;
    block[salt.length + 1] = 0;
    block[salt.length + 2] = 0;
    block[salt.length + 3] = 1;

    List<int> u = hmac.convert(block).bytes;
    List<int> t = List<int>.from(u);

    for (int i = 1; i < 100000; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    result.setAll(0, t.take(32));
    return result;
  }

  // ─── Random generation ─────────────────────────────────────────────────────

  Uint8List generateSalt([int length = 32]) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  String generateSessionToken() {
    final bytes = generateSalt(16);
    return base64Url.encode(bytes);
  }

  String generateTransferId() {
    final bytes = generateSalt(16);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  // ─── Encryption ────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] with [keyBytes] (32 bytes).
  /// Returns: [iv (12 bytes)] + [mac (16 bytes)] + [ciphertext]
  Future<Uint8List> encrypt(Uint8List plaintext, Uint8List keyBytes) async {
    try {
      final key = SecretKey(keyBytes);
      final secretBox = await _algorithm.encrypt(plaintext, secretKey: key);

      // Concatenate nonce + mac + ciphertext
      final result = Uint8List(
        secretBox.nonce.length + secretBox.mac.bytes.length + secretBox.cipherText.length,
      );
      int offset = 0;
      result.setAll(offset, secretBox.nonce);
      offset += secretBox.nonce.length;
      result.setAll(offset, secretBox.mac.bytes);
      offset += secretBox.mac.bytes.length;
      result.setAll(offset, secretBox.cipherText);

      return result;
    } catch (e) {
      _log.error('Encryption failed', e);
      throw const SecurityFailure('Encryption failed');
    }
  }

  /// Decrypts data produced by [encrypt].
  Future<Uint8List> decrypt(Uint8List encryptedData, Uint8List keyBytes) async {
    try {
      const nonceLength = 12;
      const macLength = 16;

      if (encryptedData.length < nonceLength + macLength) {
        throw const SecurityFailure('Encrypted data too short');
      }

      final nonce = encryptedData.sublist(0, nonceLength);
      final mac = Mac(encryptedData.sublist(nonceLength, nonceLength + macLength));
      final cipherText = encryptedData.sublist(nonceLength + macLength);

      final key = SecretKey(keyBytes);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
      final plaintext = await _algorithm.decrypt(secretBox, secretKey: key);

      return Uint8List.fromList(plaintext);
    } catch (e) {
      _log.error('Decryption failed', e);
      throw const SecurityFailure('Decryption failed — wrong password or corrupted data');
    }
  }

  // ─── Hashing ───────────────────────────────────────────────────────────────

  /// Returns SHA-256 hex digest of [data].
  String sha256Hex(Uint8List data) {
    return sha256.convert(data).toString();
  }

  /// Streams a file and returns its SHA-256 hash.
  /// Memory-efficient — never loads entire file.
  Future<String> hashStream(Stream<List<int>> stream) async {
    final sink = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(sink);
    await for (final chunk in stream) {
      input.add(chunk);
    }
    input.close();
    return sink.events.single.toString();
  }

  // ─── Password challenge ────────────────────────────────────────────────────

  /// Creates a challenge token for password auth.
  Map<String, String> createChallenge(String password) {
    final salt = generateSalt();
    final combined = utf8.encode(password) + salt;
    final hash = sha256.convert(combined).toString();
    return {
      'salt': base64.encode(salt),
      'hash': hash,
    };
  }

  /// Verifies a challenge response.
  bool verifyChallenge(String password, String saltB64, String expectedHash) {
    try {
      final salt = base64.decode(saltB64);
      final combined = utf8.encode(password) + salt;
      final hash = sha256.convert(combined).toString();
      return hash == expectedHash;
    } catch (_) {
      return false;
    }
  }
}
