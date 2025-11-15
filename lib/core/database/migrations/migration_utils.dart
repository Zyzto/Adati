import 'package:drift/drift.dart';
import '../app_database.dart' as db;
import '../models/tracking_types.dart';

/// Utility class for development/testing migrations
class MigrationUtils {
  /// Migrate old habits to new schema
  /// This is useful for development when testing migrations
  static Future<void> migrateOldHabitsToNewSchema(db.AppDatabase database) async {
    final habits = await database.select(database.habits).get();
    
    for (final habit in habits) {
      // If habit doesn't have tracking type set, set it to 'completed'
      if (habit.trackingType.isEmpty) {
        await (database.update(database.habits)
              ..where((h) => h.id.equals(habit.id)))
            .write(db.HabitsCompanion(
          trackingType: const Value('completed'),
          habitType: Value(HabitType.good.value),
        ));
      }
    }
  }

}

