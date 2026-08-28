import 'dart:io';

import '../../../../core/error/result.dart';
import '../entities/compression_outcome.dart';
import '../entities/compression_plan.dart';
import '../entities/compression_progress.dart';
import '../entities/video_metadata.dart';
import '../entities/video_thumbnail.dart';

abstract interface class VideoCompressionRepository {
  Stream<CompressionProgress> get progress;

  Future<Result<VideoMetadata>> analyze(File file);

  Future<Result<VideoThumbnail?>> thumbnail(File file, Duration at);

  CompressionPlan buildPlan(VideoMetadata metadata);

  Future<Result<CompressionOutcome>> compress(File file, CompressionPlan plan);

  Future<void> cancel();
}
