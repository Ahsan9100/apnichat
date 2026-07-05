import 'package:flutter/foundation.dart';

/// ErrorHandler provides standardized ways of dealing with exceptions and errors
/// across the application, logging them or returning user-friendly messages.
class ErrorHandler {
  /// Handles generic exceptions
  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('==================== ERROR ====================');
      print(error.toString());
      if (stackTrace != null) {
        print(stackTrace.toString());
      }
      print('===============================================');
    }
    // In production, integrate Crashlytics or Sentry here
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Extracts a user-friendly message from different types of errors
  static String getErrorMessage(dynamic error) {
    // Check for Firebase exceptions and return friendly strings later
    return error.toString();
  }
}
