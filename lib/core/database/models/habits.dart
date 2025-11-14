import 'package:drift/drift.dart';
import 'categories.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer()();
  TextColumn get icon => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get reminderTime => text().nullable()(); // Store as "HH:mm" format
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

