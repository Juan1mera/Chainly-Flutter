// transactions_home_section.dart
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';
import 'package:wallet_app/core/utils/number_format.dart';
import 'package:wallet_app/models/category_model.dart'; 
import 'dart:ui';

import 'package:wallet_app/models/transaction_with_details.dart';

class TransactionsHomeSection extends StatelessWidget {
  final List<TransactionWithDetails> transactions;
  final List<Category> categories; 
  final VoidCallback? onViewAllPressed;

  const TransactionsHomeSection({
    super.key,
    required this.transactions,
    required this.categories, 
    this.onViewAllPressed,
  });

  // Helper para buscar categoría por ID
  Category? _getCategoryById(int categoryId) {
    try {
      return categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTransactions = transactions.take(10).toList();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: displayTransactions.length + (displayTransactions.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayTransactions.length) {
            return _buildViewAllCard();
          }

          final transaction = displayTransactions[index];
          final category = _getCategoryById(transaction.transaction.categoryId) ?? 
              Category(name: transaction.transaction.type == 'expense' ? 'Gasto' : 'Ingreso');

          final rotation = (index % 2 == 0) ? -0.02 : 0.02;

          return Transform.rotate(
            angle: rotation,
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: _buildTransactionCard(transaction, category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionWithDetails transaction, Category category) {
    final bool isExpense = transaction.transaction.type == 'expense';

    IconData getIcon() {
      if (category.icon != null && category.icon!.isNotEmpty) {
        try {
          final code = int.tryParse(category.icon!, radix: 16);
          if (code != null) {
            return IconData(code, fontFamily: 'MaterialIcons');
          }
        } catch (_) {}
      }
      return isExpense ? Icons.shopping_bag_outlined : Icons.savings_outlined;
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getIcon(),
                        color: AppColors.black,
                        size: 24,
                      ),
                    ),
                    Text(
                      transaction.wallet.currency,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.black,
                        fontFamily: AppFonts.clashDisplay,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transaction.note ?? ''
                    ),
                    Text(
                      formatAmountTransaction(
                        transaction.transaction.amount,
                        isExpense: transaction.transaction.type == 'expense',
                      ),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.clashDisplay
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.transaction.date.day}/${transaction.transaction.date.month}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllCard() {
    return Transform.rotate(
      angle: 0.02,
      child: Container(
        margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
        width: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewAllPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_forward, color: AppColors.black, size: 30),
                        ),
                        SizedBox(height: 16),
                        Text('See All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: AppFonts.clashDisplay, color: AppColors.black)),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


}