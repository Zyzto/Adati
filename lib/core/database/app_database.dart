import 'package:drift/drift.dart';
import 'models/habits.dart';
import 'models/tracking_entries.dart';
import 'models/streaks.dart';
import 'models/tags.dart';
import 'models/habit_tags.dart';
import '../services/logging_service.dart';
import 'database_connection.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Habits, TrackingEntries, Streaks, Tags, HabitTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 4;

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

        if (from < 3) {
          // Migration 2->3: Convert categories to tags system
          // Create tags table (same structure as categories)
          await m.database.executor.runCustom('''
            CREATE TABLE tags (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 100),
              color INTEGER NOT NULL,
              icon TEXT,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
            );
            
            -- Copy all categories to tags
            -- If created_at is already in milliseconds, use as-is; otherwise convert from seconds
            INSERT INTO tags (id, name, color, icon, created_at)
            SELECT 
              id, 
              name, 
              color, 
              icon, 
              CASE 
                WHEN created_at < 10000000000 THEN created_at * 1000 
                ELSE created_at 
              END as created_at
            FROM categories;
            
            -- Create habit_tags junction table
            CREATE TABLE habit_tags (
              habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
              tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
              PRIMARY KEY (habit_id, tag_id)
            );
            
            -- Migrate existing category relationships to tags
            INSERT INTO habit_tags (habit_id, tag_id)
            SELECT id, category_id FROM habits WHERE category_id IS NOT NULL;
            
            -- Note: We keep categories table for now to avoid breaking existing code
            -- It can be removed in a future migration if needed
            ''');
          LoggingService.info(
            'Migration 2->3: Converted categories to tags system',
          );
        }

        if (from < 4) {
          // Migration 3->4: Remove unused components and add new tracking system
          await m.database.executor.runCustom('''
            -- Step 1: Remove categories table (no longer needed)
            DROP TABLE IF EXISTS categories;
            
            -- Step 2: Recreate habits table with new columns
            CREATE TABLE habits_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 100),
              description TEXT,
              color INTEGER NOT NULL,
              icon TEXT,
              habit_type INTEGER NOT NULL DEFAULT 0,
              tracking_type TEXT NOT NULL DEFAULT 'completed',
              unit TEXT,
              goal_value REAL,
              goal_period TEXT,
              occurrence_names TEXT,
              reminder_enabled INTEGER NOT NULL DEFAULT 0 CHECK ("reminder_enabled" IN (0, 1)),
              reminder_time TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
            
            -- Migrate existing habits data
            INSERT INTO habits_new (
              id, name, description, color, icon, habit_type, tracking_type,
              reminder_enabled, reminder_time, created_at, updated_at
            )
            SELECT 
              id, name, description, color, icon, 0, 'completed',
              reminder_enabled, reminder_time, created_at, updated_at
            FROM habits;
            
            DROP TABLE habits;
            ALTER TABLE habits_new RENAME TO habits;
            
            -- Step 3: Recreate tracking_entries table without id column
            CREATE TABLE tracking_entries_new (
              habit_id INTEGER NOT NULL,
              date INTEGER NOT NULL,
              completed INTEGER NOT NULL DEFAULT 0 CHECK ("completed" IN (0, 1)),
              value REAL,
              occurrence_data TEXT,
              notes TEXT,
              PRIMARY KEY (habit_id, date),
              FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
            );
            
            -- Migrate existing tracking entries
            INSERT INTO tracking_entries_new (
              habit_id, date, completed, notes
            )
            SELECT habit_id, date, completed, notes FROM tracking_entries;
            
            DROP TABLE tracking_entries;
            ALTER TABLE tracking_entries_new RENAME TO tracking_entries;
            
            -- Step 4: Recreate streaks table with new columns
            CREATE TABLE streaks_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
              habit_id INTEGER NOT NULL UNIQUE,
              combined_streak INTEGER NOT NULL DEFAULT 0,
              combined_longest_streak INTEGER NOT NULL DEFAULT 0,
              good_streak INTEGER NOT NULL DEFAULT 0,
              good_longest_streak INTEGER NOT NULL DEFAULT 0,
              bad_streak INTEGER NOT NULL DEFAULT 0,
              bad_longest_streak INTEGER NOT NULL DEFAULT 0,
              current_streak INTEGER NOT NULL DEFAULT 0,
              longest_streak INTEGER NOT NULL DEFAULT 0,
              last_updated INTEGER NOT NULL,
              FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
            );
            
            -- Migrate existing streaks data
            INSERT INTO streaks_new (
              id, habit_id, combined_streak, combined_longest_streak,
              good_streak, good_longest_streak, bad_streak, bad_longest_streak,
              current_streak, longest_streak, last_updated
            )
            SELECT 
              id, habit_id, 
              COALESCE(current_streak, 0), COALESCE(longest_streak, 0),
              COALESCE(current_streak, 0), COALESCE(longest_streak, 0),
              0, 0,
              COALESCE(current_streak, 0), COALESCE(longest_streak, 0),
              last_updated
            FROM streaks;
            
            DROP TABLE streaks;
            ALTER TABLE streaks_new RENAME TO streaks;
            ''');
          LoggingService.info(
            'Migration 3->4: Removed unused components and added new tracking system',
          );
        }
      },
    );
  }
}
