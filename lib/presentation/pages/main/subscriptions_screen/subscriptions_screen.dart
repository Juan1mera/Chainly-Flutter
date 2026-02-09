import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/subscription_model.dart';
import 'package:chainly/domain/providers/subscription_provider.dart';
import 'package:chainly/presentation/pages/main/subscriptions_screen/components/subscription_card.dart';
import 'package:chainly/presentation/pages/main/subscriptions_screen/components/subscription_edit_sheet.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  
  Future<void> _showSubscriptionSheet({Subscription? subscription}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscriptionEditSheet(subscription: subscription),
    );

    if (result == null) return;

    final notifier = ref.read(subscriptionNotifierProvider.notifier);

    try {
      if (subscription != null) {
        // Edit
        final updated = subscription.copyWith(
          title: result['title'],
          description: result['description'],
          favicon: result['favicon'],
          amount: result['amount'],
          billingDate: result['billingDate'],
          walletId: result['walletId'],
          currency: result['currency'],
          categoryId: result['categoryId'],
        );
        await notifier.updateSubscription(updated);
      } else {
        // Create
        await notifier.createSubscription(
          title: result['title'],
          description: result['description'],
          favicon: result['favicon'],
          amount: result['amount'],
          billingDate: result['billingDate'],
          walletId: result['walletId'],
          categoryId: result['categoryId'],
          currency: result['currency'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscription != null ? 'Suscripción actualizada' : 'Suscripción creada'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSubscription(Subscription subscription) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar suscripción'),
        content: Text('¿Eliminar permanentemente "${subscription.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(subscriptionNotifierProvider.notifier).deleteSubscription(subscription.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suscripción eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsProvider);
          await ref.read(subscriptionsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header + Add Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 140, 24, 20), 
                child: CustomButton(
                  text: "Nueva suscripción",
                  onPressed: () => _showSubscriptionSheet(),
                  leftIcon: const Icon(Icons.add),
                ),
              ),
            ),

            // Subscription List
            subscriptionsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
              data: (subscriptions) {
                if (subscriptions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(Icons.subscriptions_outlined, size: 90, color: Colors.grey),
                          SizedBox(height: 24),
                          Text(
                            'No hay suscripciones aún',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '¡Añade tus servicios favoritos!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.builder(
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SubscriptionCard(
                          subscription: sub,
                          onEdit: () => _showSubscriptionSheet(subscription: sub),
                          onDelete: () => _deleteSubscription(sub),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
