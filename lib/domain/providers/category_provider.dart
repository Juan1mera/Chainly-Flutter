import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

// Provider del repositorio
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    localDb: ref.watch(localDatabaseProvider),
  );
});

// Provider de lista de categorías
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  return await repository.getCategories(userId: userId);
});

// Notifier para operaciones
final categoryNotifierProvider = 
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref);
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CategoryNotifier(this._ref) : super(const AsyncValue.data(null));

  CategoryRepository get _repository => _ref.read(categoryRepositoryProvider);

  Future<Category?> createCategory({
    required String name,
    required String type,
    double monthlyBudget = 0.0,
    String? icon,
    String? color,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return null;

    state = const AsyncValue.loading();

    try {
      final category = Category.create(
        userId: userId,
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
        icon: icon,
        color: color,
      );

      final created = await _repository.createCategory(category);
      state = const AsyncValue.data(null);
      
      _ref.invalidate(categoriesProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }



  Future<bool> updateCategory({
    required String id,
    required String name,
    required String type,
    double monthlyBudget = 0.0,
    String? icon,
    String? color,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return false;

    state = const AsyncValue.loading();
    try {
      final category = Category(
        id: id,
        userId: userId,
        name: name,
        type: type,
        monthlyBudget: monthlyBudget,
        icon: icon,
        color: color,
        createdAt: DateTime.now(), 
        updatedAt: DateTime.now(),
      );
      
      await _repository.updateCategory(category);
      state = const AsyncValue.data(null);
      _ref.invalidate(categoriesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.deleteCategory(id);
      state = const AsyncValue.data(null);
      if (success) _ref.invalidate(categoriesProvider);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
