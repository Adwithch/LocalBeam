// lib/core/network/transfer_manager.dart
// Core transfer orchestration engine.
// Handles chunked sending, streaming receive, progress tracking,
// integrity verification, and encryption.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import '../security/crypto_service.dart';
import '../utils/logger.dart';
import '../../domain/entities/peer.dart';

// ─── Transfer state ────────────────────────────────────────────────────────

enum _SessionPhase { waitingAccept, transferring, completed, failed, cancelled }

class _TransferSession {
  final String id;
  final bool isSender;
  final List<_FileEntry> files;
  final String peerName;
  final bool encrypted;
  final Uint8List? encryptionKey;

  _SessionPhase phase = _SessionPhase.waitingAccept;
  int currentFileIndex = 0;
  int totalTransferred = 0;
  int totalBytes = 0;
  DateTime? startTime;
  double speedBps = 0;
  String? errorMessage;

  // For writing received files
  IOSink? _currentSink;
  int _expectedChunks = 0;
  int _receivedChunks = 0;
  final Map<int, Uint8List> _chunkBuffer = {};

  _TransferSession({
    required this.id,
    required this.isSender,
    required this.files,
    required this.peerName,
    required this.encrypted,
    this.encryptionKey,
  }) {
    totalBytes = files.fold(0, (sum, f) => sum + f.size);
  }

  Map<String, dynamic> toStatusMap() => {
        'id': id,
        'phase': phase.name,
        'currentFileIndex': currentFileIndex,
        'totalFiles': files.length,
        'totalTransferred': totalTransferred,
        'totalBytes': totalBytes,
        'speedBps': speedBps,
        'progress': totalBytes > 0 ? totalTransferred / totalBytes : 0.0,
      };
}

class _FileEntry {
  final String name;
  final String path;
  final int size;
  final String mimeType;
  String? checksum;

  _FileEntry({
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.checksum,
  });
}

// ─── Transfer events ───────────────────────────────────────────────────────

abstract class TransferEvent {
  final String sessionId;
  const TransferEvent(this.sessionId);
}

class TransferOfferEvent extends TransferEvent {
  final String peerName;
  final List<String> fileNames;
  final int totalBytes;
  final bool encrypted;
  final String senderAddress;
  final int senderPort;
  const TransferOfferEvent(
    super.sessionId, {
    required this.peerName,
    required this.fileNames,
    required this.totalBytes,
    required this.encrypted,
    required this.senderAddress,
    required this.senderPort,
  });
}

class TransferProgressEvent extends TransferEvent {
  final int transferred;
  final int total;
  final double speedBps;
  final int currentFileIndex;
  final int totalFiles;
  const TransferProgressEvent(
    super.sessionId, {
    required this.transferred,
    required this.total,
    required this.speedBps,
    required this.currentFileIndex,
    required this.totalFiles,
  });
}

class TransferCompletedEvent extends TransferEvent {
  final List<String> savedPaths;
  const TransferCompletedEvent(super.sessionId, {required this.savedPaths});
}

class TransferFailedEvent extends TransferEvent {
  final String error;
  const TransferFailedEvent(super.sessionId, {required this.error});
}

class TransferCancelledEvent extends TransferEvent {
  const TransferCancelledEvent(super.sessionId);
}

// ─── Manager ──────────────────────────────────────────────────────────────

/// Settings interface to decouple from Riverpod in network layer.
abstract class TransferSettings {
  int get chunkSize;
  bool get autoAccept;
  String get downloadPath;
  int get maxConcurrent;
  bool get encryptByDefault;
  String? get defaultPassword;
}

class TransferManager {
  final _log = AppLogger('TransferManager');
  final _sessions = <String, _TransferSession>{};
  final _crypto = CryptoService.instance;
  final _uuid = const Uuid();
  final TransferSettings settings;

  final _eventController = StreamController<TransferEvent>.broadcast();
  Stream<TransferEvent> get events => _eventController.stream;

  TransferManager({required this.settings});

