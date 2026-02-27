// lib/data/repositories/history_repository_impl.dart

import 'dart:convert';

import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_datasource.dart';
import '../models/transfer_record_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryDataSource _ds;

  HistoryRepositoryImpl(this._ds);

  @override
  List<HistoryEntry> getAll() {
    return _ds.getAll().map(_toEntry).toList();
  }

  @override
  Future<void> add(HistoryEntry entry) async {
    await _ds.add(_fromEntry(entry));
  }

  @override
  Future<void> delete(String id) => _ds.delete(id);

  @override
  Future<void> clearAll() => _ds.clearAll();

  @override
  Future<String> exportLogs() async {
    final entries = getAll();
    final buffer = StringBuffer();
    buffer.writeln('LocalBeam Transfer Log — exported ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 60);

    for (final e in entries) {
      buffer.writeln('');
      buffer.writeln('[${e.date.toIso8601String()}]');
      buffer.writeln('Direction : ${e.direction}');
      buffer.writeln('Peer      : ${e.peerName}');
      buffer.writeln('Files     : ${e.fileNames.join(', ')}');
      buffer.writeln('Size      : ${_formatBytes(e.totalBytes)}');
      buffer.writeln('Status    : ${e.success ? '✓ Success' : '✗ Failed'}');
      buffer.writeln('Encrypted : ${e.wasEncrypted ? 'Yes' : 'No'}');
      if (e.errorMessage != null) {
        buffer.writeln('Error     : ${e.errorMessage}');
      }
    }
    return buffer.toString();
  }

  static HistoryEntry _toEntry(TransferRecordModel m) => HistoryEntry(
        id: m.id,
        direction: m.direction.name,
        fileNames: m.fileNames,
        totalBytes: m.totalBytes,
        peerName: m.peerName,
        date: m.date,
        success: m.success,
        errorMessage: m.errorMessage,
        wasEncrypted: m.wasEncrypted,
      );

  static TransferRecordModel _fromEntry(HistoryEntry e) => TransferRecordModel(
        id: e.id,
        direction: e.direction == 'send' ? TransferDirection.send : TransferDirection.receive,
        fileNames: e.fileNames,
        totalBytes: e.totalBytes,
        peerName: e.peerName,
        date: e.date,
        success: e.success,
        errorMessage: e.errorMessage,
        wasEncrypted: e.wasEncrypted,
      );

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
