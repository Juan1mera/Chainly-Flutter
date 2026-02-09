import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';
import 'transaction_provider.dart';

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

// Provider para suscripciones que vencen hoy o antes
final subscriptionsDueTodayProvider = Provider.autoDispose<List<Subscription>>((ref) {
  final subscriptionsAsync = ref.watch(subscriptionsProvider);
  
  return subscriptionsAsync.maybeWhen(
    data: (subscriptions) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return subscriptions.where((s) {
        final billingDate = DateTime(s.billingDate.year, s.billingDate.month, s.billingDate.day);
        return billingDate.isAtSameMomentAs(today) || billingDate.isBefore(today);
      }).toList();
    },
    orElse: () => [],
  );
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

  Future<bool> paySubscription(Subscription subscription) async {
    state = const AsyncValue.loading();
    try {
      // 1. Crear transacción
      final transactionNotifier = _ref.read(transactionNotifierProvider.notifier);
      await transactionNotifier.createTransaction(
        walletId: subscription.walletId,
        type: 'expense',
        amount: subscription.amount,
        categoryId: subscription.categoryId ?? 'subscriptions_category',
        note: 'Pago de suscripción: ${subscription.title}',
        date: DateTime.now(),
      );

      // 2. Calcular próxima fecha de cobro (mismo día del próximo mes)
      final currentBillingDate = subscription.billingDate;
      int nextYear = currentBillingDate.year;
      int nextMonth = currentBillingDate.month + 1;
      
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      
      // Manejar casos donde el día no existe en el próximo mes (ej: 31 de enero -> 28/29 de feb)
      int nextDay = currentBillingDate.day;
      DateTime nextDate = DateTime(nextYear, nextMonth, nextDay);
      if (nextDate.month != nextMonth) {
        // Si el mes cambió, significa que el día era inválido para ese mes
        // Revertir al último día del mes correcto
        nextDate = DateTime(nextYear, nextMonth + 1, 0);
      }

      // 3. Actualizar suscripción
      final updatedSubscription = subscription.copyWith(
        billingDate: nextDate,
      );
      await _repository.updateSubscription(updatedSubscription);
      
      state = const AsyncValue.data(null);
      _ref.invalidate(subscriptionsProvider);
      _ref.invalidate(walletsProvider);
      _ref.invalidate(walletByIdProvider(subscription.walletId));
      _ref.invalidate(recentTransactionsProvider);
      
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