  // ─── Outgoing (Sender) ─────────────────────────────────────────────────

  /// Initiates a transfer to [peer] with [filePaths].
  /// Returns the session ID.
  Future<String> sendFiles({
    required Peer peer,
    required List<String> filePaths,
    String? password,
  }) async {
    final sessionId = _uuid.v4();
    final isEncrypted = password != null;
    Uint8List? key;

    if (isEncrypted) {
      final salt = _crypto.generateSalt();
      key = await _crypto.deriveKey(password, salt);
    }

    // Build file entries
    final files = <_FileEntry>[];
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) throw TransferFailure('File not found: $path');
      final stat = await file.stat();
      final mime = lookupMimeType(path) ?? 'application/octet-stream';
      files.add(_FileEntry(
        name: p.basename(path),
        path: path,
        size: stat.size,
        mimeType: mime,
      ));
    }

    // Compute checksums in isolate (non-blocking)
    for (final entry in files) {
      entry.checksum = await _computeChecksumInIsolate(entry.path);
    }

    final session = _TransferSession(
      id: sessionId,
      isSender: true,
      files: files,
      peerName: peer.name,
      encrypted: isEncrypted,
      encryptionKey: key,
    );
    _sessions[sessionId] = session;

    // Send offer to receiver
    await _sendOffer(peer, session, password: password);

    return sessionId;
  }

  Future<void> _sendOffer(
    Peer peer,
    _TransferSession session, {
    String? password,
  }) async {
    final offerBody = {
      'transferId': session.id,
      'senderName': 'This Device', // injected by caller in real use
      'files': session.files
          .map((f) => {
                'name': f.name,
                'size': f.size,
                'mimeType': f.mimeType,
                'checksum': f.checksum,
              })
          .toList(),
      'totalBytes': session.totalBytes,
      'encrypted': session.encrypted,
      if (password != null) ...CryptoService.instance.createChallenge(password),
    };

    final resp = await http
        .post(
          Uri.parse('http://${peer.address}:${peer.port}/transfer/offer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(offerBody),
        )
        .timeout(const Duration(seconds: AppConstants.connectionTimeoutSeconds));

    if (resp.statusCode != 200) {
      throw TransferFailure('Peer rejected offer: ${resp.body}');
    }

    final result = jsonDecode(resp.body) as Map<String, dynamic>;
    final accepted = result['accepted'] as bool? ?? false;

    if (!accepted) {
      session.phase = _SessionPhase.cancelled;
      _eventController.add(TransferCancelledEvent(session.id));
      return;
    }

    // Start streaming
    session.phase = _SessionPhase.transferring;
    session.startTime = DateTime.now();
    _startSending(peer, session);
  }

  /// Streams files chunk-by-chunk to the receiver.
  void _startSending(Peer peer, _TransferSession session) {
    _doSend(peer, session).catchError((e) {
      _log.error('Send error', e);
      session.phase = _SessionPhase.failed;
      session.errorMessage = e.toString();
      _eventController.add(TransferFailedEvent(session.id, error: e.toString()));
    });
  }

  Future<void> _doSend(Peer peer, _TransferSession session) async {
    final chunkSize = settings.chunkSize;
    final speedTracker = _SpeedTracker();

    for (int fi = 0; fi < session.files.length; fi++) {
      if (session.phase == _SessionPhase.cancelled) return;

      final fileEntry = session.files[fi];
      session.currentFileIndex = fi;

      final file = File(fileEntry.path);
      final stream = file.openRead();
      int chunkIndex = 0;

      // Buffer chunks from stream and upload
      final buffer = <int>[];
      await for (final byteList in stream) {
        if (session.phase == _SessionPhase.cancelled) return;
        buffer.addAll(byteList);

        while (buffer.length >= chunkSize) {
          final chunk = Uint8List.fromList(buffer.sublist(0, chunkSize));
          buffer.removeRange(0, chunkSize);

          await _uploadChunk(
            peer: peer,
            session: session,
            fileIndex: fi,
            chunkIndex: chunkIndex,
            data: chunk,
          );

          session.totalTransferred += chunk.length;
          speedTracker.record(chunk.length);
          session.speedBps = speedTracker.bytesPerSecond;
          chunkIndex++;

          _eventController.add(TransferProgressEvent(
            session.id,
            transferred: session.totalTransferred,
            total: session.totalBytes,
            speedBps: session.speedBps,
            currentFileIndex: fi,
            totalFiles: session.files.length,
          ));
        }
      }

      // Send remaining partial chunk
      if (buffer.isNotEmpty) {
        final chunk = Uint8List.fromList(buffer);
        await _uploadChunk(
          peer: peer,
          session: session,
          fileIndex: fi,
          chunkIndex: chunkIndex,
          data: chunk,
          isLast: true,
        );
        session.totalTransferred += chunk.length;
        speedTracker.record(chunk.length);
        session.speedBps = speedTracker.bytesPerSecond;

        _eventController.add(TransferProgressEvent(
          session.id,
          transferred: session.totalTransferred,
          total: session.totalBytes,
          speedBps: session.speedBps,
          currentFileIndex: fi,
          totalFiles: session.files.length,
        ));
      }
    }

    session.phase = _SessionPhase.completed;
    _eventController.add(TransferCompletedEvent(session.id, savedPaths: []));
    _log.info('Transfer ${session.id} completed');
  }

  Future<void> _uploadChunk({
    required Peer peer,
    required _TransferSession session,
    required int fileIndex,
    required int chunkIndex,
    required Uint8List data,
    bool isLast = false,
  }) async {
    Uint8List payload = data;

    // Encrypt if needed
    if (session.encrypted && session.encryptionKey != null) {
      payload = await _crypto.encrypt(data, session.encryptionKey!);
    }

    final hash = sha256.convert(data).toString();

    final resp = await http.post(
      Uri.parse('http://${peer.address}:${peer.port}/transfer/chunk'),
      headers: {
        'Content-Type': 'application/octet-stream',
        'X-Transfer-Id': session.id,
        'X-File-Index': fileIndex.toString(),
        'X-Chunk-Index': chunkIndex.toString(),
        'X-Chunk-Hash': hash,
        'X-Is-Last': isLast.toString(),
      },
      body: payload,
    );

    if (resp.statusCode != 200) {
      throw TransferFailure('Chunk upload failed (chunk $chunkIndex): ${resp.body}');
    }
  }

  // ─── Incoming (Receiver) ───────────────────────────────────────────────

  Future<Map<String, dynamic>> handleIncomingOffer(
    Map<String, dynamic> offer,
  ) async {
    final transferId = offer['transferId'] as String;
    final senderName = offer['senderName'] as String? ?? 'Unknown';
    final filesData = offer['files'] as List;
    final totalBytes = offer['totalBytes'] as int? ?? 0;
    final encrypted = offer['encrypted'] as bool? ?? false;

    final files = filesData
        .map((f) => _FileEntry(
              name: f['name'] as String,
              path: '', // will be set on receive
              size: f['size'] as int,
              mimeType: f['mimeType'] as String? ?? 'application/octet-stream',
              checksum: f['checksum'] as String?,
            ))
        .toList();

    // Notify UI
    _eventController.add(TransferOfferEvent(
      transferId,
      peerName: senderName,
      fileNames: files.map((f) => f.name).toList(),
      totalBytes: totalBytes,
      encrypted: encrypted,
      senderAddress: '', // filled in by server middleware
      senderPort: 0,
    ));

    if (settings.autoAccept) {
      final session = _TransferSession(
        id: transferId,
        isSender: false,
        files: files,
        peerName: senderName,
        encrypted: encrypted,
      );
      _sessions[transferId] = session;
      return {'accepted': true, 'message': 'Auto-accepted'};
    }

    // Not auto-accept — UI must call acceptTransfer() or rejectTransfer()
    // Return pending, UI drives the flow
    return {'accepted': false, 'pending': true};
  }

  Future<void> acceptTransfer(String transferId, {String? sessionToken}) async {
    final session = _sessions[transferId];
    if (session == null) {
      // Create new session entry for incoming
      _sessions[transferId] = _TransferSession(
        id: transferId,
        isSender: false,
        files: [],
        peerName: '',
        encrypted: false,
      );
    }
    _sessions[transferId]!.phase = _SessionPhase.transferring;
    _sessions[transferId]!.startTime = DateTime.now();
  }

  Future<void> rejectTransfer(String transferId) async {
    _sessions.remove(transferId);
  }

  /// Called by server for each incoming chunk.
  Future<void> receiveChunk({
    required String transferId,
    required int fileIndex,
    required int chunkIndex,
    required Uint8List data,
    String? expectedHash,
  }) async {
    final session = _sessions[transferId];
    if (session == null) throw TransferFailure('Unknown session: $transferId');
    if (session.phase == _SessionPhase.cancelled) return;

    Uint8List payload = data;

    // Decrypt if needed
    if (session.encrypted && session.encryptionKey != null) {
      payload = await _crypto.decrypt(data, session.encryptionKey!);
    }

    // Verify chunk integrity
    if (expectedHash != null) {
      final actualHash = sha256.convert(payload).toString();
      if (actualHash != expectedHash) {
        throw TransferFailure('Chunk $chunkIndex integrity mismatch');
      }
    }

    // Write to file
    if (fileIndex < session.files.length) {
      final fileEntry = session.files[fileIndex];
      if (fileEntry.path.isEmpty) {
        // First chunk — open file for writing
        final savePath = p.join(settings.downloadPath, fileEntry.name);
        final file = File(savePath);
        await file.parent.create(recursive: true);
        // Store path back
        session.files[fileIndex] = _FileEntry(
          name: fileEntry.name,
          path: savePath,
          size: fileEntry.size,
          mimeType: fileEntry.mimeType,
          checksum: fileEntry.checksum,
        );
        session._currentSink = file.openWrite();
      }
      session._currentSink!.add(payload);
    }

    session.totalTransferred += payload.length;
    session._receivedChunks++;

    final speedTracker = _SpeedTracker();
    speedTracker.record(payload.length);

    _eventController.add(TransferProgressEvent(
      transferId,
      transferred: session.totalTransferred,
      total: session.totalBytes,
      speedBps: speedTracker.bytesPerSecond,
      currentFileIndex: fileIndex,
      totalFiles: session.files.length,
    ));
  }

  // ─── Control ───────────────────────────────────────────────────────────

  Future<void> cancelTransfer(String transferId) async {
    final session = _sessions[transferId];
    if (session == null) return;
    session.phase = _SessionPhase.cancelled;
    await session._currentSink?.close();
    _sessions.remove(transferId);
    _eventController.add(TransferCancelledEvent(transferId));
  }

  Map<String, dynamic>? getSessionStatus(String id) {
    return _sessions[id]?.toStatusMap();
  }

  void dispose() {
    _eventController.close();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  static Future<String> _computeChecksumInIsolate(String filePath) async {
    return await Isolate.run(() async {
      final file = File(filePath);
      final sink = AccumulatorSink<Digest>();
      final input = sha256.startChunkedConversion(sink);
      await for (final chunk in file.openRead()) {
        input.add(chunk);
      }
      input.close();
      return sink.events.single.toString();
    });
  }
}

// ─── Speed tracker ─────────────────────────────────────────────────────────

class _SpeedTracker {
  final _samples = <(DateTime, int)>[];
  static const _window = Duration(seconds: 3);

  void record(int bytes) {
    _samples.add((DateTime.now(), bytes));
    final cutoff = DateTime.now().subtract(_window);
    _samples.removeWhere((s) => s.$1.isBefore(cutoff));
  }

  double get bytesPerSecond {
    if (_samples.isEmpty) return 0;
    final total = _samples.fold(0, (sum, s) => sum + s.$2);
    return total / _window.inSeconds;
  }
}
