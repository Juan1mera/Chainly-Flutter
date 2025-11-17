// lib/presentation/pages/main/home_screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/transaction_with_details.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/transactions_home_section.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/wallet_service.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/services/category_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        children: [
          const SizedBox(height: 80), // Espacio para el header fijo

          const Text(
            'Your Cards',
            style: TextStyle(fontSize: 30, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w500),
          ),

          FutureBuilder<List<Wallet>>(
            future: _walletService.getWallets(includeArchived: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar carteras'));
              }
              final wallets = snapshot.data ?? [];
              return WalletsHomeSection(wallets: wallets);
            },
          ),

          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: TextStyle(fontSize: 30, fontFamily: 'ClashDisplay', fontWeight: FontWeight.w400),
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
                    transactions: transactions,
                    categories: categories,
                    onViewAllPressed: () {},
                  );
                },
              );
            },
          ),

          const SizedBox(height: 100), // Espacio inferior
        ],
      ),
    );
  }
}