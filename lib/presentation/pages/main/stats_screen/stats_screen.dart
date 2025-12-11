import 'package:chainly/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/services/stats_service.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();

  bool _isLoading = true;
  List<String> _availableCurrencies = [];
  String? _selectedCurrency;

  // Datos
  Map<String, double> _monthlyTotals =
      {}; // income, expense, balance (convertidos)
  Map<String, double> _totalByCurrencyRaw = {}; // balance por divisa original
  Map<String, double> _totalConverted = {}; // balance total convertido
  Map<String, double> _incomeByCurrencyRaw =
      {}; // ingresos por divisa (sin convertir)
  Map<String, double> _expenseByCurrencyRaw =
      {}; // gastos por divisa (sin convertir)

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats([String? currency]) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currencies = await _statsService.getUsedCurrencies();
      if (currencies.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _selectedCurrency = currency ?? currencies.first;

      final results = await Future.wait([
        _statsService.getMonthlyTotals(targetCurrency: _selectedCurrency),
        _statsService.getTotalByCurrency(), // sin convertir
        _statsService.getTotalByCurrency(targetCurrency: _selectedCurrency),
        _statsService.getExpensesByCurrency(), // gastos por divisa original
        _statsService.getIncomesByCurrencyRaw(), // ingresos por divisa original
        _statsService.getUsedCurrencies(),
      ]);

      if (!mounted) return;

      setState(() {
        _monthlyTotals = results[0] as Map<String, double>;
        _totalByCurrencyRaw = results[1] as Map<String, double>;
        _totalConverted = results[2] as Map<String, double>;
        _expenseByCurrencyRaw = results[3] as Map<String, double>;
        _incomeByCurrencyRaw = results[4] as Map<String, double>;
        _availableCurrencies = results[5] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading stats')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _totalConverted.values.firstOrNull ?? 0.0;
    final income = _monthlyTotals['income'] ?? 0.0;
    final expense = _monthlyTotals['expense'] ?? 0.0;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadStats(_selectedCurrency),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 150, 20, 100),
                children: [
                  // === TOTAL BALANCE + CURRENCY SELECTOR ===
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontFamily: AppFonts.clashDisplay,
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatAmount(totalBalance.abs()),
                            style: const TextStyle(
                              fontFamily: AppFonts.clashDisplay,
                              fontSize: 42,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedCurrency ?? 'USD',
                            style: const TextStyle(
                              fontFamily: AppFonts.clashDisplay,
                              fontSize: 38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Custom Select
                      if (_availableCurrencies.isNotEmpty)
                        CustomSelect<String>(
                          label: 'Currency',
                          items: _availableCurrencies,
                          selectedItem: _selectedCurrency,
                          getDisplayText: (c) => c,
                          onChanged: (val) => _loadStats(val),
                          hintText: 'Select currency',
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),

                  // === BALANCE BY CURRENCY ===
                  _SectionTitle(title: 'Balance by Currency'),
                  const SizedBox(height: 12),
                  ..._totalByCurrencyRaw.entries.map(
                    (e) => _CurrencyRow(currency: e.key, amount: e.value),
                  ),

                  const SizedBox(height: 40),

                  // === THIS MONTH SUMMARY ===
                  _SectionTitle(title: 'This Month'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigNumber(
                        label: 'Income',
                        amount: income,
                        color: AppColors.greenDark,
                      ),
                      _BigNumber(
                        label: 'Expenses',
                        amount: expense,
                        color: AppColors.redDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === INCOME BY CURRENCY ===
                  _SectionTitle(title: 'Income by Currency'),
                  const SizedBox(height: 12),
                  if (_incomeByCurrencyRaw.isEmpty)
                    const Text(
                      'No income this month',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ..._incomeByCurrencyRaw.entries.map(
                    (e) => _CurrencyRow(
                      currency: e.key,
                      amount: e.value,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // === EXPENSES BY CURRENCY ===
                  _SectionTitle(title: 'Expenses by Currency'),
                  const SizedBox(height: 12),
                  if (_expenseByCurrencyRaw.isEmpty)
                    const Text(
                      'No expenses this month',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ..._expenseByCurrencyRaw.entries.map(
                    (e) => _CurrencyRow(
                      currency: e.key,
                      amount: e.value,
                      color: AppColors.redDark,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

// Widgets reutilizables
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.clashDisplay,
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _BigNumber({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          formatAmount(amount),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: AppFonts.clashDisplay,
          ),
        ),
      ],
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final String currency;
  final double amount;
  final Color? color;

  const _CurrencyRow({
    required this.currency,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currency,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '${amount >= 0 ? '+' : '-'}${formatAmount(amount.abs())} $currency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color ?? (amount >= 0 ? AppColors.greenDark : AppColors.redDark),
            ),
          ),
        ],
      ),
    );
  }
}
