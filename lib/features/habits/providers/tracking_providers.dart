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
  final habits = await ref.watch(habitsProvider.future);
  
  final entries = <int, bool>{};
  for (final habit in habits) {
    final entry = await repository.getEntry(habit.id, date);
    entries[habit.id] = entry?.completed ?? false;
  }
  
  yield entries;
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
  final habits = await ref.watch(habitsProvider.future);
  
  final streaks = <db.Streak>[];
  for (final habit in habits) {
    final streak = await repository.getStreakByHabit(habit.id);
    if (streak != null) {
      streaks.add(streak);
    }
  }
  
  yield streaks;
  
  // Also watch for changes
  await for (final habits in repository.watchAllHabits()) {
    final updatedStreaks = <db.Streak>[];
    for (final habit in habits) {
      final streak = await repository.getStreakByHabit(habit.id);
      if (streak != null) {
        updatedStreaks.add(streak);
      }
    }
    yield updatedStreaks;
  }
});

