import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { filled, outlined, plain }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final foreground = _foregroundColor(isEnabled);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: _backgroundColor(isEnabled),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: variant == AppButtonVariant.outlined ? const BorderSide(color: AppColors.border) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(foreground)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: foreground),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(label, style: AppTextStyles.button.copyWith(color: foreground)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool isEnabled) {
    return switch (variant) {
      AppButtonVariant.filled =>
        isEnabled ? (isDestructive ? AppColors.danger : AppColors.ink) : AppColors.surfaceSunken,
      AppButtonVariant.outlined => AppColors.background,
      AppButtonVariant.plain => Colors.transparent,
    };
  }

  Color _foregroundColor(bool isEnabled) {
    if (!isEnabled && variant == AppButtonVariant.filled) {
      return AppColors.textTertiary;
    }
    if (!isEnabled) return AppColors.textTertiary;
    return switch (variant) {
      AppButtonVariant.filled => AppColors.onInk,
      AppButtonVariant.outlined => isDestructive ? AppColors.danger : AppColors.textPrimary,
      AppButtonVariant.plain => isDestructive ? AppColors.danger : AppColors.textSecondary,
    };
  }
}
