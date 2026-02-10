import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/pages/main/stores_screen/add_edit_store_sheet.dart';
import 'package:chainly/presentation/pages/main/stores_screen/components/store_card.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:icons_plus/icons_plus.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({super.key});

  @override
  ConsumerState<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends ConsumerState<StoresScreen> {
  @override
  void initState() {
    super.initState();
    // Initial fetch handled by provider if needed, or automatic
  }

  void _showStoreSheet({Store? store}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditStoreSheet(store: store),
    );
  }

  Future<void> _deleteStore(Store store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text('¿Eliminar permanentemente "${store.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(storeNotifierProvider.notifier).deleteStore(store.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tienda eliminada'),
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
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storesProvider);
          await ref.read(storesProvider.future);
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
                  text: "Nueva tienda",
                  onPressed: () => _showStoreSheet(),
                  leftIcon: const Icon(Icons.add),
                ),
              ),
            ),

            // Contenido de la lista
            storesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
              data: (stores) {
                if (stores.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(Bootstrap.shop, size: 90, color: Colors.grey),
                          SizedBox(height: 24),
                          Text(
                            'No hay tiendas aún',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '¡Agrega tu primera tienda!',
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
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return StoreCard(
                        store: store,
                        onEdit: () => _showStoreSheet(store: store),
                        onDelete: () => _deleteStore(store),
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
