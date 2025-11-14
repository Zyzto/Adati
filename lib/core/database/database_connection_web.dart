import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import '../services/logging_service.dart';

LazyDatabase openConnection() {
  LoggingService.info('Using WebDatabase (IndexedDB)');
  // Note: drift/web.dart is deprecated but still functional
  // For production, consider migrating to drift/wasm.dart
  return LazyDatabase(() => WebDatabase('adati', logStatements: false));
}

