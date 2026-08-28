import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class AppMessageView extends StatelessWidget {
  const AppMessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone = AppMessageTone.neutral,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      AppMessageTone.neutral => AppColors.textSecondary,
      AppMessageTone.danger => AppColors.danger,
    };
    final surface = switch (tone) {
      AppMessageTone.neutral => AppColors.surface,
      AppMessageTone.danger => AppColors.dangerSurface,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              child: Icon(icon, size: 26, color: accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.heading, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 220,
                child: AppButton(label: actionLabel!, onPressed: onAction, variant: AppButtonVariant.outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum AppMessageTone { neutral, danger }
