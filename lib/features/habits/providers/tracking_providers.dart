import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/app_database.dart' as db;
import 'habit_providers.dart';

final trackingEntriesProvider =
    StreamProvider.family<List<db.TrackingEntry>, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final entries in repository.watchEntriesByHabit(habitId)) {
    yield entries;
  }
});

final streakProvider = StreamProvider.family<db.Streak?, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final streak in repository.watchStreakByHabit(habitId)) {
    yield streak;
  }
});

final dayEntriesProvider =
    StreamProvider.family<Map<int, bool>, DateTime>((ref, date) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
  
  // Watch for entry changes by date - this will update when any entry changes
  await for (final entries in repository.watchEntriesByDate(dateOnly)) {
    // Get all current habits
    final habits = await ref.watch(habitsProvider.future);
    final entriesMap = <int, bool>{};
    
    for (final habit in habits) {
      final entry = entries.where((e) => e.habitId == habit.id).firstOrNull;
      entriesMap[habit.id] = entry?.completed ?? false;
    }
    
    yield entriesMap;
  }
});

final todayEntryProvider = StreamProvider.family<bool, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final today = app_date_utils.DateUtils.getToday();
  
  // Get initial value
  final entry = await repository.getEntry(habitId, today);
  yield entry?.completed ?? false;
  
  // Watch for changes
  await for (final entries in repository.watchEntriesByHabit(habitId)) {
    final todayEntry = entries.where((e) => 
      app_date_utils.DateUtils.isSameDay(e.date, today)
    ).firstOrNull;
    yield todayEntry?.completed ?? false;
  }
});

final allStreaksProvider = StreamProvider<List<db.Streak>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  
  // Watch for habit changes
  await for (final habits in repository.watchAllHabits()) {
    // Get initial streaks for all habits
    final streaks = <db.Streak>[];
    for (final habit in habits) {
      final streak = await repository.getStreakByHabit(habit.id);
      if (streak != null) {
        streaks.add(streak);
      }
    }
    yield List.from(streaks);
    
    // Watch individual streak streams for each habit
    // When any streak updates (triggered by tracking entry changes), yield updated list
    if (habits.isNotEmpty) {
      // Watch the first habit's streak stream as a trigger
      // When any habit's tracking changes, its streak updates, which triggers this
      await for (final updatedStreak in repository.watchStreakByHabit(habits.first.id)) {
        if (updatedStreak != null) {
          // Recalculate all streaks when any streak changes
          final updatedStreaks = <db.Streak>[];
          for (final habit in habits) {
            final streak = await repository.getStreakByHabit(habit.id);
            if (streak != null) {
              updatedStreaks.add(streak);
            }
          }
          yield List.from(updatedStreaks);
        }
        // Break after first update to avoid too many recalculations
        // The stream will restart when habits change
        break;
      }
    }
  }
});

