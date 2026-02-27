// lib/core/utils/logger.dart

import 'package:logger/logger.dart';

final _globalLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
  ),
  level: Level.debug,
);

/// Per-class logger with tag prefix.
class AppLogger {
  final String tag;
  const AppLogger(this.tag);

  void debug(String msg, [dynamic data]) =>
      _globalLogger.d('[$tag] $msg', error: data);
  void info(String msg, [dynamic data]) =>
      _globalLogger.i('[$tag] $msg', error: data);
  void warn(String msg, [dynamic data]) =>
      _globalLogger.w('[$tag] $msg', error: data);
  void error(String msg, [dynamic error, StackTrace? stack]) =>
      _globalLogger.e('[$tag] $msg', error: error, stackTrace: stack);

  static Logger get raw => _globalLogger;
}

// lib/core/utils/size_formatter.dart

class SizeFormatter {
  static String format(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(int bytesPerSecond) {
    return '${format(bytesPerSecond)}/s';
  }

  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}
