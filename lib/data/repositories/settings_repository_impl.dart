// lib/data/repositories/settings_repository_impl.dart

import '../../core/constants/app_constants.dart';
import '../../core/network/transfer_manager.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource _ds;

  SettingsRepositoryImpl(this._ds);

  @override
  String get deviceName => _ds.deviceName;
  @override
  Future<void> setDeviceName(String name) => _ds.set(AppConstants.keyDeviceName, name);

  @override
  String get downloadPath => _ds.downloadPath;
  @override
  Future<void> setDownloadPath(String path) => _ds.set(AppConstants.keyDownloadPath, path);

  @override
  bool get autoAccept => _ds.autoAccept;
  @override
  Future<void> setAutoAccept(bool value) => _ds.set(AppConstants.keyAutoAccept, value);

  @override
  bool get passwordEnabled => _ds.passwordEnabled;
  @override
  Future<void> setPasswordEnabled(bool value) => _ds.set(AppConstants.keyPasswordEnabled, value);

  @override
  String? get defaultPassword => _ds.defaultPassword;
  @override
  Future<void> setDefaultPassword(String? password) => _ds.set(AppConstants.keyDefaultPassword, password);

  @override
  int get sessionTimeout => _ds.sessionTimeout;
  @override
  Future<void> setSessionTimeout(int seconds) => _ds.set(AppConstants.keySessionTimeout, seconds);

  @override
  int get maxConcurrent => _ds.maxConcurrent;
  @override
  Future<void> setMaxConcurrent(int count) => _ds.set(AppConstants.keyMaxConcurrent, count);

  @override
  int get chunkSize => _ds.chunkSize;
  @override
  Future<void> setChunkSize(int bytes) => _ds.set(AppConstants.keyChunkSize, bytes);

  @override
  bool get bandwidthLimitEnabled => _ds.bandwidthLimitEnabled;
  @override
  Future<void> setBandwidthLimitEnabled(bool value) => _ds.set(AppConstants.keyBandwidthLimitEnabled, value);

  @override
  int get bandwidthLimit => _ds.bandwidthLimit;
  @override
  Future<void> setBandwidthLimit(int bytesPerSec) => _ds.set(AppConstants.keyBandwidthLimit, bytesPerSec);

  @override
  String get themeMode => _ds.themeMode;
  @override
  Future<void> setThemeMode(String mode) => _ds.set(AppConstants.keyThemeMode, mode);

  @override
  TransferSettings asTransferSettings() => _SettingsAdapter(this);
}

class _SettingsAdapter implements TransferSettings {
  final SettingsRepositoryImpl _repo;
  const _SettingsAdapter(this._repo);

  @override
  int get chunkSize => _repo.chunkSize;
  @override
  bool get autoAccept => _repo.autoAccept;
  @override
  String get downloadPath => _repo.downloadPath;
  @override
  int get maxConcurrent => _repo.maxConcurrent;
  @override
  bool get encryptByDefault => _repo.passwordEnabled;
  @override
  String? get defaultPassword => _repo.defaultPassword;
}
