import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/utils/favicon_getter.dart';
import 'package:chainly/data/models/store_model.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StoreCard({
    super.key,
    required this.store,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: (store.website != null && store.website!.isNotEmpty)
                      ? Image.network(
                          FaviconGetter.getFaviconUrl(store.website!),
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Bootstrap.shop, size: 28, color: AppColors.black),
                        )
                      : const Icon(Bootstrap.shop, size: 28, color: AppColors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.clashDisplay,
                          color: AppColors.black,
                        ),
                      ),
                      if (store.website != null && store.website!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          store.website!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.black.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.purple),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
