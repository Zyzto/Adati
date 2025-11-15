import 'package:drift/drift.dart';
import 'habits.dart';
import 'tags.dart';

class HabitTags extends Table {
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();
  
  @override
  Set<Column> get primaryKey => {habitId, tagId};
}

