// lib/providers/wallet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/services/wallet_service.dart';

final walletServiceProvider = Provider((ref) => WalletService());

final walletsProvider = StateNotifierProvider<WalletsNotifier, AsyncValue<List<Wallet>>>((ref) {
  return WalletsNotifier(ref.read(walletServiceProvider));
});

class WalletsNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletService _walletService;

  WalletsNotifier(this._walletService) : super(const AsyncValue.loading()) {
    loadWallets();
  }

  Future<void> loadWallets({bool includeArchived = true}) async {
    state = const AsyncValue.loading();
    try {
      final wallets = await _walletService.getWallets(includeArchived: includeArchived);

      wallets.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;  // a antes que b
        if (!a.isFavorite && b.isFavorite) return 1;   // b antes que a

        return b.createdAt.compareTo(a.createdAt);
      });

      state = AsyncValue.data(wallets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => loadWallets(includeArchived: true);
  Future<void> refreshAfterTransaction() async => refresh();
}