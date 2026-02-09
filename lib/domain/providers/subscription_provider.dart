import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

// Provider del repositorio
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    localDb: ref.watch(localDatabaseProvider),
  );
});

// Provider de lista de suscripciones
final subscriptionsProvider = FutureProvider.autoDispose<List<Subscription>>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  return await repository.getSubscriptions(userId: userId);
});

// Notifier para operaciones
final subscriptionNotifierProvider = 
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<void>>((ref) {
  return SubscriptionNotifier(ref);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SubscriptionNotifier(this._ref) : super(const AsyncValue.data(null));

  SubscriptionRepository get _repository => _ref.read(subscriptionRepositoryProvider);

  Future<Subscription?> createSubscription({
    required String title,
    String? description,
    required double amount,
    String? favicon,
    required DateTime billingDate,
    required String walletId,
    String? categoryId,
    required String currency,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return null;

    state = const AsyncValue.loading();

    try {
      final subscription = Subscription.create(
        userId: userId,
        title: title,
        description: description,
        amount: amount,
        favicon: favicon,
        billingDate: billingDate,
        walletId: walletId,
        categoryId: categoryId,
        currency: currency,
      );

      final created = await _repository.createSubscription(subscription);
      state = const AsyncValue.data(null);
      
      _ref.invalidate(subscriptionsProvider);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateSubscription(Subscription subscription) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateSubscription(subscription);
      state = const AsyncValue.data(null);
      _ref.invalidate(subscriptionsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteSubscription(String id) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.deleteSubscription(id);
      state = const AsyncValue.data(null);
      if (success) _ref.invalidate(subscriptionsProvider);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
