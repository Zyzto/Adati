import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:adati/core/database/app_database.dart' as db;

/// Creates an in-memory database for testing
/// This database is isolated and will be destroyed when the test completes
Future<db.AppDatabase> createTestDatabase() async {
  // Use NativeDatabase.memory() for in-memory SQLite database
  final executor = LazyDatabase(() async => NativeDatabase.memory());
  
  // Create AppDatabase with the in-memory executor
  final database = db.AppDatabase(executor);
  
  // The database will automatically run migrations on first use
  // We can trigger schema creation by accessing a table
  await database.customSelect('SELECT 1').get();
  
  return database;
}

/// Creates a test database and returns it along with a cleanup function
Future<({db.AppDatabase database, Future<void> Function() cleanup})> 
    createTestDatabaseWithCleanup() async {
  final database = await createTestDatabase();
  
  Future<void> cleanup() async {
    await database.close();
  }
  
  return (database: database, cleanup: cleanup);
}

