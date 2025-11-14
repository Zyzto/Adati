import 'package:drift/drift.dart';
import 'models/categories.dart';
import 'models/habits.dart';
import 'models/tracking_entries.dart';
import 'models/streaks.dart';
import '../services/logging_service.dart';
import 'database_connection.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Habits, TrackingEntries, Streaks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        LoggingService.info('Database created');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        LoggingService.info('Database upgraded from $from to $to');

        if (from < 2) {
          // Migration 1->2: Make tracking_entries.id nullable
          // SQLite doesn't support ALTER COLUMN, so we need to recreate the table
          await m.database.executor.runCustom('''
            CREATE TABLE tracking_entries_new (
              id INTEGER,
              habit_id INTEGER NOT NULL,
              date INTEGER NOT NULL,
              completed INTEGER NOT NULL DEFAULT 0,
              notes TEXT,
              PRIMARY KEY (habit_id, date),
              FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
            );
            
            INSERT INTO tracking_entries_new (id, habit_id, date, completed, notes)
            SELECT id, habit_id, date, completed, notes FROM tracking_entries;
            
            DROP TABLE tracking_entries;
            
            ALTER TABLE tracking_entries_new RENAME TO tracking_entries;
            ''');
          LoggingService.info(
            'Migration 1->2: Made tracking_entries.id nullable',
          );
        }
      },
    );
  }
}
