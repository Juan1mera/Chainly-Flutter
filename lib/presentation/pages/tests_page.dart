import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';

class TestsPage extends StatelessWidget {
  const TestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bug_report_outlined,
              size: 80,
              color: AppColors.purple,
            ),
            const SizedBox(height: 24),
            Text(
              'Tests Page',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.clashDisplay,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This page is only visible in DEV environment.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
