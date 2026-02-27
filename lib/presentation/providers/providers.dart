// lib/presentation/providers/providers.dart
// All Riverpod providers in one place.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/discovery_service.dart';
import '../../core/network/transfer_manager.dart';
import '../../domain/entities/peer.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/history_repository.dart';

// ─── Repository providers ─────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => GetIt.I<SettingsRepository>(),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => GetIt.I<HistoryRepository>(),
);

// ─── Settings state ───────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(SettingsState.fromRepo(_repo));

  Future<void> setDeviceName(String name) async {
    await _repo.setDeviceName(name);
    state = state.copyWith(deviceName: name);
  }

  Future<void> setAutoAccept(bool value) async {
    await _repo.setAutoAccept(value);
    state = state.copyWith(autoAccept: value);
  }

  Future<void> setPasswordEnabled(bool value) async {
    await _repo.setPasswordEnabled(value);
    state = state.copyWith(passwordEnabled: value);
  }

  Future<void> setDefaultPassword(String? password) async {
    await _repo.setDefaultPassword(password);
    state = state.copyWith(defaultPassword: password);
  }

  Future<void> setChunkSize(int bytes) async {
    await _repo.setChunkSize(bytes);
    state = state.copyWith(chunkSize: bytes);
  }

  Future<void> setMaxConcurrent(int count) async {
    await _repo.setMaxConcurrent(count);
    state = state.copyWith(maxConcurrent: count);
  }

  Future<void> setSessionTimeout(int seconds) async {
    await _repo.setSessionTimeout(seconds);
    state = state.copyWith(sessionTimeout: seconds);
  }

  Future<void> setBandwidthLimitEnabled(bool value) async {
    await _repo.setBandwidthLimitEnabled(value);
    state = state.copyWith(bandwidthLimitEnabled: value);
  }

  Future<void> setThemeMode(String mode) async {
    await _repo.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setDownloadPath(String path) async {
    await _repo.setDownloadPath(path);
    state = state.copyWith(downloadPath: path);
  }
}

class SettingsState {
  final String deviceName;
  final String downloadPath;
  final bool autoAccept;
  final bool passwordEnabled;
  final String? defaultPassword;
  final int sessionTimeout;
  final int maxConcurrent;
  final int chunkSize;
  final bool bandwidthLimitEnabled;
  final int bandwidthLimit;
  final String themeMode;

  const SettingsState({
    required this.deviceName,
    required this.downloadPath,
    required this.autoAccept,
    required this.passwordEnabled,
    this.defaultPassword,
    required this.sessionTimeout,
    required this.maxConcurrent,
    required this.chunkSize,
    required this.bandwidthLimitEnabled,
    required this.bandwidthLimit,
    required this.themeMode,
  });

  factory SettingsState.fromRepo(SettingsRepository repo) => SettingsState(
        deviceName: repo.deviceName,
        downloadPath: repo.downloadPath,
        autoAccept: repo.autoAccept,
        passwordEnabled: repo.passwordEnabled,
        defaultPassword: repo.defaultPassword,
        sessionTimeout: repo.sessionTimeout,
        maxConcurrent: repo.maxConcurrent,
        chunkSize: repo.chunkSize,
        bandwidthLimitEnabled: repo.bandwidthLimitEnabled,
        bandwidthLimit: repo.bandwidthLimit,
        themeMode: repo.themeMode,
      );

  SettingsState copyWith({
    String? deviceName,
    String? downloadPath,
    bool? autoAccept,
    bool? passwordEnabled,
    String? defaultPassword,
    int? sessionTimeout,
    int? maxConcurrent,
    int? chunkSize,
    bool? bandwidthLimitEnabled,
    int? bandwidthLimit,
    String? themeMode,
  }) {
    return SettingsState(
      deviceName: deviceName ?? this.deviceName,
      downloadPath: downloadPath ?? this.downloadPath,
      autoAccept: autoAccept ?? this.autoAccept,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      defaultPassword: defaultPassword ?? this.defaultPassword,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      chunkSize: chunkSize ?? this.chunkSize,
      bandwidthLimitEnabled: bandwidthLimitEnabled ?? this.bandwidthLimitEnabled,
      bandwidthLimit: bandwidthLimit ?? this.bandwidthLimit,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.read(settingsRepositoryProvider)),
);

// ─── Peers ────────────────────────────────────────────────────────────────

final discoveryServiceProvider = Provider<DiscoveryService>(
  (ref) => GetIt.I<DiscoveryService>(),
);

final peersProvider = StreamProvider<List<Peer>>((ref) {
  return ref.read(discoveryServiceProvider).peersStream;
});

// ─── Transfer events ──────────────────────────────────────────────────────

final transferManagerProvider = Provider<TransferManager>(
  (ref) => GetIt.I<TransferManager>(),
);

final transferEventsProvider = StreamProvider<TransferEvent>((ref) {
  return ref.read(transferManagerProvider).events;
});

// ─── Active transfers ─────────────────────────────────────────────────────

class ActiveTransfersNotifier extends StateNotifier<Map<String, TransferSessionUiState>> {
  final TransferManager _manager;
  StreamSubscription? _sub;

