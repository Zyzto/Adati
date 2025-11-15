import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/tags.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<Tag>> getAllTags() => select(db.tags).get();

  Stream<List<Tag>> watchAllTags() => select(db.tags).watch();

  Future<Tag?> getTagById(int id) =>
      (select(db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTag(TagsCompanion tag) =>
      into(db.tags).insert(tag);

  Future<bool> updateTag(TagsCompanion tag) =>
      update(db.tags).replace(tag);

  Future<int> deleteTag(int id) =>
      (delete(db.tags)..where((t) => t.id.equals(id))).go();
}

