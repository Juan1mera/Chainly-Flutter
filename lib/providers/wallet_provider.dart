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
    loadWallets(); // Carga inicial
  }

  /// Carga (o recarga) todas las carteras
  Future<void> loadWallets({bool includeArchived = true}) async {
    state = const AsyncValue.loading();
    try {
      final wallets = await _walletService.getWallets(includeArchived: includeArchived);
      // Ordenar: favoritas primero
      wallets.sort((a, b) => b.isFavorite == a.isFavorite ? 0 : b.isFavorite ? -1 : 1);
      state = AsyncValue.data(wallets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Método público para refrescar después de crear/editar/borrar una cartera o transacción
  Future<void> refresh() async {
    await loadWallets(includeArchived: true);
  }

  /// Alias específico para cuando se crea una transacción (más semántico)
  Future<void> refreshAfterTransaction() async {
    await refresh();
  }
}