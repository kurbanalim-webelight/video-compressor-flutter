import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_message_view.dart';
import '../../../../core/widgets/labelled_value.dart';
import '../bloc/video_compression_bloc.dart';
import '../widgets/notice_banner.dart';

class CompressionProgressScreen extends StatelessWidget {
  const CompressionProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoCompressionBloc, VideoCompressionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case VideoCompressionStatus.completed:
            Navigator.of(context).pushReplacementNamed(AppRoutes.result);
          case VideoCompressionStatus.ready:
            Navigator.of(context).pop();
          case _:
            break;
        }
      },
      builder: (context, state) {
        final isCompressing = state.status == VideoCompressionStatus.compressing;

        return PopScope(
          canPop: !isCompressing,
          child: Scaffold(
            appBar: AppBar(title: const Text('Compressing'), automaticallyImplyLeading: !isCompressing),
            body: SafeArea(
              child: state.status == VideoCompressionStatus.failed
                  ? _FailureView(state: state)
                  : _ProgressView(state: state),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.state});

  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;
    final isStarting = state.progress <= 0;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProgressDial(progress: state.progress),
                const SizedBox(height: AppSpacing.xl),
                Text(isStarting ? 'Preparing your video' : 'Compressing on-device', style: AppTextStyles.heading),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isStarting
                      ? 'Reading the source and setting up the encoder.'
                      : 'Keep the app open until this finishes.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ),
        if (state.stalledInBackground)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: const NoticeBanner(
              icon: Icons.pause_circle_outline,
              message: 'This device cannot compress while the app is in the background, '
                  'so the job stalled when you left. Cancel and try again with the app open.',
              tone: NoticeTone.danger,
            ),
          ),
        if (plan != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LabelledValue(label: 'Target', value: plan.resolutionLabel),
                ),
                Expanded(
                  child: LabelledValue(label: 'Bitrate', value: Formatters.bitrate(plan.videoBitrate)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.outlined,
            isDestructive: true,
            onPressed: () => context.read<VideoCompressionBloc>().add(const CompressionCancelRequested()),
          ),
        ),
      ],
    );
  }
}

class _ProgressDial extends StatelessWidget {
  const _ProgressDial({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      width: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              builder: (context, value, child) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.surfaceSunken,
                valueColor: const AlwaysStoppedAnimation(AppColors.ink),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Formatters.percent(progress), style: AppTextStyles.display.copyWith(fontSize: 40)),
              Text('complete', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.state});

  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VideoCompressionBloc>();

    return Column(
      children: [
        Expanded(
          child: AppMessageView(
            icon: Icons.error_outline,
            title: 'Compression failed',
            message: state.failure?.userMessage ?? 'Something went wrong while compressing.',
            tone: AppMessageTone.danger,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: () => bloc.add(const CompressionRequested()),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Back',
                variant: AppButtonVariant.plain,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
