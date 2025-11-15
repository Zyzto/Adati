/// Habit types
enum HabitType {
  good(0),
  bad(1);

  final int value;
  const HabitType(this.value);

  static HabitType fromValue(int value) {
    return HabitType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HabitType.good,
    );
  }
}

/// Tracking types
enum TrackingType {
  completed('completed'),
  measurable('measurable'),
  occurrences('occurrences');

  final String value;
  const TrackingType(this.value);

  static TrackingType fromValue(String value) {
    return TrackingType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrackingType.completed,
    );
  }
}

/// Goal periods for measurable tracking
enum GoalPeriod {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  final String value;
  const GoalPeriod(this.value);

  static GoalPeriod fromValue(String value) {
    return GoalPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalPeriod.daily,
    );
  }
}

/// Predefined units for measurable tracking
const List<String> predefinedUnits = [
  'minutes',
  'hours',
  'km',
  'miles',
  'steps',
  'count',
  'times',
  'pages',
  'glasses',
  'cups',
  'liters',
  'calories',
  'kg',
  'lbs',
  'reps',
  'sets',
];

