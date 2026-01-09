import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/habit_tags.dart';
import '../models/tags.dart';
import '../models/habits.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

part 'habit_tag_dao.g.dart';

@DriftAccessor(tables: [HabitTags, Tags, Habits])
class HabitTagDao extends DatabaseAccessor<AppDatabase> with _$HabitTagDaoMixin, Loggable {
  HabitTagDao(super.db);

  Future<List<Tag>> getTagsForHabit(int habitId) async {
    logDebug('getTagsForHabit(habitId=$habitId) called');
    try {
      // Get tag IDs for this habit
      final habitTagIds = await (select(db.habitTags)
            ..where((ht) => ht.habitId.equals(habitId)))
          .get();
      
      if (habitTagIds.isEmpty) {
        logDebug('getTagsForHabit(habitId=$habitId) returned 0 tags');
        return [];
      }
      
      final tagIds = habitTagIds.map((ht) => ht.tagId).toList();
      
      // Get tags by IDs
      final result = await (select(db.tags)
            ..where((t) => t.id.isIn(tagIds)))
          .get();
      logDebug('getTagsForHabit(habitId=$habitId) returned ${result.length} tags');
      return result;
    } catch (e, stackTrace) {
      logError('getTagsForHabit(habitId=$habitId) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Tag>> watchTagsForHabit(int habitId) {
    logDebug('watchTagsForHabit(habitId=$habitId) called');
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
    logDebug('setHabitTags(habitId=$habitId, tagIds=$tagIds) called');
    try {
      // Remove existing tags
      await (delete(db.habitTags)..where((ht) => ht.habitId.equals(habitId))).go();
      
      // Add new tags
      for (final tagId in tagIds) {
        await into(db.habitTags).insert(HabitTagsCompanion(
          habitId: Value(habitId),
          tagId: Value(tagId),
        ));
      }
      logInfo('setHabitTags(habitId=$habitId) set ${tagIds.length} tags');
    } catch (e, stackTrace) {
      logError('setHabitTags(habitId=$habitId) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Habit>> getHabitsByTag(int tagId) async {
    logDebug('getHabitsByTag(tagId=$tagId) called');
    try {
      // Get habit IDs for this tag
      final habitTagIds = await (select(db.habitTags)
            ..where((ht) => ht.tagId.equals(tagId)))
          .get();
      
      if (habitTagIds.isEmpty) {
        logDebug('getHabitsByTag(tagId=$tagId) returned 0 habits');
        return [];
      }
      
      final habitIds = habitTagIds.map((ht) => ht.habitId).toList();
      
      // Get habits by IDs
      final result = await (select(db.habits)
            ..where((h) => h.id.isIn(habitIds)))
          .get();
      logDebug('getHabitsByTag(tagId=$tagId) returned ${result.length} habits');
      return result;
    } catch (e, stackTrace) {
      logError('getHabitsByTag(tagId=$tagId) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Habit>> watchHabitsByTag(int tagId) {
    logDebug('watchHabitsByTag(tagId=$tagId) called');
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

