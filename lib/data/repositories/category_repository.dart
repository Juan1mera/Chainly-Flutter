import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../../core/database/local_database.dart';

class CategoryRepository {
  final SupabaseClient _supabase;
  final Db _localDb;
  final Connectivity _connectivity;

  CategoryRepository({
    required SupabaseClient supabase,
    required Db localDb,
    Connectivity? connectivity,
  })  : _supabase = supabase,
    _localDb = localDb,
    _connectivity = connectivity ?? Connectivity();

  Future<List<Category>> getCategories({
    required String userId,
    bool forceRefresh = false,
  }) async {
    final isOnline = await _checkConnectivity();

    if (!isOnline || !forceRefresh) {
      return await _getCategoriesFromLocal(userId);
    }

    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('name');

      final categories = (response as List)
          .map((json) => Category.fromSupabase(json))
          .toList();

      await _updateLocalCache(categories);

      return categories;
    } catch (e) {
      debugPrint('Error getting categories from Supabase: $e');
      return await _getCategoriesFromLocal(userId);
    }
  }

  Future<Category> createCategory(Category category) async {
    await _localDb.insert('categories', category.toLocal());

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase.from('categories').insert(category.toSupabase());

        final syncedCategory = category.markAsSynced();
        await _localDb.update(
          'categories',
          syncedCategory.toLocal(),
          where: 'id = ?',
          whereArgs: [category.id],
        );

        return syncedCategory;
      } catch (e) {
        debugPrint('Error creating category in Supabase: $e');
        await _queuePendingOperation(
            'insert', 'categories', category.id, category.toSupabase());
      }
    } else {
      await _queuePendingOperation(
          'insert', 'categories', category.id, category.toSupabase());
    }

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

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase
            .from('categories')
            .update(updatedCategory.toSupabase())
            .eq('id', category.id);

        final syncedCategory = updatedCategory.markAsSynced();
        await _localDb.update(
          'categories',
          syncedCategory.toLocal(),
          where: 'id = ?',
          whereArgs: [category.id],
        );

        return syncedCategory;
      } catch (e) {
        debugPrint('Error updating category in Supabase: $e');
        await _queuePendingOperation(
            'update', 'categories', category.id, updatedCategory.toSupabase());
      }
    } else {
      await _queuePendingOperation(
          'update', 'categories', category.id, updatedCategory.toSupabase());
    }

    return updatedCategory;
  }

  Future<bool> deleteCategory(String id) async {
    await _localDb.delete('categories', where: 'id = ?', whereArgs: [id]);

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase.from('categories').delete().eq('id', id);
        return true;
      } catch (e) {
        debugPrint('Error deleting category from Supabase: $e');
        await _queuePendingOperation('delete', 'categories', id, {});
      }
    } else {
      await _queuePendingOperation('delete', 'categories', id, {});
    }

    return true;
  }

  // Sincroniza operaciones pendientes
  Future<void> syncPendingOperations() async { // Reutilizado lógicamente, aunque idealmente debería estar en un sync service
    // Implementación simplificada aquí, idealmente la lógica de sync debería ser centralizada
    // ya que es idéntica para todas las tablas.
    // Por ahora, asumimos que WalletRepository maneja el loop principal o duplicamos lógica.
    // Duplicaré la lógica específica para categories aquí por seguridad.
    
    final isOnline = await _checkConnectivity();
    if (!isOnline) return;

    final pending = await _localDb.getPendingOperations();

    for (final op in pending) {
       final tableName = op['table_name'] as String;
       if (tableName != 'categories') continue;

      try {
        final opType = op['operation_type'] as String;
        final recordId = op['record_id'] as String;

        switch (opType) {
          case 'insert':
            final category = await _getCategoryFromLocal(recordId);
            if (category != null) {
              await _supabase.from('categories').insert(category.toSupabase());
              await _markAsSynced(recordId);
            }
            break;
          case 'update':
            final category = await _getCategoryFromLocal(recordId);
            if (category != null) {
              await _supabase
                  .from('categories')
                  .update(category.toSupabase())
                  .eq('id', recordId);
              await _markAsSynced(recordId);
            }
            break;
          case 'delete':
            await _supabase.from('categories').delete().eq('id', recordId);
            break;
        }
        await _localDb.removePendingOperation(op['id'] as int);
      } catch (e) {
        debugPrint('Error syncing category op: $e');
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
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

  Future<Category?> _getCategoryFromLocal(String id) async {
    final results = await _localDb.query('categories', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Category.fromLocal(results.first);
  }

  Future<void> _updateLocalCache(List<Category> categories) async {
    for (final category in categories) {
      await _localDb.insert('categories', category.toLocal());
    }
  }

  Future<void> _queuePendingOperation(
      String type, String table, String id, Map<String, dynamic> data) async {
    await _localDb.addPendingOperation(
      operationType: type,
      tableName: table,
      recordId: id,
      data: json.encode(data),
    );
  }

  Future<void> _markAsSynced(String id) async {
     final category = await _getCategoryFromLocal(id);
     if (category != null) {
        await _localDb.update(
          'categories',
          category.markAsSynced().toLocal(),
          where: 'id = ?',
          whereArgs: [id],
        );
     }
  }
}
