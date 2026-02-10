import 'dart:async';
import '../models/store_model.dart';
import '../../core/database/local_database.dart';

class StoreRepository {
  final Db _localDb;

  StoreRepository({
    required Db localDb,
  }) : _localDb = localDb;

  Future<List<Store>> getStores({
    required String userId,
  }) async {
    return await _getStoresFromLocal(userId);
  }

  Future<Store> createStore(Store store) async {
    await _localDb.insert('stores', store.toLocal());
    return store;
  }

  Future<Store> updateStore(Store store) async {
    await _localDb.update(
      'stores',
      store.toLocal(),
      where: 'id = ?',
      whereArgs: [store.id],
    );

    return store;
  }

  Future<bool> deleteStore(String id) async {
    await _localDb.delete('stores', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<List<Store>> _getStoresFromLocal(String userId) async {
    final results = await _localDb.query(
      'stores',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return results.map((map) => Store.fromLocal(map)).toList();
  }
}
