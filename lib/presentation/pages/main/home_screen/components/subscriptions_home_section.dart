import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/favicon_getter.dart';
import 'package:chainly/core/utils/number_format.dart';
import 'package:chainly/data/models/subscription_model.dart';
import 'package:chainly/domain/providers/subscription_provider.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:collection/collection.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:intl/intl.dart';

class SubscriptionsHomeSection extends ConsumerWidget {
  const SubscriptionsHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsDue = ref.watch(subscriptionsDueTodayProvider);

    if (subscriptionsDue.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximos Cobros',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.clashDisplay,
          ),
        ),
        const Text(
          'Suscripciones pendientes para hoy',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 203,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: subscriptionsDue.length,
            itemBuilder: (context, index) {
              final subscription = subscriptionsDue[index];
              final rotation = (index % 2 == 0) ? -0.06 : 0.06;

              return Transform.rotate(
                angle: rotation,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
                  child: _SubscriptionDueItem(subscription: subscription),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SubscriptionDueItem extends ConsumerStatefulWidget {
  final Subscription subscription;

  const _SubscriptionDueItem({required this.subscription});

  @override
  ConsumerState<_SubscriptionDueItem> createState() => _SubscriptionDueItemState();
}

class _SubscriptionDueItemState extends ConsumerState<_SubscriptionDueItem> {
  void _showPaymentConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirmar Pago',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.clashDisplay,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Suscripción', widget.subscription.title),
              _buildDetailRow('Monto', '${formatAmount(widget.subscription.amount)} ${widget.subscription.currency}'),
              _buildDetailRow('Fecha Actual', DateFormat('dd MMM, yyyy').format(DateTime.now())),
              
              Consumer(
                builder: (context, ref, child) {
                  final walletAsync = ref.watch(walletByIdProvider(widget.subscription.walletId));
                  return walletAsync.when(
                    data: (wallet) => _buildDetailRow('De la cuenta', wallet?.name ?? 'Billetera desconocida'),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => _buildDetailRow('De la cuenta', 'Error al cargar'),
                  );
                }
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              const Text(
                'Siguiente Cobro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.clashDisplay,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La suscripción se actualizará al día ${widget.subscription.billingDate.day} del próximo mes.',
                style: const TextStyle(fontSize: 14, color: AppColors.greyDark),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(subscriptionNotifierProvider.notifier).paySubscription(widget.subscription);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Confirmar Pago'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.greyDark, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);
    final stores = storesAsync.asData?.value ?? [];
    final store = stores.firstWhereOrNull((s) => s.id == widget.subscription.storeId);
    
    String? faviconUrl;
    if (store?.website != null && store!.website!.isNotEmpty) {
      faviconUrl = FaviconGetter.getFaviconUrl(store.website!);
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          )
                        ]
                      ),
                      child: (faviconUrl != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.network(
                                  faviconUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.subscriptions_outlined, color: AppColors.purple, size: 20),
                                ),
                              ),
                            )
                          : const Icon(Icons.subscriptions_outlined, color: AppColors.purple, size: 20),
                    ),
                    Text(
                        '${widget.subscription.billingDate.day.toString()}/${widget.subscription.billingDate.month.toString()}',
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.subscription.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${formatAmount(widget.subscription.amount)} ${widget.subscription.currency}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showPaymentConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(double.infinity, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Pagar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
