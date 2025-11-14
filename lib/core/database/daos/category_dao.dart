import 'package:drift/drift.dart';
import '../app_database.dart';
import '../models/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() => select(db.categories).get();

  Stream<List<Category>> watchAllCategories() => select(db.categories).watch();

  Future<Category?> getCategoryById(int id) =>
      (select(db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(db.categories).insert(category);

  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(db.categories).replace(category);

  Future<int> deleteCategory(int id) =>
      (delete(db.categories)..where((c) => c.id.equals(id))).go();
}

