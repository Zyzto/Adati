import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/app_database.dart' as db;
import 'habit_providers.dart';

final trackingEntriesProvider =
    StreamProvider.family<List<db.TrackingEntry>, int>((ref, habitId) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  await for (final entries in repository.watchEntriesByHabit(habitId)) {
    yield entries;
  }
});

final streakProvider = StreamProvider.family<db.Streak?, int>((ref, habitId) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  await for (final streak in repository.watchStreakByHabit(habitId)) {
    yield streak;
  }
});

final dayEntriesProvider =
    StreamProvider.family<Map<int, bool>, DateTime>((ref, date) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
  
  // Get initial habits
  final initialHabits = await ref.watch(habitsProvider.future);
  
  // Watch for entry changes by date - this will update when any entry changes
  await for (final entries in repository.watchEntriesByDate(dateOnly)) {
    // Get current habits (may have changed)
    final habits = ref.read(habitsProvider).value ?? initialHabits;
    final entriesMap = <int, bool>{};
    
    for (final habit in habits) {
      final entry = entries.where((e) => e.habitId == habit.id).firstOrNull;
      entriesMap[habit.id] = entry?.completed ?? false;
    }
    
    yield entriesMap;
  }
});

final todayEntryProvider = StreamProvider.family<bool, int>((ref, habitId) async* {
  ref.keepAlive();
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

// Date range parameter class for family provider
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

// Provider for date range entries - batches queries for multiple dates
final dateRangeEntriesProvider = StreamProvider.family<Map<DateTime, Map<int, bool>>, DateRange>((ref, params) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  final startDateOnly = app_date_utils.DateUtils.getDateOnly(params.startDate);
  final endDateOnly = app_date_utils.DateUtils.getDateOnly(params.endDate);
  
  // Get initial habits
  final initialHabits = await ref.watch(habitsProvider.future);
  
  // Watch for entry changes in the date range
  await for (final entries in repository.watchEntriesByDateRange(startDateOnly, endDateOnly)) {
    // Get current habits (may have changed)
    final habits = ref.read(habitsProvider).value ?? initialHabits;
    
    // Group entries by date
    final entriesByDate = <DateTime, Map<int, bool>>{};
    
    // Initialize all dates in range with false for all habits
    var currentDate = startDateOnly;
    while (!currentDate.isAfter(endDateOnly)) {
      entriesByDate[currentDate] = <int, bool>{};
      for (final habit in habits) {
        entriesByDate[currentDate]![habit.id] = false;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Fill in actual entry data
    for (final entry in entries) {
      final entryDate = app_date_utils.DateUtils.getDateOnly(entry.date);
      if (entriesByDate.containsKey(entryDate)) {
        entriesByDate[entryDate]![entry.habitId] = entry.completed;
      }
    }
    
    yield entriesByDate;
  }
});

final allStreaksProvider = StreamProvider<List<db.Streak>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  
  // Watch for habit changes
  await for (final habits in repository.watchAllHabits()) {
    // Get initial streaks for all habits - batch queries
    final streakFutures = habits.map((habit) => repository.getStreakByHabit(habit.id));
    final streakResults = await Future.wait(streakFutures);
    final streaks = streakResults.whereType<db.Streak>().toList();
    yield List.from(streaks);
    
    // Watch individual streak streams for each habit
    // When any streak updates (triggered by tracking entry changes), yield updated list
    if (habits.isNotEmpty) {
      // Watch the first habit's streak stream as a trigger
      // When any habit's tracking changes, its streak updates, which triggers this
      await for (final updatedStreak in repository.watchStreakByHabit(habits.first.id)) {
        if (updatedStreak != null) {
          // Recalculate all streaks when any streak changes - batch queries
          final updatedStreakFutures = habits.map((habit) => repository.getStreakByHabit(habit.id));
          final updatedStreakResults = await Future.wait(updatedStreakFutures);
          final updatedStreaks = updatedStreakResults.whereType<db.Streak>().toList();
          yield List.from(updatedStreaks);
        }
        // Break after first update to avoid too many recalculations
        // The stream will restart when habits change
        break;
      }
    }
  }
});

