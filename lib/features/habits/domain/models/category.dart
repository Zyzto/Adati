import 'package:drift/drift.dart' as drift;
import 'package:adati/core/database/app_database.dart' as db;

class Category {
  final int? id;
  final String name;
  final int color;
  final String? icon;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  db.CategoriesCompanion toCompanion() {
    return db.CategoriesCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      name: drift.Value(name),
      color: drift.Value(color),
      icon: drift.Value(icon),
      createdAt: drift.Value(createdAt),
    );
  }
}

