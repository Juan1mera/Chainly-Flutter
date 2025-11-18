// lib/presentation/pages/extra/wallet_screen/components/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/category_model.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'MXN': r'$', 'BRL': r'R$', 'INR': '₹', 'COP': 'COL',
    };
    return symbols[currency] ?? currency;
  }

  Color _getColor(String type) => type == 'income' ? Colors.green : Colors.red;
  IconData _getIcon(String type) => type == 'income' ? Icons.arrow_downward : Icons.arrow_upward;

  // FORMATEO MANUAL DE FECHA (sin intl)
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No hay transacciones', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Las transacciones aparecerán aquí', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final symbol = _getCurrencySymbol(currency);

    // Agrupar por fecha formateada
    final Map<String, List<Transaction>> grouped = {};
    for (var t in transactions) {
      final key = _formatDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ),
            ...items.map((t) {
              final category = categories.firstWhereOrNull((c) => c.id == t.categoryId) ?? Category(name: 'Sin categoría');
              final color = _getColor(t.type);
              final icon = _getIcon(t.type);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(_formatTime(t.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      if (t.note != null && t.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(t.note!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${t.type == 'expense' ? '-' : '+'}$symbol${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}