// lib/core/network/local_server.dart
// Local HTTP server powered by Shelf.
// Handles:
//   POST /transfer/offer    — Sender announces a transfer
//   POST /transfer/accept   — Receiver accepts
//   POST /transfer/reject   — Receiver rejects
//   POST /transfer/chunk    — Sender streams a chunk
//   GET  /transfer/status   — Progress polling
//   GET  /info              — Device info (name, platform, version)
//   GET  /ping              — Reachability check

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import '../utils/logger.dart';
import 'transfer_manager.dart';

class LocalServer {
  final _log = AppLogger('LocalServer');
  HttpServer? _server;
  final TransferManager _transferManager;
  final String deviceName;
  final String deviceId;
  final String platform;

  LocalServer({
    required this.deviceName,
    required this.deviceId,
    required this.platform,
    required TransferManager transferManager,
  }) : _transferManager = transferManager;

  bool get isRunning => _server != null;
  int get port => _server?.port ?? AppConstants.defaultServerPort;

  // ─── Start / Stop ──────────────────────────────────────────────────────────

  Future<void> start([int preferredPort = AppConstants.defaultServerPort]) async {
    if (_server != null) return;

    final router = Router()
      ..get('/ping', _handlePing)
      ..get('/info', _handleInfo)
      ..post('/transfer/offer', _handleOffer)
      ..post('/transfer/accept', _handleAccept)
      ..post('/transfer/reject', _handleReject)
      ..post('/transfer/chunk', _handleChunk)
      ..get('/transfer/<id>/status', _handleStatus)
      ..post('/transfer/<id>/cancel', _handleCancel);

    final handler = Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        preferredPort,
        shared: true,
      );
      _log.info('Server started on port ${_server!.port}');
    } catch (e) {
      _log.error('Failed to start server', e);
      throw NetworkFailure('Could not start server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _log.info('Server stopped');
  }

  // ─── Middleware ────────────────────────────────────────────────────────────

  Middleware _corsMiddleware() {
    return (Handler inner) {
      return (Request req) async {
        final resp = await inner(req);
        return resp.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-Session-Token, X-Transfer-Id',
          ...resp.headers,
        });
      };
    };
  }

  Middleware _authMiddleware() {
    return (Handler inner) {
      return (Request req) async {
        // Skip auth for ping/info
        if (req.url.path == 'ping' || req.url.path == 'info') {
          return inner(req);
        }
        // Token validation handled at transfer manager level
        return inner(req);
      };
    };
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<Response> _handlePing(Request req) async {
    return Response.ok(
      jsonEncode({'status': 'ok', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleInfo(Request req) async {
    return Response.ok(
      jsonEncode({
        'id': deviceId,
        'name': deviceName,
        'platform': platform,
        'version': AppConstants.appVersion,
        'port': port,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _handleOffer(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final result = await _transferManager.handleIncomingOffer(body);
      return Response.ok(
        jsonEncode(result),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log.error('Offer handler error', e);
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _handleAccept(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final transferId = body['transferId'] as String;
      final sessionToken = body['sessionToken'] as String?;
      await _transferManager.acceptTransfer(transferId, sessionToken: sessionToken);
      return Response.ok(
        jsonEncode({'status': 'accepted'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(e);
    }
  }

  Future<Response> _handleReject(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final transferId = body['transferId'] as String;
      await _transferManager.rejectTransfer(transferId);
      return Response.ok(
        jsonEncode({'status': 'rejected'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(e);
    }
  }

  /// Handles a binary chunk upload.
  /// Headers: X-Transfer-Id, X-File-Index, X-Chunk-Index, X-Chunk-Hash
  Future<Response> _handleChunk(Request req) async {
    final transferId = req.headers['x-transfer-id'];
    final fileIndex = int.tryParse(req.headers['x-file-index'] ?? '0') ?? 0;
    final chunkIndex = int.tryParse(req.headers['x-chunk-index'] ?? '0') ?? 0;
    final expectedHash = req.headers['x-chunk-hash'];

    if (transferId == null) {
      return Response.badRequest(body: 'Missing X-Transfer-Id header');
    }

    try {
      // Stream chunk data directly — no full-file buffering
      final bytes = await req.read().expand((e) => e).toList();
      final chunkData = Uint8List.fromList(bytes);

      await _transferManager.receiveChunk(
        transferId: transferId,
        fileIndex: fileIndex,
        chunkIndex: chunkIndex,
        data: chunkData,
        expectedHash: expectedHash,
      );

      return Response.ok(
        jsonEncode({'status': 'ok', 'chunkIndex': chunkIndex}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      _log.error('Chunk handler error', e);
      return _errorResponse(e);
    }
  }

  Future<Response> _handleStatus(Request req, String id) async {
    try {
      final status = _transferManager.getSessionStatus(id);
      if (status == null) {
        return Response.notFound(jsonEncode({'error': 'Transfer not found'}));
      }
      return Response.ok(
        jsonEncode(status),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse(e);
    }
  }

  Future<Response> _handleCancel(Request req, String id) async {
    try {
      await _transferManager.cancelTransfer(id);
      return Response.ok(jsonEncode({'status': 'cancelled'}));
    } catch (e) {
      return _errorResponse(e);
    }
  }

  Response _errorResponse(dynamic e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
