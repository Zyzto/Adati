import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/daos/habit_dao.dart';
import 'package:adati/core/database/daos/category_dao.dart';
import 'package:adati/core/database/daos/tracking_entry_dao.dart';
import 'package:adati/core/database/daos/streak_dao.dart';
import 'package:adati/core/utils/date_utils.dart' as app_date_utils;
import '../domain/models/habit.dart' as domain;
import '../domain/models/category.dart' as domain;
import '../../tracking/domain/models/tracking_entry.dart' as domain;
import '../../tracking/domain/models/streak.dart' as domain;

class HabitRepository {
  final db.AppDatabase _db;
  late final HabitDao _habitDao;
  late final CategoryDao _categoryDao;
  late final TrackingEntryDao _trackingEntryDao;
  late final StreakDao _streakDao;

  HabitRepository(this._db) {
    _habitDao = HabitDao(_db);
    _categoryDao = CategoryDao(_db);
    _trackingEntryDao = TrackingEntryDao(_db);
    _streakDao = StreakDao(_db);
  }

  // Habits
  Stream<List<db.Habit>> watchAllHabits() => _habitDao.watchAllHabits();

  Stream<List<db.Habit>> watchHabitsByCategory(int? categoryId) =>
      _habitDao.watchHabitsByCategory(categoryId);

  Future<List<db.Habit>> getAllHabits() => _habitDao.getAllHabits();

  Future<db.Habit?> getHabitById(int id) => _habitDao.getHabitById(id);

  Future<int> createHabit(domain.Habit habit) =>
      _habitDao.insertHabit(habit.toCompanion());

  Future<bool> updateHabit(domain.Habit habit) =>
      _habitDao.updateHabit(habit.toCompanion());

  Future<int> deleteHabit(int id) => _habitDao.deleteHabit(id);

  // Categories
  Stream<List<db.Category>> watchAllCategories() =>
      _categoryDao.watchAllCategories();

  Future<List<db.Category>> getAllCategories() =>
      _categoryDao.getAllCategories();

  Future<db.Category?> getCategoryById(int id) =>
      _categoryDao.getCategoryById(id);

  Future<int> createCategory(domain.Category category) =>
      _categoryDao.insertCategory(category.toCompanion());

  Future<bool> updateCategory(domain.Category category) =>
      _categoryDao.updateCategory(category.toCompanion());

  Future<int> deleteCategory(int id) => _categoryDao.deleteCategory(id);

  // Tracking
  Stream<List<db.TrackingEntry>> watchEntriesByHabit(int habitId) =>
      _trackingEntryDao.watchEntriesByHabit(habitId);

  Future<List<db.TrackingEntry>> getEntriesByHabit(int habitId) =>
      _trackingEntryDao.getEntriesByHabit(habitId);

  Future<db.TrackingEntry?> getEntry(int habitId, DateTime date) =>
      _trackingEntryDao.getEntry(habitId, date);

  Future<bool> toggleCompletion(int habitId, DateTime date, bool completed,
      {String? notes}) async {
      final entry = domain.TrackingEntry(
      habitId: habitId,
      date: app_date_utils.DateUtils.getDateOnly(date),
      completed: completed,
      notes: notes,
    );
    await _trackingEntryDao.insertOrUpdateEntry(entry.toCompanion());
    await _updateStreak(habitId);
    return true;
  }

  Future<bool> _updateStreak(int habitId) async {
    final entries = await getEntriesByHabit(habitId);
    if (entries.isEmpty) return false;

    final sortedEntries = entries
        .where((e) => e.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedEntries.isEmpty) {
      await _streakDao.insertOrUpdateStreak(
        domain.Streak(habitId: habitId, lastUpdated: DateTime.now()).toCompanion(),
      );
      return false;
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final entry in sortedEntries) {
      final entryDate = app_date_utils.DateUtils.getDateOnly(entry.date);
      if (lastDate == null) {
        if (app_date_utils.DateUtils.isToday(entryDate) ||
            app_date_utils.DateUtils.isSameDay(entryDate, app_date_utils.DateUtils.getToday().subtract(const Duration(days: 1)))) {
          tempStreak = 1;
          if (app_date_utils.DateUtils.isToday(entryDate)) {
            currentStreak = 1;
          }
        }
        lastDate = entryDate;
      } else {
        final daysDiff = app_date_utils.DateUtils.daysBetween(entryDate, lastDate);
        if (daysDiff == 1) {
          tempStreak++;
          if (lastDate == app_date_utils.DateUtils.getToday() || lastDate == app_date_utils.DateUtils.getToday().subtract(const Duration(days: 1))) {
            currentStreak = tempStreak;
          }
        } else {
          longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
          tempStreak = 1;
        }
        lastDate = entryDate;
      }
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
    }

    await _streakDao.insertOrUpdateStreak(
      domain.Streak(
        habitId: habitId,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastUpdated: DateTime.now(),
      ).toCompanion(),
    );

    return true;
  }

  // Streaks
  Stream<db.Streak?> watchStreakByHabit(int habitId) =>
      _streakDao.watchStreakByHabit(habitId);

  Future<db.Streak?> getStreakByHabit(int habitId) =>
      _streakDao.getStreakByHabit(habitId);
}

