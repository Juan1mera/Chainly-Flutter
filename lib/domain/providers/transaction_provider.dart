import 'package:chainly/domain/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'wallet_provider.dart';

// Provider del repositorio
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    localDb: ref.watch(localDatabaseProvider),
  );
});

// Provider de transacciones por wallet
final transactionsByWalletProvider = FutureProvider.family.autoDispose<List<Transaction>, String>((ref, walletId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByWallet(walletId);
});

final recentTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getAllTransactions();
});

// Notifier
final transactionNotifierProvider = 
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super(const AsyncValue.data(null));

  TransactionRepository get _repository => _ref.read(transactionRepositoryProvider);

  Future<Transaction?> createTransaction({
    required String walletId,
    required String type,
    required double amount,
    String? categoryId,
    String? storeId,
    String? note,
    DateTime? date,
  }) async {
    // Optimistic update: No loading state needed
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      final transaction = Transaction.create(
        userId: userId,
        walletId: walletId,
        type: type,
        amount: amount,
        categoryId: categoryId,
        storeId: storeId,
        note: note,
        date: date ?? DateTime.now(),
      );

      final created = await _repository.createTransaction(transaction);
      
      // Invalidar providers relevantes
      _ref.invalidate(transactionsByWalletProvider(walletId));
      _ref.invalidate(walletsProvider); 
      _ref.invalidate(walletByIdProvider(walletId)); 
      _ref.invalidate(recentTransactionsProvider);

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteTransaction(String id, String walletId) async {
    // Optimistic: No loading state
    try {
      final success = await _repository.deleteTransaction(id);
      
      if (success) {
         _ref.invalidate(transactionsByWalletProvider(walletId));
         _ref.invalidate(walletsProvider);
         _ref.invalidate(walletByIdProvider(walletId));
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
    String? fromCurrency,
    String? toCurrency,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Convert amount if currencies differ
      double finalAmount = amount;
      if (fromCurrency != null && toCurrency != null && fromCurrency != toCurrency) {
        finalAmount = await _repository.convertCurrency(
          amount: amount, 
          fromCurrency: fromCurrency, 
          toCurrency: toCurrency
        );
      }

      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      // 2. Create outgoing transaction
      final outTxn = Transaction.create(
        userId: userId,
        walletId: fromWalletId,
        type: 'expense',
        amount: amount,
        note: note ?? 'Transferencia saliente',
        date: DateTime.now(),
        categoryId: 'transfer_out', // ID especial o buscar categoría real
      );
      
      // 3. Create incoming transaction
      final inTxn = Transaction.create(
        userId: userId,
        walletId: toWalletId,
        type: 'income',
        amount: finalAmount,
        note: note ?? 'Transferencia entrante',
        date: DateTime.now(),
        categoryId: 'transfer_in', // ID especial o buscar categoría real
      );

      await _repository.createTransaction(outTxn);
      await _repository.createTransaction(inTxn);
      
      state = const AsyncValue.data(null);
      
      _ref.invalidate(transactionsByWalletProvider(fromWalletId));
      _ref.invalidate(transactionsByWalletProvider(toWalletId));
      _ref.invalidate(walletsProvider);
      _ref.invalidate(walletByIdProvider(fromWalletId));
      _ref.invalidate(walletByIdProvider(toWalletId));

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
