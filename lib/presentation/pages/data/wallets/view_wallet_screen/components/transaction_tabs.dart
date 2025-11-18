import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class TransactionTabs extends StatelessWidget {
  final TabController controller;

  const TransactionTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Todas'),
          Tab(text: 'Ingresos'),
          Tab(text: 'Gastos'),
        ],
      ),
    );
  }
}