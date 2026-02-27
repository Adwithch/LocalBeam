// lib/domain/entities/peer.dart

import 'package:flutter/foundation.dart';

/// Represents a discovered peer device on the local network.
@immutable
class Peer {
  final String id;
  final String name;
  final String address;
  final int port;
  final String? platform; // android | ios | macos | windows | linux | web
  final DateTime discoveredAt;
  final bool isReachable;

  const Peer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    this.platform,
    required this.discoveredAt,
    this.isReachable = true,
  });

  Peer copyWith({
    String? id,
    String? name,
    String? address,
    int? port,
    String? platform,
    DateTime? discoveredAt,
    bool? isReachable,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      platform: platform ?? this.platform,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isReachable: isReachable ?? this.isReachable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Peer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Peer($name @ $address:$port)';
}

// lib/domain/entities/transfer_file.dart

@immutable
class TransferFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final String? checksum; // SHA-256

  const TransferFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.checksum,
  });

  TransferFile copyWith({String? checksum}) =>
      TransferFile(
        id: id,
        name: name,
        path: path,
        size: size,
        mimeType: mimeType,
        checksum: checksum ?? this.checksum,
      );
}

// lib/domain/entities/transfer_session.dart

enum TransferStatus {
  pending,
  connecting,
  waitingAccept,
  inProgress,
  paused,
  completed,
  failed,
  cancelled,
}

enum TransferDirection { send, receive }

@immutable
class TransferSession {
  final String id;
  final TransferDirection direction;
  final TransferStatus status;
  final List<TransferFile> files;
  final Peer? peer;
  final int totalBytes;
  final int transferredBytes;
  final double speedBytesPerSec;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final bool isEncrypted;
  final int currentFileIndex;

  const TransferSession({
    required this.id,
    required this.direction,
    required this.status,
    required this.files,
    this.peer,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.speedBytesPerSec = 0,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.isEncrypted = false,
    this.currentFileIndex = 0,
  });

  double get progress =>
      totalBytes > 0 ? (transferredBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  Duration get elapsed => (completedAt ?? DateTime.now()).difference(startedAt);

  Duration? get eta {
    if (speedBytesPerSec <= 0) return null;
    final remaining = totalBytes - transferredBytes;
    return Duration(seconds: (remaining / speedBytesPerSec).round());
  }

  bool get isActive =>
      status == TransferStatus.inProgress || status == TransferStatus.connecting;

  TransferSession copyWith({
    TransferStatus? status,
    int? transferredBytes,
    double? speedBytesPerSec,
    DateTime? completedAt,
    String? errorMessage,
    Peer? peer,
    bool? isEncrypted,
    int? currentFileIndex,
    List<TransferFile>? files,
  }) {
    return TransferSession(
      id: id,
      direction: direction,
      status: status ?? this.status,
      files: files ?? this.files,
      peer: peer ?? this.peer,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
    );
  }
}

// lib/domain/entities/transfer_record.dart
// Persisted history record (stored in Hive).

@immutable
class TransferRecord {
  final String id;
  final TransferDirection direction;
  final List<String> fileNames;
  final int totalBytes;
  final String peerName;
  final DateTime date;
  final bool success;
  final String? errorMessage;
  final bool wasEncrypted;

  const TransferRecord({
    required this.id,
    required this.direction,
    required this.fileNames,
    required this.totalBytes,
    required this.peerName,
    required this.date,
    required this.success,
    this.errorMessage,
    this.wasEncrypted = false,
  });
}
