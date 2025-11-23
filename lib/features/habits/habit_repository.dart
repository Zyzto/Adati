import 'dart:convert';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/daos/habit_dao.dart';
import 'package:adati/core/database/daos/tag_dao.dart';
import 'package:adati/core/database/daos/habit_tag_dao.dart';
import 'package:adati/core/database/daos/tracking_entry_dao.dart';
import 'package:adati/core/database/daos/streak_dao.dart';
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as app_date_utils;
import 'package:adati/core/services/loggable_mixin.dart';
import 'package:adati/core/services/notification_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';

class HabitRepository with Loggable {
  final db.AppDatabase _db;
  late final HabitDao _habitDao;
  late final TagDao _tagDao;
  late final HabitTagDao _habitTagDao;
  late final TrackingEntryDao _trackingEntryDao;
  late final StreakDao _streakDao;

  HabitRepository(this._db) {
    logDebug('HabitRepository initialized');
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
    logInfo('createHabit(name=${habit.name.value}, tagIds=$tagIds)');
    try {
      final habitId = await _habitDao.insertHabit(habit);
      if (tagIds != null && tagIds.isNotEmpty) {
        await _habitTagDao.setHabitTags(habitId, tagIds);
      }
      
      // Schedule reminders if enabled
      if (habit.reminderEnabled.present && 
          habit.reminderEnabled.value == true && 
          habit.reminderTime.present && 
          habit.reminderTime.value != null) {
        await _scheduleReminders(habitId, habit.name.value, habit.reminderTime.value!);
      }
      
      logInfo('createHabit() created habit with id=$habitId');
      return habitId;
    } catch (e, stackTrace) {
      logError('createHabit() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateHabit(
    db.HabitsCompanion habit, {
    List<int>? tagIds,
  }) async {
    final id = habit.id.value;
    logInfo('updateHabit(id=$id, tagIds=$tagIds)');
    try {
      // Get existing habit to check reminder changes
      final existingHabit = await getHabitById(id);
      
      final result = await _habitDao.updateHabit(habit);
      if (tagIds != null && habit.id.present) {
        await _habitTagDao.setHabitTags(habit.id.value, tagIds);
      }
      
      // Cancel existing reminders
      await _cancelReminders(id);
      
      // Schedule new reminders if enabled
      if (habit.reminderEnabled.present && 
          habit.reminderEnabled.value == true && 
          habit.reminderTime.present && 
          habit.reminderTime.value != null) {
        final habitName = habit.name.value.isNotEmpty 
            ? habit.name.value 
            : (existingHabit?.name ?? 'Habit');
        await _scheduleReminders(
          id,
          habitName,
          habit.reminderTime.value!,
        );
      }
      
      logInfo('updateHabit(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateHabit(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteHabit(int id) async {
    logInfo('deleteHabit(id=$id)');
    try {
      // Cancel reminders before deleting
      await _cancelReminders(id);
      
      final result = await _habitDao.deleteHabit(id);
      logInfo('deleteHabit(id=$id) deleted successfully');
      return result;
    } catch (e, stackTrace) {
      logError('deleteHabit(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

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

  Future<List<db.TrackingEntry>> getEntriesByDateRange(DateTime startDate, DateTime endDate) =>
      _trackingEntryDao.getEntriesByDateRange(startDate, endDate);

  Stream<List<db.TrackingEntry>> watchEntriesByDateRange(DateTime startDate, DateTime endDate) =>
      _trackingEntryDao.watchEntriesByDateRange(startDate, endDate);

  Future<bool> toggleCompletion(
    int habitId,
    DateTime date,
    bool completed, {
    String? notes,
  }) async {
    logInfo('toggleCompletion(habitId=$habitId, date=$date, completed=$completed)');
    try {
      final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
      final companion = db.TrackingEntriesCompanion(
        habitId: drift.Value(habitId),
        date: drift.Value(dateOnly),
        completed: drift.Value(completed),
        notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
      );
      await _trackingEntryDao.insertOrUpdateEntry(companion);
      await _updateStreak(habitId);
      logInfo('toggleCompletion() completed successfully');
      return true;
    } catch (e, stackTrace) {
      logError('toggleCompletion() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
    
    // Filter entries to only include dates >= habit creation date
    final habitCreatedAt = app_date_utils.DateUtils.getDateOnly(habit.createdAt);
    final validEntries = entries.where((e) {
      final entryDate = app_date_utils.DateUtils.getDateOnly(e.date);
      return app_date_utils.DateUtils.isDateAfterHabitCreation(entryDate, habitCreatedAt);
    }).toList();
    
    if (validEntries.isEmpty) {
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
    final successfulEntries = validEntries.where((e) {
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

  // Import helper methods
  Future<void> insertOrUpdateEntry(db.TrackingEntriesCompanion entry) async {
    await _trackingEntryDao.insertOrUpdateEntry(entry);
  }

  Future<void> insertOrUpdateStreak(db.StreaksCompanion streak) async {
    await _streakDao.insertOrUpdateStreak(streak);
  }

  // Advanced: Delete all data
  Future<void> deleteAllHabits() async {
    // Delete all habits (cascades to entries and streaks via foreign keys)
    await _db.delete(_db.habits).go();
  }

  Future<void> deleteAllTags() async {
    await _db.delete(_db.tags).go();
  }

  Future<void> deleteAllData() async {
    // Delete all data in correct order to respect foreign keys
    await _db.delete(_db.habitTags).go();
    await _db.delete(_db.trackingEntries).go();
    await _db.delete(_db.streaks).go();
    await _db.delete(_db.habits).go();
    await _db.delete(_db.tags).go();
  }

  // Advanced: Database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    try {
      // Use SQL aggregate queries for better performance
      final habitsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM habits',
        readsFrom: {_db.habits},
      ).getSingle();
      
      final tagsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM tags',
        readsFrom: {_db.tags},
      ).getSingle();
      
      final entriesCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM tracking_entries',
        readsFrom: {_db.trackingEntries},
      ).getSingle();
      
      final streaksCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM streaks',
        readsFrom: {_db.streaks},
      ).getSingle();
      
      return {
        'habits': habitsCount.read<int>('count'),
        'tags': tagsCount.read<int>('count'),
        'entries': entriesCount.read<int>('count'),
        'streaks': streaksCount.read<int>('count'),
      };
    } catch (e, stackTrace) {
      logError(
        'getDatabaseStats() failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Return zeros on error
      return {
        'habits': 0,
        'tags': 0,
        'entries': 0,
        'streaks': 0,
      };
    }
  }

  // Advanced: Vacuum database (optimize)
  Future<void> vacuumDatabase() async {
    await _db.customStatement('VACUUM');
  }

  // Reminder scheduling helpers
  Future<void> _scheduleReminders(int habitId, String habitName, String reminderTimeJson) async {
    try {
      final reminderData = jsonDecode(reminderTimeJson) as Map<String, dynamic>;
      final frequency = reminderData['frequency'] as String? ?? 'daily';
      final days = (reminderData['days'] as List<dynamic>?)?.cast<int>() ?? [];
      final timeStr = reminderData['time'] as String? ?? '09:00';
      
      final timeParts = timeStr.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 9;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (frequency == 'daily') {
        // Schedule daily notification
        var scheduledDate = DateTime(today.year, today.month, today.day, hour, minute);
        // If time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        
        await NotificationService.scheduleNotification(
          id: habitId,
          title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
          body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
          scheduledDate: scheduledDate,
          payload: habitId.toString(),
        );
        logInfo('Scheduled daily reminder for habit $habitId at $timeStr');
      } else if (frequency == 'weekly' && days.isNotEmpty) {
        // Schedule weekly notifications for specified days
        for (final dayOfWeek in days) {
          // dayOfWeek: 1=Monday, 7=Sunday
          final daysUntilNext = (dayOfWeek - now.weekday) % 7;
          final scheduledDate = today.add(Duration(days: daysUntilNext == 0 ? 7 : daysUntilNext));
          final scheduledDateTime = DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            hour,
            minute,
          );
          
          // Use habitId * 100 + dayOfWeek as unique notification ID
          await NotificationService.scheduleNotification(
            id: habitId * 100 + dayOfWeek,
            title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
            body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
            scheduledDate: scheduledDateTime,
            payload: habitId.toString(),
          );
        }
        logInfo('Scheduled weekly reminders for habit $habitId on days $days at $timeStr');
      } else if (frequency == 'monthly' && days.isNotEmpty) {
        // Schedule monthly notifications for specified days
        for (final dayOfMonth in days) {
          final currentMonth = DateTime(now.year, now.month, dayOfMonth, hour, minute);
          DateTime scheduledDate;
          
          if (currentMonth.isBefore(now)) {
            // If day has passed this month, schedule for next month
            scheduledDate = DateTime(now.year, now.month + 1, dayOfMonth, hour, minute);
          } else {
            scheduledDate = currentMonth;
          }
          
          // Use habitId * 1000 + dayOfMonth as unique notification ID
          await NotificationService.scheduleNotification(
            id: habitId * 1000 + dayOfMonth,
            title: 'reminder_title'.tr(namedArgs: {'habit': habitName}),
            body: 'reminder_body'.tr(namedArgs: {'habit': habitName}),
            scheduledDate: scheduledDate,
            payload: habitId.toString(),
          );
        }
        logInfo('Scheduled monthly reminders for habit $habitId on days $days at $timeStr');
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to schedule reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - allow habit creation/update to succeed even if reminders fail
    }
  }

  Future<void> _cancelReminders(int habitId) async {
    try {
      // Cancel daily reminder (uses habitId as notification ID)
      await NotificationService.cancelNotification(habitId);
      
      // Cancel weekly reminders (habitId * 100 + dayOfWeek, where dayOfWeek is 1-7)
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
        await NotificationService.cancelNotification(habitId * 100 + dayOfWeek);
      }
      
      // Cancel monthly reminders (habitId * 1000 + dayOfMonth, where dayOfMonth is 1-31)
      for (int dayOfMonth = 1; dayOfMonth <= 31; dayOfMonth++) {
        await NotificationService.cancelNotification(habitId * 1000 + dayOfMonth);
      }
      
      logInfo('Cancelled all reminders for habit $habitId');
    } catch (e, stackTrace) {
      logError(
        'Failed to cancel reminders for habit $habitId',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - allow operation to continue
    }
  }
}
