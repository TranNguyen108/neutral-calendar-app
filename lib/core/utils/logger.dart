import 'package:flutter/foundation.dart';

/// Centralized logging utility
/// Only logs in debug mode to prevent console clutter in production
class Logger {
  void log(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  void error(String message, {String tag = 'NC_APP', Object? error}) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) {
        debugPrint('[$tag] Error details: $error');
      }
    }
  }

  void info(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      debugPrint('[$tag] INFO: $message');
    }
  }

  void warning(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $message');
    }
  }
}
