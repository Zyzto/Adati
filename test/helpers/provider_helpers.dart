import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/features/habits/habit_repository.dart';
import 'database_helpers.dart';

/// Creates a provider override for HabitRepository with a test database
/// Returns a list that can be used with ProviderScope.overrides
Future<List<dynamic>> createHabitRepositoryOverrides({
  db.AppDatabase? testDatabase,
}) async {
  final database = testDatabase ?? await createTestDatabase();
  // Repository is created but not used yet - will be used when providers are set up
  // ignore: unused_local_variable
  final repository = HabitRepository(database);
  
  return [
    // Add provider overrides here when needed
    // For example: habitRepositoryProvider.overrideWithValue(repository)
  ];
}

/// Creates a test container with overrides
ProviderContainer createTestContainer({
  dynamic overrides,
}) {
  return ProviderContainer(
    overrides: overrides ?? [],
  );
}

