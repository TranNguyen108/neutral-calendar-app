import 'package:flutter/foundation.dart';

class Logger {
  void log(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  void error(String message, {String tag = 'NC_APP', Object? error}) {
    if (kDebugMode) {
      print('[$tag] ERROR: $message');
      if (error != null) {
        print('[$tag] Error details: $error');
      }
    }
  }

  void info(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      print('[$tag] INFO: $message');
    }
  }

  void warning(String message, {String tag = 'NC_APP'}) {
    if (kDebugMode) {
      print('[$tag] WARNING: $message');
    }
  }
}
