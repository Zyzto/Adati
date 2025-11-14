import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' as db;
import '../habit_repository.dart';

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

final categoriesProvider = StreamProvider<List<db.Category>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final categories in repository.watchAllCategories()) {
    yield categories;
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

