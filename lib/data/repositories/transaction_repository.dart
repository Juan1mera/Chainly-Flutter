import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../../core/database/local_database.dart';
import '../../core/database/env.dart';

class TransactionRepository {
  final Db _localDb;

  TransactionRepository({
    required Db localDb,
  }) : _localDb = localDb;

  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();

    if (from == to) return amount;

    try {
      final response = await http.get(Uri.parse('${Env.exchangeApi}$from'));
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

  Future<List<Transaction>> getAllTransactions() async {
    return await _getAllTransactionsFromLocal();
  }

  Future<List<Transaction>> getTransactionsByWallet(String walletId) async {
    return await _getTransactionsFromLocal(walletId);
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    await _localDb.insert('transactions', transaction.toLocal());
    await _updateLocalWalletBalance(transaction.walletId, transaction.amount, transaction.type);

    return transaction;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
     // Nota: Manejar cambio de balance en update es complejo, simplificado aquí
    await _localDb.update(
      'transactions',
      transaction.toLocal(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    return transaction;
  }

  Future<bool> deleteTransaction(String id) async {
    // Primero necesitamos saber el monto para revertir
    final txn = await _getTransactionFromLocal(id);
    if (txn != null) {
       await _updateLocalWalletBalance(txn.walletId, -txn.amount, txn.type); // Invertir
    }

    await _localDb.delete('transactions', where: 'id = ?', whereArgs: [id]);

    return true;
  }
  
  Future<List<Transaction>> _getTransactionsFromLocal(String walletId) async {
    final results = await _localDb.query(
      'transactions',
      where: 'wallet_id = ?',
      whereArgs: [walletId],
      orderBy: 'date DESC',
    );
    return results.map((map) => Transaction.fromLocal(map)).toList();
  }

  Future<List<Transaction>> _getAllTransactionsFromLocal() async {
    final results = await _localDb.query(
      'transactions',
      orderBy: 'date DESC',
      limit: 20
    );
    return results.map((map) => Transaction.fromLocal(map)).toList();
  }

  Future<Transaction?> _getTransactionFromLocal(String id) async {
    final results = await _localDb.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Transaction.fromLocal(results.first);
  }

  Future<void> _updateLocalWalletBalance(String walletId, double amount, String type) async {
    final factor = type == 'income' ? 1 : -1;
    final delta = amount * factor;
    
    // Leer wallet actual
    final walletResults = await _localDb.query('wallets', where: 'id = ?', whereArgs: [walletId]);
    if (walletResults.isNotEmpty) {
       final currentBalance = (walletResults.first['balance'] as num).toDouble();
       final newBalance = currentBalance + delta;
       
       await _localDb.update(
         'wallets', 
         {'balance': newBalance},
         where: 'id = ?',
         whereArgs: [walletId]
       );
    }
  }
}
