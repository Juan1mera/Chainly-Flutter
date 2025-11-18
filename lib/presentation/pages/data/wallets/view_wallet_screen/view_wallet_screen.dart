// lib/presentation/pages/extra/wallet_screen/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/presentation/pages/data/transactions/create_transaction_screen/create_transaction_screen.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/transaction_list.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/transaction_tabs.dart';
import 'package:wallet_app/presentation/pages/data/wallets/view_wallet_screen/components/wallet_card.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/services/category_service.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/services/wallet_service.dart';

class ViewWalletScreen extends StatefulWidget {
  final int walletId;

  const ViewWalletScreen({super.key, required this.walletId});

  @override
  State<ViewWalletScreen> createState() => _ViewWalletScreenState();
}

class _ViewWalletScreenState extends State<ViewWalletScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  Wallet? _wallet;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _filterType = 'all';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _filterType = ['all', 'income', 'expense'][_tabController.index]);
    _loadTransactions();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadWallet(), _loadCategories(), _loadTransactions()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadWallet() async {
    final wallets = await _walletService.getWallets(includeArchived: true);
    _wallet = wallets.firstWhere((w) => w.id == widget.walletId);
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getCategories();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _transactionService.getTransactionsByWallet(
      widget.walletId,
      type: _filterType == 'all' ? null : _filterType,
    );
    if (mounted) setState(() => _transactions = transactions);
  }

  // NUEVA NAVEGACIÓN
  void _goToCreateTransaction() async {
    if (_wallet == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTransactionScreen(
          walletId: _wallet!.id!,
          currency: _wallet!.currency,
        ),
      ),
    );

    if (result == true && mounted) {
      await Future.wait([_loadTransactions(), _loadCategories()]);
      // Opcional: actualizar saldo
      await _loadWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        onPressed: _goToCreateTransaction, // NAVEGA A LA NUEVA PANTALLA
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva transacción', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
              ? const Center(child: Text('Cartera no encontrada'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      WalletCard(wallet: _wallet!),
                      TransactionTabs(controller: _tabController),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TransactionList(
                          transactions: _transactions,
                          categories: _categories,
                          currency: _wallet!.currency,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}