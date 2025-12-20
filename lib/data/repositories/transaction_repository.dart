import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../../core/database/local_database.dart';
import '../../core/database/env.dart';

class TransactionRepository {
  final SupabaseClient _supabase;
  final Db _localDb;
  final Connectivity _connectivity;

  TransactionRepository({
    required SupabaseClient supabase,
    required Db localDb,
    Connectivity? connectivity,
  })  : _supabase = supabase,
        _localDb = localDb,
        _connectivity = connectivity ?? Connectivity();

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



  Future<List<Transaction>> getAllTransactions({
    bool forceRefresh = false,
  }) async {
    final isOnline = await _checkConnectivity();

    if (!isOnline && !forceRefresh) {
      return await _getAllTransactionsFromLocal();
    }

    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('date', ascending: false)
          .limit(20); // Limit for home screen

      final transactions = (response as List)
          .map((json) => Transaction.fromSupabase(json))
          .toList();

      await _updateLocalCache(transactions);

      return transactions;
    } catch (e) {
      debugPrint('Error getting all transactions: $e');
      return await _getAllTransactionsFromLocal();
    }
  }

  Future<List<Transaction>> getTransactionsByWallet(
    String walletId, {
    bool forceRefresh = false,
  }) async {
    final isOnline = await _checkConnectivity();

    if (!isOnline || !forceRefresh) {
      return await _getTransactionsFromLocal(walletId);
    }

    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('date', ascending: false);

      final transactions = (response as List)
          .map((json) => Transaction.fromSupabase(json))
          .toList();

      await _updateLocalCache(transactions);

      return transactions;
    } catch (e) {
      debugPrint('Error getting transactions from Supabase: $e');
      return await _getTransactionsFromLocal(walletId);
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    await _localDb.insert('transactions', transaction.toLocal());

    // Actualizar balance de wallet localmente
    await _updateLocalWalletBalance(transaction.walletId, transaction.amount, transaction.type);

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase.from('transactions').insert(transaction.toSupabase());
        
        // Update remote wallet balance
        await _updateRemoteWalletBalance(transaction.walletId, transaction.amount, transaction.type);

        final syncedTransaction = transaction.markAsSynced();
        await _localDb.update(
          'transactions',
          syncedTransaction.toLocal(),
          where: 'id = ?',
          whereArgs: [transaction.id],
        );

        return syncedTransaction;
      } catch (e) {
        debugPrint('Error creating transaction in Supabase: $e');
        await _queuePendingOperation(
            'insert', 'transactions', transaction.id, transaction.toSupabase());
      }
    } else {
      await _queuePendingOperation(
          'insert', 'transactions', transaction.id, transaction.toSupabase());
    }

    return transaction;
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
     // Nota: Manejar cambio de balance en update es complejo, simplificado aquí
    final updatedTransaction = transaction.incrementVersion();

    await _localDb.update(
      'transactions',
      updatedTransaction.toLocal(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase
            .from('transactions')
            .update(updatedTransaction.toSupabase())
            .eq('id', transaction.id);

        final syncedTransaction = updatedTransaction.markAsSynced();
        await _localDb.update(
          'transactions',
          syncedTransaction.toLocal(),
          where: 'id = ?',
          whereArgs: [transaction.id],
        );

        return syncedTransaction;
      } catch (e) {
        debugPrint('Error updating transaction in Supabase: $e');
        await _queuePendingOperation(
            'update', 'transactions', transaction.id, updatedTransaction.toSupabase());
      }
    } else {
      await _queuePendingOperation(
          'update', 'transactions', transaction.id, updatedTransaction.toSupabase());
    }

    return updatedTransaction;
  }

  Future<bool> deleteTransaction(String id) async {
    // Revertir balance antes de borrar (complejo, simplificado)
    // En una app real de finanzas, NUNCA se borran transacciones, se crean contra-asientos
    // Pero aquí seguiremos el CRUD.
    
    // Primero necesitamos saber el monto para revertir
    final txn = await _getTransactionFromLocal(id);
    if (txn != null) {
       await _updateLocalWalletBalance(txn.walletId, -txn.amount, txn.type); // Invertir
    }

    await _localDb.delete('transactions', where: 'id = ?', whereArgs: [id]);

    final isOnline = await _checkConnectivity();

    if (isOnline) {
      try {
        await _supabase.from('transactions').delete().eq('id', id);
        
        // Revert remote balance
        // We need the txn details which we fetched earlier locally (txn var)
        if (txn != null) {
          await _updateRemoteWalletBalance(txn.walletId, -txn.amount, txn.type);
        }
        
        return true;
      } catch (e) {
        debugPrint('Error deleting transaction from Supabase: $e');
        await _queuePendingOperation('delete', 'transactions', id, {});
      }
    } else {
      await _queuePendingOperation('delete', 'transactions', id, {});
    }

    return true;
  }
  
  Future<void> syncPendingOperations() async {
    final isOnline = await _checkConnectivity();
    if (!isOnline) return;

    final pending = await _localDb.getPendingOperations();

    for (final op in pending) {
       final tableName = op['table_name'] as String;
       if (tableName != 'transactions') continue;

      try {
        final opType = op['operation_type'] as String;
        final recordId = op['record_id'] as String;

        switch (opType) {
          case 'insert':
            final txn = await _getTransactionFromLocal(recordId);
            if (txn != null) {
              await _supabase.from('transactions').insert(txn.toSupabase());
              await _updateRemoteWalletBalance(txn.walletId, txn.amount, txn.type);
              await _markAsSynced(recordId);
            }
            break;
          case 'update':
            final txn = await _getTransactionFromLocal(recordId);
            if (txn != null) {
              await _supabase
                  .from('transactions')
                  .update(txn.toSupabase())
                  .eq('id', recordId);
              await _markAsSynced(recordId);
            }
            break;
          case 'delete':
            await _supabase.from('transactions').delete().eq('id', recordId);
            break;
        }
        await _localDb.removePendingOperation(op['id'] as int);
      } catch (e) {
        debugPrint('Error syncing transaction op: $e');
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
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

  Future<void> _updateLocalCache(List<Transaction> transactions) async {
    for (final txn in transactions) {
      await _localDb.insert('transactions', txn.toLocal());
    }
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

  Future<void> _queuePendingOperation(
      String type, String table, String id, Map<String, dynamic> data) async {
    await _localDb.addPendingOperation(
      operationType: type,
      tableName: table,
      recordId: id,
      data: json.encode(data),
    );
  }

  Future<void> _markAsSynced(String id) async {
     final txn = await _getTransactionFromLocal(id);
     if (txn != null) {
        await _localDb.update(
          'transactions',
          txn.markAsSynced().toLocal(),
          where: 'id = ?',
          whereArgs: [id],
        );
     }
  }

  Future<void> _updateRemoteWalletBalance(String walletId, double amount, String type) async {
    final factor = type == 'income' ? 1 : -1;
    final delta = amount * factor;

    try {
      // 1. Get current remote balance
      final res = await _supabase.from('wallets').select('balance').eq('id', walletId).single();
      final currentBalance = (res['balance'] as num).toDouble();
      final newBalance = currentBalance + delta;

      await _supabase.from('wallets').update({'balance': newBalance}).eq('id', walletId);
      
    } catch (e) {
      debugPrint('Error updating remote wallet balance: $e');
    }
  }
}
