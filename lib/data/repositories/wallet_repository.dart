import 'dart:async';
import '../models/wallet_model.dart';
import '../../core/database/local_database.dart';

class WalletRepository {
  final Db _localDb;

  WalletRepository({
    required Db localDb,
  })  : _localDb = localDb;

  // Obtiene wallets solo de local
  Future<List<Wallet>> getWallets({
    required String userId,
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    return await _getWalletsFromLocal(
      userId: userId,
      onlyFavorites: onlyFavorites,
      includeArchived: includeArchived,
    );
  }

  // Obtiene una wallet por ID solo de local
  Future<Wallet?> getWalletById(String id) async {
    final results = await _localDb.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Wallet.fromLocal(results.first);
  }

  // Crea una nueva wallet solo en local
  Future<Wallet> createWallet(Wallet wallet) async {
    await _localDb.insert('wallets', wallet.toLocal());
    return wallet;
  }

  // Actualiza una wallet solo en local
  Future<Wallet> updateWallet(Wallet wallet) async {
    final updatedWallet = wallet.incrementVersion();

    await _localDb.update(
      'wallets',
      updatedWallet.toLocal(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );

    return updatedWallet;
  }

  // Elimina una wallet solo de local
  Future<bool> deleteWallet(String id) async {
    await _localDb.delete('wallets', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  Future<List<Wallet>> _getWalletsFromLocal({
    required String userId,
    bool onlyFavorites = false,
    bool includeArchived = false,
  }) async {
    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (onlyFavorites) {
      where += ' AND is_favorite = 1';
    }

    if (!includeArchived) {
      where += ' AND is_archived = 0';
    }

    final results = await _localDb.query(
      'wallets',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => Wallet.fromLocal(map)).toList();
  }
}