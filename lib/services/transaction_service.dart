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

// ← Reemplaza SOLO este método en tu TransactionService
Future<int> createTransactionWithCategoryName({
  required int walletId,
  required String type,
  required double amount,
  required String categoryName,
  String? note,
}) async {
  final db = await _db.database;

  // 1. Aseguramos que la categoría exista
  final categoryId = await _categoryService.getOrCreateCategoryId(categoryName);

  // 2. Creamos la transacción
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

  // 3. Iniciar una transacción de base de datos para mantener consistencia
  return await db.transaction((txn) async {
    // Insertar la transacción
    final transactionId = await txn.insert('transactions', transaction.toMap());

    // 4. Actualizar el balance de la wallet
    final updateQuery = '''
      UPDATE wallets 
      SET balance = balance + ? 
      WHERE id = ?
    ''';

    // Si es ingreso → suma, si es gasto → resta
    final balanceChange = type == 'income' ? amount : -amount;

    await txn.rawUpdate(updateQuery, [balanceChange, walletId]);

    return transactionId;
  });
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


Future<List<TransactionWithDetails>> getAllTransactionsWithDetails({
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;

    // 1. Primero obtenemos todas las transacciones (con filtros)
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

    // 2. JOIN con wallets y categories para traer todo junto
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

    // 3. Convertir a objetos
    final List<TransactionWithDetails> result = [];

    for (final map in maps) {
      final transaction = Transaction.fromMap(_extractTransactionMap(map));
      final wallet = Wallet.fromMap(_extractWalletMap(map));
      final category = Category.fromMap(_extractCategoryMap(map));

      result.add(TransactionWithDetails(
        transaction: transaction,
        wallet: wallet,
        category: category,
      ));
    }

    return result;
  }

  // Helpers para extraer sub-mapas (porque rawQuery devuelve todo plano)
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
      'balance': 0.0, // no lo necesitamos aquí
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