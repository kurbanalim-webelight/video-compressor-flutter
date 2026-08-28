import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_message_view.dart';
import '../bloc/video_compression_bloc.dart';
import '../cubit/gallery_save_cubit.dart';
import '../widgets/compression_stats_card.dart';
import '../widgets/notice_banner.dart';
import '../widgets/video_preview_player.dart';

class CompressionResultScreen extends StatelessWidget {
  const CompressionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<GallerySaveCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Done'), automaticallyImplyLeading: false),
        body: SafeArea(
          child: BlocBuilder<VideoCompressionBloc, VideoCompressionState>(
            builder: (context, state) {
              final outcome = state.outcome;
              if (outcome == null) {
                return AppMessageView(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing to show',
                  message: 'This compression result is no longer available.',
                  actionLabel: 'Start over',
                  onAction: () => _startOver(context),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VideoPreviewPlayer(file: File(outcome.outputPath)),
                          const SizedBox(height: AppSpacing.xl),
                          if (outcome.wasSkipped) ...[
                            const NoticeBanner(
                              icon: Icons.verified_outlined,
                              message:
                                  'Already optimised - this clip was small and '
                                  'efficient enough to keep as-is.',
                              tone: NoticeTone.success,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          CompressionStatsCard(outcome: outcome),
                        ],
                      ),
                    ),
                  ),
                  _ResultActions(outputPath: outcome.outputPath),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static void _startOver(BuildContext context) {
    context.read<VideoCompressionBloc>().add(const FlowResetRequested());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.outputPath});

  final String outputPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaveToGalleryAction(outputPath: outputPath),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Continue',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.upload),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Start over',
            variant: AppButtonVariant.plain,
            onPressed: () => CompressionResultScreen._startOver(context),
          ),
        ],
      ),
    );
  }
}

class _SaveToGalleryAction extends StatelessWidget {
  const _SaveToGalleryAction({required this.outputPath});

  final String outputPath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GallerySaveCubit, GallerySaveState>(
      builder: (context, state) {
        final cubit = context.read<GallerySaveCubit>();

        if (state.status == GallerySaveStatus.saved) {
          return const NoticeBanner(
            icon: Icons.check_circle_outline,
            message: 'Saved to your gallery.',
            tone: NoticeTone.success,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.hasError) ...[
              NoticeBanner(
                icon: Icons.warning_amber_outlined,
                message: state.failure?.userMessage ?? 'The video could not be saved.',
                tone: NoticeTone.danger,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              label: state.hasError ? 'Try saving again' : 'Save to gallery',
              icon: state.hasError ? Icons.refresh : Icons.download_outlined,
              variant: AppButtonVariant.outlined,
              isLoading: state.isSaving,
              onPressed: () => cubit.save(File(outputPath)),
            ),
          ],
        );
      },
    );
  }
}
