import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';

class AddEditStoreScreen extends ConsumerStatefulWidget {
  final Store? store;

  const AddEditStoreScreen({super.key, this.store});

  @override
  ConsumerState<AddEditStoreScreen> createState() => _AddEditStoreScreenState();
}

class _AddEditStoreScreenState extends ConsumerState<AddEditStoreScreen> {
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      _nameController.text = widget.store!.name;
      _websiteController.text = widget.store!.website ?? '';
    }
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

      if (widget.store == null) {
        await notifier.createStore(
          name: _nameController.text.trim(),
          website: website,
        );
      } else {
        await notifier.updateStore(
          widget.store!.copyWith(
            name: _nameController.text.trim(),
            website: website,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.green, AppColors.yellow],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   CustomHeader(
                    title: isEditing ? 'Editar Tienda' : 'Nueva Tienda',
                  ),
                  const SizedBox(height: 32),

                  CustomTextField(
                    controller: _nameController,
                    label: 'Nombre',
                    hintText: 'Ej: Amazon, Netflix, Uber...',
                  ),

                  const SizedBox(height: 24),

                  CustomTextField(
                    controller: _websiteController,
                    label: 'Sitio Web (para el ícono)',
                    hintText: 'Ej: amazon.com',
                    keyboardType: TextInputType.url,
                  ),
                  
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa el dominio o sitio web para obtener el logo automáticamente.',
                    style: TextStyle(fontSize: 12, color: AppColors.greyDark),
                  ),

                  const SizedBox(height: 48),

                  CustomButton(
                    text: isEditing ? 'Guardar Cambios' : 'Crear Tienda',
                    onPressed: _isLoading ? null : _saveStore,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}
