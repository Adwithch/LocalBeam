// lib/domain/repositories/settings_repository.dart

import '../../core/network/transfer_manager.dart';

abstract class SettingsRepository {
  String get deviceName;
  Future<void> setDeviceName(String name);

  String get downloadPath;
  Future<void> setDownloadPath(String path);

  bool get autoAccept;
  Future<void> setAutoAccept(bool value);

  bool get passwordEnabled;
  Future<void> setPasswordEnabled(bool value);

  String? get defaultPassword;
  Future<void> setDefaultPassword(String? password);

  int get sessionTimeout;
  Future<void> setSessionTimeout(int seconds);

  int get maxConcurrent;
  Future<void> setMaxConcurrent(int count);

  int get chunkSize;
  Future<void> setChunkSize(int bytes);

  bool get bandwidthLimitEnabled;
  Future<void> setBandwidthLimitEnabled(bool value);

  int get bandwidthLimit;
  Future<void> setBandwidthLimit(int bytesPerSec);

  String get themeMode;
  Future<void> setThemeMode(String mode);

  TransferSettings asTransferSettings();
}

// lib/domain/repositories/history_repository.dart

abstract class HistoryRepository {
  List<HistoryEntry> getAll();
  Future<void> add(HistoryEntry entry);
  Future<void> delete(String id);
  Future<void> clearAll();
  Future<String> exportLogs();
}

class HistoryEntry {
  final String id;
  final String direction;
  final List<String> fileNames;
  final int totalBytes;
  final String peerName;
  final DateTime date;
  final bool success;
  final String? errorMessage;
  final bool wasEncrypted;

  const HistoryEntry({
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
