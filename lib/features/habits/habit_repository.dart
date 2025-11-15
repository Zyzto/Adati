import 'dart:convert';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/daos/habit_dao.dart';
import 'package:adati/core/database/daos/tag_dao.dart';
import 'package:adati/core/database/daos/habit_tag_dao.dart';
import 'package:adati/core/database/daos/tracking_entry_dao.dart';
import 'package:adati/core/database/daos/streak_dao.dart';
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as app_date_utils;
import 'package:drift/drift.dart' as drift;

class HabitRepository {
  final db.AppDatabase _db;
  late final HabitDao _habitDao;
  late final TagDao _tagDao;
  late final HabitTagDao _habitTagDao;
  late final TrackingEntryDao _trackingEntryDao;
  late final StreakDao _streakDao;

  HabitRepository(this._db) {
    _habitDao = HabitDao(_db);
    _tagDao = TagDao(_db);
    _habitTagDao = HabitTagDao(_db);
    _trackingEntryDao = TrackingEntryDao(_db);
    _streakDao = StreakDao(_db);
  }

  // Habits
  Stream<List<db.Habit>> watchAllHabits() => _habitDao.watchAllHabits();

  Future<List<db.Habit>> getAllHabits() => _habitDao.getAllHabits();

  Future<db.Habit?> getHabitById(int id) => _habitDao.getHabitById(id);

  Future<int> createHabit(db.HabitsCompanion habit, {List<int>? tagIds}) async {
    final habitId = await _habitDao.insertHabit(habit);
    if (tagIds != null && tagIds.isNotEmpty) {
      await _habitTagDao.setHabitTags(habitId, tagIds);
    }
    return habitId;
  }

  Future<bool> updateHabit(
    db.HabitsCompanion habit, {
    List<int>? tagIds,
  }) async {
    final result = await _habitDao.updateHabit(habit);
    if (tagIds != null && habit.id.present) {
      await _habitTagDao.setHabitTags(habit.id.value, tagIds);
    }
    return result;
  }

  Future<int> deleteHabit(int id) => _habitDao.deleteHabit(id);

  // Tags
  Stream<List<db.Tag>> watchAllTags() => _tagDao.watchAllTags();

  Future<List<db.Tag>> getAllTags() => _tagDao.getAllTags();

  Future<db.Tag?> getTagById(int id) => _tagDao.getTagById(id);

  Future<List<db.Tag>> getTagsForHabit(int habitId) =>
      _habitTagDao.getTagsForHabit(habitId);

  Stream<List<db.Tag>> watchTagsForHabit(int habitId) =>
      _habitTagDao.watchTagsForHabit(habitId);

  Future<int> createTag(db.TagsCompanion tag) => _tagDao.insertTag(tag);

  Future<bool> updateTag(db.TagsCompanion tag) => _tagDao.updateTag(tag);

  Future<int> deleteTag(int id) => _tagDao.deleteTag(id);

  Future<List<db.Habit>> getHabitsByTag(int tagId) =>
      _habitTagDao.getHabitsByTag(tagId);

  Stream<List<db.Habit>> watchHabitsByTag(int tagId) =>
      _habitTagDao.watchHabitsByTag(tagId);

  // Tracking
  Stream<List<db.TrackingEntry>> watchEntriesByHabit(int habitId) =>
      _trackingEntryDao.watchEntriesByHabit(habitId);

  Future<List<db.TrackingEntry>> getEntriesByHabit(int habitId) =>
      _trackingEntryDao.getEntriesByHabit(habitId);

  Future<db.TrackingEntry?> getEntry(int habitId, DateTime date) =>
      _trackingEntryDao.getEntry(habitId, date);

  Future<List<db.TrackingEntry>> getEntriesByDate(DateTime date) =>
      _trackingEntryDao.getEntriesByDate(date);

  Stream<List<db.TrackingEntry>> watchEntriesByDate(DateTime date) =>
      _trackingEntryDao.watchEntriesByDate(date);

  Future<bool> toggleCompletion(
    int habitId,
    DateTime date,
    bool completed, {
    String? notes,
  }) async {
    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
    final companion = db.TrackingEntriesCompanion(
      habitId: drift.Value(habitId),
      date: drift.Value(dateOnly),
      completed: drift.Value(completed),
      notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
    );
    await _trackingEntryDao.insertOrUpdateEntry(companion);
    await _updateStreak(habitId);
    return true;
  }

  /// Track measurable value for a habit
  Future<bool> trackMeasurable(
    int habitId,
    DateTime date,
    double value, {
    String? notes,
  }) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return false;

    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
    
    // Check if goal is reached
    bool completed = false;
    if (habit.goalValue != null) {
      if (habit.habitType == HabitType.good.value) {
        // Good habit: complete when goal is reached
        completed = value >= habit.goalValue!;
      } else {
        // Bad habit: fail if exceeds limit
        // For period-based goals, we need to check the period
        if (habit.goalPeriod == 'daily') {
          completed = value <= habit.goalValue!;
        } else if (habit.goalPeriod == 'weekly') {
          // Calculate weekly total
          final weekStart = dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          final weekEntries = await _trackingEntryDao.getEntriesByHabit(habitId);
          final weekTotal = weekEntries
              .where((e) {
                final eDate = app_date_utils.DateUtils.getDateOnly(e.date);
                return eDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                    eDate.isBefore(weekEnd.add(const Duration(days: 1))) &&
                    e.value != null;
              })
              .fold<double>(0.0, (sum, e) => sum + (e.value ?? 0.0));
          completed = (weekTotal + value) <= habit.goalValue!;
        } else if (habit.goalPeriod == 'monthly') {
          // Calculate monthly total
          final monthStart = DateTime(dateOnly.year, dateOnly.month, 1);
          final monthEnd = DateTime(dateOnly.year, dateOnly.month + 1, 0);
          final monthEntries = await _trackingEntryDao.getEntriesByHabit(habitId);
          final monthTotal = monthEntries
              .where((e) {
                final eDate = app_date_utils.DateUtils.getDateOnly(e.date);
                return eDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                    eDate.isBefore(monthEnd.add(const Duration(days: 1))) &&
                    e.value != null;
              })
              .fold<double>(0.0, (sum, e) => sum + (e.value ?? 0.0));
          completed = (monthTotal + value) <= habit.goalValue!;
        }
      }
    } else {
      // No goal set, any value means completed
      completed = value > 0;
    }

