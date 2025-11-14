import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../domain/models/tracking_entry.dart';
import '../../domain/models/streak.dart';

final trackingEntriesProvider =
    StreamProvider.family<List<TrackingEntry>, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final entries in repository.watchEntriesByHabit(habitId)) {
    yield entries.map((e) => TrackingEntry(
          id: e.id,
          habitId: e.habitId,
          date: e.date,
          completed: e.completed,
          notes: e.notes,
        )).toList();
  }
});

final streakProvider = StreamProvider.family<Streak?, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final streak in repository.watchStreakByHabit(habitId)) {
    if (streak != null) {
      yield Streak(
        id: streak.id,
        habitId: streak.habitId,
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        lastUpdated: streak.lastUpdated,
      );
    } else {
      yield null;
    }
  }
});

final dayEntriesProvider =
    StreamProvider.family<Map<int, bool>, DateTime>((ref, date) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final habits = await ref.watch(habitsProvider.future);
  
  final entries = <int, bool>{};
  for (final habit in habits) {
    final entry = await repository.getEntry(habit.id!, date);
    entries[habit.id!] = entry?.completed ?? false;
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

final allStreaksProvider = StreamProvider<List<Streak>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final habits = await ref.watch(habitsProvider.future);
  
  final streaks = <Streak>[];
  for (final habit in habits) {
    final streak = await repository.getStreakByHabit(habit.id!);
    if (streak != null) {
      streaks.add(Streak(
        id: streak.id,
        habitId: streak.habitId,
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        lastUpdated: streak.lastUpdated,
      ));
    }
  }
  
  yield streaks;
  
  // Also watch for changes
  await for (final habits in repository.watchAllHabits()) {
    final updatedStreaks = <Streak>[];
    for (final habit in habits) {
      final streak = await repository.getStreakByHabit(habit.id);
      if (streak != null) {
        updatedStreaks.add(Streak(
          id: streak.id,
          habitId: streak.habitId,
          currentStreak: streak.currentStreak,
          longestStreak: streak.longestStreak,
          lastUpdated: streak.lastUpdated,
        ));
      }
    }
    yield updatedStreaks;
  }
});

