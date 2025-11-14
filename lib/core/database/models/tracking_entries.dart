import 'package:drift/drift.dart';
import 'habits.dart';

class TrackingEntries extends Table {
  IntColumn get id => integer().nullable()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {habitId, date};
}

