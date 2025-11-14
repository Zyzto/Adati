import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../data/habit_repository.dart';
import '../../domain/models/habit.dart' as domain;
import '../../domain/models/category.dart' as domain;

final databaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HabitRepository(db);
});

final habitsProvider = StreamProvider<List<domain.Habit>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final habits in repository.watchAllHabits()) {
    yield habits.map((h) {
      return domain.Habit(
        id: h.id,
        name: h.name,
        description: h.description,
        color: h.color,
        icon: h.icon,
        categoryId: h.categoryId,
        reminderEnabled: h.reminderEnabled,
        reminderTime: h.reminderTime,
        createdAt: h.createdAt,
        updatedAt: h.updatedAt,
      );
    }).toList();
  }
});

final categoriesProvider = StreamProvider<List<domain.Category>>((ref) async* {
  final repository = ref.watch(habitRepositoryProvider);
  await for (final categories in repository.watchAllCategories()) {
    yield categories.map((c) {
      return domain.Category(
        id: c.id,
        name: c.name,
        color: c.color,
        icon: c.icon,
        createdAt: c.createdAt,
      );
    }).toList();
  }
});

final habitByIdProvider = StreamProvider.family<domain.Habit?, int>((ref, id) async* {
  final repository = ref.watch(habitRepositoryProvider);
  final habitData = await repository.getHabitById(id);
  if (habitData != null) {
    yield domain.Habit(
      id: habitData.id,
      name: habitData.name,
      description: habitData.description,
      color: habitData.color,
      icon: habitData.icon,
      categoryId: habitData.categoryId,
      reminderEnabled: habitData.reminderEnabled,
      reminderTime: habitData.reminderTime,
      createdAt: habitData.createdAt,
      updatedAt: habitData.updatedAt,
    );
  } else {
    yield null;
  }
  
  // Also watch for changes
  await for (final habits in repository.watchAllHabits()) {
    final habitData = habits.where((h) => h.id == id).firstOrNull;
    if (habitData != null) {
      yield domain.Habit(
        id: habitData.id,
        name: habitData.name,
        description: habitData.description,
        color: habitData.color,
        icon: habitData.icon,
        categoryId: habitData.categoryId,
        reminderEnabled: habitData.reminderEnabled,
        reminderTime: habitData.reminderTime,
        createdAt: habitData.createdAt,
        updatedAt: habitData.updatedAt,
      );
    } else {
      yield null;
    }
  }
});

