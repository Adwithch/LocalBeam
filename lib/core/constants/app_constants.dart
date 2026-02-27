// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'LocalBeam';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Hive boxes
  static const String transferHistoryBox = 'transfer_history';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String keyDeviceName = 'device_name';
  static const String keyDownloadPath = 'download_path';
  static const String keyAutoAccept = 'auto_accept';
  static const String keyDefaultPassword = 'default_password';
  static const String keyPasswordEnabled = 'password_enabled';
  static const String keySessionTimeout = 'session_timeout';
  static const String keyMaxConcurrent = 'max_concurrent';
  static const String keyChunkSize = 'chunk_size';
  static const String keyBandwidthLimit = 'bandwidth_limit';
  static const String keyBandwidthLimitEnabled = 'bandwidth_limit_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingDone = 'onboarding_done';

  // Network
  static const int defaultServerPort = 7432;
  static const int defaultSignalingPort = 7433;
  static const String multicastGroup = '224.0.0.251';
  static const int multicastPort = 7434;
  static const String serviceType = '_localbeam._tcp';
  static const String serviceName = 'LocalBeam';

  // Transfer
  static const int defaultChunkSize = 512 * 1024; // 512 KB
  static const int maxChunkSize = 4 * 1024 * 1024; // 4 MB
  static const int minChunkSize = 64 * 1024; // 64 KB
  static const int defaultSessionTimeoutSeconds = 300; // 5 min
  static const int defaultMaxConcurrent = 3;
  static const int connectionTimeoutSeconds = 30;

  // Security
  static const int saltLength = 32;
  static const int ivLength = 16;
  static const int keyLength = 32;
  static const int pbkdf2Iterations = 100000;

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Author
  static const String authorName = 'Adwith';
  static const String authorInstagram =
      'https://www.instagram.com/a.dwith?igsh=MXdyeXU5cDM5YW5oeQ==';
  static const String repoUrl = 'https://github.com/adwith/localbeam';
  static const String licenseType = 'MIT License';
}

class ChunkSizeOption {
  final String label;
  final int bytes;
  const ChunkSizeOption(this.label, this.bytes);

  static const List<ChunkSizeOption> options = [
    ChunkSizeOption('64 KB (Slow networks)', 64 * 1024),
    ChunkSizeOption('256 KB', 256 * 1024),
    ChunkSizeOption('512 KB (Default)', 512 * 1024),
    ChunkSizeOption('1 MB', 1024 * 1024),
    ChunkSizeOption('2 MB', 2 * 1024 * 1024),
    ChunkSizeOption('4 MB (Fast LAN)', 4 * 1024 * 1024),
  ];
}
