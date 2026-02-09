import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/favicon_getter.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/data/models/subscription_model.dart';
import 'package:intl/intl.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Favicon or Placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: (subscription.favicon != null && subscription.favicon!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(
                        FaviconGetter.getFaviconUrl(subscription.favicon!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.subscriptions_outlined, color: AppColors.purple),
                      ),
                    ),
                  )
                : const Icon(Icons.subscriptions_outlined, color: AppColors.purple),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
                Text(
                  'Próximo cobro: ${DateFormat('dd MMM').format(subscription.billingDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          // Amount and Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatAmount(subscription.amount)} ${subscription.currency}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
