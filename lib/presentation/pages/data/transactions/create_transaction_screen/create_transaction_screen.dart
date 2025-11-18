import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/services/category_service.dart';
import 'package:wallet_app/services/transaction_service.dart';
import 'package:wallet_app/providers/wallet_provider.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  final int walletId;
  final String currency;

  const CreateTransactionScreen({
    super.key,
    required this.walletId,
    required this.currency,
  });

  @override
  ConsumerState<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends ConsumerState<CreateTransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _noteController = TextEditingController();

  List<Category> _categories = [];
  String _type = 'expense';
  double _amount = 0.0;
  String? _selectedCategoryName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryService.getCategories();
      setState(() {
        _categories = cats;
        _selectedCategoryName = cats.isNotEmpty ? cats.first.name : null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTransaction() async {
    if (_amount <= 0 || _selectedCategoryName == null || _selectedCategoryName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    try {
      await _transactionService.createTransactionWithCategoryName(
        walletId: widget.walletId,
        type: _type,
        amount: _amount,
        categoryName: _selectedCategoryName!.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción creada')),
        );
        ref.read(walletsProvider.notifier).refresh();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Transacción'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTransaction,
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CustomNumberField(
                    currency: widget.currency,
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
                    hintText: 'Ej: Pago en efectivo, supermercado...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.purple)),
        ),
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
                    decoration: const InputDecoration(hintText: 'Nombre'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
                  _categories.add(Category(name: result));
                });
              }
            } else {
              setState(() => _selectedCategoryName = val);
            }
          },
          color: AppColors.purple,
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.purple)),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: _type == 'income' ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Ingreso'),
                  ],
                ),
                value: 'income',
                groupValue: _type,
                onChanged: (val) => setState(() => _type = val!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20, color: _type == 'expense' ? Colors.red : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Gasto'),
                  ],
                ),
                value: 'expense',
                groupValue: _type,
                onChanged: (val) => setState(() => _type = val!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}