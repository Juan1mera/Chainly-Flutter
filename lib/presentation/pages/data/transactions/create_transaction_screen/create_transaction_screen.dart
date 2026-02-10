import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/presentation/widgets/common/wallet_mini_card.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';
import 'package:chainly/presentation/widgets/ui/custom_number_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/domain/providers/category_provider.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';

import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/pages/main/stores_screen/add_edit_store_sheet.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final String? initialWalletId;
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
  final TextEditingController _noteController = TextEditingController();

  String _type = 'expense';
  double _amount = 0.0;
  String? _selectedCategoryName;
  Wallet? _selectedWallet;
  Store? _selectedStore;

  bool _hasSetInitialWallet = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == 'income' || widget.initialType == 'expense') {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
    // No need to setState here if called during build or if build will happen anyway
  }

  bool _isLoading = false;

  Future<void> _createTransaction() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un monto válido')));
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una billetera')));
      return;
    }

    if (_selectedCategoryName == null ||
        _selectedCategoryName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona o crea una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find category ID from name
      final categories = ref.read(categoriesProvider).value ?? [];
      var category = categories.firstWhere(
          (c) => c.name == _selectedCategoryName,
          orElse: () => categories.first // Should handle case where it doesn't exist?
      );
      
      final notifier = ref.read(transactionNotifierProvider.notifier);
      
      await notifier.createTransaction(
        walletId: _selectedWallet!.id,
        type: _type,
        amount: _amount,
        categoryId: category.id,
        storeId: _selectedStore?.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción creada')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));
    final categoriesAsync = ref.watch(categoriesProvider);
    final storesAsync = ref.watch(storesProvider);

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
          
          // Schedule this to run after build if needed, or just run it (it sets state internal flag)
          // Since we are in build, we shouldn't call setState. But _setInitialWalletIfNeeded only sets local var if not set.
          if (!_hasSetInitialWallet && availableWallets.isNotEmpty) {
             _setInitialWalletIfNeeded(wallets);
             // Since we modified _selectedWallet during build phase (which is generally bad practice but here we are initializing),
             // let's ensure the UI reflects it.
          }

          if (availableWallets.isEmpty) {
            return const Center(
              child: Text('No tienes billeteras activas.\nCrea una primero.'),
            );
          }

          return categoriesAsync.when(
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (e, s) => Center(child: Text('Error al cargar categorías: $e')),
             data: (categories) {
                // Initialize selected category if needed
                if (_selectedCategoryName == null && categories.isNotEmpty) {
                  _selectedCategoryName = categories.first.name;
                }
               
                return storesAsync.when(
                   loading: () => const Center(child: CircularProgressIndicator()), // Or loading indicator for stores specifically?
                   error: (e, s) => Center(child: Text('Error al cargar tiendas: $e')),
                   data: (stores) {
                      return Container(
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
                              _buildCategorySelector(categories),
                              const SizedBox(height: 24),
                              _buildStoreSelector(stores),
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
                                onPressed: _isLoading ? null : _createTransaction,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      );
                   }
                );
             }
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(List<Category> categories) {
    return CustomSelect<String>(
      label: '',
      items: ['＋ Nueva categoría...', ...categories.map((c) => c.name)],
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
            // Crear categoría
            try {
              final newCat = await ref.read(categoryNotifierProvider.notifier).createCategory(
                name: result, 
                type: _type
              );
              
              if (newCat != null) {
                setState(() {
                  _selectedCategoryName = newCat.name;
                });
              }
            } catch(e) {
               if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
               }
            }
          }
        } else {
          setState(() => _selectedCategoryName = val);
        }
      },
    );
  }

  Widget _buildStoreSelector(List<Store> stores) {
    final newStoreAction = Store(
      id: 'new_store_action',
      userId: '',
      name: '＋ Nueva tienda...',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final items = [newStoreAction, ...stores];

    return CustomSelect<Store>(
      label: '',
      hintText: 'Seleccionar tienda (opcional)',
      items: items,
      selectedItem: _selectedStore,
      getDisplayText: (store) => store.name,
      onChanged: (val) async {
        if (val?.id == 'new_store_action') {
           // Navigate to add store
           final result = await showModalBottomSheet<Store>(
             context: context,
             isScrollControlled: true,
             backgroundColor: Colors.transparent,
             builder: (_) => const AddEditStoreSheet(),
           );
           
           if (result != null) {
             setState(() => _selectedStore = result);
           }
        } else {
          setState(() => _selectedStore = val);
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
