import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_message_view.dart';
import '../../domain/entities/video_source.dart';
import '../bloc/video_compression_bloc.dart';
import '../widgets/selected_video_card.dart';

class SelectVideoScreen extends StatelessWidget {
  const SelectVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compress video')),
      body: SafeArea(
        child: BlocConsumer<VideoCompressionBloc, VideoCompressionState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == VideoCompressionStatus.compressing) {
              Navigator.of(context).pushNamed(AppRoutes.progress);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(child: _Body(state: state)),
                _Actions(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink));
    }

    if (state.status == VideoCompressionStatus.failed) {
      return AppMessageView(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: state.failure?.userMessage ?? 'Please try again.',
        tone: AppMessageTone.danger,
        actionLabel: 'Start over',
        onAction: () => context.read<VideoCompressionBloc>().add(const FlowResetRequested()),
      );
    }

    final metadata = state.metadata;
    if (metadata == null) {
      return const AppMessageView(
        icon: Icons.video_library_outlined,
        title: 'No video selected',
        message: 'Pick a clip from your gallery or record a new one. Videos are compressed on-device.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectedVideoCard(metadata: metadata, thumbnailPath: state.thumbnailPath),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state});

  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VideoCompressionBloc>();
    final hasVideo = state.metadata != null;
    final isDisabled = state.isBusy;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasVideo) ...[
            if (state.plan != null && !state.plan!.shouldSkipCompression) ...[
              Text(
                'Target ${state.plan!.resolutionLabel} at '
                '${Formatters.bitrate(state.plan!.videoBitrate)}, '
                '${state.plan!.frameRate} fps',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              label: 'Compress video',
              icon: Icons.bolt_outlined,
              onPressed: isDisabled ? null : () => bloc.add(const CompressionRequested()),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Choose a different video',
              variant: AppButtonVariant.plain,
              onPressed: isDisabled ? null : () => bloc.add(const VideoPickRequested(VideoSource.gallery)),
            ),
          ] else ...[
            AppButton(
              label: 'Choose from gallery',
              icon: Icons.photo_library_outlined,
              onPressed: isDisabled ? null : () => bloc.add(const VideoPickRequested(VideoSource.gallery)),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Record a video',
              icon: Icons.videocam_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: isDisabled ? null : () => bloc.add(const VideoPickRequested(VideoSource.camera)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Compressed with your device hardware encoder.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}
