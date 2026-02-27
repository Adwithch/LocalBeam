// lib/core/network/webrtc_service.dart
// WebRTC data channel for fallback peer-to-peer connectivity.
// Used when HTTP server cannot be reached (e.g., cross-subnet).
// Signaling is done over the local HTTP server (no STUN/TURN needed on LAN).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';
import '../../domain/entities/peer.dart';

typedef OnDataChannelMessage = void Function(Uint8List data);
typedef OnConnectionStateChange = void Function(RTCPeerConnectionState state);

class WebRtcService {
  final _log = AppLogger('WebRtcService');

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  StreamController<Uint8List>? _dataController;
  Stream<Uint8List>? get dataStream => _dataController?.stream;

  OnConnectionStateChange? onConnectionStateChange;

  static const _rtcConfig = {
    // LAN-only ICE — no STUN/TURN
    'iceServers': <Map>[], 
    'iceTransportPolicy': 'all',
  };

  static const _offerOptions = {
    'offerToReceiveAudio': false,
    'offerToReceiveVideo': false,
  };

  // ─── Initiator (Sender) ───────────────────────────────────────────────

  Future<String> createOffer() async {
    _dataController = StreamController<Uint8List>.broadcast();
    _peerConnection = await createPeerConnection(_rtcConfig);

    _peerConnection!.onConnectionState = (state) {
      _log.debug('PeerConnection state: $state');
      onConnectionStateChange?.call(state);
    };

    // Create data channel
    final dcInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 30;
    _dataChannel = await _peerConnection!.createDataChannel('transfer', dcInit);

    _dataChannel!.onMessage = (RTCDataChannelMessage msg) {
      if (msg.isBinary) {
        _dataController?.add(msg.binary);
      }
    };

    _dataChannel!.onDataChannelState = (RTCDataChannelState state) {
      _log.debug('Data channel state: $state');
    };

    final offer = await _peerConnection!.createOffer(_offerOptions);
    await _peerConnection!.setLocalDescription(offer);

    // Wait for ICE gathering to complete
    await _waitForIceGathering();

    final localDesc = await _peerConnection!.getLocalDescription();
    return jsonEncode({
      'type': localDesc!.type,
      'sdp': localDesc.sdp,
    });
  }

  Future<String> createAnswer(String offerJson) async {
    _dataController = StreamController<Uint8List>.broadcast();
    _peerConnection = await createPeerConnection(_rtcConfig);

    _peerConnection!.onConnectionState = (state) {
      _log.debug('PeerConnection state: $state');
      onConnectionStateChange?.call(state);
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _dataChannel!.onMessage = (RTCDataChannelMessage msg) {
        if (msg.isBinary) _dataController?.add(msg.binary);
      };
    };

    final offerMap = jsonDecode(offerJson) as Map<String, dynamic>;
    final offer = RTCSessionDescription(
      offerMap['sdp'] as String,
      offerMap['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _waitForIceGathering();

    final localDesc = await _peerConnection!.getLocalDescription();
    return jsonEncode({
      'type': localDesc!.type,
      'sdp': localDesc.sdp,
    });
  }

  Future<void> setAnswer(String answerJson) async {
    final answerMap = jsonDecode(answerJson) as Map<String, dynamic>;
    final answer = RTCSessionDescription(
      answerMap['sdp'] as String,
      answerMap['type'] as String,
    );
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _waitForIceGathering() async {
    if (_peerConnection!.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) return;

    final completer = Completer<void>();
    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (!completer.isCompleted) completer.complete();
      }
    };
    await completer.future.timeout(const Duration(seconds: 10));
  }

  // ─── Data sending ─────────────────────────────────────────────────────

  Future<void> sendBinary(Uint8List data) async {
    if (_dataChannel == null) throw Exception('Data channel not established');
    if (_dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw Exception('Data channel not open');
    }
    await _dataChannel!.send(RTCDataChannelMessage.fromBinary(data));
  }

  Future<void> sendText(String text) async {
    if (_dataChannel == null) throw Exception('Data channel not established');
    await _dataChannel!.send(RTCDataChannelMessage(text));
  }

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  // ─── Cleanup ──────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _dataChannel?.close();
    await _peerConnection?.close();
    await _dataController?.close();
    _dataChannel = null;
    _peerConnection = null;
    _dataController = null;
    _log.info('WebRTC disposed');
  }
}
