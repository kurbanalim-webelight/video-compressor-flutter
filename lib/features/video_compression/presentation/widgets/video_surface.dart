import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

class VideoSurface extends StatelessWidget {
  const VideoSurface({required this.controller, required this.onTogglePlay, super.key});

  final VideoPlayerController controller;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized) {
          return const ColoredBox(
            color: AppColors.surfaceSunken,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textTertiary)),
          );
        }

        return GestureDetector(
          onTap: onTogglePlay,
          child: ColoredBox(
            color: AppColors.scrim,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(controller)),
                ),
                if (!value.isPlaying) const Center(child: _PlayBadge()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.92), shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow_rounded, size: 30, color: AppColors.ink),
    );
  }
}
