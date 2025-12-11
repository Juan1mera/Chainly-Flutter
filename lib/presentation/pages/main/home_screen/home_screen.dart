import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/models/category_model.dart';
import 'package:chainly/models/transaction_with_details.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/transactions_home_section.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:chainly/providers/wallet_provider.dart';
import 'package:chainly/services/transaction_service.dart';
import 'package:chainly/services/category_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TransactionService _transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(walletsProvider.notifier).loadWallets(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        children: [
          const SizedBox(height: 80),

          const Text(
            'Your Cards',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            'Cards information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),

          walletsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (wallets) => WalletsHomeSection(wallets: wallets),
          ),

          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    'Latest account activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              Icon(Bootstrap.arrow_up_right, size: 35, color: AppColors.black),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Category>>(
            future: CategoryService().getCategories(),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final categories = categorySnapshot.data ?? [];

              return FutureBuilder<List<TransactionWithDetails>>(
                future: _transactionService.getAllTransactionsWithDetails(),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (transactionSnapshot.hasError) {
                    return const Center(
                      child: Text('Error al cargar transacciones'),
                    );
                  }
                  final transactions = transactionSnapshot.data ?? [];

                  return TransactionsHomeSection(
                    transactions: transactions.take(5).toList(),
                    categories: categories,
                    onViewAllPressed: () {},
                  );
                },
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
