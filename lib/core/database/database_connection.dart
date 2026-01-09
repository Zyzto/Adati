import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Opens a database connection using drift_flutter which handles
/// all platform-specific setup automatically (native, web WASM, etc.)
QueryExecutor openConnection() {
  Log.info('Opening database connection with drift_flutter');
  
  // drift_flutter handles platform-specific setup automatically:
  // - Native: Uses sqlite3_flutter_libs
  // - Web: Uses WASM with IndexedDB for persistence
  return driftDatabase(
    name: 'adati',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
