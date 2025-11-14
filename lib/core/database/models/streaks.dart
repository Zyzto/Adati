import 'package:drift/drift.dart';
import 'habits.dart';

class Streaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().unique().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

