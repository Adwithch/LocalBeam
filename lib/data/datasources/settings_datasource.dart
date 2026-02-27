// lib/data/datasources/settings_datasource.dart

import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/transfer_manager.dart';

class SettingsDataSource {
  final Box _box;
  final String defaultDeviceName;

  SettingsDataSource(this._box, {required this.defaultDeviceName});

  String get(String key, {String? defaultDeviceName}) {
    return _box.get(key, defaultValue: defaultDeviceName ?? '') as String;
  }

  T getValue<T>(String key, T defaultValue) {
    return _box.get(key, defaultValue: defaultValue) as T;
  }

  Future<void> set<T>(String key, T value) async {
    await _box.put(key, value);
  }

  // Convenience getters
  String get deviceName => _box.get(AppConstants.keyDeviceName, defaultValue: defaultDeviceName) as String;
  String get downloadPath => _box.get(AppConstants.keyDownloadPath, defaultValue: '') as String;
  bool get autoAccept => _box.get(AppConstants.keyAutoAccept, defaultValue: false) as bool;
  bool get passwordEnabled => _box.get(AppConstants.keyPasswordEnabled, defaultValue: false) as bool;
  String? get defaultPassword => _box.get(AppConstants.keyDefaultPassword) as String?;
  int get sessionTimeout => _box.get(AppConstants.keySessionTimeout, defaultValue: AppConstants.defaultSessionTimeoutSeconds) as int;
  int get maxConcurrent => _box.get(AppConstants.keyMaxConcurrent, defaultValue: AppConstants.defaultMaxConcurrent) as int;
  int get chunkSize => _box.get(AppConstants.keyChunkSize, defaultValue: AppConstants.defaultChunkSize) as int;
  bool get bandwidthLimitEnabled => _box.get(AppConstants.keyBandwidthLimitEnabled, defaultValue: false) as bool;
  int get bandwidthLimit => _box.get(AppConstants.keyBandwidthLimit, defaultValue: 0) as int;
  String get themeMode => _box.get(AppConstants.keyThemeMode, defaultValue: 'dark') as String;
}

// lib/data/repositories/settings_repository_impl.dart
