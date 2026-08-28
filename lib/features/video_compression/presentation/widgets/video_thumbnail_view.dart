import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class VideoThumbnailView extends StatelessWidget {
  const VideoThumbnailView({required this.path, super.key});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final thumbnailPath = path;
    if (thumbnailPath == null) return const _ThumbnailPlaceholder();

    return Image.file(
      File(thumbnailPath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceSunken,
      child: Center(child: Icon(Icons.movie_outlined, size: 26, color: AppColors.textTertiary)),
    );
  }
}
