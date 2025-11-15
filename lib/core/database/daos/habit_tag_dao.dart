import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/habit_tags.dart';
import '../models/tags.dart';
import '../models/habits.dart';

part 'habit_tag_dao.g.dart';

@DriftAccessor(tables: [HabitTags, Tags, Habits])
class HabitTagDao extends DatabaseAccessor<AppDatabase> with _$HabitTagDaoMixin {
  HabitTagDao(super.db);

  Future<List<Tag>> getTagsForHabit(int habitId) async {
    // Get tag IDs for this habit
    final habitTagIds = await (select(db.habitTags)
          ..where((ht) => ht.habitId.equals(habitId)))
        .get();
    
    if (habitTagIds.isEmpty) {
      return [];
    }
    
    final tagIds = habitTagIds.map((ht) => ht.tagId).toList();
    
    // Get tags by IDs
    return (select(db.tags)
          ..where((t) => t.id.isIn(tagIds)))
        .get();
  }

  Stream<List<Tag>> watchTagsForHabit(int habitId) {
    // Watch habit tags and map to tags
    return (select(db.habitTags)
          ..where((ht) => ht.habitId.equals(habitId)))
        .watch()
        .asyncMap((habitTags) async {
      if (habitTags.isEmpty) {
        return <Tag>[];
      }
      
      final tagIds = habitTags.map((ht) => ht.tagId).toList();
      return (select(db.tags)
            ..where((t) => t.id.isIn(tagIds)))
          .get();
    });
  }

  Future<void> setHabitTags(int habitId, List<int> tagIds) async {
    // Remove existing tags
    await (delete(db.habitTags)..where((ht) => ht.habitId.equals(habitId))).go();
    
    // Add new tags
    for (final tagId in tagIds) {
      await into(db.habitTags).insert(HabitTagsCompanion(
        habitId: Value(habitId),
        tagId: Value(tagId),
      ));
    }
  }

  Future<List<Habit>> getHabitsByTag(int tagId) async {
    // Get habit IDs for this tag
    final habitTagIds = await (select(db.habitTags)
          ..where((ht) => ht.tagId.equals(tagId)))
        .get();
    
    if (habitTagIds.isEmpty) {
      return [];
    }
    
    final habitIds = habitTagIds.map((ht) => ht.habitId).toList();
    
    // Get habits by IDs
    return (select(db.habits)
          ..where((h) => h.id.isIn(habitIds)))
        .get();
  }

  Stream<List<Habit>> watchHabitsByTag(int tagId) {
    // Watch habit tags and map to habits
    return (select(db.habitTags)
          ..where((ht) => ht.tagId.equals(tagId)))
        .watch()
        .asyncMap((habitTags) async {
      if (habitTags.isEmpty) {
        return <Habit>[];
      }
      
      final habitIds = habitTags.map((ht) => ht.habitId).toList();
      return (select(db.habits)
            ..where((h) => h.id.isIn(habitIds)))
          .get();
    });
  }
}

