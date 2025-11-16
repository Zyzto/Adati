import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/habits.dart';
import '../../services/loggable_mixin.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin, Loggable {
  HabitDao(super.db);

  Future<List<Habit>> getAllHabits() async {
    logDebug('getAllHabits() called');
    try {
      final result = await select(db.habits).get();
      logInfo('getAllHabits() returned ${result.length} habits');
      return result;
    } catch (e, stackTrace) {
      logError('getAllHabits() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Habit>> watchAllHabits() {
    logDebug('watchAllHabits() called');
    return select(db.habits).watch();
  }

  Future<Habit?> getHabitById(int id) async {
    logDebug('getHabitById(id=$id) called');
    try {
      final result = await (select(db.habits)..where((h) => h.id.equals(id))).getSingleOrNull();
      logDebug('getHabitById(id=$id) returned ${result != null ? "habit" : "null"}');
      return result;
    } catch (e, stackTrace) {
      logError('getHabitById(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> insertHabit(HabitsCompanion habit) async {
    logDebug('insertHabit(name=${habit.name.value}) called');
    try {
      final id = await into(db.habits).insert(habit);
      logInfo('insertHabit() inserted habit with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertHabit() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateHabit(HabitsCompanion habit) async {
    final id = habit.id.value;
    logDebug('updateHabit(id=$id) called');
    try {
      final result = await update(db.habits).replace(habit);
      logInfo('updateHabit(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateHabit(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteHabit(int id) async {
    logDebug('deleteHabit(id=$id) called');
    try {
      final result = await (delete(db.habits)..where((h) => h.id.equals(id))).go();
      logInfo('deleteHabit(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteHabit(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
