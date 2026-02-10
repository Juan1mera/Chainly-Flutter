import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/data/models/transaction_model.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/core/utils/favicon_getter.dart';

class TransactionCardSimple extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final Store? store; // Nuevo parametro
  final String currencySymbol;

  const TransactionCardSimple({
    super.key,
    required this.transaction,
    required this.category,
    this.store,
    required this.currencySymbol,
  });

  Widget _getIconWidget() {
    // 1. Si hay store con website, mostrar favicon
    if (store?.website != null && store!.website!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10), // Un poco menos que el contenedor
        child: Image.network(
          FaviconGetter.getFaviconUrl(store!.website!),
          width: 26,
          height: 26,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            _getCategoryIcon(),
             color: AppColors.black,
             size: 26,
          ),
        ),
      );
    }

    // 2. Si no, mostrar icono de categoría
    return Icon(
      _getCategoryIcon(),
      color: AppColors.black,
      size: 26,
    );
  }

  IconData _getCategoryIcon() {
    if (category.icon != null && category.icon!.isNotEmpty) {
      final code = int.tryParse(category.icon!, radix: 16);
      if (code != null) {
        return IconData(code, fontFamily: 'MaterialIcons');
      }
    }
    return transaction.type == 'expense'
        ? Icons.shopping_bag_outlined
        : Icons.savings_outlined;
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction.type == 'expense';
    final String displayText = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!
        : category.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Icono en círculo blanco
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _getIconWidget(),
                ),

                const SizedBox(width: 14),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.clashDisplay,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(transaction.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.greyDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Monto y moneda
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmountTransaction(
                        transaction.amount,
                        isExpense: isExpense,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.clashDisplay,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
}