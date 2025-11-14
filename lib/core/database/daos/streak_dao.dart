import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/streaks.dart';
import '../models/habits.dart';

part 'streak_dao.g.dart';

@DriftAccessor(tables: [Streaks, Habits])
class StreakDao extends DatabaseAccessor<AppDatabase> with _$StreakDaoMixin {
  StreakDao(super.db);

  Future<Streak?> getStreakByHabit(int habitId) => (select(
    db.streaks,
  )..where((s) => s.habitId.equals(habitId))).getSingleOrNull();

  Stream<Streak?> watchStreakByHabit(int habitId) => (select(
    db.streaks,
  )..where((s) => s.habitId.equals(habitId))).watchSingleOrNull();

  Future<void> insertOrUpdateStreak(StreaksCompanion streak) async {
    // Check if streak exists for this habit
    final existing = await getStreakByHabit(streak.habitId.value);

    if (existing != null) {
      // Update existing streak, preserving the existing id
      await (update(db.streaks)
            ..where((s) => s.habitId.equals(streak.habitId.value)))
          .write(streak.copyWith(id: Value(existing.id)));
    } else {
      // Insert new streak (id will be auto-generated)
      await into(db.streaks).insert(streak);
    }
  }

  Future<int> deleteStreak(int id) =>
      (delete(db.streaks)..where((s) => s.id.equals(id))).go();
}
