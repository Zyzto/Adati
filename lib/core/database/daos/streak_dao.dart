import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/streaks.dart';
import '../models/habits.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'streak_dao.g.dart';

@DriftAccessor(tables: [Streaks, Habits])
class StreakDao extends DatabaseAccessor<AppDatabase>
    with _$StreakDaoMixin, Loggable {
  StreakDao(super.db);

  Future<Streak?> getStreakByHabit(int habitId) async {
    logDebug('getStreakByHabit(habitId=$habitId) called');
    try {
      final result = await (select(
        db.streaks,
      )..where((s) => s.habitId.equals(habitId))).getSingleOrNull();
      logDebug(
        'getStreakByHabit(habitId=$habitId) returned ${result != null ? "streak" : "null"}',
      );
      return result;
    } catch (e, stackTrace) {
      logError(
        'getStreakByHabit(habitId=$habitId) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<Streak?> watchStreakByHabit(int habitId) {
    logDebug('watchStreakByHabit(habitId=$habitId) called');
    return (select(
      db.streaks,
    )..where((s) => s.habitId.equals(habitId))).watchSingleOrNull();
  }

  Future<void> insertOrUpdateStreak(StreaksCompanion streak) async {
    final habitId = streak.habitId.value;
    logDebug('insertOrUpdateStreak(habitId=$habitId) called');
    try {
      // Check if streak exists for this habit
      final existing = await getStreakByHabit(habitId);

      if (existing != null) {
        // Update existing streak, preserving the existing id
        await (update(db.streaks)..where((s) => s.habitId.equals(habitId)))
            .write(streak.copyWith(id: Value(existing.id)));
        logInfo(
          'insertOrUpdateStreak(habitId=$habitId) updated existing streak',
        );
      } else {
        // Insert new streak (id will be auto-generated)
        await into(db.streaks).insert(streak);
        logInfo('insertOrUpdateStreak(habitId=$habitId) inserted new streak');
      }
    } catch (e, stackTrace) {
      logError(
        'insertOrUpdateStreak(habitId=$habitId) failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> deleteStreak(int id) async {
    logDebug('deleteStreak(id=$id) called');
    try {
      final result = await (delete(
        db.streaks,
      )..where((s) => s.id.equals(id))).go();
      logInfo('deleteStreak(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteStreak(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
