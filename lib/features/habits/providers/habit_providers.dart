import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/models/tracking_types.dart';
import '../habit_repository.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/log_helper.dart';

/// Singleton database instance to avoid multiple database warnings.
/// This ensures all parts of the app use the same database connection.
db.AppDatabase? _databaseInstance;

db.AppDatabase getDatabase() {
  _databaseInstance ??= db.AppDatabase();
  return _databaseInstance!;
}

final databaseProvider = Provider<db.AppDatabase>((ref) {
  return getDatabase();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HabitRepository(db);
});

final habitsProvider = StreamProvider<List<db.Habit>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  try {
    await for (final habits in repository.watchAllHabits()) {
      yield habits;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in habitsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final tagsProvider = StreamProvider<List<db.Tag>>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  try {
    await for (final tags in repository.watchAllTags()) {
      yield tags;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in tagsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final habitTagsProvider = StreamProvider.family<List<db.Tag>, int>((
  ref,
  habitId,
) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  try {
    await for (final tags in repository.watchTagsForHabit(habitId)) {
      yield tags;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in habitTagsProvider stream for habitId=$habitId',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

final habitByIdProvider = StreamProvider.family<db.Habit?, int>((
  ref,
  id,
) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  try {
    // Get initial value
    final habitData = await repository.getHabitById(id);
    yield habitData;

    // Watch for changes - the keepAlive() above prevents recreation on hot reload
    await for (final habits in repository.watchAllHabits()) {
      final habitData = habits.where((h) => h.id == id).firstOrNull;
      yield habitData;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in habitByIdProvider stream for id=$id',
      error: e,
      stackTrace: stackTrace,
    );
    yield null; // Yield null on error to prevent crashes
  }
});

// Filtered and sorted habits provider
final filteredSortedHabitsProvider = StreamProvider<List<db.Habit>>((
  ref,
) async* {
  ref.keepAlive();
  final sortOrder = ref.watch(habitSortOrderProvider);
  final filterQuery = ref.watch(habitFilterQueryProvider);
  final filterByType = ref.watch(habitFilterByTypeProvider);
  final filterByTags = ref.watch(habitFilterByTagsProvider);
  final repository = ref.watch(habitRepositoryProvider);

  try {
    await for (final habits in repository.watchAllHabits()) {
    // Apply text filter
    var filtered = habits;
    if (filterQuery != null && filterQuery.isNotEmpty) {
      final query = filterQuery.toLowerCase();
      final filteredList = <db.Habit>[];
      for (final habit in habits) {
        // Check name and description
        final matchesName = habit.name.toLowerCase().contains(query);
        final matchesDescription =
            habit.description?.toLowerCase().contains(query) ?? false;

        // Check tags
        bool matchesTags = false;
        if (!matchesName && !matchesDescription) {
          final habitTags = await repository.getTagsForHabit(habit.id);
          matchesTags = habitTags.any(
            (tag) => tag.name.toLowerCase().contains(query),
          );
        }

        if (matchesName || matchesDescription || matchesTags) {
          filteredList.add(habit);
        }
      }
      filtered = filteredList;
    }

    // Apply type filter
    if (filterByType != null && filterByType.isNotEmpty) {
      const filterTypeGood = 'good';
      const filterTypeBad = 'bad';
      if (filterByType == filterTypeGood) {
        filtered = filtered
            .where((h) => h.habitType == HabitType.good.value)
            .toList();
      } else if (filterByType == filterTypeBad) {
        filtered = filtered
            .where((h) => h.habitType == HabitType.bad.value)
            .toList();
      }
      // 'all' or null means no filter
    }

    // Apply tag filter
    if (filterByTags != null && filterByTags.isNotEmpty) {
      final tagIds = filterByTags
          .split(',')
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toList();
      if (tagIds.isNotEmpty) {
        final filteredList = <db.Habit>[];
        for (final habit in filtered) {
          final habitTags = await repository.getTagsForHabit(habit.id);
          final habitTagIds = habitTags.map((t) => t.id).toList();
          if (tagIds.any((id) => habitTagIds.contains(id))) {
            filteredList.add(habit);
          }
        }
        filtered = filteredList;
      }
    }

    // Apply sort
    final sorted = List<db.Habit>.from(filtered);
    switch (sortOrder) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'streak':
      case 'streak_desc':
        // Sort by streak - batch queries for better performance
        final streaks = <int, int>{};
        // Batch all streak queries
        final streakFutures = sorted.map((habit) async {
          final streak = await repository.getStreakByHabit(habit.id);
          return MapEntry(habit.id, streak?.combinedStreak ?? 0);
        });
        final streakResults = await Future.wait(streakFutures);
        for (final entry in streakResults) {
          streaks[entry.key] = entry.value;
        }
        if (sortOrder == 'streak') {
          sorted.sort(
            (a, b) => (streaks[b.id] ?? 0).compareTo(streaks[a.id] ?? 0),
          );
        } else {
          sorted.sort(
            (a, b) => (streaks[a.id] ?? 0).compareTo(streaks[b.id] ?? 0),
          );
        }
        break;
      case 'created':
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'created_desc':
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      default:
        break;
    }

    yield sorted;
    }
  } catch (e, stackTrace) {
    Log.error(
      'Error in filteredSortedHabitsProvider stream',
      error: e,
      stackTrace: stackTrace,
    );
    yield []; // Yield empty list on error to prevent crashes
  }
});

// Habit Group By
class HabitGroupByNotifier {
  String? _groupBy;

  HabitGroupByNotifier() : _groupBy = PreferencesService.getHabitGroupBy();

  String? get groupBy => _groupBy;

  Future<void> setHabitGroupBy(String? groupBy) async {
    _groupBy = groupBy;
    await PreferencesService.setHabitGroupBy(groupBy);
  }
}

final habitGroupByNotifierProvider = Provider<HabitGroupByNotifier>((ref) {
  return HabitGroupByNotifier();
});

final habitGroupByProvider = Provider<String?>((ref) {
  return ref.watch(habitGroupByNotifierProvider).groupBy;
});

// Habit Filter By Type
class HabitFilterByTypeNotifier {
  String? _filterByType;

  HabitFilterByTypeNotifier()
    : _filterByType = PreferencesService.getHabitFilterByType();

  String? get filterByType => _filterByType;

  Future<void> setHabitFilterByType(String? filterByType) async {
    _filterByType = filterByType;
    await PreferencesService.setHabitFilterByType(filterByType);
  }
}

final habitFilterByTypeNotifierProvider = Provider<HabitFilterByTypeNotifier>((
  ref,
) {
  return HabitFilterByTypeNotifier();
});

final habitFilterByTypeProvider = Provider<String?>((ref) {
  return ref.watch(habitFilterByTypeNotifierProvider).filterByType;
});

// Habit Filter By Tags
class HabitFilterByTagsNotifier {
  String? _filterByTags;

  HabitFilterByTagsNotifier()
    : _filterByTags = PreferencesService.getHabitFilterByTags();

  String? get filterByTags => _filterByTags;

  Future<void> setHabitFilterByTags(String? filterByTags) async {
    _filterByTags = filterByTags;
    await PreferencesService.setHabitFilterByTags(filterByTags);
  }
}

final habitFilterByTagsNotifierProvider = Provider<HabitFilterByTagsNotifier>((
  ref,
) {
  return HabitFilterByTagsNotifier();
});

final habitFilterByTagsProvider = Provider<String?>((ref) {
  return ref.watch(habitFilterByTagsNotifierProvider).filterByTags;
});

// Session-based view options (override global settings)
class SessionViewOptions {
  final bool? showTags;
  final bool? showDescriptions;
  final bool? compactCards;

  SessionViewOptions({this.showTags, this.showDescriptions, this.compactCards});

  SessionViewOptions copyWith({
    bool? showTags,
    bool? showDescriptions,
    bool? compactCards,
  }) {
    return SessionViewOptions(
      showTags: showTags ?? this.showTags,
      showDescriptions: showDescriptions ?? this.showDescriptions,
      compactCards: compactCards ?? this.compactCards,
    );
  }
}

// Global state for session view options (session-based, not persisted)
SessionViewOptions _globalSessionViewOptions = SessionViewOptions();

// Provider that returns the current session view options
final sessionViewOptionsProvider = Provider<SessionViewOptions>((ref) {
  return _globalSessionViewOptions;
});

// Helper function to update session options and invalidate provider
void updateSessionViewOptions(WidgetRef ref, SessionViewOptions newOptions) {
  _globalSessionViewOptions = newOptions;
  ref.invalidate(sessionViewOptionsProvider);
}

// Demo data provider
final hasDemoDataProvider = StreamProvider<bool>((ref) async* {
  ref.keepAlive();
  final repository = ref.watch(habitRepositoryProvider);
  await for (final _ in repository.watchAllHabits()) {
    try {
      final hasDemo = await DemoDataService.hasDemoData(repository);
      yield hasDemo;
    } catch (e) {
      yield false;
    }
  }
});