    final companion = db.TrackingEntriesCompanion(
      habitId: drift.Value(habitId),
      date: drift.Value(dateOnly),
      completed: drift.Value(completed),
      value: drift.Value(value),
      notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
    );
    await _trackingEntryDao.insertOrUpdateEntry(companion);
    await _updateStreak(habitId);
    return true;
  }

  /// Track occurrences for a habit
  Future<bool> trackOccurrences(
    int habitId,
    DateTime date,
    List<String> completedOccurrences, {
    String? notes,
  }) async {
    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
    final occurrenceDataJson = jsonEncode(completedOccurrences);
    final completed = completedOccurrences.isNotEmpty;

    final companion = db.TrackingEntriesCompanion(
      habitId: drift.Value(habitId),
      date: drift.Value(dateOnly),
      completed: drift.Value(completed),
      occurrenceData: drift.Value(occurrenceDataJson),
      notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
    );
    await _trackingEntryDao.insertOrUpdateEntry(companion);
    await _updateStreak(habitId);
    return true;
  }

  Future<bool> _updateStreak(int habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return false;

    final entries = await getEntriesByHabit(habitId);
    if (entries.isEmpty) {
      final companion = db.StreaksCompanion(
        id: const drift.Value.absent(),
        habitId: drift.Value(habitId),
        combinedStreak: drift.Value(0),
        combinedLongestStreak: drift.Value(0),
        goodStreak: drift.Value(0),
        goodLongestStreak: drift.Value(0),
        badStreak: drift.Value(0),
        badLongestStreak: drift.Value(0),
        currentStreak: drift.Value(0),
        longestStreak: drift.Value(0),
        lastUpdated: drift.Value(DateTime.now()),
      );
      await _streakDao.insertOrUpdateStreak(companion);
      return false;
    }

    // Calculate streaks based on habit type
    final isGoodHabit = habit.habitType == HabitType.good.value;
    
    // For good habits: completed = true means success
    // For bad habits: completed = false means success (not doing bad habit)
    final successfulEntries = entries.where((e) {
      if (isGoodHabit) {
        return e.completed;
      } else {
        return !e.completed;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate combined streak (for main page)
    final combinedStreaks = _calculateStreak(successfulEntries);
    
    // Calculate type-specific streaks
    int goodStreak = 0;
    int goodLongestStreak = 0;
    int badStreak = 0;
    int badLongestStreak = 0;

    if (isGoodHabit) {
      goodStreak = combinedStreaks.current;
      goodLongestStreak = combinedStreaks.longest;
    } else {
      badStreak = combinedStreaks.current;
      badLongestStreak = combinedStreaks.longest;
    }

    final companion = db.StreaksCompanion(
      id: const drift.Value.absent(),
      habitId: drift.Value(habitId),
      combinedStreak: drift.Value(combinedStreaks.current),
      combinedLongestStreak: drift.Value(combinedStreaks.longest),
      goodStreak: drift.Value(goodStreak),
      goodLongestStreak: drift.Value(goodLongestStreak),
      badStreak: drift.Value(badStreak),
      badLongestStreak: drift.Value(badLongestStreak),
      // Backward compatibility
      currentStreak: drift.Value(combinedStreaks.current),
      longestStreak: drift.Value(combinedStreaks.longest),
      lastUpdated: drift.Value(DateTime.now()),
    );
    await _streakDao.insertOrUpdateStreak(companion);

    return true;
  }

  /// Calculate streak from sorted entries (newest first)
  ({int current, int longest}) _calculateStreak(List<db.TrackingEntry> sortedEntries) {
    if (sortedEntries.isEmpty) {
      return (current: 0, longest: 0);
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    final today = app_date_utils.DateUtils.getToday();

    for (final entry in sortedEntries) {
      final entryDate = app_date_utils.DateUtils.getDateOnly(entry.date);
      if (lastDate == null) {
        if (app_date_utils.DateUtils.isToday(entryDate) ||
            app_date_utils.DateUtils.isSameDay(
              entryDate,
              today.subtract(const Duration(days: 1)),
            )) {
          tempStreak = 1;
          if (app_date_utils.DateUtils.isToday(entryDate)) {
            currentStreak = 1;
          }
        }
        lastDate = entryDate;
      } else {
        final daysDiff = app_date_utils.DateUtils.daysBetween(
          entryDate,
          lastDate,
        );
        if (daysDiff == 1) {
          tempStreak++;
          if (lastDate == today ||
              lastDate == today.subtract(const Duration(days: 1))) {
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

    return (current: currentStreak, longest: longestStreak);
  }

  // Streaks
  Stream<db.Streak?> watchStreakByHabit(int habitId) =>
      _streakDao.watchStreakByHabit(habitId);

  Future<db.Streak?> getStreakByHabit(int habitId) =>
      _streakDao.getStreakByHabit(habitId);
}
