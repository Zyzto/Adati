import 'package:drift/drift.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer()();
  TextColumn get icon => text().nullable()();
  IntColumn get habitType => integer().withDefault(const Constant(0))(); // 0=good, 1=bad
  TextColumn get trackingType => text().withDefault(const Constant('completed'))(); // completed, measurable, occurrences
  // Measurable tracking configuration
  TextColumn get unit => text().nullable()(); // Unit for measurable tracking (e.g., "minutes", "km")
  RealColumn get goalValue => real().nullable()(); // Goal value for measurable tracking
  TextColumn get goalPeriod => text().nullable()(); // daily, weekly, monthly
  // Occurrences tracking configuration
  TextColumn get occurrenceNames => text().nullable()(); // JSON array of occurrence names
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get reminderTime => text().nullable()(); // Store as "HH:mm" format
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

