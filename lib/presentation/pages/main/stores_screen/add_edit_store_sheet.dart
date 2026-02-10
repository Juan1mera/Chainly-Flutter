import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';

class AddEditStoreSheet extends ConsumerStatefulWidget {
  final Store? store;

  const AddEditStoreSheet({super.key, this.store});

  @override
  ConsumerState<AddEditStoreSheet> createState() => _AddEditStoreSheetState();
}

class _AddEditStoreSheetState extends ConsumerState<AddEditStoreSheet> {
  late TextEditingController _nameController;
  late TextEditingController _websiteController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store?.name ?? '');
    _websiteController = TextEditingController(text: widget.store?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveStore() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es requerido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(storeNotifierProvider.notifier);
      final website = _websiteController.text.trim().isEmpty 
          ? null 
          : _websiteController.text.trim();

      Store? resultStore;
      if (widget.store == null) {
        resultStore = await notifier.createStore(
          name: _nameController.text.trim(),
          website: website,
        );
      } else {
        final updated = widget.store!.copyWith(
          name: _nameController.text.trim(),
          website: website,
          updatedAt: DateTime.now(),
        );
        await notifier.updateStore(updated);
        resultStore = updated;
      }

      if (mounted) {
        Navigator.pop(context, resultStore);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.store != null;

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
              isEditing ? 'Editar Tienda' : 'Nueva Tienda',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.clashDisplay,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            CustomTextField(
              controller: _nameController,
              label: 'Nombre',
              hintText: 'Ej: Amazon, Netflix, Uber...',
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _websiteController,
              label: 'Sitio web (Opcional)',
              hintText: 'ejemplo.com',
              description: 'Usaremos la web para obtener el logo automáticamente',
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: isEditing ? 'Guardar Cambios' : 'Crear Tienda',
              onPressed: _saveStore,
              isLoading: _isLoading,
              backgroundColor: AppColors.purple,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
