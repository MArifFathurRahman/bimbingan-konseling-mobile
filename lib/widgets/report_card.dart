import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';
import '../core/themes/app_theme.dart';

class ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final String? value;
  final IconData icon;
  final Color? iconColor;
  final Color? cardColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.title,
    required this.description,
    this.value,
    required this.icon,
    this.iconColor,
    this.cardColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: cardColor ?? AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          boxShadow: cardColor != null ? null : AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: AppTextStyle.titleLg.copyWith(
                  color: cardColor == AppColors.errorContainer
                      ? AppColors.onErrorContainer
                      : AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                description,
                style: AppTextStyle.labelMd.copyWith(
                  color: cardColor == AppColors.errorContainer
                      ? AppColors.onErrorContainer.withValues(alpha: 0.8)
                      : AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final bool showNotificationDot;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.bgColor,
    this.showNotificationDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          boxShadow: bgColor != null ? null : AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 24,
                  ),
                ),
                if (showNotificationDot)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: AppTextStyle.titleLg.copyWith(
                  color: bgColor == AppColors.errorContainer
                      ? AppColors.onErrorContainer
                      : AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                style: AppTextStyle.labelMd.copyWith(
                  color: bgColor == AppColors.errorContainer
                      ? AppColors.onErrorContainer.withValues(alpha: 0.8)
                      : AppColors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
