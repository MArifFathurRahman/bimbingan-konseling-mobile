import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory StatusBadge.aktif() {
    return const StatusBadge(
      label: 'Aktif',
      backgroundColor: Color(0xFFbbf7d0),
      textColor: Color(0xFF166534),
    );
  }

  factory StatusBadge.peringatan() {
    return const StatusBadge(
      label: 'Peringatan',
      backgroundColor: AppColors.errorContainer,
      textColor: AppColors.onErrorContainer,
    );
  }

  factory StatusBadge.safe() {
    return const StatusBadge(
      label: 'Aman (Safe)',
      icon: Icons.check_circle,
      backgroundColor: Color(0xFF22c55e),
      textColor: AppColors.onPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceContainer;
    final fg = textColor ?? AppColors.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: bg == AppColors.green
            ? Border.all(color: AppColors.green.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyle.labelLg.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ClassBadge extends StatelessWidget {
  final String label;

  const ClassBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMd.copyWith(
          color: AppColors.onSecondaryContainer,
        ),
      ),
    );
  }
}

class WarningAlert extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onButtonTap;

  const WarningAlert({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.priority_high,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyle.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onButtonTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.onError,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    buttonLabel,
                    style: AppTextStyle.labelLg.copyWith(
                      color: AppColors.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
