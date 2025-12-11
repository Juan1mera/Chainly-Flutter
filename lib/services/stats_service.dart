// lib/services/stats_service.dart

import 'package:chainly/core/database/db.dart';
import 'package:chainly/services/transaction_service.dart';
import 'package:chainly/services/wallet_service.dart';

class StatsService {
  final Db _db = Db();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  // Cache simple para tasas de cambio (para evitar muchas peticiones)
  final Map<String, double> _exchangeCache = {};
  DateTime? _cacheTimestamp;
  static const Duration cacheDuration = Duration(hours: 1);

  Future<List<String>> getUsedCurrencies() async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT DISTINCT w.currency
      FROM wallets w
      WHERE w.is_archived = 0
      ORDER BY w.currency
    ''');
    return results.map((row) => row['currency'] as String).toList();
  }

  // Conversión con caché
  Future<double> _convert(double amount, String from, String? to) async {
    if (to == null || from == to) return amount;

    final cacheKey = '$from->$to';
    final now = DateTime.now();

    if (_cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < cacheDuration &&
        _exchangeCache.containsKey(cacheKey)) {
      return amount * _exchangeCache[cacheKey]!;
    }

    try {
      final converted = await _transactionService.convertCurrency(
        amount: amount,
        fromCurrency: from,
        toCurrency: to,
      );
      // Guardar tasa inversa también
      final rate = converted / amount;
      _exchangeCache[cacheKey] = rate;
      _exchangeCache['$to->$from'] = 1 / rate;
      _cacheTimestamp = now;
      return converted;
    } catch (e) {
      return amount; // fallback si falla internet
    }
  }

  // GASTOS POR CATEGORÍA (convertidos a divisa objetivo)
  Future<Map<String, double>> getExpensesByCategory({
    DateTime? month,
    String? targetCurrency,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59,59);

    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT 
        c.name AS category_name,
        t.amount,
        w.currency AS wallet_currency
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.type = 'expense'
        AND t.date >= ?
        AND t.date <= ?
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    final Map<String, double> totals = {};

    for (var row in results) {
      final category = row['category_name'] as String? ?? 'Sin categoría';
      final amount = (row['amount'] as num).toDouble();
      final currency = row['wallet_currency'] as String? ?? 'USD';

      final convertedAmount = await _convert(amount, currency, targetCurrency);

      totals.update(
        category,
        (v) => v + convertedAmount,
        ifAbsent: () => convertedAmount,
      );
    }

    // Ordenar desc
    final sorted = Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sorted;
  }

  // INGRESOS POR CATEGORÍA
  Future<Map<String, double>> getIncomesByCategory({
    DateTime? month,
    String? targetCurrency,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23,59,59);

    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT 
        c.name AS category_name,
        t.amount,
        w.currency AS wallet_currency
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.type = 'income'
        AND t.date >= ?
        AND t.date <= ?
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    final Map<String, double> totals = {};

    for (var row in results) {
      final category = row['category_name'] as String? ?? 'Sin categoría';
      final amount = (row['amount'] as num).toDouble();
      final currency = row['wallet_currency'] as String? ?? 'USD';

      final convertedAmount = await _convert(amount, currency, targetCurrency);

      totals.update(
        category,
        (v) => v + convertedAmount,
        ifAbsent: () => convertedAmount,
      );
    }

    final sorted = Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sorted;
  }

  // TOTALES MENSUALES
  Future<Map<String, double>> getMonthlyTotals({
    DateTime? month,
    String? targetCurrency,
  }) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23,59,59);

    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT t.type, t.amount, w.currency
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.date >= ? AND t.date <= ?
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    double income = 0, expense = 0;

    for (var row in results) {
      final type = row['type'] as String;
      final amount = (row['amount'] as num).toDouble();
      final currency = row['currency'] as String? ?? 'USD';

      final converted = await _convert(amount, currency, targetCurrency);

      if (type == 'income') {
        income += converted;
      } else if (type == 'expense') {
        expense += converted;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  // GASTOS POR DIVISA (sin convertir, solo para mostrar distribución)
  Future<Map<String, double>> getExpensesByCurrency({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23,59,59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT w.currency, SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.type = 'expense'
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY w.currency
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    final Map<String, double> expenses = {};
    for (var row in results) {
      final currency = row['currency'] as String? ?? 'USD';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      expenses[currency] = total;
    }
    return expenses;
  }

  // BALANCE TOTAL POR DIVISA (convertido opcionalmente)
  Future<Map<String, double>> getTotalByCurrency({String? targetCurrency}) async {
    final wallets = await _walletService.getWallets(includeArchived: false);
    final Map<String, double> totals = {};

    for (final wallet in wallets) {
      final converted = targetCurrency == null || wallet.currency == targetCurrency
          ? wallet.balance
          : await _convert(wallet.balance, wallet.currency, targetCurrency);

      totals.update(
        wallet.currency,
        (v) => v + converted,
        ifAbsent: () => converted,
      );
    }

    // Si hay divisa objetivo, agrupar todo bajo esa divisa
    if (targetCurrency != null) {
      final total = totals.values.fold(0.0, (a, b) => a + b);
      return {targetCurrency: total};
    }

    return totals;
  }

  // Comparación de gastos por wallet (convertido a divisa seleccionada)
  Future<Map<String, Map<String, double>>> getWalletExpensesComparison({
    String? targetCurrency,
  }) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final wallets = await _walletService.getWallets(includeArchived: false);
    final comparison = <String, Map<String, double>>{};

    for (final wallet in wallets) {
      final current = await _getWalletExpensesForMonth(wallet.id!, currentMonth, targetCurrency);
      final previous = await _getWalletExpensesForMonth(wallet.id!, lastMonth, targetCurrency);

      final diff = current - previous;
      final pct = previous > 0 ? (diff / previous) * 100 : (current > 0 ? 100.0 : 0.0);

      comparison[wallet.name] = {
        'current': current,
        'previous': previous,
        'difference': diff,
        'percentageChange': pct,
      };
    }
    return comparison;
  }

  Future<double> _getWalletExpensesForMonth(int walletId, DateTime month, String? targetCurrency) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23,59,59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT SUM(t.amount) as total, w.currency
      FROM transactions t
      JOIN wallets w ON t.wallet_id = w.id
      WHERE t.wallet_id = ? AND t.type = 'expense'
        AND t.date >= ? AND t.date <= ?
      GROUP BY w.currency
    ''', [walletId, firstDay.toIso8601String(), lastDay.toIso8601String()]);

    if (results.isEmpty || results.first['total'] == null) return 0.0;

    final amount = (results.first['total'] as num).toDouble();
    final currency = results.first['currency'] as String? ?? 'USD';

    return await _convert(amount, currency, targetCurrency);
  }

  Future<Map<String, double>> getIncomesByCurrencyRaw({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT w.currency, SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.type = 'income'
        AND t.date >= ? AND t.date <= ?
      GROUP BY w.currency
    ''', [firstDay.toIso8601String(), lastDay.toIso8601String()]);

    final Map<String, double> incomes = {};
    for (var row in results) {
      final currency = row['currency'] as String? ?? 'USD';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      incomes[currency] = total;
    }
    return incomes;
  } 


  // Tendencia de gastos (convertida)
  Future<Map<String, double>> getExpensesTrend({String? targetCurrency}) async {
    final now = DateTime.now();
    final trend = <String, double>{};

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final firstDay = DateTime(monthDate.year, monthDate.month, 1);
      final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0, 23,59,59);

      final transactions = await _transactionService.getAllTransactions(
        type: 'expense',
        from: firstDay,
        to: lastDay,
      );

      double total = 0.0;
      for (final t in transactions) {
        final wallet = await _walletService.getWalletById(t.walletId); 
        final currency = wallet?.currency ?? 'USD';
        total += await _convert(t.amount, currency, targetCurrency);
      }

      trend[_getMonthName(monthDate.month)] = total;
    }
    return trend;
  }

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }
}