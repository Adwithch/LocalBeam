// lib/domain/usecases/send_files_usecase.dart
import '../../core/error/failures.dart';
import '../../domain/entities/peer.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../core/network/transfer_manager.dart';

/// Orchestrates sending files to a peer.
/// Handles password injection from settings if not explicitly provided.
class SendFilesUseCase {
  final TransferManager _manager;
  final SettingsRepository _settings;

  const SendFilesUseCase({
    required TransferManager manager,
    required SettingsRepository settings,
  }) : _manager = manager, _settings = settings;

  Future<String> call({
    required Peer peer,
    required List<String> filePaths,
    String? password,
  }) async {
    if (filePaths.isEmpty) throw const TransferFailure('No files selected');

    // Use default password from settings if encryption is on but no password passed
    final effectivePassword = password ??
        (_settings.passwordEnabled ? _settings.defaultPassword : null);

    return _manager.sendFiles(
      peer: peer,
      filePaths: filePaths,
      password: effectivePassword,
    );
  }
}

// lib/domain/usecases/get_history_usecase.dart
import '../../domain/repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository _repo;
  const GetHistoryUseCase(this._repo);
  List<HistoryEntry> call() => _repo.getAll();
}

class ClearHistoryUseCase {
  final HistoryRepository _repo;
  const ClearHistoryUseCase(this._repo);
  Future<void> call() => _repo.clearAll();
}

class ExportLogsUseCase {
  final HistoryRepository _repo;
  const ExportLogsUseCase(this._repo);
  Future<String> call() => _repo.exportLogs();
}

// lib/domain/repositories/history_repository.dart (already declared above)
// This file just re-exports so imports stay clean
export '../repositories/history_repository.dart';
