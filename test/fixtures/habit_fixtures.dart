import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:drift/drift.dart' as drift;

/// Creates a test habit with default values
db.Habit createTestHabit({
  int? id,
  String? name,
  String? description,
  int? color,
  String? icon,
  HabitType? habitType,
  TrackingType? trackingType,
  String? unit,
  double? goalValue,
  GoalPeriod? goalPeriod,
  List<String>? occurrenceNames,
  bool? reminderEnabled,
  String? reminderTime,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return db.Habit(
    id: id ?? 1,
    name: name ?? 'Test Habit',
    description: description,
    color: color ?? 0xFF2196F3, // Blue
    icon: icon,
    habitType: (habitType ?? HabitType.good).value,
    trackingType: (trackingType ?? TrackingType.completed).value,
    unit: unit,
    goalValue: goalValue,
    goalPeriod: goalPeriod?.value,
    occurrenceNames: occurrenceNames?.toString(),
    reminderEnabled: reminderEnabled ?? false,
    reminderTime: reminderTime,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

/// Creates a test habit companion for insertion
db.HabitsCompanion createTestHabitCompanion({
  drift.Value<int>? id,
  String? name,
  String? description,
  int? color,
  String? icon,
  HabitType? habitType,
  TrackingType? trackingType,
  String? unit,
  double? goalValue,
  GoalPeriod? goalPeriod,
  List<String>? occurrenceNames,
  bool? reminderEnabled,
  String? reminderTime,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  return db.HabitsCompanion(
    id: id ?? const drift.Value.absent(),
    name: drift.Value(name ?? 'Test Habit'),
    description: description != null
        ? drift.Value(description)
        : const drift.Value.absent(),
    color: drift.Value(color ?? 0xFF2196F3),
    icon: icon != null ? drift.Value(icon) : const drift.Value.absent(),
    habitType: drift.Value((habitType ?? HabitType.good).value),
    trackingType: drift.Value((trackingType ?? TrackingType.completed).value),
    unit: unit != null ? drift.Value(unit) : const drift.Value.absent(),
    goalValue: goalValue != null
        ? drift.Value(goalValue)
        : const drift.Value.absent(),
    goalPeriod: goalPeriod != null
        ? drift.Value(goalPeriod.value)
        : const drift.Value.absent(),
    occurrenceNames: occurrenceNames != null
        ? drift.Value(occurrenceNames.toString())
        : const drift.Value.absent(),
    reminderEnabled: drift.Value(reminderEnabled ?? false),
    reminderTime: reminderTime != null
        ? drift.Value(reminderTime)
        : const drift.Value.absent(),
    createdAt: drift.Value(createdAt ?? now),
    updatedAt: drift.Value(updatedAt ?? now),
  );
}

/// Creates a test good habit
db.Habit createTestGoodHabit({
  int? id,
  String? name,
}) {
  return createTestHabit(
    id: id,
    name: name ?? 'Good Habit',
    habitType: HabitType.good,
  );
}

/// Creates a test bad habit
db.Habit createTestBadHabit({
  int? id,
  String? name,
}) {
  return createTestHabit(
    id: id,
    name: name ?? 'Bad Habit',
    habitType: HabitType.bad,
  );
}

/// Creates a test measurable habit
db.Habit createTestMeasurableHabit({
  int? id,
  String? name,
  String? unit,
  double? goalValue,
  GoalPeriod? goalPeriod,
}) {
  return createTestHabit(
    id: id,
    name: name ?? 'Measurable Habit',
    trackingType: TrackingType.measurable,
    unit: unit ?? 'minutes',
    goalValue: goalValue ?? 30.0,
    goalPeriod: goalPeriod ?? GoalPeriod.daily,
  );
}

/// Creates a test occurrences habit
db.Habit createTestOccurrencesHabit({
  int? id,
  String? name,
  List<String>? occurrenceNames,
}) {
  return createTestHabit(
    id: id,
    name: name ?? 'Occurrences Habit',
    trackingType: TrackingType.occurrences,
    occurrenceNames: occurrenceNames ?? ['Morning', 'Evening'],
  );
}

