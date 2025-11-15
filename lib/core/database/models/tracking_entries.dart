import 'package:drift/drift.dart';
import 'habits.dart';

class TrackingEntries extends Table {
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  // Measurable tracking
  RealColumn get value => real().nullable()(); // Value for measurable tracking
  // Occurrences tracking
  TextColumn get occurrenceData => text().nullable()(); // JSON array of completed occurrence names
  TextColumn get notes => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {habitId, date};
}

