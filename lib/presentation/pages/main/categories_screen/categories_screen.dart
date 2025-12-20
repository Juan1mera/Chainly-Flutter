
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/models/category_model.dart';
import 'package:chainly/presentation/pages/main/categories_screen/components/category_card.dart';
import 'package:chainly/presentation/pages/main/categories_screen/components/category_edit_dialog.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<Category>> _categoriesFuture;

  User? get _user => Supabase.instance.client.auth.currentUser;


  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = _categoryService.getCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final isEdit = category != null;
    final controller = TextEditingController(text: category?.name ?? '');
    String? selectedIconCode = category?.icon;

    final result = await showDialog<Map<String, String?>?>(
      context: context,
      builder: (ctx) => CategoryEditDialog(
        controller: controller,
        initialIconCode: selectedIconCode,
      ),
    );

    if (result == null || result['name']?.trim().isEmpty != false) return;

    final name = result['name']!.trim();
    final iconCode = result['iconCode']; // ← ¡Aquí estaba el error! Usamos iconCode

    try {
      if (isEdit) {
        await _categoryService.updateCategory(Category(
          id: category.id,
          name: name,
          icon: iconCode, 
          monthlyBudget: category.monthlyBudget,
          userId: '${_user?.id}'
        ));
      } else {
        await _categoryService.createCategory(Category(
          name: name,
          icon: iconCode, 
          monthlyBudget: 0.0,
          userId: '${_user?.id}'
        ));
      }

      _loadCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Categoría actualizada' : 'Categoría creada'),
            backgroundColor: AppColors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar permanentemente "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && category.id != null) {
      try {
        await _categoryService.deleteCategory(category.id!);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: RefreshIndicator(
      onRefresh: () async {
        _loadCategories();
        await _categoriesFuture;
      },
      color: AppColors.purple,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Espacio superior + botón
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 20), 
              child: CustomButton(
                text: "Nueva categoría",
                onPressed: () => _showCategoryDialog(),
                leftIcon: const Icon(Icons.add),
              ),
            ),
          ),

          // Contenido de la lista (o mensaje vacío)
          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                return SliverFillRemaining(
                  child: const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: const [
                        Icon(Icons.category_outlined, size: 90, color: Colors.grey),
                        SizedBox(height: 24),
                        Text(
                          'No hay categorías aún',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '¡Crea tu primera categoría!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Lista de categorías
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CategoryCard(
                        category: cat,
                        onEdit: () => _showCategoryDialog(category: cat),
                        onDelete: () => _deleteCategory(cat),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Espacio inferior para que el último elemento no quede pegado al botón al hacer scroll
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    ),
  );
}
}

