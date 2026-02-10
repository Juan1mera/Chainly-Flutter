import 'package:chainly/data/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/data/models/transaction_model.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/presentation/widgets/common/transaction_card_simple.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionListSection extends ConsumerWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  User? get _user => Supabase.instance.client.auth.currentUser;


  const TransactionListSection({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  String _getSymbol(String currency) {
    const map = {
      'USD': r'USD',
      'EUR': 'EUR',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
      'COP': r'COP',
      'RUB': r'RUB',
    };
    return map[currency] ?? currency;
  }

  String _formatDate(DateTime d) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.white70,
              ),
              SizedBox(height: 16),
              Text(
                'No hay transacciones',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              Text(
                'Toca + para empezar',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );
    }

    final storesAsync = ref.watch(storesProvider);
    final stores = storesAsync.asData?.value ?? [];

    final symbol = _getSymbol(currency);
    final grouped = groupBy(
      transactions,
      (Transaction t) => _formatDate(t.date),
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final date = grouped.keys.elementAt(index);
        final dayTransactions = grouped[date]!;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + index * 100),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (_, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                    fontFamily: AppFonts.clashDisplay
                  ),
                ),
              ),
                  ...dayTransactions.map((t) {
                final category =
                    categories.firstWhereOrNull((c) => c.id == t.categoryId) ??
                    Category(
                      id: 'temp', 
                      name: 'Sin categoría', 
                      icon: 'question_mark', 
                      userId: '${_user?.id}',
                      type: 'expense',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                
                final store = stores.firstWhereOrNull((s) => s.id == t.storeId);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TransactionCardSimple(
                    key: ValueKey(t.id),
                    transaction: t,
                    category: category,
                    store: store,
                    currencySymbol: symbol,
                  ),
                );
              }),
            ],
          ),
        );
      }, childCount: grouped.length),
    );
  }
}


