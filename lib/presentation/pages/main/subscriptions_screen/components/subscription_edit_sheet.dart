import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/data/models/subscription_model.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_number_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';
import 'package:chainly/presentation/widgets/ui/custom_date_picker.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/pages/main/stores_screen/add_edit_store_sheet.dart';

class SubscriptionEditSheet extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const SubscriptionEditSheet({super.key, this.subscription});

  @override
  ConsumerState<SubscriptionEditSheet> createState() => _SubscriptionEditSheetState();
}

class _SubscriptionEditSheetState extends ConsumerState<SubscriptionEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late double _amount;
  late DateTime _billingDate;
  Wallet? _selectedWallet;
  Store? _selectedStore;
  bool _isEditing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.subscription != null;
    _titleController = TextEditingController(text: widget.subscription?.title ?? '');
    _descriptionController = TextEditingController(text: widget.subscription?.description ?? '');
    _amount = widget.subscription?.amount ?? 0.0;
    
    final now = DateTime.now();
    _billingDate = widget.subscription?.billingDate ?? now;
    if (_billingDate.isBefore(DateTime(now.year, now.month, now.day))) {
      _billingDate = now;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_titleController.text.trim().isEmpty || _amount <= 0 || _selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos obligatorios')),
      );
      return;
    }

    final result = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'amount': _amount,
      'billingDate': _billingDate,
      'walletId': _selectedWallet!.id,
      'currency': _selectedWallet!.currency,
      'categoryId': 'subscriptions_category', // Default category for subscriptions
      'storeId': _selectedStore?.id,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));
    // We also need stores to be loaded to find the selectedStore object if editing
    final storesAsync = ref.watch(storesProvider);

    // Initialize selected items once data is available
    if (!_initialized) {
        if (walletsAsync.hasValue) {
             final wallets = walletsAsync.value!;
             if (_selectedWallet == null && wallets.isNotEmpty) {
                if (_isEditing) {
                   _selectedWallet = wallets.firstWhere(
                      (w) => w.id == widget.subscription!.walletId,
                      orElse: () => wallets.first
                   );
                } else {
                   _selectedWallet = wallets.first;
                }
             }
        }
        
        if (storesAsync.hasValue) {
            final stores = storesAsync.value!;
            if (_selectedStore == null && widget.subscription?.storeId != null && stores.isNotEmpty) {
                 _selectedStore = stores.firstWhere(
                    (s) => s.id == widget.subscription!.storeId,
                    orElse: () => stores.first // Just safe fallback for lookup, check id next
                 );
                 if (_selectedStore?.id != widget.subscription!.storeId) {
                    _selectedStore = null;
                 }
            }
        }
        
        // Mark initialized only if we have at least tried to load data. 
        // We can check if loading is done.
        if (!walletsAsync.isLoading && !storesAsync.isLoading) {
             _initialized = true; 
        }
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Editar Suscripción' : 'Nueva Suscripción',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.clashDisplay,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _titleController,
              label: 'Nombre de la suscripción',
              hintText: 'Ej: Netflix, Spotify, Internet',
            ),
            const SizedBox(height: 16),
            
            // Wallet Selector
            walletsAsync.when(
              data: (wallets) {
                 return CustomSelect<Wallet>(
                  label: 'Billetera de pago',
                  items: wallets,
                  selectedItem: _selectedWallet,
                  getDisplayText: (w) => '${w.name} (${w.currency})',
                  onChanged: (w) => setState(() => _selectedWallet = w),
                );
              },
               loading: () => const Center(child: CircularProgressIndicator()),
               error: (err, _) => Text('Error al cargar billeteras: $err'),
            ),
            
            const SizedBox(height: 16),
            
            // Store Selector
            storesAsync.when(
                data: (stores) {
                  final newStoreAction = Store(
                    id: 'new_store_action',
                    userId: '',
                    name: '＋ Nueva tienda...',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  final items = [newStoreAction, ...stores];

                  return CustomSelect<Store>(
                    label: 'Tienda (Opcional)',
                    hintText: 'Seleccionar tienda',
                    items: items,
                    selectedItem: _selectedStore,
                    getDisplayText: (s) => s.name,
                    onChanged: (val) async {
                      if (val?.id == 'new_store_action') {
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
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            

            const SizedBox(height: 16),
            CustomNumberField(
              currency: _selectedWallet?.currency ?? 'USD',
              hintText: '0.00',
              onChanged: (val) => setState(() => _amount = val),
            ),
            const SizedBox(height: 16),
            CustomDatePicker(
              label: 'Fecha de próximo cobro',
              firstDate: DateTime.now(),
              selectedDate: _billingDate,
              onDateSelected: (date) => setState(() => _billingDate = date),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción (Opcional)',
              hintText: 'Ej: Plan familiar',
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: _isEditing ? 'Guardar Cambios' : 'Crear Suscripción',
              onPressed: _onSave,
              backgroundColor: AppColors.purple,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
