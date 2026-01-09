import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/tracking_entries.dart';
import '../models/habits.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'tracking_entry_dao.g.dart';

@DriftAccessor(tables: [TrackingEntries, Habits])
class TrackingEntryDao extends DatabaseAccessor<AppDatabase>
    with _$TrackingEntryDaoMixin, Loggable {
  TrackingEntryDao(super.db);

  Future<List<TrackingEntry>> getEntriesByHabit(int habitId) async {
    logDebug('getEntriesByHabit(habitId=$habitId) called');
    try {
      final result = await (select(db.trackingEntries)
            ..where((e) => e.habitId.equals(habitId))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();
      logDebug('getEntriesByHabit(habitId=$habitId) returned ${result.length} entries');
      return result;
    } catch (e, stackTrace) {
      logError('getEntriesByHabit(habitId=$habitId) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<TrackingEntry>> watchEntriesByHabit(int habitId) {
    logDebug('watchEntriesByHabit(habitId=$habitId) called');
    return (select(db.trackingEntries)
          ..where((e) => e.habitId.equals(habitId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  Future<List<TrackingEntry>> getEntriesByDate(DateTime date) async {
    logDebug('getEntriesByDate(date=$date) called');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final result = await (select(db.trackingEntries)..where(
            (e) =>
                e.date.isBiggerOrEqualValue(startOfDay) &
                e.date.isSmallerThanValue(endOfDay),
          ))
          .get();
      logDebug('getEntriesByDate(date=$date) returned ${result.length} entries');
      return result;
    } catch (e, stackTrace) {
      logError('getEntriesByDate(date=$date) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<TrackingEntry>> watchEntriesByDate(DateTime date) {
    logDebug('watchEntriesByDate(date=$date) called');
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(db.trackingEntries)..where(
          (e) =>
              e.date.isBiggerOrEqualValue(startOfDay) &
              e.date.isSmallerThanValue(endOfDay),
        ))
        .watch();
  }

  Future<List<TrackingEntry>> getEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    logDebug('getEntriesByDateRange(startDate=$startDate, endDate=$endDate) called');
    try {
      final startOfFirstDay = DateTime(startDate.year, startDate.month, startDate.day);
      final endOfLastDay = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));
      final result = await (select(db.trackingEntries)..where(
            (e) =>
                e.date.isBiggerOrEqualValue(startOfFirstDay) &
                e.date.isSmallerThanValue(endOfLastDay),
          ))
          .get();
      logDebug('getEntriesByDateRange(startDate=$startDate, endDate=$endDate) returned ${result.length} entries');
      return result;
    } catch (e, stackTrace) {
      logError('getEntriesByDateRange(startDate=$startDate, endDate=$endDate) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<TrackingEntry>> watchEntriesByDateRange(DateTime startDate, DateTime endDate) {
    logDebug('watchEntriesByDateRange(startDate=$startDate, endDate=$endDate) called');
    final startOfFirstDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfLastDay = DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1));
    return (select(db.trackingEntries)..where(
          (e) =>
              e.date.isBiggerOrEqualValue(startOfFirstDay) &
              e.date.isSmallerThanValue(endOfLastDay),
        ))
        .watch();
  }

  Future<TrackingEntry?> getEntry(int habitId, DateTime date) async {
    logDebug('getEntry(habitId=$habitId, date=$date) called');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final result = await (select(db.trackingEntries)..where(
            (e) =>
                e.habitId.equals(habitId) &
                e.date.isBiggerOrEqualValue(startOfDay) &
                e.date.isSmallerThanValue(endOfDay),
          ))
          .getSingleOrNull();
      logDebug('getEntry(habitId=$habitId, date=$date) returned ${result != null ? "entry" : "null"}');
      return result;
    } catch (e, stackTrace) {
      logError('getEntry(habitId=$habitId, date=$date) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> insertOrUpdateEntry(TrackingEntriesCompanion entry) async {
    final habitId = entry.habitId.value;
    final date = entry.date.value;
    logDebug('insertOrUpdateEntry(habitId=$habitId, date=$date) called');
    try {
      // Extract values from Companion
      // Check if entry exists first
      final existing = await getEntry(habitId, date);

      if (existing != null) {
        // Update existing entry
        await (update(db.trackingEntries)
              ..where((e) => e.habitId.equals(habitId) & e.date.equals(date)))
            .write(entry);
        logInfo('insertOrUpdateEntry(habitId=$habitId, date=$date) updated existing entry');
      } else {
        // Insert new entry
        await into(db.trackingEntries).insert(entry);
        logInfo('insertOrUpdateEntry(habitId=$habitId, date=$date) inserted new entry');
      }
    } catch (e, stackTrace) {
      logError('insertOrUpdateEntry(habitId=$habitId, date=$date) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteEntry(int habitId, DateTime date) async {
    logDebug('deleteEntry(habitId=$habitId, date=$date) called');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final result = await (delete(db.trackingEntries)
            ..where(
              (e) =>
                  e.habitId.equals(habitId) &
                  e.date.isBiggerOrEqualValue(startOfDay) &
                  e.date.isSmallerThanValue(endOfDay),
            ))
          .go();
      logInfo('deleteEntry(habitId=$habitId, date=$date) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteEntry(habitId=$habitId, date=$date) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteEntriesByHabit(int habitId) async {
    logDebug('deleteEntriesByHabit(habitId=$habitId) called');
    try {
      final result = await (delete(
        db.trackingEntries,
      )..where((e) => e.habitId.equals(habitId))).go();
      logInfo('deleteEntriesByHabit(habitId=$habitId) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteEntriesByHabit(habitId=$habitId) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
