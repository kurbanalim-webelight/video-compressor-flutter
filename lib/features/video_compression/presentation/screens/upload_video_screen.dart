import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_message_view.dart';
import '../bloc/video_compression_bloc.dart';

class UploadVideoScreen extends StatelessWidget {
  const UploadVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: SafeArea(
        child: BlocBuilder<VideoCompressionBloc, VideoCompressionState>(
          builder: (context, state) {
            final outcome = state.outcome;
            if (outcome == null) {
              return const AppMessageView(
                icon: Icons.cloud_off_outlined,
                title: 'No file to upload',
                message: 'Compress a video first, then continue to upload.',
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppMessageView(
                          icon: Icons.cloud_upload_outlined,
                          title: 'Ready to upload',
                          message:
                              'This is where the upload flow takes over. The '
                              'compressed file below is ready to be sent.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _FileSummary(path: outcome.outputPath, sizeBytes: outcome.compressedSizeBytes),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                  child: AppButton(
                    label: 'Back to result',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FileSummary extends StatelessWidget {
  const _FileSummary({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  path.split(Platform.pathSeparator).last,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(Formatters.fileSize(sizeBytes), style: AppTextStyles.mono),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(path, style: AppTextStyles.caption, maxLines: 2),
        ],
      ),
    );
  }
}
