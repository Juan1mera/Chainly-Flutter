import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';
import 'package:wallet_app/core/utils/number_format.dart';
import 'package:wallet_app/models/wallet_model.dart';

class WalletMiniCard extends StatelessWidget {
  final Wallet wallet;

  const WalletMiniCard({
    super.key,
    required this.wallet,
  });


  @override
  Widget build(BuildContext context) {
    final walletColor = Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));

    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: walletColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre 
            Text(
              wallet.name,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 23,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.clashDisplay,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            // Moneda + Monto grande
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatAmount(wallet.balance),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  wallet.currency,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}