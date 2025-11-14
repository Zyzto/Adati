import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/habits.dart';
import '../models/categories.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits, Categories])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Future<List<Habit>> getAllHabits() => select(db.habits).get();

  Stream<List<Habit>> watchAllHabits() => select(db.habits).watch();

  Future<List<Habit>> getHabitsByCategory(int? categoryId) {
    if (categoryId == null) {
      return (select(db.habits)..where((h) => h.categoryId.isNull())).get();
    }
    return (select(db.habits)..where((h) => h.categoryId.equals(categoryId))).get();
  }

  Stream<List<Habit>> watchHabitsByCategory(int? categoryId) {
    if (categoryId == null) {
      return (select(db.habits)..where((h) => h.categoryId.isNull())).watch();
    }
    return (select(db.habits)..where((h) => h.categoryId.equals(categoryId))).watch();
  }

  Future<Habit?> getHabitById(int id) =>
      (select(db.habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<int> insertHabit(HabitsCompanion habit) =>
      into(db.habits).insert(habit);

  Future<bool> updateHabit(HabitsCompanion habit) =>
      update(db.habits).replace(habit);

  Future<int> deleteHabit(int id) =>
      (delete(db.habits)..where((h) => h.id.equals(id))).go();
}

