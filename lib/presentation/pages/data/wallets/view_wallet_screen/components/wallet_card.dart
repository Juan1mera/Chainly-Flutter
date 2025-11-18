import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';
import 'package:wallet_app/core/utils/number_format.dart';
import 'package:wallet_app/models/wallet_model.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final String? ownerName;

  const WalletCard({
    super.key,
    required this.wallet,
    this.ownerName,
  });


  @override
  Widget build(BuildContext context) {
    final walletColor = Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));
    final displayOwnerName = ownerName ?? 'You'; // fallback si no tienes el nombre

    return Container(
      height: 190,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: walletColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nombre + Icono tipo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wallet.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.clashDisplay,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  wallet.type == 'bank' ? Icons.account_balance : Icons.wallet,
                  color: AppColors.white,
                  size: 28,
                ),
              ],
            ),

            // Moneda + Monto grande
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  wallet.currency,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatAmount(wallet.balance),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
              ],
            ),

            // Owner + Created At
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Owner
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.clashDisplay,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayOwnerName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.clashDisplay,
                      ),
                    ),
                  ],
                ),

                // Created At
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Created',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.clashDisplay,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${wallet.createdAt.month.toString().padLeft(2, '0')}/${wallet.createdAt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.clashDisplay,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}