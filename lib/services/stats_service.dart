import 'package:chainly/core/database/db.dart';
import 'package:chainly/services/transaction_service.dart';
import 'package:chainly/services/wallet_service.dart';

class StatsService {
  final Db _db = Db();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  // Gastos por categoría en el mes actual
  Future<Map<String, double>> getExpensesByCategory({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT c.name, SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense'
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY c.name
      ORDER BY total DESC
    ''', [firstDay.millisecondsSinceEpoch, lastDay.millisecondsSinceEpoch]);

    final Map<String, double> expenses = {};
    for (var row in results) {
      final name = row['name'] as String? ?? 'Sin categoría';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      expenses[name] = total;
    }
    return expenses;
  }

  // Ingresos por categoría en el mes actual
  Future<Map<String, double>> getIncomesByCategory({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT c.name, SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'income'
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY c.name
      ORDER BY total DESC
    ''', [firstDay.millisecondsSinceEpoch, lastDay.millisecondsSinceEpoch]);

    final Map<String, double> incomes = {};
    for (var row in results) {
      final name = row['name'] as String? ?? 'Sin categoría';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      incomes[name] = total;
    }
    return incomes;
  }

  // Total de gastos e ingresos del mes actual
  Future<Map<String, double>> getMonthlyTotals({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final transactions = await _transactionService.getAllTransactions(
      from: firstDay,
      to: lastDay,
    );

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final t in transactions) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else if (t.type == 'expense') {
        totalExpense += t.amount;
      }
    }

    return {
      'income': totalIncome,
      'expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // Gastos por divisa en el mes actual
  Future<Map<String, double>> getExpensesByCurrency({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT w.currency, SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN wallets w ON t.wallet_id = w.id
      WHERE t.type = 'expense'
        AND t.date >= ?
        AND t.date <= ?
      GROUP BY w.currency
      ORDER BY total DESC
    ''', [firstDay.millisecondsSinceEpoch, lastDay.millisecondsSinceEpoch]);

    final Map<String, double> expenses = {};
    for (var row in results) {
      final currency = row['currency'] as String? ?? 'USD';
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      expenses[currency] = total;
    }
    return expenses;
  }

  // Balance total por divisa (suma de balances de wallets activas)
  Future<Map<String, double>> getTotalByCurrency() async {
    final wallets = await _walletService.getWallets(includeArchived: false);
    final Map<String, double> totals = {};

    for (final wallet in wallets) {
      totals.update(
        wallet.currency,
        (existing) => existing + wallet.balance,
        ifAbsent: () => wallet.balance,
      );
    }
    return totals;
  }

  // Comparación de gastos por wallet: mes actual vs mes anterior
  Future<Map<String, Map<String, double>>> getWalletExpensesComparison() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final wallets = await _walletService.getWallets(includeArchived: false);
    final comparison = <String, Map<String, double>>{};

    for (final wallet in wallets) {
      final double currentExpenses =
          await _getWalletExpensesForMonth(wallet.id!, currentMonth);
      final double lastExpenses =
          await _getWalletExpensesForMonth(wallet.id!, lastMonth);

      final double difference = currentExpenses - lastExpenses;
      final double percentageChange = lastExpenses > 0
          ? ((currentExpenses - lastExpenses) / lastExpenses) * 100
          : 0.0;

      comparison[wallet.name] = {
        'current': currentExpenses,
        'previous': lastExpenses,
        'difference': difference,
        'percentageChange': percentageChange,
      };
    }

    return comparison;
  }

  // Helper: gastos de una wallet en un mes específico
  Future<double> _getWalletExpensesForMonth(int walletId, DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final transactions = await _transactionService.getTransactionsByWallet(
      walletId,
      type: 'expense',
      from: firstDay,
      to: lastDay,
    );

    return transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // Tendencia de gastos de los últimos 6 meses
  Future<Map<String, double>> getExpensesTrend() async {
    final now = DateTime.now();
    final trend = <String, double>{};

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final firstDay = DateTime(monthDate.year, monthDate.month, 1);
      final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

      final transactions = await _transactionService.getAllTransactions(
        type: 'expense',
        from: firstDay,
        to: lastDay,
      );

      final total = transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
      final monthName = _getMonthName(monthDate.month);

      trend[monthName] = total;
    }

    return trend;
  }

  // Nombre corto del mes en español
  String _getMonthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }
}