import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_message_view.dart';
import 'video_surface.dart';

class VideoPreviewPlayer extends StatefulWidget {
  const VideoPreviewPlayer({required this.file, super.key});

  final File file;

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(false)
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object _) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
      return;
    }
    if (_controller.value.position >= _controller.value.duration) {
      _controller.seekTo(Duration.zero);
    }
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: AppMessageView(
          icon: Icons.videocam_off_outlined,
          title: 'Preview unavailable',
          message: 'The compressed file could not be opened for playback.',
          tone: AppMessageTone.danger,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoSurface(controller: _controller, onTogglePlay: _togglePlay),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            return Row(
              children: [
                Text(Formatters.duration(value.position), style: AppTextStyles.mono),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: value.isInitialized,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.ink,
                      bufferedColor: AppColors.border,
                      backgroundColor: AppColors.surfaceSunken,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  Formatters.duration(value.duration),
                  style: AppTextStyles.mono.copyWith(color: AppColors.textTertiary),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
