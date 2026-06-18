import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';
import '../core/themes/app_theme.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? trend;
  final bool gradient;
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.trend,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: gradient ? null : AppColors.surfaceContainerLowest,
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
              )
            : null,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: gradient ? AppColors.onPrimary : (iconColor ?? AppColors.primary),
                size: 24,
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: gradient
                        ? AppColors.onPrimary.withValues(alpha: 0.2)
                        : AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    trend!,
                    style: AppTextStyle.labelLg.copyWith(
                      color: gradient ? AppColors.onPrimary : AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: gradient ? AppColors.onPrimary : AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                label,
                style: AppTextStyle.labelMd.copyWith(
                  color: gradient
                      ? AppColors.onPrimary.withValues(alpha: 0.8)
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatCardBento extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? trend;
  final Color? trendColor;

  const StatCardBento({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 20,
                ),
              ),
              if (trend != null)
                Text(
                  trend!,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trendColor ?? AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyle.headlineMd.copyWith(
              color: iconColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyle.labelLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
