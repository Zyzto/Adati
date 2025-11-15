import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' as db;
import '../habit_repository.dart';
import '../../settings/providers/settings_providers.dart';

final databaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HabitRepository(db);
});

final habitsProvider = StreamProvider<List<db.Habit>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final habits in repository.watchAllHabits()) {
    yield habits;
  }
});

final tagsProvider = StreamProvider<List<db.Tag>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final tags in repository.watchAllTags()) {
    yield tags;
  }
});

final habitTagsProvider = StreamProvider.family<List<db.Tag>, int>((ref, habitId) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final tags in repository.watchTagsForHabit(habitId)) {
    yield tags;
  }
});

final habitByIdProvider = StreamProvider.family<db.Habit?, int>((ref, id) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final habitData = await repository.getHabitById(id);
  yield habitData;
  
  // Also watch for changes
  await for (final habits in repository.watchAllHabits()) {
    final habitData = habits.where((h) => h.id == id).firstOrNull;
    yield habitData;
  }
});

// Filtered and sorted habits provider
final filteredSortedHabitsProvider = Provider<AsyncValue<List<db.Habit>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final sortOrder = ref.watch(habitSortOrderProvider);
  final filterQuery = ref.watch(habitFilterQueryProvider);

  return habitsAsync.when(
    data: (habits) {
      // Apply filter
      var filtered = habits;
      if (filterQuery != null && filterQuery.isNotEmpty) {
        final query = filterQuery.toLowerCase();
        filtered = habits.where((habit) {
          return habit.name.toLowerCase().contains(query) ||
              (habit.description?.toLowerCase().contains(query) ?? false);
        }).toList();
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
          // Sort by current streak (requires async, so we'll do it differently)
          sorted.sort((a, b) {
            // This will be handled by a separate provider that includes streak data
            return 0;
          });
          break;
        case 'created':
          sorted.sort((a, b) => a.id.compareTo(b.id)); // Assuming ID reflects creation order
          break;
        case 'created_desc':
          sorted.sort((a, b) => b.id.compareTo(a.id));
          break;
        default:
          break;
      }

      return AsyncValue.data(sorted);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

