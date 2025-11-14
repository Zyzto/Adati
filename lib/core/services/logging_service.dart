import 'package:easy_logger/easy_logger.dart';

class LoggingService {
  static final EasyLogger _logger = EasyLogger(
    name: 'Adati',
  );

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.debug(message);
    if (error != null) {
      _logger.debug('Error: $error');
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message);
    if (error != null) {
      _logger.info('Error: $error');
    }
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message);
    if (error != null) {
      _logger.warning('Error: $error');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.error(message);
    if (error != null) {
      _logger.error('Error: $error');
    }
  }

  static void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.error(message);
    if (error != null) {
      _logger.error('Error: $error');
    }
  }
}

