// lib/presentation/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/transfer/transfer_screen.dart';
import 'screens/receive/receive_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/file_picker/file_picker_screen.dart';

class LocalBeamApp extends ConsumerWidget {
  const LocalBeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = switch (settings.themeMode) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    final onboardingDone = Hive.box(AppConstants.settingsBox)
        .get(AppConstants.keyOnboardingDone, defaultValue: false) as bool;
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: onboardingDone ? '/home' : '/onboarding',
      onGenerateRoute: _generateRoute,
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings s) {
    switch (s.name) {
      case '/onboarding': return _fade(const OnboardingScreen(), s);
      case '/home': return _fade(const HomeScreen(), s);
      case '/transfer': return _slide(TransferScreen(args: s.arguments as Map<String, dynamic>?), s);
      case '/receive': return _slide(const ReceiveScreen(), s);
      case '/history': return _slide(const HistoryScreen(), s);
      case '/settings': return _slide(const SettingsScreen(), s);
      case '/about': return _slide(const AboutScreen(), s);
      case '/file-picker': return _slide(const FilePickerScreen(), s);
      default: return _fade(const HomeScreen(), s);
    }
  }

  static PageRoute<T> _fade<T>(Widget p, RouteSettings s) => PageRouteBuilder<T>(
    settings: s, pageBuilder: (_, __, ___) => p,
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    transitionDuration: AppConstants.animationNormal,
  );

  static PageRoute<T> _slide<T>(Widget p, RouteSettings s) => PageRouteBuilder<T>(
    settings: s, pageBuilder: (_, __, ___) => p,
    transitionsBuilder: (_, a, __, c) => SlideTransition(
      position: a.drive(Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
      child: c,
    ),
    transitionDuration: AppConstants.animationNormal,
  );
}
