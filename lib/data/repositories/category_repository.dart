import 'dart:async';
import '../models/category_model.dart';
import '../../core/database/local_database.dart';

class CategoryRepository {
  final Db _localDb;

  CategoryRepository({
    required Db localDb,
  }) : _localDb = localDb;

  Future<List<Category>> getCategories({
    required String userId,
  }) async {
    return await _getCategoriesFromLocal(userId);
  }

  Future<Category> createCategory(Category category) async {
    await _localDb.insert('categories', category.toLocal());
    return category;
  }

  Future<Category> updateCategory(Category category) async {
    final updatedCategory = category.incrementVersion();

    await _localDb.update(
      'categories',
      updatedCategory.toLocal(),
      where: 'id = ?',
      whereArgs: [category.id],
    );

    return updatedCategory;
  }

  Future<bool> deleteCategory(String id) async {
    await _localDb.delete('categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<List<Category>> _getCategoriesFromLocal(String userId) async {
    final results = await _localDb.query(
      'categories',
      where: 'user_id = ? OR user_id = ?',
      whereArgs: [userId, 'system'],
      orderBy: 'name ASC',
    );
    return results.map((map) => Category.fromLocal(map)).toList();
  }
}
