import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wallet_app/core/database/db.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/transaction_with_details.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/services/auth_service.dart';
import 'package:wallet_app/services/category_service.dart';

class TransactionService {
  final Db _db = Db();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();

  // CREAR
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
    final db = await _db.database;
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

    return await db.transaction((txn) async {
      final transactionId = await txn.insert('transactions', transaction.toMap());
      final balanceChange = type == 'income' ? amount : -amount;
      await txn.rawUpdate(
        'UPDATE wallets SET balance = balance + ? WHERE id = ?',
        [balanceChange, walletId],
      );
      return transactionId;
    });
  }

  // TRANSFERENCIA ENTRE BILLETERAS
  Future<void> transferBetweenWallets({
    required int fromWalletId,
    required int toWalletId,
    required double fromAmount,
    String? note,
  }) async {
    if (fromWalletId == toWalletId) {
      throw Exception('No puedes transferir a la misma billetera');
    }
    if (fromAmount <= 0) {
      throw Exception('El monto debe ser mayor a 0');
    }

    final db = await _db.database;

    final fromWalletResult = await db.query('wallets', where: 'id = ?', whereArgs: [fromWalletId]);
    final toWalletResult = await db.query('wallets', where: 'id = ?', whereArgs: [toWalletId]);

    if (fromWalletResult.isEmpty) throw Exception('Billetera origen no encontrada');
    if (toWalletResult.isEmpty) throw Exception('Billetera destino no encontrada');

    final fromWallet = Wallet.fromMap(fromWalletResult.first);
    final toWallet = Wallet.fromMap(toWalletResult.first);

    double toAmount = fromAmount;
    if (fromWallet.currency != toWallet.currency) {
      toAmount = await convertCurrency(
        amount: fromAmount,
        fromCurrency: fromWallet.currency,
        toCurrency: toWallet.currency,
      );
    }

    final now = DateTime.now();
    final transferOut = Transaction(
      walletId: fromWalletId,
      categoryId: await _categoryService.getOrCreateCategoryId('Transferencia saliente'),
      type: 'expense',
      amount: fromAmount,
      note: note ?? 'Transferencia a ${toWallet.name}',
      date: now,
      createdAt: now,
    );

    final transferIn = Transaction(
      walletId: toWalletId,
      categoryId: await _categoryService.getOrCreateCategoryId('Transferencia entrante'),
      type: 'income',
      amount: toAmount,
      note: note ?? 'Transferencia desde ${fromWallet.name}',
      date: now,
      createdAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('transactions', transferOut.toMap());
      await txn.insert('transactions', transferIn.toMap());
      await txn.rawUpdate('UPDATE wallets SET balance = balance - ? WHERE id = ?', [fromAmount, fromWalletId]);
      await txn.rawUpdate('UPDATE wallets SET balance = balance + ? WHERE id = ?', [toAmount, toWalletId]);
    });
  }

  // CONVERSIÓN DE DIVISAS
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();

    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$from'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = (data['rates'][to] as num?)?.toDouble() ?? 1.0;
        return double.parse((amount * rate).toStringAsFixed(8));
      }
    } catch (e) {
      debugPrint('Error en conversión: $e');
    }
    return amount;
  }

  // OBTENER
  Future<List<Transaction>> getTransactionsByWallet(
    int walletId, {
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;
    final whereParts = <String>['wallet_id = ?'];
    final whereArgs = <Object?>[walletId];

    if (type != null) {
      whereParts.add('type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('date >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);  
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
      whereParts.add('date <= ?');
      whereArgs.add(endOfDay.millisecondsSinceEpoch);  
    }

    final maps = await db.query(
      'transactions',
      where: whereParts.isNotEmpty ? whereParts.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
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

  Future<List<TransactionWithDetails>> getAllTransactionsWithDetails({
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;
    final whereParts = <String>[];
    final whereArgs = <Object>[];

    if (type != null) {
      whereParts.add('t.type = ?');
      whereArgs.add(type);
    }
    if (from != null) {
      whereParts.add('t.date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereParts.add('t.date <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        t.*,
        w.name AS wallet_name,
        w.currency AS wallet_currency,
        w.color AS wallet_color,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      LEFT JOIN categories c ON t.category_id = c.id
      ${whereClause != null ? 'WHERE $whereClause' : ''}
      ORDER BY t.date DESC
    ''', whereArgs);

    final List<TransactionWithDetails> result = [];
    for (final map in maps) {
      final transaction = Transaction.fromMap(_extractTransactionMap(map));
      final wallet = Wallet.fromMap(_extractWalletMap(map));
      final category = Category.fromMap(_extractCategoryMap(map));
      result.add(TransactionWithDetails(transaction: transaction, wallet: wallet, category: category));
    }
    return result;
  }

  // ACTUALIZAR
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

  // ELIMINAR
  Future<bool> deleteTransaction(int id) async {
    final db = await _db.database;
    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // HELPERS
  Map<String, dynamic> _extractTransactionMap(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'wallet_id': map['wallet_id'],
      'category_id': map['category_id'],
      'type': map['type'],
      'amount': map['amount'],
      'note': map['note'],
      'date': map['date'],
      'created_at': map['created_at'],
    };
  }

  Map<String, dynamic> _extractWalletMap(Map<String, dynamic> map) {
    return {
      'id': map['wallet_id'],
      'name': map['wallet_name'] ?? 'Unknown Wallet',
      'currency': map['wallet_currency'] ?? 'USD',
      'color': map['wallet_color'] ?? '#000000',
      'balance': 0.0,
      'is_favorite': 0,
      'is_archived': 0,
      'type': 'bank',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _extractCategoryMap(Map<String, dynamic> map) {
    return {
      'id': map['category_id'],
      'name': map['category_name'] ?? 'Sin categoría',
      'monthly_budget': 0.0,
      'icon': map['category_icon'],
      'color': map['category_color'],
    };
  }
}