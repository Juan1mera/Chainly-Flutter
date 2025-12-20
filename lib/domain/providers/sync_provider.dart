import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/auth_provider.dart';
import 'package:chainly/domain/providers/category_provider.dart';

final syncProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  Future<void> syncAll() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      debugPrint('Sync skipped: No user logged in');
      return;
    }

    try {
      debugPrint('Starting full data sync...');
      
      // 1. First push pending local changes
      debugPrint('Syncing pending operations...');
      await _ref.read(walletRepositoryProvider).syncPendingOperations();
      await _ref.read(categoryRepositoryProvider).syncPendingOperations();
      await _ref.read(transactionRepositoryProvider).syncPendingOperations();

      // 2. Sync Wallets (download)
      await _ref.read(walletRepositoryProvider).getWallets(
        userId: userId,
        forceRefresh: true,
      );
      
      // 3. Sync Categories (download)
      await _ref.read(categoryRepositoryProvider).getCategories(
        userId: userId,
        forceRefresh: true,
      );
      
      // 4. Sync Transactions (download)
      await _ref.read(transactionRepositoryProvider).getAllTransactions(
        forceRefresh: true,
      );

      // 3. Refresh Providers to update UI
      _ref.invalidate(walletsProvider);
      _ref.invalidate(favoriteWalletsProvider);
      _ref.invalidate(totalBalanceProvider);
      _ref.invalidate(recentTransactionsProvider);
      
      // Also invalidate transaction lists for specific wallets if needed
      // This might be expensive if many wallets, so maybe we leave it lazy loaded
      
      debugPrint('Full data sync completed successfully');
    } catch (e) {
      debugPrint('Error during data sync: $e');
    }
  }
}
