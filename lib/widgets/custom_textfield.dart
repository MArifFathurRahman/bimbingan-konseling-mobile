import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle.bodyMd.copyWith(
              color: AppColors.outlineVariant,
            ),
            prefixIcon: icon != null
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      icon,
                      color: AppColors.outline,
                      size: 20,
                    ),
                  )
                : null,
            suffixIcon: isPassword
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const SearchField({
    super.key,
    this.hint = 'Cari...',
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyle.bodyMd.copyWith(
            color: AppColors.outline,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(
              Icons.search,
              color: AppColors.outline,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class CustomTextArea extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const CustomTextArea({
    super.key,
    required this.hint,
    required this.controller,
    this.maxLines = 4,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyle.bodyMd.copyWith(
          color: AppColors.outline,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        counterStyle: AppTextStyle.labelMd.copyWith(color: AppColors.outline),
      ),
    );
  }
}
