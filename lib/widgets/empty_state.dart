import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyle.bodyMd.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyle.labelLg.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyClassState extends StatelessWidget {
  final String className;
  final String studentCount;
  final VoidCallback? onViewAll;

  const EmptyClassState({
    super.key,
    required this.className,
    required this.studentCount,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(color: AppColors.outlineVariant, width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.group, size: 48, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('Data Siswa $className', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Ketuk untuk memuat daftar lengkap siswa untuk kelas ini.',
            style: AppTextStyle.bodyMd.copyWith(color: AppColors.outline), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text('Lihat Semua', style: AppTextStyle.labelLg.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
