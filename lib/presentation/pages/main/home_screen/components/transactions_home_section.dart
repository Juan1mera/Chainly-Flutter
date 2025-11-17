// transactions_home_section.dart
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/category_model.dart'; // Asegúrate de tener este import
import 'dart:ui';

class TransactionsHomeSection extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories; // ← Añadimos las categorías
  final VoidCallback? onViewAllPressed;

  const TransactionsHomeSection({
    super.key,
    required this.transactions,
    required this.categories, // ← ahora es obligatorio
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
          final category = _getCategoryById(transaction.categoryId) ?? 
              Category(name: transaction.type == 'expense' ? 'Gasto' : 'Ingreso');

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

  Widget _buildTransactionCard(Transaction transaction, Category category) {
    final bool isExpense = transaction.type == 'expense';

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
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
                        color: AppColors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getIcon(),
                        color: AppColors.black.withOpacity(0.9),
                        size: 24,
                      ),
                    ),
                    Text(
                      transaction.currency ?? 'USD',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                Text(
                  transaction.comment?.isNotEmpty == true
                      ? transaction.comment!
                      : category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ClashDisplay',
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}',
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                          backgroundColor: Colors.white12,
                          child: Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                        ),
                        SizedBox(height: 16),
                        Text('Ver todas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'ClashDisplay', color: Colors.white)),
                        SizedBox(height: 4),
                        Text('las transacciones', style: TextStyle(fontSize: 12, color: Colors.white70)),
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