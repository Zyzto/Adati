import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/log_helper.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'adati.db'));
      Log.info('Database path: ${file.path}');
      
      // Ensure the directory exists
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
        Log.info('Created database directory: ${dbFolder.path}');
      }
      
      final database = NativeDatabase(file);
      Log.info('Database connection opened successfully');
      return database;
    } catch (e, stackTrace) {
      Log.error(
        'Failed to open database connection',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Let Drift handle the error, but log it first
    }
  });
}

