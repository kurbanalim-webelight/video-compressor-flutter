import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

enum NoticeTone { info, success, danger }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({required this.icon, required this.message, this.tone = NoticeTone.info, super.key});

  final IconData icon;
  final String message;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      NoticeTone.info => (AppColors.accentSurface, AppColors.accent),
      NoticeTone.success => (AppColors.successSurface, AppColors.success),
      NoticeTone.danger => (AppColors.dangerSurface, AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: AppTextStyles.label.copyWith(color: foreground)),
          ),
        ],
      ),
    );
  }
}
