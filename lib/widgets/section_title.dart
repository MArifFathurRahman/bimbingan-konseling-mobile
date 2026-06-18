import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final int? badgeCount;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyle.titleLg.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount! > 9 ? '+9' : '$badgeCount',
                  style: AppTextStyle.labelMd.copyWith(
                    color: AppColors.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: AppTextStyle.labelLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (actionIcon != null)
                  Icon(
                    actionIcon,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyle.headlineLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyle.labelLg.copyWith(
          color: AppColors.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
