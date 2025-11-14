import 'package:drift/drift.dart' as drift;
import 'package:adati/core/database/app_database.dart' as db;

class TrackingEntry {
  final int? id;
  final int habitId;
  final DateTime date;
  final bool completed;
  final String? notes;

  TrackingEntry({
    this.id,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.notes,
  });

  TrackingEntry copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    bool? completed,
    String? notes,
  }) {
    return TrackingEntry(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }

  db.TrackingEntriesCompanion toCompanion() {
    return db.TrackingEntriesCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      habitId: drift.Value(habitId),
      date: drift.Value(date),
      completed: drift.Value(completed),
      notes: drift.Value(notes),
    );
  }
}

