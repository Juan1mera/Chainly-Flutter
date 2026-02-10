import 'package:chainly/domain/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/data/models/transaction_with_details.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/transactions_home_section.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/subscriptions_home_section.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/category_provider.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';
import 'package:chainly/data/models/transaction_model.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Dummy data for skeleton loading
  final List<Wallet> _dummyWallets = List.generate(
    3,
    (index) => Wallet(
      id: 'dummy_$index',
      name: 'Wallet Name',
      currency: 'USD',
      userId: 'user',
      color: '#000000',
      type: 'cash',
      balance: 1000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  final List<Category> _dummyCategories = List.generate(
    5,
    (index) => Category(
      id: 'dummy_cat_$index',
      name: 'Category',
      userId: 'user',
      type: 'expense',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  final List<Transaction> _dummyTransactions = List.generate(
    5,
    (index) => Transaction(
      id: 'dummy_trans_$index',
      amount: 50.0,
      type: 'expense',
      date: DateTime.now(),
      walletId: 'dummy_0',
      categoryId: 'dummy_cat_0',
      note: 'Transaction Description',
      userId: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));
    final categoriesAsync = ref.watch(categoriesProvider);
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);
    final storesAsync = ref.watch(storesProvider);

    // Determine loading state
    final bool isLoading = walletsAsync.isLoading ||
        categoriesAsync.isLoading ||
        recentTransactionsAsync.isLoading ||
        storesAsync.isLoading;

    // Prepare data (use dummy if loading, otherwise real data or empty list)
    final wallets = walletsAsync.asData?.value ?? (isLoading ? _dummyWallets : []);
    final categories = categoriesAsync.asData?.value ?? (isLoading ? _dummyCategories : []);
    final transactions = recentTransactionsAsync.asData?.value ?? (isLoading ? _dummyTransactions : []);
    final stores = storesAsync.asData?.value ?? [];

    // Create TransactionWithDetails list
    final transactionsWithDetails = transactions.map((t) {
      final wallet = wallets.firstWhere(
        (w) => w.id == t.walletId,
        orElse: () => Wallet(
          id: 'unknown',
          name: 'Unknown',
          currency: '???',
          userId: 'user',
          color: '#000000',
          type: 'cash',
          balance: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final category = categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          userId: 'user',
          type: t.type,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final store = stores.where((s) => s.id == t.storeId).firstOrNull;

      return TransactionWithDetails(
        transaction: t,
        wallet: wallet,
        category: category,
        store: store,
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(subscriptionsProvider);
        ref.invalidate(storesProvider);
      },
      child: Skeletonizer(
        enabled: isLoading,
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

            // Wallets Section
            WalletsHomeSection(wallets: wallets),

            const SizedBox(height: 24),

            // Subscriptions Section
            const SubscriptionsHomeSection(),

            const SizedBox(height: 12),
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

            // Transactions Section
            TransactionsHomeSection(
              transactions: transactionsWithDetails.take(5).toList(),
              categories: categories,
              onViewAllPressed: () {
                // Navigate to all transactions if implemented
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
