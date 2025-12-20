import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/models/category_model.dart';
import 'package:chainly/models/wallet_model.dart';
import 'package:chainly/presentation/widgets/common/wallet_mini_card.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';
import 'package:chainly/presentation/widgets/ui/custom_number_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/providers/wallet_provider.dart';
import 'package:chainly/services/category_service.dart';
import 'package:chainly/services/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final int? initialWalletId;
  final String? initialType;

  const CreateTransactionScreen({
    super.key,
    this.initialWalletId,
    this.initialType,
  });

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _noteController = TextEditingController();
  User? get _user => Supabase.instance.client.auth.currentUser;

  List<Category> _categories = [];
  String _type = 'expense';
  double _amount = 0.0;
  String? _selectedCategoryName;
  Wallet? _selectedWallet;

  bool _isLoadingCategories = true;
  bool _hasSetInitialWallet = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == 'income' || widget.initialType == 'expense') {
      _type = widget.initialType!;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      setState(() {
        _categories = cats;
        _selectedCategoryName = cats.isNotEmpty ? cats.first.name : null;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _setInitialWalletIfNeeded(List<Wallet> wallets) {
    if (_hasSetInitialWallet || wallets.isEmpty) return;

    final availableWallets = wallets.where((w) => !w.isArchived).toList();
    if (availableWallets.isEmpty) return;

    if (widget.initialWalletId != null) {
      _selectedWallet = availableWallets.firstWhere(
        (w) => w.id == widget.initialWalletId,
        orElse: () => availableWallets.first,
      );
    } else {
      _selectedWallet = availableWallets.first;
    }

    _hasSetInitialWallet = true;
    if (mounted) setState(() {});
  }

  Future<void> _createTransaction() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un monto válido')));
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una billetera')));
      return;
    }

    if (_selectedCategoryName == null ||
        _selectedCategoryName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona o crea una categoría')),
      );
      return;
    }

    try {
      await _transactionService.createTransactionWithCategoryName(
        walletId: _selectedWallet!.id!,
        type: _type,
        amount: _amount,
        categoryName: _selectedCategoryName!.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transacción creada')));
        ref.read(walletsProvider.notifier).refreshAfterTransaction();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error cargando billeteras: $err'),
            ],
          ),
        ),
        data: (wallets) {
          final availableWallets = wallets.where((w) => !w.isArchived).toList();
          _setInitialWalletIfNeeded(wallets);

          if (availableWallets.isEmpty) {
            return const Center(
              child: Text('No tienes billeteras activas.\nCrea una primero.'),
            );
          }

          return _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.green, AppColors.yellow],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Column(
                      children: [
                        const CustomHeader(),

                        if (_selectedWallet != null) ...[
                          WalletMiniCard(wallet: _selectedWallet!),
                          const SizedBox(height: 20),
                        ],

                        CustomSelect<Wallet>(
                          items: availableWallets,
                          selectedItem: _selectedWallet,
                          getDisplayText: (wallet) =>
                              '${wallet.name} • ${wallet.currency}',
                          onChanged: (wallet) =>
                              setState(() => _selectedWallet = wallet),
                          label: '',
                        ),

                        const SizedBox(height: 24),

                        CustomNumberField(
                          currency: _selectedWallet?.currency ?? 'USD',
                          hintText: '0.00',
                          onChanged: (val) => setState(() => _amount = val),
                        ),

                        const SizedBox(height: 24),
                        _buildCategorySelector(),
                        const SizedBox(height: 24),
                        _buildTypeSelector(),
                        const SizedBox(height: 24),

                        CustomTextField(
                          controller: _noteController,
                          label: 'Nota (opcional)',
                          hintText: 'Ej: Supermercado, salario, Netflix...',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 32),

                        CustomButton(
                          text: 'Guardar transacción',
                          onPressed: _createTransaction,
                        ),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return CustomSelect<String>(
      label: '',
      items: ['＋ Nueva categoría...', ..._categories.map((c) => c.name)],
      selectedItem: _selectedCategoryName,
      getDisplayText: (name) => name,
      onChanged: (val) async {
        if (val == '＋ Nueva categoría...') {
          final controller = TextEditingController();
          final result = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Nueva categoría'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Nombre de la categoría',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Crear'),
                ),
              ],
            ),
          );
          if (result != null && result.isNotEmpty) {
            setState(() {
              _selectedCategoryName = result;
              _categories.add(Category(name: result, userId: '${_user?.id}'));
            });
          }
        } else {
          setState(() => _selectedCategoryName = val);
        }
      },
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Income',
            rightIcon: const Icon(Bootstrap.arrow_down_left, size: 20),
            onPressed: () => setState(() => _type = 'income'),
            backgroundColor: _type == 'income'
                ? AppColors.purple.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Expense',
            rightIcon: const Icon(Bootstrap.arrow_up_right, size: 20),
            onPressed: () => setState(() => _type = 'expense'),
            backgroundColor: _type == 'expense'
                ? AppColors.purple.withValues(alpha: 0.5)
                : AppColors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
