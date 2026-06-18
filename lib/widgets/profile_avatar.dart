import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/safe_display.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final bool showOnlineDot;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = AppSizes.avatarMd,
    this.borderWidth = 2,
    this.borderColor,
    this.showOnlineDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? AppColors.outlineVariant,
                width: borderWidth,
              ),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: imageUrl == null
                  ? AppColors.primaryFixed
                  : null,
            ),
            child: imageUrl == null
                ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : null,
          ),
          if (showOnlineDot)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
