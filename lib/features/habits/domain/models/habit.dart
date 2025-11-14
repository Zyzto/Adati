import 'package:drift/drift.dart' as drift;
import 'package:adati/core/database/app_database.dart' as db;

class Habit {
  final int? id;
  final String name;
  final String? description;
  final int color;
  final String? icon;
  final int? categoryId;
  final bool reminderEnabled;
  final String? reminderTime; // Stored as "HH:mm" format
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    this.id,
    required this.name,
    this.description,
    required this.color,
    this.icon,
    this.categoryId,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    int? color,
    String? icon,
    int? categoryId,
    bool? reminderEnabled,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  db.HabitsCompanion toCompanion() {
    return db.HabitsCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      name: drift.Value(name),
      description: drift.Value(description),
      color: drift.Value(color),
      icon: drift.Value(icon),
      categoryId: drift.Value(categoryId),
      reminderEnabled: drift.Value(reminderEnabled),
      reminderTime: reminderTime == null
          ? const drift.Value.absent()
          : drift.Value(reminderTime),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );
  }
}

