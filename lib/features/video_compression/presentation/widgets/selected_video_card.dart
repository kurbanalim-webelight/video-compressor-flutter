import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/labelled_value.dart';
import '../../domain/entities/video_metadata.dart';
import 'video_thumbnail_view.dart';

class SelectedVideoCard extends StatelessWidget {
  const SelectedVideoCard({required this.metadata, required this.thumbnailPath, super.key});

  final VideoMetadata metadata;
  final String? thumbnailPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoThumbnailView(path: thumbnailPath),
                Positioned(
                  left: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _DurationBadge(duration: metadata.duration),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metadata.name, style: AppTextStyles.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: LabelledValue(label: 'Size', value: Formatters.fileSize(metadata.fileSizeBytes)),
                    ),
                    Expanded(
                      child: LabelledValue(label: 'Resolution', value: '${metadata.width}x${metadata.height}'),
                    ),
                    Expanded(
                      child: LabelledValue(label: 'Bitrate', value: Formatters.bitrate(metadata.averageBitrate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.scrim.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(Formatters.duration(duration), style: AppTextStyles.mono.copyWith(color: AppColors.onInk)),
    );
  }
}
