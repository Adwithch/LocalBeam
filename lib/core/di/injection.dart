// lib/core/di/injection.dart
// Dependency injection container using get_it.

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../network/discovery_service.dart';
import '../network/local_server.dart';
import '../network/transfer_manager.dart';
import '../security/crypto_service.dart';
import '../../data/datasources/settings_datasource.dart';
import '../../data/datasources/history_datasource.dart';
import '../../data/models/transfer_record_model.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/history_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Device info ────────────────────────────────────────────────────────
  final devicePlugin = DeviceInfoPlugin();
  String deviceName = 'Unknown Device';
  String platform = 'unknown';

  try {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final info = await devicePlugin.androidInfo;
        deviceName = info.model;
        platform = 'android';
      } else if (Platform.isIOS) {
        final info = await devicePlugin.iosInfo;
        deviceName = info.name;
        platform = 'ios';
      } else if (Platform.isMacOS) {
        final info = await devicePlugin.macOsInfo;
        deviceName = info.computerName;
        platform = 'macos';
      } else if (Platform.isWindows) {
        final info = await devicePlugin.windowsInfo;
        deviceName = info.computerName;
        platform = 'windows';
      } else if (Platform.isLinux) {
        final info = await devicePlugin.linuxInfo;
        deviceName = info.prettyName;
        platform = 'linux';
      }
    }
  } catch (_) {}

  // ─── Hive boxes ─────────────────────────────────────────────────────────
  final historyBox = Hive.box<TransferRecordModel>(AppConstants.transferHistoryBox);
  final settingsBox = Hive.box(AppConstants.settingsBox);

  // ─── Data sources ────────────────────────────────────────────────────────
  final settingsDs = SettingsDataSource(settingsBox, defaultDeviceName: deviceName);
  final historyDs = HistoryDataSource(historyBox);

  // ─── Repositories ────────────────────────────────────────────────────────
  final settingsRepo = SettingsRepositoryImpl(settingsDs);
  final historyRepo = HistoryRepositoryImpl(historyDs);

  getIt
    ..registerSingleton<SettingsRepository>(settingsRepo)
    ..registerSingleton<HistoryRepository>(historyRepo)
    ..registerSingleton<CryptoService>(CryptoService.instance);

  // ─── Transfer manager ────────────────────────────────────────────────────
  final transferSettings = settingsRepo.asTransferSettings();
  final transferManager = TransferManager(settings: transferSettings);
  getIt.registerSingleton<TransferManager>(transferManager);

  // ─── Network services ────────────────────────────────────────────────────
  final resolvedDeviceName = settingsDs.get(AppConstants.keyDeviceName, defaultDeviceName: deviceName);
  final deviceId = settingsDs.get('device_id', defaultDeviceName: const Uuid().v4());
  // Store deviceId if new
  if (!settingsBox.containsKey('device_id')) {
    await settingsBox.put('device_id', deviceId);
  }

  final localServer = LocalServer(
    deviceName: resolvedDeviceName,
    deviceId: deviceId,
    platform: platform,
    transferManager: transferManager,
  );
  getIt.registerSingleton<LocalServer>(localServer);

  final discoveryService = DiscoveryService();
  getIt.registerSingleton<DiscoveryService>(discoveryService);

  // ─── Start services ──────────────────────────────────────────────────────
  await localServer.start();
  await discoveryService.start(
    deviceName: resolvedDeviceName,
    deviceId: deviceId,
    platform: platform,
    serverPort: localServer.port,
  );
}
