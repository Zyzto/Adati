import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/tracking_entries.dart';
import '../models/habits.dart';

part 'tracking_entry_dao.g.dart';

@DriftAccessor(tables: [TrackingEntries, Habits])
class TrackingEntryDao extends DatabaseAccessor<AppDatabase>
    with _$TrackingEntryDaoMixin {
  TrackingEntryDao(super.db);

  Future<List<TrackingEntry>> getEntriesByHabit(int habitId) =>
      (select(db.trackingEntries)
            ..where((e) => e.habitId.equals(habitId))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .get();

  Stream<List<TrackingEntry>> watchEntriesByHabit(int habitId) =>
      (select(db.trackingEntries)
            ..where((e) => e.habitId.equals(habitId))
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .watch();

  Future<List<TrackingEntry>> getEntriesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(db.trackingEntries)..where(
          (e) =>
              e.date.isBiggerOrEqualValue(startOfDay) &
              e.date.isSmallerThanValue(endOfDay),
        ))
        .get();
  }

  Stream<List<TrackingEntry>> watchEntriesByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(db.trackingEntries)..where(
          (e) =>
              e.date.isBiggerOrEqualValue(startOfDay) &
              e.date.isSmallerThanValue(endOfDay),
        ))
        .watch();
  }

  Future<TrackingEntry?> getEntry(int habitId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(db.trackingEntries)..where(
          (e) =>
              e.habitId.equals(habitId) &
              e.date.isBiggerOrEqualValue(startOfDay) &
              e.date.isSmallerThanValue(endOfDay),
        ))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateEntry(TrackingEntriesCompanion entry) async {
    // Extract values from Companion
    final habitId = entry.habitId.value;
    final date = entry.date.value;

    // Check if entry exists first
    final existing = await getEntry(habitId, date);

    if (existing != null) {
      // Update existing entry
      await (update(db.trackingEntries)
            ..where((e) => e.habitId.equals(habitId) & e.date.equals(date)))
          .write(entry);
    } else {
      // Insert new entry
      await into(db.trackingEntries).insert(entry);
    }
  }

  Future<int> deleteEntry(int habitId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (delete(db.trackingEntries)
          ..where(
            (e) =>
                e.habitId.equals(habitId) &
                e.date.isBiggerOrEqualValue(startOfDay) &
                e.date.isSmallerThanValue(endOfDay),
          ))
        .go();
  }

  Future<int> deleteEntriesByHabit(int habitId) => (delete(
    db.trackingEntries,
  )..where((e) => e.habitId.equals(habitId))).go();
}
