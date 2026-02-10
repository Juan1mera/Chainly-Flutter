import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/utils/favicon_getter.dart';
import 'package:chainly/data/models/store_model.dart';
import 'package:chainly/domain/providers/store_provider.dart';
import 'package:chainly/presentation/pages/main/stores_screen/add_edit_store_sheet.dart';
import 'package:chainly/presentation/widgets/ui/custom_header.dart';

class StoreListScreen extends ConsumerWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);

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
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: CustomHeader(
                title: 'Mis Tiendas',
              ),
            ),
            
            Expanded(
              child: storesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (stores) {
                  if (stores.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Bootstrap.shop, size: 64, color: AppColors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes tiendas guardadas',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.greyDark.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _StoreItem(store: store);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddEditStoreSheet(),
          );
        },
        backgroundColor: AppColors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StoreItem extends ConsumerWidget {
  final Store store;

  const _StoreItem({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(store.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar tienda?'),
            content: const Text('Esta acción no se puede deshacer.'),
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
      },
      onDismissed: (_) {
        ref.read(storeNotifierProvider.notifier).deleteStore(store.id);
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddEditStoreSheet(store: store),
            );
          },
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: (store.website != null && store.website!.isNotEmpty)
                ? Image.network(
                    FaviconGetter.getFaviconUrl(store.website!),
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Bootstrap.shop, size: 20),
                  )
                : const Icon(Bootstrap.shop, size: 20),
          ),
          title: Text(
            store.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: store.website != null 
              ? Text(store.website!, style: const TextStyle(fontSize: 12)) 
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        ),
      ),
    );
  }
}
