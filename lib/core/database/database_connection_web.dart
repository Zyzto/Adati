import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import '../services/log_helper.dart';

LazyDatabase openConnection() {
  Log.info('Using WasmDatabase (WebAssembly)');
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'adati',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor.executor;
  });
}

