// lib/data/models/transfer_record_model.dart
// Hive-serializable transfer record for persistent history.

import 'package:hive/hive.dart';
import '../../domain/entities/peer.dart';

part 'transfer_record_model.g.dart';

@HiveType(typeId: 0)
enum TransferStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  connecting,
  @HiveField(2)
  waitingAccept,
  @HiveField(3)
  inProgress,
  @HiveField(4)
  paused,
  @HiveField(5)
  completed,
  @HiveField(6)
  failed,
  @HiveField(7)
  cancelled,
}

@HiveType(typeId: 1)
enum TransferDirection {
  @HiveField(0)
  send,
  @HiveField(1)
  receive,
}

@HiveType(typeId: 2)
class TransferRecordModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TransferDirection direction;

  @HiveField(2)
  final List<String> fileNames;

  @HiveField(3)
  final int totalBytes;

  @HiveField(4)
  final String peerName;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final bool success;

  @HiveField(7)
  final String? errorMessage;

  @HiveField(8)
  final bool wasEncrypted;

  TransferRecordModel({
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
