import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/tags.dart';
import '../../services/loggable_mixin.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin, Loggable {
  TagDao(super.db);

  Future<List<Tag>> getAllTags() async {
    logDebug('getAllTags() called');
    try {
      final result = await select(db.tags).get();
      logInfo('getAllTags() returned ${result.length} tags');
      return result;
    } catch (e, stackTrace) {
      logError('getAllTags() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<List<Tag>> watchAllTags() {
    logDebug('watchAllTags() called');
    return select(db.tags).watch();
  }

  Future<Tag?> getTagById(int id) async {
    logDebug('getTagById(id=$id) called');
    try {
      final result = await (select(db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();
      logDebug('getTagById(id=$id) returned ${result != null ? "tag" : "null"}');
      return result;
    } catch (e, stackTrace) {
      logError('getTagById(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> insertTag(TagsCompanion tag) async {
    logDebug('insertTag(name=${tag.name.value}) called');
    try {
      final id = await into(db.tags).insert(tag);
      logInfo('insertTag() inserted tag with id=$id');
      return id;
    } catch (e, stackTrace) {
      logError('insertTag() failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> updateTag(TagsCompanion tag) async {
    if (!tag.id.present) {
      throw ArgumentError('Tag id must be present for update');
    }
    final id = tag.id.value;
    logDebug('updateTag(id=$id) called');
    try {
      final result = await update(db.tags).replace(tag);
      logInfo('updateTag(id=$id) updated successfully');
      return result;
    } catch (e, stackTrace) {
      logError('updateTag(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteTag(int id) async {
    logDebug('deleteTag(id=$id) called');
    try {
      final result = await (delete(db.tags)..where((t) => t.id.equals(id))).go();
      logInfo('deleteTag(id=$id) deleted $result rows');
      return result;
    } catch (e, stackTrace) {
      logError('deleteTag(id=$id) failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