  ActiveTransfersNotifier(this._manager) : super({}) {
    _sub = _manager.events.listen(_onEvent);
  }

  void _onEvent(TransferEvent event) {
    if (event is TransferProgressEvent) {
      final current = state[event.sessionId] ?? TransferSessionUiState(id: event.sessionId);
      state = {
        ...state,
        event.sessionId: current.copyWith(
          transferred: event.transferred,
          total: event.total,
          speedBps: event.speedBps,
          currentFileIndex: event.currentFileIndex,
          totalFiles: event.totalFiles,
          status: 'inProgress',
        ),
      };
    } else if (event is TransferCompletedEvent) {
      final current = state[event.sessionId];
      if (current != null) {
        state = {
          ...state,
          event.sessionId: current.copyWith(status: 'completed'),
        };
      }
    } else if (event is TransferFailedEvent) {
      final current = state[event.sessionId];
      if (current != null) {
        state = {
          ...state,
          event.sessionId: current.copyWith(
            status: 'failed',
            errorMessage: event.error,
          ),
        };
      }
    } else if (event is TransferOfferEvent) {
      state = {
        ...state,
        event.sessionId: TransferSessionUiState(
          id: event.sessionId,
          peerName: event.peerName,
          fileNames: event.fileNames,
          total: event.totalBytes,
          status: 'waitingAccept',
          isEncrypted: event.encrypted,
        ),
      };
    }
  }

  void addOutgoing(String sessionId, {
    required List<String> fileNames,
    required int total,
    required String peerName,
  }) {
    state = {
      ...state,
      sessionId: TransferSessionUiState(
        id: sessionId,
        peerName: peerName,
        fileNames: fileNames,
        total: total,
        status: 'connecting',
      ),
    };
  }

  void remove(String sessionId) {
    final newState = Map<String, TransferSessionUiState>.from(state);
    newState.remove(sessionId);
    state = newState;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class TransferSessionUiState {
  final String id;
  final String? peerName;
  final List<String> fileNames;
  final int transferred;
  final int total;
  final double speedBps;
  final int currentFileIndex;
  final int totalFiles;
  final String status;
  final String? errorMessage;
  final bool isEncrypted;
  final List<String> savedPaths;

  const TransferSessionUiState({
    required this.id,
    this.peerName,
    this.fileNames = const [],
    this.transferred = 0,
    this.total = 0,
    this.speedBps = 0,
    this.currentFileIndex = 0,
    this.totalFiles = 1,
    this.status = 'pending',
    this.errorMessage,
    this.isEncrypted = false,
    this.savedPaths = const [],
  });

  double get progress => total > 0 ? (transferred / total).clamp(0.0, 1.0) : 0.0;

  TransferSessionUiState copyWith({
    String? peerName,
    List<String>? fileNames,
    int? transferred,
    int? total,
    double? speedBps,
    int? currentFileIndex,
    int? totalFiles,
    String? status,
    String? errorMessage,
    bool? isEncrypted,
    List<String>? savedPaths,
  }) {
    return TransferSessionUiState(
      id: id,
      peerName: peerName ?? this.peerName,
      fileNames: fileNames ?? this.fileNames,
      transferred: transferred ?? this.transferred,
      total: total ?? this.total,
      speedBps: speedBps ?? this.speedBps,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      savedPaths: savedPaths ?? this.savedPaths,
    );
  }
}

final activeTransfersProvider =
    StateNotifierProvider<ActiveTransfersNotifier, Map<String, TransferSessionUiState>>(
  (ref) => ActiveTransfersNotifier(ref.read(transferManagerProvider)),
);

// ─── History ──────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  final HistoryRepository _repo;

  HistoryNotifier(this._repo) : super(_repo.getAll());

  Future<void> add(HistoryEntry entry) async {
    await _repo.add(entry);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }

  Future<String> exportLogs() => _repo.exportLogs();
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  (ref) => HistoryNotifier(ref.read(historyRepositoryProvider)),
);
