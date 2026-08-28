import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/compression_outcome.dart';

class CompressionStatsCard extends StatelessWidget {
  const CompressionStatsCard({required this.outcome, super.key});

  final CompressionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SPACE SAVED', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      Formatters.percent(outcome.savedFraction),
                      style: AppTextStyles.numeric.copyWith(
                        fontSize: 38,
                        color: outcome.savedBytes > 0 ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('${Formatters.fileSize(outcome.savedBytes)} smaller', style: AppTextStyles.label),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          _StatRow(
            label: 'Original',
            value: Formatters.fileSize(outcome.originalSizeBytes),
            detail: outcome.originalResolution,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatRow(
            label: 'Compressed',
            value: Formatters.fileSize(outcome.compressedSizeBytes),
            detail: outcome.compressedResolution,
            emphasised: true,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatRow(label: 'Duration', value: Formatters.duration(outcome.duration), detail: ''),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, required this.detail, this.emphasised = false});

  final String label;
  final String value;
  final String detail;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        if (detail.isNotEmpty) ...[Text(detail, style: AppTextStyles.caption), const SizedBox(width: AppSpacing.md)],
        Text(
          value,
          style: emphasised
              ? AppTextStyles.mono.copyWith(fontSize: 15)
              : AppTextStyles.mono.copyWith(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
