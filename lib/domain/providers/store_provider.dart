import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/local_database.dart';
import '../../data/models/store_model.dart';
import '../../data/repositories/store_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(localDb: Db());
});

final storesProvider = FutureProvider<List<Store>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final userId = user?.id ?? 'local_user';
  final repository = ref.watch(storeRepositoryProvider);
  return repository.getStores(userId: userId);
});

final storeNotifierProvider = StateNotifierProvider<StoreNotifier, AsyncValue<void>>((ref) {
  return StoreNotifier(ref);
});

class StoreNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  StoreNotifier(this._ref) : super(const AsyncData(null));

  Future<Store> createStore({
    required String name,
    String? website,
  }) async {
    state = const AsyncLoading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'local_user';
      final repository = _ref.read(storeRepositoryProvider);
      
      final newStore = Store.create(
        userId: userId,
        name: name,
        website: website,
      );

      final createdStore = await repository.createStore(newStore);
      
      // Invalidar provider para recargar lista
      _ref.invalidate(storesProvider);
      state = const AsyncData(null);
      
      return createdStore;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateStore(Store store) async {
    state = const AsyncLoading();
    try {
      final repository = _ref.read(storeRepositoryProvider);
      
      final updatedStore = store.copyWith(updatedAt: DateTime.now());
      await repository.updateStore(updatedStore);
      
      _ref.invalidate(storesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteStore(String id) async {
    state = const AsyncLoading();
    try {
      final repository = _ref.read(storeRepositoryProvider);
      await repository.deleteStore(id);
      
      _ref.invalidate(storesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
