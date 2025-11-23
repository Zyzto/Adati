import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import 'package:drift/drift.dart' as drift;

/// Creates a test tracking entry
db.TrackingEntry createTestTrackingEntry({
  required int habitId,
  DateTime? date,
  bool? completed,
  double? value,
  String? occurrenceData,
  String? notes,
}) {
  final entryDate = date ?? date_utils.DateUtils.getToday();
  return db.TrackingEntry(
    habitId: habitId,
    date: entryDate,
    completed: completed ?? false,
    value: value,
    occurrenceData: occurrenceData,
    notes: notes,
  );
}

/// Creates a test tracking entry companion for insertion
db.TrackingEntriesCompanion createTestTrackingEntryCompanion({
  required int habitId,
  DateTime? date,
  bool? completed,
  double? value,
  String? occurrenceData,
  String? notes,
}) {
  final entryDate = date ?? date_utils.DateUtils.getToday();
  return db.TrackingEntriesCompanion(
    habitId: drift.Value(habitId),
    date: drift.Value(entryDate),
    completed: drift.Value(completed ?? false),
    value: value != null ? drift.Value(value) : const drift.Value.absent(),
    occurrenceData: occurrenceData != null
        ? drift.Value(occurrenceData)
        : const drift.Value.absent(),
    notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
  );
}

/// Creates a completed tracking entry
db.TrackingEntry createCompletedEntry({
  required int habitId,
  DateTime? date,
  String? notes,
}) {
  return createTestTrackingEntry(
    habitId: habitId,
    date: date,
    completed: true,
    notes: notes,
  );
}

/// Creates an incomplete tracking entry
db.TrackingEntry createIncompleteEntry({
  required int habitId,
  DateTime? date,
}) {
  return createTestTrackingEntry(
    habitId: habitId,
    date: date,
    completed: false,
  );
}

/// Creates a measurable tracking entry
db.TrackingEntry createMeasurableEntry({
  required int habitId,
  DateTime? date,
  required double value,
  String? notes,
}) {
  return createTestTrackingEntry(
    habitId: habitId,
    date: date,
    completed: false, // Will be determined by goal
    value: value,
    notes: notes,
  );
}

/// Creates an occurrences tracking entry
db.TrackingEntry createOccurrencesEntry({
  required int habitId,
  DateTime? date,
  required List<String> occurrences,
  String? notes,
}) {
  final occurrenceData = occurrences.toString();
  return createTestTrackingEntry(
    habitId: habitId,
    date: date,
    completed: occurrences.isNotEmpty,
    occurrenceData: occurrenceData,
    notes: notes,
  );
}

