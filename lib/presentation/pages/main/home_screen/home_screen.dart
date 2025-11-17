import 'package:flutter/material.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/header_home_section.dart';
import 'package:wallet_app/presentation/pages/main/home_screen/components/wallets_home_section.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/wallet_service.dart';

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
    return Scaffold(
      appBar: HeaderHomeSection(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Wallets Section
            const Text(
              'Your Cards',
              style: TextStyle(
                fontSize: 20, 
                fontFamily: 'ClashDisplay',
                fontWeight: FontWeight.w500
              ),
            ),
            const SizedBox(height: 12),
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

            // Recent Transactions Section
            const Text(
              'Últimas Transacciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Transaction>>(
              future: _transactionService.getAllTransactions().then((all) => all.take(10).toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar transacciones'));
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay transacciones recientes',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Column(
                  children: transactions.map((t) {
                    final isExpense = t.type == 'expense';
                    final sign = isExpense ? '- ' : '+ ';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(t.comment ?? (isExpense ? 'Gasto' : 'Ingreso')),
                        subtitle: Text(
                          '${t.date.day}/${t.date.month}/${t.date.year} • ${t.currency}',
                        ),
                        trailing: Text(
                          '$sign${t.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}