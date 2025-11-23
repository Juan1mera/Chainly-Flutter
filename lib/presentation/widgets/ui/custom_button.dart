import 'dart:ui';
import 'package:chainly/core/constants/fonts.dart';
import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color backgroundColor;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.leftIcon,
    this.rightIcon,
    this.backgroundColor = AppColors.white,
    this.isLoading = false,
  });

  Widget _buildIconWithBackground(Widget icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconTheme(
        data: const IconThemeData(color: AppColors.black, size: 20),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasIcons = leftIcon != null || rightIcon != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isLoading ? null : onPressed,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: EdgeInsets.symmetric(
                horizontal: hasIcons ? 6 : 20,
                vertical: hasIcons ? 6 : 12,
              ),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leftIcon != null) ...[
                    _buildIconWithBackground(leftIcon!),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      fontFamily: AppFonts.clashDisplay
                    ),
                  ),
                  if (rightIcon != null) ...[
                    const SizedBox(width: 12),
                    _buildIconWithBackground(rightIcon!),
                  ],
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}