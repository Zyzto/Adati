import 'package:drift/drift.dart';
import 'habits.dart';

class Streaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().unique().references(Habits, #id, onDelete: KeyAction.cascade)();
  // Combined streak (main streak shown on main page)
  IntColumn get combinedStreak => integer().withDefault(const Constant(0))();
  IntColumn get combinedLongestStreak => integer().withDefault(const Constant(0))();
  // Good habit streak (only for good habits)
  IntColumn get goodStreak => integer().withDefault(const Constant(0))();
  IntColumn get goodLongestStreak => integer().withDefault(const Constant(0))();
  // Bad habit streak (only for bad habits - not doing bad habit)
  IntColumn get badStreak => integer().withDefault(const Constant(0))();
  IntColumn get badLongestStreak => integer().withDefault(const Constant(0))();
  // Backward compatibility (map to combinedStreak)
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

