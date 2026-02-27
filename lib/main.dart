// lib/main.dart
// LocalBeam — local file transfer app
// Made with 💙 by Adwith

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'data/models/transfer_record_model.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait + landscape on mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransferRecordModelAdapter());
  Hive.registerAdapter(TransferStatusAdapter());
  Hive.registerAdapter(TransferDirectionAdapter());

  await Hive.openBox<TransferRecordModel>(AppConstants.transferHistoryBox);
  await Hive.openBox(AppConstants.settingsBox);

  // Setup DI
  await setupDependencies();

  runApp(
    const ProviderScope(
      child: LocalBeamApp(),
    ),
  );
}
