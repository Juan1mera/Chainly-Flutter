import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/category_model.dart';
import 'package:chainly/presentation/pages/main/categories_screen/components/category_card.dart';
import 'package:chainly/presentation/pages/main/categories_screen/components/category_edit_dialog.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/domain/providers/category_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  
  @override
  void initState() {
    super.initState();
    // Initial fetch happens via provider
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
    final iconCode = result['iconCode'];

    final notifier = ref.read(categoryNotifierProvider.notifier);

    try {
      if (isEdit) {
        await notifier.updateCategory(
          id: category.id,
          name: name,
          icon: iconCode,
          type: category.type
        );
      } else {
        await notifier.createCategory(
          name: name,
          icon: iconCode,
          type: 'expense' // Default type for now, or add selector in dialog
        );
      }

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

    if (confirm == true) {
      try {
        await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          await ref.read(categoriesProvider.future);
        },
        color: AppColors.purple,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Espacio superior + botón
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 140, 24, 20), 
                child: CustomButton(
                  text: "Nueva categoría",
                  onPressed: () => _showCategoryDialog(),
                  leftIcon: const Icon(Icons.add),
                ),
              ),
            ),

            // Contenido de la lista
            categoriesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
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

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
