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

class SubscriptionEditSheet extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const SubscriptionEditSheet({super.key, this.subscription});

  @override
  ConsumerState<SubscriptionEditSheet> createState() => _SubscriptionEditSheetState();
}

class _SubscriptionEditSheetState extends ConsumerState<SubscriptionEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _faviconController;
  late double _amount;
  late DateTime _billingDate;
  Wallet? _selectedWallet;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.subscription != null;
    _titleController = TextEditingController(text: widget.subscription?.title ?? '');
    _descriptionController = TextEditingController(text: widget.subscription?.description ?? '');
    _faviconController = TextEditingController(text: widget.subscription?.favicon ?? '');
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
    _faviconController.dispose();
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
      'favicon': _faviconController.text.trim().isEmpty ? null : _faviconController.text.trim(),
      'amount': _amount,
      'billingDate': _billingDate,
      'walletId': _selectedWallet!.id,
      'currency': _selectedWallet!.currency,
      'categoryId': 'subscriptions_category', // Default category for subscriptions
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider(const WalletFilters(includeArchived: false)));

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
            CustomTextField(
              controller: _faviconController,
              label: 'URL del Icono (Favicon)',
              hintText: 'https://example.com/logo.png',
            ),
            const SizedBox(height: 16),
            walletsAsync.when(
              data: (wallets) {
                if (_selectedWallet == null && wallets.isNotEmpty) {
                  if (_isEditing) {
                    _selectedWallet = wallets.firstWhere(
                      (w) => w.id == widget.subscription!.walletId,
                      orElse: () => wallets.first,
                    );
                  } else {
                    _selectedWallet = wallets.first;
                  }
                }
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
