import 'package:wallet_app/core/database/db.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/services/auth_service.dart';
import 'package:wallet_app/services/category_service.dart';

class TransactionService {
  final Db _db = Db();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();

  Future<int> createTransaction(Transaction transaction) async {
    final userEmail = _authService.currentUserEmail; 
    if (userEmail == null) throw Exception('User not authenticated');

    final db = await _db.database;

    final walletCheck = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [transaction.walletId],
    );
    if (walletCheck.isEmpty) throw Exception('Wallet not found');

    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> createTransactionWithCategoryName({
    required int walletId,
    required String type,
    required double amount,
    required String categoryName,
    String? note,
  }) async {
    final categoryId = await _categoryService.getOrCreateCategoryId(categoryName);
    final now = DateTime.now();

    final transaction = Transaction(
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: now,
      createdAt: now,
    );

    return await createTransaction(transaction);
  }

  Future<List<Transaction>> getTransactionsByWallet(
    int walletId, {
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    final whereParts = <String>['wallet_id = ?'];
    final whereArgs = <Object>[walletId];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getAllTransactions({
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    final whereParts = <String>[];
    final whereArgs = <Object>[];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map(Transaction.fromMap).toList();
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Transaction ID required');

    final db = await _db.database;
    final result = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return result > 0;
  }

  Future<bool> deleteTransaction(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }
}