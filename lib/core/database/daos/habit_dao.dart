import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/habits.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Future<List<Habit>> getAllHabits() => select(db.habits).get();

  Stream<List<Habit>> watchAllHabits() => select(db.habits).watch();

  Future<Habit?> getHabitById(int id) =>
      (select(db.habits)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<int> insertHabit(HabitsCompanion habit) =>
      into(db.habits).insert(habit);

  Future<bool> updateHabit(HabitsCompanion habit) =>
      update(db.habits).replace(habit);

  Future<int> deleteHabit(int id) =>
      (delete(db.habits)..where((h) => h.id.equals(id))).go();
}
