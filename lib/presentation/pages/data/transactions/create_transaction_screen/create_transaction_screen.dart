import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/widgets/common/wallet_mini_card.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/providers/wallet_provider.dart';
import 'package:wallet_app/services/category_service.dart';
import 'package:wallet_app/services/transaction_service.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final int? initialWalletId;
  final String? initialType;

  const CreateTransactionScreen({super.key, this.initialWalletId, this.initialType, });

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _noteController = TextEditingController();

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

  // Método para establecer la billetera inicial solo una vez
  void _setInitialWalletIfNeeded(List<Wallet> wallets) {
    if (_hasSetInitialWallet || wallets.isEmpty) return;

    if (widget.initialWalletId != null) {
      final preselected = wallets.firstWhere(
        (w) => w.id == widget.initialWalletId,
        orElse: () => wallets.first,
      );
      _selectedWallet = preselected;
    } else {
      _selectedWallet = wallets.first;
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
          // Filtrar solo billeteras no archivadas
          final availableWallets = wallets.where((w) => !w.isArchived).toList();
          // Establecer billetera inicial solo la primera vez
          _setInitialWalletIfNeeded(availableWallets);

          if (availableWallets.isEmpty) {
            return const Center(
              child: Text('No tienes billeteras activas.\nCrea una primero.'),
            );
          }

          return _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.green, AppColors.yellow],
                      ),
                    ),
                    child: Column(
                      
                      children: [
                        CustomHeader(),
                    
                        // Tarjeta de la billetera seleccionada
                        if (_selectedWallet != null) ...[
                          WalletMiniCard(wallet: _selectedWallet!),
                          const SizedBox(height: 20),
                        ],
                    
                        // Selector de billetera
                        CustomSelect<Wallet>(
                          items: wallets,
                          selectedItem: _selectedWallet,
                          getDisplayText: (wallet) =>
                              '${wallet.name} • ${wallet.currency} ',
                          onChanged: (wallet) {
                            setState(() {
                              _selectedWallet = wallet;
                            });
                          },
                          label: '',
                        ),
                    
                        const SizedBox(height: 24),
                    
                        // Monto
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
                    
                        CustomButton(
                          text: 'Save',
                          onPressed:
                              _isLoadingCategories || walletsAsync.isLoading
                              ? null
                              : _createTransaction,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomSelect<String>(
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
                      onPressed: () =>
                          Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                setState(() {
                  _selectedCategoryName = result;
                  _categories.add(Category(name: result));
                });
              }
            } else {
              setState(() => _selectedCategoryName = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomButton(
          text: 'Income',
          rightIcon: Icon(Bootstrap.arrow_down_left),
          onPressed: () {
            setState(() => _type = 'income');
          },
          bgColor: _type == 'income'
              ? AppColors.purple.withValues(alpha: 0.5)
              : AppColors.white.withValues(alpha: 0.5),
        ),
        CustomButton(
          text: 'Expense',
          rightIcon: Icon(Bootstrap.arrow_up_right,),
          onPressed: () {
            setState(() => _type = 'expense');
          },
          bgColor: _type == 'expense'
              ? AppColors.purple.withValues(alpha: 0.5)
              : AppColors.white.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
