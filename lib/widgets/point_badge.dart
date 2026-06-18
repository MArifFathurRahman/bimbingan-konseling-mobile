import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class PointBadge extends StatelessWidget {
  final int points;
  final double fontSize;

  const PointBadge({
    super.key,
    required this.points,
    this.fontSize = 14,
  });

  Color get _bgColor {
    if (points >= 25) return AppColors.error.withValues(alpha: 0.1);
    if (points >= 11) return AppColors.yellow.withValues(alpha: 0.1);
    return AppColors.green.withValues(alpha: 0.1);
  }

  Color get _textColor {
    if (points >= 25) return AppColors.error;
    if (points >= 11) return AppColors.yellow;
    return AppColors.green;
  }

  Color get _borderColor {
    if (points >= 25) return AppColors.error.withValues(alpha: 0.2);
    if (points >= 11) return AppColors.yellow.withValues(alpha: 0.2);
    return AppColors.green.withValues(alpha: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        '$points pts',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _textColor,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class ActivePointsBadge extends StatelessWidget {
  final int points;

  const ActivePointsBadge({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        'Poin Aktif: $points',
        style: AppTextStyle.labelLg.copyWith(
          color: AppColors.onSecondaryContainer,
        ),
      ),
    );
  }
}
