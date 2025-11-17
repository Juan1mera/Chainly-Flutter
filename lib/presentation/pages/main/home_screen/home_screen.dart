import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/models/transaction_with_details.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/transactions_home_section.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:wallet_app/providers/wallet_provider.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/category_service.dart';

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

          const Text('Your Cards', style: TextStyle(fontSize: 30, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w500)),
          const Text('Cards information', style: TextStyle(fontSize: 16, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w300)),
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
                  Text('Transactions', style: TextStyle(fontSize: 30, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w400)),
                  Text('Latest account activity', style: TextStyle(fontSize: 16, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w300)),
                ],
              ),
              Icon(Icons.arrow_outward_rounded, size: 35, color: AppColors.black),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Category>>(
            future: CategoryService().getCategories(),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final categories = categorySnapshot.data ?? [];

              return FutureBuilder<List<TransactionWithDetails>>(
                future: _transactionService.getAllTransactionsWithDetails(),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (transactionSnapshot.hasError) {
                    return const Center(child: Text('Error al cargar transacciones'));
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