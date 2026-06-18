import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class AppDialog {
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Center(
                        child: Text(cancelLabel, style: AppTextStyle.labelLg.copyWith(color: AppColors.onSurfaceVariant)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: confirmColor ?? AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                      ),
                      child: Center(
                        child: Text(confirmLabel, style: AppTextStyle.labelLg.copyWith(color: AppColors.onPrimary)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        ),
        contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                ),
                child: Center(
                  child: Text('OK', style: AppTextStyle.labelLg.copyWith(color: AppColors.onPrimary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<DateTime?> pickDate(BuildContext context, DateTime? initialDate) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
  }

  static Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay? initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
  }
}
