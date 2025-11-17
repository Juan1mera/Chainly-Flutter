import 'package:wallet_app/core/database/db.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/services/auth_service.dart';

class WalletService {
  final Db _db = Db();
  final AuthService _authService = AuthService();

  Future<int> createWallet(Wallet wallet) async {
    final userEmail = _authService.currentUserEmail;
    if (userEmail == null) throw Exception('User not authenticated');

    final db = await _db.database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<List<Wallet>> getWallets({
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    final userEmail = _authService.currentUserEmail;
    if (userEmail == null) return [];

    final db = await _db.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'wallets',
      where: onlyFavorites
          ? 'is_favorite = 1'
          : includeArchived
              ? null
              : 'is_archived = 0',
      orderBy: 'created_at DESC',
    );

    return maps.map(Wallet.fromMap).toList();
  }

  Future<bool> updateWallet(Wallet wallet) async {
    if (wallet.id == null) throw Exception('Wallet ID required');

    final db = await _db.database;
    final result = await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
    return result > 0;
  }

  Future<bool> deleteWallet(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }
}