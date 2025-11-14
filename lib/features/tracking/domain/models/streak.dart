import 'package:drift/drift.dart' as drift;
import 'package:adati/core/database/app_database.dart' as db;

class Streak {
  final int? id;
  final int habitId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastUpdated;

  Streak({
    this.id,
    required this.habitId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastUpdated,
  });

  Streak copyWith({
    int? id,
    int? habitId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUpdated,
  }) {
    return Streak(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  db.StreaksCompanion toCompanion() {
    return db.StreaksCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      habitId: drift.Value(habitId),
      currentStreak: drift.Value(currentStreak),
      longestStreak: drift.Value(longestStreak),
      lastUpdated: drift.Value(lastUpdated),
    );
  }
}

