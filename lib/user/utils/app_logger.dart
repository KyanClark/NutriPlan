import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for the NutriPlan app
/// 
/// Provides different log levels:
/// - debug: Detailed information for debugging (only in debug mode)
/// - info: General informational messages
/// - warning: Warning messages that might indicate potential issues
/// - error: Error messages that need attention
/// 
/// Example usage:
/// ```dart
/// AppLogger.debug('Searching for ingredient');
/// AppLogger.info('User logged in successfully');
/// AppLogger.warning('Low nutrition data accuracy');
/// AppLogger.error('Failed to fetch recipe', error: e);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    // Only log errors in release mode
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Log debug messages (only shown in debug mode)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log informational messages
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log verbose/trace messages (most detailed)
  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
      if (kDebugMode) {
      _logger.t(message, error: error, stackTrace: stackTrace);
    }
  }
}

