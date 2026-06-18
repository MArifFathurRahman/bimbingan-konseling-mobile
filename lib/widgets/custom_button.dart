import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class GradientButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.title,
    this.onTap,
    this.icon,
    this.height = 56,
    this.borderRadius = AppSizes.radiusFull,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.onPrimary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: AppTextStyle.titleLg.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.title,
    this.onTap,
    this.icon,
    this.height = 48,
    this.borderRadius = AppSizes.radiusFull,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.onPrimary, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: AppTextStyle.labelLg.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutlineButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.title,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: AppTextStyle.labelLg.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
