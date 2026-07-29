import 'package:logger/logger.dart';
import '../config/app_config.dart';

class AppLogger {
  static late Logger _logger;

  static void init() {
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: AppConfig.isDevelopment ? Level.debug : Level.warning,
    );
  }

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  // ✅ canonical warning method
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // ✅ alias so AppLogger.warn() works
  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    warning(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}